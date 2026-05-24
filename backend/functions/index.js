if (process.env.FUNCTIONS_EMULATOR === "true") {
  require("dotenv").config({ path: ".env.local" });
}

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const OpenAI = require("openai");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const openAiApiKey = defineSecret("OPENAI_API_KEY");

setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
});

// ================= HELPERS =================

function requireAuth(request) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return uid;
}

function validatePositiveInteger(value, fieldName) {
  if (!Number.isInteger(value) || value <= 0) {
    throw new HttpsError("invalid-argument", `${fieldName} must be a positive integer.`);
  }
}

function sanitizeString(value, fallback = "") {
  if (typeof value !== "string") return fallback;
  return value.trim();
}

function toNumber(value, fallback = 0) {
  const normalized = Number(value);
  if (!Number.isFinite(normalized)) return fallback;
  return normalized;
}

function resolveOpenAiKey() {
  try {
    const secret = openAiApiKey.value();
    if (secret) return secret;
  } catch (_) {
    // Secret not bound (e.g. local emulator without secrets).
  }
  if (process.env.FUNCTIONS_EMULATOR === "true") {
    return process.env.OPENAI_API_KEY || "";
  }
  return "";
}

// ================= XP =================

exports.getXp = onCall(async (request) => {
  const uid = requireAuth(request);
  const snap = await db.collection("users").doc(uid).get();

  if (!snap.exists) {
    throw new HttpsError("not-found", "User profile does not exist.");
  }

  return { xp: Number(snap.data()?.xp ?? 0) };
});

function logXpTransaction(tx, userRef, payload) {
  tx.set(userRef.collection("xpTransactions").doc(), {
    ...payload,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

exports.earnXp = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;
  const source = sanitizeString(request.data?.source, "unknown");

  validatePositiveInteger(amount, "amount");

  const userRef = db.collection("users").doc(uid);

  const updatedXp = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) throw new HttpsError("not-found", "User profile does not exist.");

    const currentXp = Number(snap.data()?.xp ?? 0);
    const newXp = currentXp + amount;

    tx.update(userRef, {
      xp: newXp,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logXpTransaction(tx, userRef, {
      type: "earn",
      amount,
      previousXp: currentXp,
      newXp,
      source,
    });

    return newXp;
  });

  return { xp: updatedXp };
});

exports.earnXpOnce = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;
  const source = sanitizeString(request.data?.source, "unknown");
  const awardKey = sanitizeString(request.data?.awardKey);

  validatePositiveInteger(amount, "amount");
  if (!awardKey) {
    throw new HttpsError("invalid-argument", "awardKey is required.");
  }

  const userRef = db.collection("users").doc(uid);
  const awardRef = userRef.collection("xpAwards").doc(awardKey);

  return db.runTransaction(async (tx) => {
    const awardSnap = await tx.get(awardRef);
    const userSnap = await tx.get(userRef);

    if (!userSnap.exists) {
      throw new HttpsError("not-found", "User profile does not exist.");
    }

    const currentXp = Number(userSnap.data()?.xp ?? 0);

    if (awardSnap.exists) {
      return { xp: currentXp, awarded: false };
    }

    const newXp = currentXp + amount;

    tx.update(userRef, {
      xp: newXp,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(awardRef, {
      amount,
      source,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logXpTransaction(tx, userRef, {
      type: "earn",
      amount,
      previousXp: currentXp,
      newXp,
      source,
      awardKey,
    });

    return { xp: newXp, awarded: true };
  });
});

exports.spendXp = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;
  const source = sanitizeString(request.data?.source, "unknown");

  validatePositiveInteger(amount, "amount");

  const userRef = db.collection("users").doc(uid);

  const updatedXp = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "User profile does not exist.");
    }

    const currentXp = Number(snap.data()?.xp ?? 0);
    if (currentXp < amount) {
      throw new HttpsError("failed-precondition", "Not enough XP.");
    }

    const newXp = currentXp - amount;

    tx.update(userRef, {
      xp: newXp,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logXpTransaction(tx, userRef, {
      type: "spend",
      amount,
      previousXp: currentXp,
      newXp,
      source,
    });

    return newXp;
  });

  return { xp: updatedXp };
});

// ================= FINANCE =================

exports.getFinanceSummary = onCall(async (request) => {
  const uid = requireAuth(request);
  const snap = await db.collection("balances").doc(uid).get();
  const data = snap.data() ?? {};

  return {
    available: toNumber(data.available, 0),
    income: toNumber(data.income, 0),
    spent: toNumber(data.spent, 0),
    saved: toNumber(data.saved, 0),
  };
});

// ================= AI =================

exports.miroChat = onCall(
  {
    maxInstances: 5,
    secrets: [openAiApiKey],
  },
  async (request) => {
    requireAuth(request);

    const message = sanitizeString(request.data?.message);
    if (!message) {
      throw new HttpsError("invalid-argument", "message is required.");
    }

    const knowledgeContext = sanitizeString(
      request.data?.knowledgeContext || request.data?.lessonContext,
    );
    const maxContextLen = 14000;
    const trimmedContext =
      knowledgeContext.length > maxContextLen
        ? `${knowledgeContext.slice(0, maxContextLen)}\n…`
        : knowledgeContext;

    const key = resolveOpenAiKey();
    if (!key) {
      throw new HttpsError("failed-precondition", "Missing API key.");
    }

    const client = new OpenAI({ apiKey: key });

    const systemParts = [
      'You are "Miro", a financial literacy coach for the Monéo app (Mauritius). Be simple, helpful, and practical.',
      "Always express money in Mauritian Rupees. Prefer the format \"Rs\" with thousands separators (e.g. Rs 2,000 or Rs 15,000). You may also use \"MUR\" when matching app lesson content.",
      "Never use $, USD, or other currencies unless the user explicitly asks about converting or comparing foreign currency.",
    ];
    if (trimmedContext) {
      systemParts.push(
        "Below is official Monéo documentation: app features (tabs, tools, wallet, deals, XP), lesson content, and quiz material.",
        "When the user asks how to use the app, where to find something, or what a feature does, answer from this documentation — include navigation paths (e.g. Home → Tools → Loan).",
        "When they ask about a financial concept covered in the lessons, teach using that content and stay consistent with it.",
        "When the question is general financial literacy not covered above, answer from your own knowledge but keep Rs/MUR and Mauritius context.",
        "Do not invent features that are not listed. If unsure, say what the app does support.",
        "",
        "--- Monéo knowledge base ---",
        trimmedContext,
        "--- End knowledge base ---",
      );
    }

    try {
      const completion = await client.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: systemParts.join("\n"),
          },
          { role: "user", content: message },
        ],
      });

      const reply = completion.choices?.[0]?.message?.content?.trim();

      return {
        reply: reply || "Try asking again.",
      };
    } catch (err) {
      console.error(err);
      throw new HttpsError("internal", "AI error.");
    }
  }
);
