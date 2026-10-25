const {onCall, HttpsError} = require("firebase-functions/v2/https");

const callable = {
  cors: true,
  invoker: "public",
  region: "asia-northeast3",
  timeoutSeconds: 40,
  memory: "512MiB",
};

async function accessToken() {
  const res = await fetch(
    "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token",
    {headers: {"Metadata-Flavor": "Google"}},
  );
  if (!res.ok) {
    throw new Error(`metadata-token-${res.status}`);
  }
  const json = await res.json();
  if (!json.access_token) {
    throw new Error("metadata-token-missing");
  }
  return json.access_token;
}

function cleanEvents(raw, year) {
  const list = Array.isArray(raw) ? raw : raw?.events;
  if (!Array.isArray(list)) return [];
  const events = [];
  for (const item of list.slice(0, 80)) {
    const title = `${item?.title || ""}`.trim().slice(0, 80);
    if (!title) continue;
    const parsed = parseDay(`${item?.date || ""}`, year);
    if (!parsed) continue;
    events.push({
      title,
      date: parsed,
      until: clampUntil(parsed, parseDay(`${item?.until || ""}`, year)),
      start: parseClock(`${item?.start || ""}`),
      end: parseClock(`${item?.end || ""}`),
    });
  }
  return events;
}

function parseDay(text, year) {
  const match = text.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
  if (!match) return "";
  const y = Number(match[1]);
  const m = Number(match[2]);
  const d = Number(match[3]);
  if (y < year - 1 || y > year + 1) return "";
  if (m < 1 || m > 12 || d < 1 || d > 31) return "";
  return `${y}-${String(m).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
}

function clampUntil(start, until) {
  if (!until || until < start) return start;
  const from = new Date(`${start}T00:00:00`);
  const to = new Date(`${until}T00:00:00`);
  const days = Math.round((to - from) / 86400000);
  if (days > 62) {
    const last = new Date(from);
    last.setDate(last.getDate() + 62);
    return `${last.getFullYear()}-${String(last.getMonth() + 1).padStart(2, "0")}-${String(last.getDate()).padStart(2, "0")}`;
  }
  return until;
}

function parseClock(text) {
  const match = text.trim().match(/^(\d{1,2}):(\d{2})$/);
  if (!match) return "";
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  if (hour > 23 || minute > 59) return "";
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

async function readPhoto({image, mime, year}) {
  const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
  if (!project) {
    throw new Error("missing-project");
  }
  const prompt =
    "달력 사진에서 실제 일정만 뽑으세요.\n" +
    "- 날짜는 YYYY-MM-DD.\n" +
    "- 하루 일정은 date만 넣고 until은 빈 문자.\n" +
    "- 여러 날에 걸친 막대·기간은 하루씩 쪼개지 말고 date=첫날, until=마지막날.\n" +
    "- 제목이 첫 칸에만 있고 옆 칸으로 이어진 막대도 기간입니다.\n" +
    "- 시간이 있으면 start와 end는 HH:MM, 없으면 빈 문자.\n" +
    "- 공휴일, 요일, 빈 칸, 달 이름만 있는 글자는 빼세요.\n" +
    "- 제목은 사진에 쓰인 대로 짧게.\n" +
    `연도가 안 보이면 ${year}년을 쓰세요.`;
  const token = await accessToken();
  const url =
    `https://aiplatform.googleapis.com/v1/projects/${project}` +
    "/locations/global/publishers/google/models/gemini-3.5-flash-lite:generateContent";
  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [
        {
          role: "user",
          parts: [
            {text: prompt},
            {inlineData: {mimeType: mime, data: image}},
          ],
        },
      ],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 4096,
        responseMimeType: "application/json",
        responseSchema: {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              title: {type: "STRING"},
              date: {type: "STRING"},
              until: {type: "STRING"},
              start: {type: "STRING"},
              end: {type: "STRING"},
            },
            required: ["title", "date", "until", "start", "end"],
          },
        },
        thinkingConfig: {thinkingBudget: 0},
      },
    }),
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`vertex-${response.status}: ${body.slice(0, 240)}`);
  }
  const json = await response.json();
  const text = json?.candidates?.[0]?.content?.parts
    ?.map((part) => part.text || "")
    .join("")
    .trim();
  if (!text) {
    throw new Error("empty-model");
  }
  return cleanEvents(JSON.parse(text), year);
}

exports.importCalendarPhoto = onCall(callable, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "login-required");
  }
  const image = `${request.data?.image || ""}`.replace(/\s+/g, "");
  const mime = `${request.data?.mime || "image/jpeg"}`.trim();
  const year = Number(request.data?.year) || new Date().getFullYear();
  if (image.length < 80 || image.length > 1_800_000) {
    throw new HttpsError("invalid-argument", "bad-image");
  }
  if (!["image/jpeg", "image/png", "image/webp"].includes(mime)) {
    throw new HttpsError("invalid-argument", "bad-mime");
  }
  try {
    return {events: await readPhoto({image, mime, year})};
  } catch (error) {
    console.error("importCalendarPhoto failed", error?.message || error);
    throw new HttpsError("internal", "photo-failed");
  }
});
