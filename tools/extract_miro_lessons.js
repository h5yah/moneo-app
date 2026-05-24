#!/usr/bin/env node
/**
 * Extracts lesson bodies from lesson_content_screen.dart into miro_lessons.json.
 * Run: node tools/extract_miro_lessons.js
 */
const fs = require("fs");
const path = require("path");

const dartPath = path.join(
  __dirname,
  "../frontend/lib/screens/home/learn_screen/lesson_content_screen.dart",
);
const learnPath = path.join(__dirname, "../frontend/assets/learn_content.json");
const outPath = path.join(__dirname, "../frontend/assets/miro_lessons.json");

const dart = fs.readFileSync(dartPath, "utf8");
const learn = JSON.parse(fs.readFileSync(learnPath, "utf8"));

/** @type {Map<string, string>} */
const titleToTopic = new Map();
for (const [topicId, topic] of Object.entries(learn.topics || {})) {
  for (const lesson of topic.lessons || []) {
    if (lesson.title) titleToTopic.set(lesson.title, topicId);
  }
}

function unescapeDartString(s) {
  return s
    .replace(/\\n/g, "\n")
    .replace(/\\'/g, "'")
    .replace(/\\"/g, '"')
    .replace(/\\\\/g, "\\");
}

function extractQuotedField(block, field) {
  const re = new RegExp(`${field}:\\s*'((?:\\\\'|[^'])*)'`, "g");
  const reD = new RegExp(`${field}:\\s*"((?:\\\\"|[^"])*)"`, "g");
  const m = re.exec(block) || reD.exec(block);
  return m ? unescapeDartString(m[1]) : "";
}

function extractBullets(block) {
  const m = block.match(/reflectionBullets:\s*\[([\s\S]*?)\]/);
  if (!m) return [];
  const inner = m[1];
  const bullets = [];
  const bulletRe = /'((?:\\'|[^'])*)'/g;
  let b;
  while ((b = bulletRe.exec(inner)) !== null) {
    bullets.push(unescapeDartString(b[1]));
  }
  return bullets;
}

const lessons = [];
const parts = dart.split(/if \(lessonTitle == '/);
for (let i = 1; i < parts.length; i++) {
  const titleEnd = parts[i].indexOf("')");
  if (titleEnd < 0) continue;
  const title = parts[i].slice(0, titleEnd);
  const after = parts[i].slice(titleEnd);
  const arrayStart = after.indexOf("return const [");
  if (arrayStart < 0) continue;
  const fromArray = after.slice(arrayStart);
  const arrayEnd = fromArray.indexOf("\n      ];");
  if (arrayEnd < 0) continue;
  const block = fromArray.slice(0, arrayEnd);
  const stepRe = /_TopicIntroStep\(\s*([\s\S]*?)\),/g;
  const steps = [];
  let stepMatch;
  while ((stepMatch = stepRe.exec(block)) !== null) {
    const stepBlock = stepMatch[1];
    const stepTitle = extractQuotedField(stepBlock, "title");
    const body = extractQuotedField(stepBlock, "body");
    const reflectionNote = extractQuotedField(stepBlock, "reflectionNote");
    const bullets = extractBullets(stepBlock);
    if (!stepTitle && !body) continue;
    steps.push({
      title: stepTitle,
      body,
      ...(bullets.length ? { bullets } : {}),
      ...(reflectionNote ? { note: reflectionNote } : {}),
    });
  }
  if (steps.length === 0) continue;
  // Skip generic placeholder intros duplicated across topics.
  if (
    steps.length === 1 &&
    steps[0].body.includes("Swipe through to explore")
  ) {
    continue;
  }
  lessons.push({
    title,
    topicId: titleToTopic.get(title) || null,
    steps,
  });
}

const output = {
  generatedAt: new Date().toISOString(),
  lessonCount: lessons.length,
  lessons,
};

fs.writeFileSync(outPath, JSON.stringify(output, null, 2));
console.log(`Wrote ${lessons.length} lessons to ${outPath}`);
