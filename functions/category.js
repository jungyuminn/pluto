const {onCall, HttpsError} = require("firebase-functions/v2/https");

const callable = {
  cors: true,
  invoker: "public",
  region: "asia-northeast3",
  timeoutSeconds: 15,
  memory: "256MiB",
};

function briefOf(kind) {
  switch (kind) {
    case "ledger":
      return (
        "가계부 칸입니다. 돈이 오간 곳을 고르세요. 예: 점심값→식비, 버스비→교통.\n" +
        "운동·여행처럼 할 일 이름은 쓰지 마세요."
      );
    case "license":
      return "자격증 칸입니다. 시험·자격의 종류를 고르세요. 예: 토익→어학, 정보처리기사→기사.";
    case "company":
      return "지원서 칸입니다. 회사·기관의 종류를 고르세요. 예: 삼성전자→대기업.";
    default:
      return (
        "할 일·일기 칸입니다. 하는 일의 종류를 고르세요. 예: 축구가기→운동.\n" +
        "식비·교통처럼 돈 쓰는 곳 이름은 쓰지 마세요."
      );
  }
}

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

async function classify(title, names, kind) {
  const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
  if (!project) {
    throw new Error("missing-project");
  }
  const list = names.length ? names.join(", ") : "없음";
  const prompt =
    `${briefOf(kind)}\n` +
    "- 분명히 같은 종류일 때만 기존 칸. mode는 existing.\n" +
    "- 일상, 기타, 일반, 할일처럼 넓은 칸은 그 일이 그 칸의 이름 그대로일 때만 쓰세요. 나머지를 거기에 넣지 마세요.\n" +
    "- 기존 칸에 딱 안 맞으면 더 구체적인 새 칸. mode는 new.\n" +
    "- 새 이름은 2~8글자 명사. 제목을 그대로 쓰지 마세요.\n" +
    `제목: ${title}\n` +
    `기존 칸: ${list}`;
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
      contents: [{role: "user", parts: [{text: prompt}]}],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 48,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            mode: {type: "STRING", enum: ["existing", "new"]},
            name: {type: "STRING"},
          },
          required: ["mode", "name"],
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
  const parsed = JSON.parse(text);
  return {
    mode: `${parsed.mode || ""}`.trim(),
    name: `${parsed.name || ""}`.trim(),
  };
}

exports.classifyCategory = onCall(callable, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "login-required");
  }
  const title = `${request.data?.title || ""}`.trim().slice(0, 80);
  const kind = `${request.data?.kind || "event"}`;
  const names = Array.isArray(request.data?.names)
    ? request.data.names
        .map((name) => `${name || ""}`.trim())
        .filter((name) => name.length > 0)
        .slice(0, 40)
    : [];
  if (!title) {
    throw new HttpsError("invalid-argument", "missing-title");
  }
  try {
    return await classify(title, names, kind);
  } catch (error) {
    console.error("classifyCategory failed", error?.message || error);
    throw new HttpsError("internal", "classify-failed");
  }
});
