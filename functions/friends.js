const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

const callable = {
  cors: true,
  invoker: "public",
  region: "asia-northeast3",
};

function db() {
  return getFirestore();
}

function requireUid(request) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "login-required");
  }
  return uid;
}

const CODE_COOLDOWN_MS = 30 * 24 * 60 * 60 * 1000;

const RESERVED_CODES = new Set([
  "pluto",
  "플루토",
  "admin",
  "official",
  "support",
  "help",
]);

function normalizeHandle(raw) {
  return String(raw || "")
      .normalize("NFC")
      .replace(/＠/g, "@")
      .replace(/^@+/, "")
      .replace(/\s+/g, "")
      .replace(/[A-Z]/g, (ch) => ch.toLowerCase())
      .trim();
}

function isUsableCode(code) {
  if (!code || code.length < 2 || code.length > 32) return false;
  if (RESERVED_CODES.has(code)) return false;
  if (!/^[a-z0-9_.]+$/.test(code)) return false;
  if (code.includes("..")) return false;
  return true;
}

function parseCode(raw) {
  const code = normalizeHandle(raw);
  if (!isUsableCode(code)) {
    throw new HttpsError("invalid-argument", "bad-code");
  }
  return code;
}

function suggestCode(name) {
  const code = normalizeHandle(String(name || "").replace(/[#＃@＠/\\]/g, ""));
  return isUsableCode(code) ? code : "";
}

function isBadName(raw) {
  const value = String(raw || "").trim();
  if (!value) return true;
  if (value.includes("@")) return true;
  if (/^\d+$/.test(value)) return true;
  return false;
}

function safeName(raw) {
  const cleaned = String(raw || "")
      .normalize("NFC")
      .replace(/[#＃/\\]/g, "")
      .replace(/\s+/g, " ")
      .trim();
  if (!cleaned) return "플루토";
  return cleaned.slice(0, 16);
}

function nameFromHint(hint) {
  if (isBadName(hint)) return null;
  return safeName(hint);
}

function parseDisplayName(raw) {
  const name = String(raw || "")
      .normalize("NFC")
      .replace(/[\u0000-\u001f\u007f]/g, "")
      .replace(/\s+/g, " ")
      .trim();
  if (name.length < 1 || name.length > 16) {
    throw new HttpsError("invalid-argument", "bad-name");
  }
  if (/[#＃@＠]/.test(name)) {
    throw new HttpsError("invalid-argument", "bad-name");
  }
  return name;
}

function nameFromAuth(user) {
  const candidates = [
    user.displayName,
    ...(user.providerData || []).map((info) => info.displayName),
  ];
  for (const raw of candidates) {
    if (isBadName(raw)) continue;
    return safeName(raw);
  }
  return "플루토";
}

async function rateLimit(uid, action, max, windowMs) {
  const ref = db().collection("rate_limits").doc(`${uid}_${action}`);
  const now = Date.now();
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() || {};
    let windowStart = Number(data.windowStart) || now;
    let count = Number(data.count) || 0;
    if (now - windowStart > windowMs) {
      windowStart = now;
      count = 0;
    }
    if (count >= max) {
      throw new HttpsError("resource-exhausted", "rate-limited");
    }
    tx.set(ref, {windowStart, count: count + 1});
  });
}

function toClientProfile(uid, data, displayName) {
  const stored = String(data.friendCode || "");
  const usable = isUsableCode(stored);
  const changedAt = Number(data.friendCodeChangedAt) || 0;
  const name = displayName || String(data.displayName || "플루토");
  return {
    uid,
    displayName: name,
    friendCode: usable ? stored : "",
    suggestedCode: suggestCode(name),
    needsCode: !usable,
    codeChangedAt: changedAt,
    nextChangeAt: usable && changedAt ? changedAt + CODE_COOLDOWN_MS : 0,
    photoURL: String(data.photoURL || ""),
  };
}

async function resolveDisplayName(uid, hint) {
  try {
    const user = await getAuth().getUser(uid);
    return nameFromHint(hint) || nameFromAuth(user);
  } catch (_) {
    return nameFromHint(hint) || "플루토";
  }
}

async function profileOf(uid) {
  const snap = await db().collection("profiles").doc(uid).get();
  if (!snap.exists) return null;
  return toClientProfile(uid, snap.data() || {});
}

async function ensureProfile(uid, hint) {
  const profileRef = db().collection("profiles").doc(uid);
  const existing = await profileRef.get();
  const now = Date.now();
  if (existing.exists && existing.data()?.customName) {
    const data = existing.data() || {};
    return toClientProfile(uid, data, String(data.displayName || "플루토"));
  }
  const displayName = await resolveDisplayName(uid, hint);
  if (!existing.exists) {
    await profileRef.set({
      displayName,
      friendCode: "",
      customName: false,
      updatedAt: now,
    });
    return toClientProfile(uid, {}, displayName);
  }
  const data = existing.data() || {};
  if (data.displayName !== displayName) {
    await profileRef.update({displayName, updatedAt: now});
  }
  return toClientProfile(uid, data, displayName);
}

async function claimFriendCode(uid, rawCode, hint) {
  const code = parseCode(rawCode);
  const profileRef = db().collection("profiles").doc(uid);
  const existing = await profileRef.get();
  const data = existing.data() || {};
  const displayName = data.customName
      ? String(data.displayName || "플루토")
      : await resolveDisplayName(uid, hint);
  const now = Date.now();
  const current = String(data.friendCode || "");
  const hadUsable = isUsableCode(current);
  if (hadUsable && current === code) {
    return toClientProfile(uid, data, displayName);
  }
  if (hadUsable) {
    const changedAt = Number(data.friendCodeChangedAt) || 0;
    if (changedAt && now < changedAt + CODE_COOLDOWN_MS) {
      throw new HttpsError("failed-precondition", "code-cooldown", {
        nextChangeAt: changedAt + CODE_COOLDOWN_MS,
      });
    }
  }
  await db().runTransaction(async (tx) => {
    const taken = await tx.get(db().collection("friend_codes").doc(code));
    if (taken.exists && taken.data()?.uid !== uid) {
      throw new HttpsError("already-exists", "taken");
    }
    tx.set(db().collection("friend_codes").doc(code), {uid});
    tx.set(profileRef, {
      ...(!data.customName ? {displayName} : {}),
      friendCode: code,
      friendCodeChangedAt: now,
      updatedAt: now,
    }, {merge: true});
    if (current && current !== code) {
      tx.delete(db().collection("friend_codes").doc(current));
    }
  });
  return toClientProfile(uid, {
    ...data,
    friendCode: code,
    friendCodeChangedAt: now,
  }, displayName);
}

async function propagateName(uid, name) {
  const store = db();
  const refs = [];
  const friends = await store
      .collection("friendships")
      .doc(uid)
      .collection("friends")
      .get();
  for (const doc of friends.docs) {
    refs.push({
      ref: store.collection("friendships").doc(doc.id).collection("friends").doc(uid),
      data: {displayName: name},
    });
  }
  const outgoing = await store
      .collection("friend_requests")
      .where("fromUid", "==", uid)
      .get();
  for (const doc of outgoing.docs) {
    if (doc.data()?.status === "pending") {
      refs.push({ref: doc.ref, data: {fromName: name}});
    }
  }
  const incoming = await store
      .collection("friend_requests")
      .where("toUid", "==", uid)
      .get();
  for (const doc of incoming.docs) {
    if (doc.data()?.status === "pending") {
      refs.push({ref: doc.ref, data: {toName: name}});
    }
  }
  for (let i = 0; i < refs.length; i += 400) {
    const batch = store.batch();
    for (const item of refs.slice(i, i + 400)) {
      batch.set(item.ref, item.data, {merge: true});
    }
    await batch.commit();
  }
}

function parsePhotoURL(raw) {
  const url = String(raw || "").trim();
  if (!url) return "";
  if (!url.startsWith("https://") || url.length > 2048) {
    throw new HttpsError("invalid-argument", "bad-photo");
  }
  return url;
}

async function propagatePhoto(uid, photoURL) {
  const store = db();
  const friends = await store
      .collection("friendships")
      .doc(uid)
      .collection("friends")
      .get();
  const refs = friends.docs.map((doc) => ({
    ref: store.collection("friendships").doc(doc.id).collection("friends").doc(uid),
    data: {photoURL},
  }));
  for (let i = 0; i < refs.length; i += 400) {
    const batch = store.batch();
    for (const item of refs.slice(i, i + 400)) {
      batch.set(item.ref, item.data, {merge: true});
    }
    await batch.commit();
  }
}

async function updateFriendPhoto(uid, raw) {
  const photoURL = parsePhotoURL(raw);
  const profileRef = db().collection("profiles").doc(uid);
  const existing = await profileRef.get();
  const data = existing.data() || {};
  await profileRef.set({
    photoURL,
    updatedAt: Date.now(),
  }, {merge: true});
  propagatePhoto(uid, photoURL).catch((error) => {
    console.error("propagatePhoto failed", uid, error);
  });
  return toClientProfile(uid, {...data, photoURL});
}

async function updateFriendDisplayName(uid, raw) {
  const name = parseDisplayName(raw);
  const profileRef = db().collection("profiles").doc(uid);
  const existing = await profileRef.get();
  const data = existing.data() || {};
  await profileRef.set({
    displayName: name,
    customName: true,
    updatedAt: Date.now(),
  }, {merge: true});
  propagateName(uid, name).catch((error) => {
    console.error("propagateName failed", uid, error);
  });
  return toClientProfile(uid, {...data, displayName: name, customName: true}, name);
}

async function lookupByCode(code) {
  const snap = await db().collection("friend_codes").doc(code).get();
  const uid = snap.data()?.uid;
  if (!uid) {
    throw new HttpsError("not-found", "no-user");
  }
  const profile = await profileOf(uid);
  if (!profile || !profile.friendCode) {
    throw new HttpsError("not-found", "no-user");
  }
  return profile;
}

async function areFriends(a, b) {
  const snap = await db()
      .collection("friendships")
      .doc(a)
      .collection("friends")
      .doc(b)
      .get();
  return snap.exists;
}

async function writeFriendship(from, to) {
  const now = Date.now();
  const batch = db().batch();
  batch.set(
      db().collection("friendships").doc(from.uid).collection("friends").doc(to.uid),
      {
        uid: to.uid,
        displayName: to.displayName,
        friendCode: to.friendCode,
        photoURL: String(to.photoURL || ""),
        createdAt: now,
      },
  );
  batch.set(
      db().collection("friendships").doc(to.uid).collection("friends").doc(from.uid),
      {
        uid: from.uid,
        displayName: from.displayName,
        friendCode: from.friendCode,
        photoURL: String(from.photoURL || ""),
        createdAt: now,
      },
  );
  await batch.commit();
}

async function pendingBetween(fromUid, toUid) {
  const snaps = await db()
      .collection("friend_requests")
      .where("fromUid", "==", fromUid)
      .get();
  return snaps.docs.find((doc) => {
    const data = doc.data() || {};
    return data.toUid === toUid && data.status === "pending";
  });
}

exports.ensureFriendProfile = onCall(callable, async (request) => {
  const uid = requireUid(request);
  await rateLimit(uid, "ensure", 20, 60 * 1000);
  return ensureProfile(uid, request.data?.displayName);
});

exports.claimFriendCode = onCall(callable, async (request) => {
  const uid = requireUid(request);
  await rateLimit(uid, "claim", 10, 60 * 1000);
  return claimFriendCode(uid, request.data?.code, request.data?.displayName);
});

exports.updateFriendDisplayName = onCall(callable, async (request) => {
  const uid = requireUid(request);
  await rateLimit(uid, "rename", 10, 60 * 1000);
  return updateFriendDisplayName(uid, request.data?.displayName);
});

exports.updateFriendPhoto = onCall(callable, async (request) => {
  const uid = requireUid(request);
  await rateLimit(uid, "photo", 10, 60 * 1000);
  return updateFriendPhoto(uid, request.data?.photoURL);
});

async function lookupFriendFor(uid, rawCode) {
  await rateLimit(uid, "lookup", 20, 60 * 1000);
  const profile = await lookupByCode(parseCode(rawCode));
  if (profile.uid === uid) {
    throw new HttpsError("invalid-argument", "self");
  }
  return profile;
}

function requestPayload(me, other) {
  return {
    fromUid: me.uid,
    toUid: other.uid,
    fromName: me.displayName,
    fromCode: me.friendCode,
    fromPhotoURL: String(me.photoURL || ""),
    toName: other.displayName,
    toCode: other.friendCode,
    toPhotoURL: String(other.photoURL || ""),
    status: "pending",
    createdAt: Date.now(),
    participants: [me.uid, other.uid],
  };
}

async function sendFriendFor(uid, rawCode) {
  await rateLimit(uid, "send", 10, 60 * 1000);
  const me = await ensureProfile(uid);
  if (me.needsCode) {
    throw new HttpsError("failed-precondition", "needs-code");
  }
  const other = await lookupByCode(parseCode(rawCode));
  if (other.uid === uid) {
    throw new HttpsError("invalid-argument", "self");
  }
  if (await areFriends(uid, other.uid)) {
    throw new HttpsError("already-exists", "already-friends");
  }
  const reverse = await pendingBetween(other.uid, uid);
  if (reverse) {
    await writeFriendship(me, other);
    await reverse.ref.update({
      status: "accepted",
      updatedAt: Date.now(),
    });
    return {status: "accepted", requestId: reverse.id};
  }
  const existing = await pendingBetween(uid, other.uid);
  if (existing) {
    throw new HttpsError("already-exists", "already-sent");
  }
  const id = `${uid}_${other.uid}`;
  await db().collection("friend_requests").doc(id).set(requestPayload(me, other));
  return {status: "pending", requestId: id};
}

async function acceptFriendFor(uid, requestId) {
  if (!requestId) {
    throw new HttpsError("invalid-argument", "missing-request");
  }
  const ref = db().collection("friend_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "no-request");
  }
  const data = snap.data() || {};
  if (data.toUid !== uid || data.status !== "pending") {
    throw new HttpsError("permission-denied", "not-allowed");
  }
  const me = await ensureProfile(uid);
  const other = await profileOf(data.fromUid);
  if (!other) {
    throw new HttpsError("not-found", "no-user");
  }
  await writeFriendship(me, other);
  await ref.update({status: "accepted", updatedAt: Date.now()});
  return {status: "accepted"};
}

async function declineFriendFor(uid, requestId) {
  const ref = db().collection("friend_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "no-request");
  }
  const data = snap.data() || {};
  if (data.toUid !== uid || data.status !== "pending") {
    throw new HttpsError("permission-denied", "not-allowed");
  }
  await ref.update({status: "declined", updatedAt: Date.now()});
  return {status: "declined"};
}

async function cancelFriendFor(uid, requestId) {
  const ref = db().collection("friend_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "no-request");
  }
  const data = snap.data() || {};
  if (data.fromUid !== uid || data.status !== "pending") {
    throw new HttpsError("permission-denied", "not-allowed");
  }
  await ref.update({status: "cancelled", updatedAt: Date.now()});
  return {status: "cancelled"};
}

async function removeFriendFor(uid, otherUid) {
  if (!otherUid || otherUid === uid) {
    throw new HttpsError("invalid-argument", "bad-uid");
  }
  const batch = db().batch();
  batch.delete(
      db().collection("friendships").doc(uid).collection("friends").doc(otherUid),
  );
  batch.delete(
      db().collection("friendships").doc(otherUid).collection("friends").doc(uid),
  );
  await batch.commit();
  return {status: "removed"};
}

exports.lookupFriendCode = onCall(callable, async (request) => {
  return lookupFriendFor(requireUid(request), request.data?.code);
});

exports.sendFriendRequest = onCall(callable, async (request) => {
  return sendFriendFor(requireUid(request), request.data?.code);
});

exports.acceptFriendRequest = onCall(callable, async (request) => {
  return acceptFriendFor(requireUid(request), request.data?.requestId);
});

exports.declineFriendRequest = onCall(callable, async (request) => {
  return declineFriendFor(requireUid(request), request.data?.requestId);
});

exports.cancelFriendRequest = onCall(callable, async (request) => {
  return cancelFriendFor(requireUid(request), request.data?.requestId);
});

exports.removeFriend = onCall(callable, async (request) => {
  return removeFriendFor(requireUid(request), String(request.data?.uid || ""));
});

function parseTodoDate(raw) {
  const date = String(raw || "").trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    throw new HttpsError("invalid-argument", "bad-todo");
  }
  return date;
}

function parseTodoTitle(raw) {
  const title = String(raw || "").trim();
  if (!title || title.length > 80) {
    throw new HttpsError("invalid-argument", "bad-todo");
  }
  return title;
}

const TODO_MODES = new Set(["single", "range", "repeat", "multiple"]);
const TODO_DATE_MAX = 366;

function parseTodoSchedule(data) {
  const date = parseTodoDate(data?.date);
  const seen = new Set();
  const dates = [];
  const raw = Array.isArray(data?.dates) ? data.dates : [];
  for (const item of raw) {
    const value = String(item || "").trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || seen.has(value)) continue;
    seen.add(value);
    dates.push(value);
    if (dates.length >= TODO_DATE_MAX) break;
  }
  if (!dates.length) {
    dates.push(date);
  } else if (!seen.has(date) && dates.length < TODO_DATE_MAX) {
    dates.push(date);
  }
  dates.sort();
  const modeRaw = String(data?.dateMode || "").trim();
  const dateMode = TODO_MODES.has(modeRaw)
    ? modeRaw
    : (dates.length > 1 ? "multiple" : "single");
  return {date: dates[0], dates, dateMode};
}

async function sendTodoFor(uid, data) {
  await rateLimit(uid, "todo-send", 20, 60 * 1000);
  const me = await ensureProfile(uid);
  const otherUid = String(data?.toUid || "");
  if (!otherUid || otherUid === uid) {
    throw new HttpsError("invalid-argument", "bad-uid");
  }
  if (!(await areFriends(uid, otherUid))) {
    throw new HttpsError("failed-precondition", "not-friends");
  }
  const other = await profileOf(otherUid);
  if (!other) {
    throw new HttpsError("not-found", "no-user");
  }
  const title = parseTodoTitle(data?.title);
  const schedule = parseTodoSchedule(data);
  const memo = String(data?.memo || "").slice(0, 2000);
  const categoryName = String(data?.categoryName || "").trim().slice(0, 32);
  const categoryColor = Number(data?.categoryColor);
  const startMinutes = data?.startMinutes == null ? null : Number(data.startMinutes);
  const endMinutes = data?.endMinutes == null ? null : Number(data.endMinutes);
  const id = `${uid}_${otherUid}_${Date.now()}`;
  await db().collection("todo_requests").doc(id).set({
    fromUid: me.uid,
    toUid: other.uid,
    fromName: me.displayName,
    fromCode: me.friendCode,
    fromPhotoURL: String(me.photoURL || ""),
    toName: other.displayName,
    toCode: other.friendCode,
    toPhotoURL: String(other.photoURL || ""),
    title,
    date: schedule.date,
    dates: schedule.dates,
    dateMode: schedule.dateMode,
    memo,
    categoryName,
    categoryColor: Number.isFinite(categoryColor) ? categoryColor : 0xFF3B82F6,
    startMinutes: Number.isFinite(startMinutes) ? startMinutes : null,
    endMinutes: Number.isFinite(endMinutes) ? endMinutes : null,
    status: "pending",
    fromCompleted: false,
    toCompleted: false,
    createdAt: Date.now(),
    participants: [me.uid, other.uid],
  });
  return {status: "pending", requestId: id};
}

async function respondTodoFor(uid, requestId, nextStatus) {
  if (!requestId) {
    throw new HttpsError("invalid-argument", "missing-request");
  }
  const ref = db().collection("todo_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "no-request");
  }
  const data = snap.data() || {};
  if (data.status !== "pending") {
    throw new HttpsError("failed-precondition", "not-allowed");
  }
  if (nextStatus === "cancelled") {
    if (data.fromUid !== uid) {
      throw new HttpsError("permission-denied", "not-allowed");
    }
  } else if (data.toUid !== uid) {
    throw new HttpsError("permission-denied", "not-allowed");
  }
  await ref.update({status: nextStatus, updatedAt: Date.now()});
  return {status: nextStatus};
}

async function editTodoFor(uid, data) {
  await rateLimit(uid, "todo-edit", 30, 60 * 1000);
  const requestId = String(data?.requestId || "");
  if (!requestId) {
    throw new HttpsError("invalid-argument", "missing-request");
  }
  const ref = db().collection("todo_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "no-request");
  }
  const current = snap.data() || {};
  if (current.fromUid !== uid && current.toUid !== uid) {
    throw new HttpsError("permission-denied", "not-allowed");
  }
  if (current.status !== "accepted") {
    throw new HttpsError("failed-precondition", "not-allowed");
  }
  const title = parseTodoTitle(data?.title);
  const schedule = parseTodoSchedule(data);
  const memo = String(data?.memo || "").slice(0, 2000);
  const startMinutes = data?.startMinutes == null ? null : Number(data.startMinutes);
  const endMinutes = data?.endMinutes == null ? null : Number(data.endMinutes);
  await ref.update({
    title,
    date: schedule.date,
    dates: schedule.dates,
    dateMode: schedule.dateMode,
    memo,
    startMinutes: Number.isFinite(startMinutes) ? startMinutes : null,
    endMinutes: Number.isFinite(endMinutes) ? endMinutes : null,
    updatedAt: Date.now(),
  });
  return {status: "accepted"};
}

async function removeTodoFor(uid, requestId) {
  if (!requestId) {
    throw new HttpsError("invalid-argument", "missing-request");
  }
  const ref = db().collection("todo_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    return {status: "removed"};
  }
  const data = snap.data() || {};
  if (data.fromUid !== uid && data.toUid !== uid) {
    throw new HttpsError("permission-denied", "not-allowed");
  }
  if (data.status === "removed" || data.status === "declined" || data.status === "cancelled") {
    return {status: data.status};
  }
  await ref.update({status: "removed", updatedAt: Date.now()});
  return {status: "removed"};
}

exports.friendAction = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const action = String(request.data?.action || "");
  switch (action) {
    case "ensure":
      await rateLimit(uid, "ensure", 20, 60 * 1000);
      return ensureProfile(uid, request.data?.displayName);
    case "claim":
      await rateLimit(uid, "claim", 10, 60 * 1000);
      return claimFriendCode(uid, request.data?.code, request.data?.displayName);
    case "rename":
      await rateLimit(uid, "rename", 10, 60 * 1000);
      return updateFriendDisplayName(uid, request.data?.displayName);
    case "photo":
      await rateLimit(uid, "photo", 10, 60 * 1000);
      return updateFriendPhoto(uid, request.data?.photoURL);
    case "lookup":
      return lookupFriendFor(uid, request.data?.code);
    case "send":
      return sendFriendFor(uid, request.data?.code);
    case "accept":
      return acceptFriendFor(uid, request.data?.requestId);
    case "decline":
      return declineFriendFor(uid, request.data?.requestId);
    case "cancel":
      return cancelFriendFor(uid, request.data?.requestId);
    case "remove":
      return removeFriendFor(uid, String(request.data?.uid || ""));
    case "todo-send":
      return sendTodoFor(uid, request.data || {});
    case "todo-accept":
      return respondTodoFor(uid, String(request.data?.requestId || ""), "accepted");
    case "todo-decline":
      return respondTodoFor(uid, String(request.data?.requestId || ""), "declined");
    case "todo-cancel":
      return respondTodoFor(uid, String(request.data?.requestId || ""), "cancelled");
    case "todo-remove":
      return removeTodoFor(uid, String(request.data?.requestId || ""));
    case "todo-edit":
      return editTodoFor(uid, request.data || {});
    default:
      throw new HttpsError("invalid-argument", "bad-action");
  }
});

exports.deleteFriendData = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const store = db();
  const profile = await profileOf(uid);
  const batchDeletes = [];

  const addAll = async (query) => {
    const snaps = await query.get();
    for (const doc of snaps.docs) {
      batchDeletes.push(doc.ref);
    }
  };

  await addAll(store.collection("friend_requests").where("fromUid", "==", uid));
  await addAll(store.collection("friend_requests").where("toUid", "==", uid));
  await addAll(store.collection("todo_requests").where("fromUid", "==", uid));
  await addAll(store.collection("todo_requests").where("toUid", "==", uid));
  await addAll(store.collection("friendships").doc(uid).collection("friends"));
  await addAll(store.collection("shared_calendars").doc(uid).collection("events"));
  await addAll(store.collection("shared_calendars").doc(uid).collection("stickers"));

  const friends = await store
      .collection("friendships")
      .doc(uid)
      .collection("friends")
      .get();
  for (const doc of friends.docs) {
    batchDeletes.push(
        store.collection("friendships").doc(doc.id).collection("friends").doc(uid),
    );
  }
  if (profile?.friendCode) {
    batchDeletes.push(store.collection("friend_codes").doc(profile.friendCode));
  }
  batchDeletes.push(store.collection("profiles").doc(uid));

  for (let i = 0; i < batchDeletes.length; i += 400) {
    const batch = store.batch();
    for (const ref of batchDeletes.slice(i, i + 400)) {
      batch.delete(ref);
    }
    await batch.commit();
  }
  return {status: "deleted"};
});
