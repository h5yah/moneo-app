require("dotenv").config();

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const OpenAI = require("openai");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

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

function validatePositiveNumber(value, fieldName) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    throw new HttpsError("invalid-argument", `${fieldName} must be a positive number.`);
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

// ================= TRANSACTIONS =================

function buildTransactionPayload({
  uid,
  type,
  amount,
  expenseName,
  category,
  merchantName,
  merchantId,
  merchantAccount,
  rawPayload,
  note,
  metadata,
}) {
  return {
    userId: uid,
    type,
    amount,
    myShare: amount,
    expenseName,
    category,
    merchantName,
    merchantId,
    merchantAccount,
    rawPayload,
    note,
    date: new Date().toISOString(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    metadata: metadata ?? {},
  };
}

async function performFinanceTransaction({
  uid,
  amount,
  type,
  expenseName,
  category,
  note,
  metadata,
  merchantName,
  merchantId,
  merchantAccount,
  rawPayload,
  operation,
}) {
  const balanceRef = db.collection("balances").doc(uid);
  const transactionRef = db.collection("transactions").doc();

  return db.runTransaction(async (tx) => {
    const balanceSnap = await tx.get(balanceRef);
    const balanceData = balanceSnap.data() ?? {};

    const currentAvailable = toNumber(balanceData.available, 0);
    const currentIncome = toNumber(balanceData.income, 0);
    const currentSpent = toNumber(balanceData.spent, 0);
    const currentSaved = toNumber(balanceData.saved, 0);

    const next = operation({
      currentAvailable,
      currentIncome,
      currentSpent,
      currentSaved,
      amount,
    });

    tx.set(
      balanceRef,
      {
        available: next.available,
        income: next.income,
        spent: next.spent,
        saved: next.saved,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    tx.set(
      transactionRef,
      buildTransactionPayload({
        uid,
        type,
        amount,
        expenseName,
        category,
        merchantName,
        merchantId,
        merchantAccount,
        rawPayload,
        note,
        metadata,
      }),
      { merge: true }
    );

    return next;
  });
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

// ================= AI (FIXED) =================

exports.miroChat = onCall(
  {
    maxInstances: 5,
  },
  async (request) => {
    const uid = requireAuth(request);

    const message = sanitizeString(request.data?.message);
    if (!message) {
      throw new HttpsError("invalid-argument", "message is required.");
    }

    const lessonContext = sanitizeString(request.data?.lessonContext);
    const maxContextLen = 8000;
    const trimmedContext =
      lessonContext.length > maxContextLen
        ? `${lessonContext.slice(0, maxContextLen)}\n…`
        : lessonContext;

    // ✅ SAFE KEY FROM .env
    const key = process.env.OPENAI_API_KEY;

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
        "The user may be asking about material from the app's Learn section. Below is an excerpt from that curriculum (lesson titles and quiz notes).",
        "If their question clearly relates to this excerpt, base your answer on it and stay consistent with it.",
        "If the question is unrelated or only loosely related, ignore the excerpt and answer from general financial literacy knowledge.",
        "",
        "--- App curriculum excerpt ---",
        trimmedContext,
        "--- End excerpt ---",
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