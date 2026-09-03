const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getStorage} = require("firebase-admin/storage");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");

initializeApp();

const syncedFolders = new Set([
  "cover_letters",
  "license_files",
  "diaries",
  "custom_themes",
]);

const storageCors = [
  {
    origin: ["*"],
    method: ["GET", "HEAD", "PUT", "POST", "DELETE"],
    responseHeader: [
      "Content-Type",
      "Content-Length",
      "Authorization",
      "x-goog-resumable",
    ],
    maxAgeSeconds: 3600,
  },
];

getStorage()
  .bucket()
  .setCorsConfiguration(storageCors)
  .catch((error) => {
    console.error("storage cors skipped", error?.message || error);
  });

exports.kakaoWebSignIn = onCall(
  {
    cors: true,
    invoker: "public",
    region: "us-central1",
  },
  async (request) => {
    try {
      const accessToken = request.data?.accessToken;
      if (typeof accessToken !== "string" || accessToken.length < 10) {
        throw new HttpsError("invalid-argument", "missing-token");
      }

      const kakaoResponse = await fetch("https://kapi.kakao.com/v2/user/me", {
        headers: {Authorization: `Bearer ${accessToken}`},
      });
      if (!kakaoResponse.ok) {
        throw new HttpsError("unauthenticated", "kakao-token-invalid");
      }

      const me = await kakaoResponse.json();
      const kakaoId = String(me.id ?? "");
      if (!kakaoId) {
        throw new HttpsError("unauthenticated", "kakao-id-missing");
      }

      const nickname =
        me.kakao_account?.profile?.nickname ||
        me.properties?.nickname ||
        undefined;
      const auth = getAuth();
      const generatedUid = `kakao_${kakaoId}`;
      let uid;

      try {
        uid = (await auth.getUserByProviderUid("oidc.kakao", kakaoId)).uid;
      } catch (error) {
        if (error.code !== "auth/user-not-found") {
          throw error;
        }
        try {
          uid = (await auth.getUser(generatedUid)).uid;
        } catch (missing) {
          if (missing.code !== "auth/user-not-found") {
            throw missing;
          }
          const imported = await auth.importUsers([
            {
              uid: generatedUid,
              displayName: nickname,
              providerData: [
                {
                  uid: kakaoId,
                  providerId: "oidc.kakao",
                  displayName: nickname,
                },
              ],
            },
          ]);
          if (imported.errors.length) {
            uid = (await auth.createUser({
              uid: generatedUid,
              displayName: nickname,
            })).uid;
          } else {
            uid = generatedUid;
          }
        }
      }

      return {token: await auth.createCustomToken(uid, {provider: "kakao"})};
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("kakaoWebSignIn failed", error?.code, error?.message);
      throw new HttpsError("internal", error?.code || "sign-in-failed");
    }
  },
);

exports.getSyncedFile = onRequest(
  {
    cors: true,
    invoker: "public",
    region: "us-central1",
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (req, res) => {
    const header = `${req.headers.authorization || ""}`;
    const match = header.match(/^Bearer (.+)$/i);
    if (!match) {
      res.status(401).send("missing-token");
      return;
    }
    let decoded;
    try {
      decoded = await getAuth().verifyIdToken(match[1]);
    } catch (_) {
      res.status(401).send("bad-token");
      return;
    }
    const folder = `${req.query.folder || ""}`;
    const name = `${req.query.name || ""}`;
    if (
      !syncedFolders.has(folder) ||
      !name ||
      name.includes("/") ||
      name.includes("\\") ||
      name.includes("..")
    ) {
      res.status(400).send("bad-path");
      return;
    }
    try {
      const file = getStorage().bucket("jopb-65c0f.firebasestorage.app").file(
        `users/${decoded.uid}/${folder}/${name}`,
      );
      const [buffer] = await file.download();
      const [meta] = await file.getMetadata();
      res.set("Content-Type", meta.contentType || "application/octet-stream");
      res.set("Cache-Control", "private, max-age=3600");
      res.status(200).send(buffer);
    } catch (error) {
      console.error("getSyncedFile failed", folder, name, error?.message || error);
      res.status(404).send("missing");
    }
  },
);
