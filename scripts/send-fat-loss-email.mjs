#!/usr/bin/env node
/**
 * Send today's fat-loss plan email via Gmail SMTP (App Password).
 *
 * Required env:
 *   GMAIL_USER          — sender Gmail address (e.g. pwyw000@gmail.com)
 *   GMAIL_APP_PASSWORD  — 16-char Google App Password (spaces optional)
 *   EMAIL_TO            — recipient (default: pwyw000@gmail.com)
 *
 * Body source (first match wins):
 *   1) --file <path>
 *   2) EMAIL_BODY_FILE
 *   3) stdin
 *   4) logs/plans/YYYY-MM-DD.md (America/New_York "today")
 *
 * Subject:
 *   EMAIL_SUBJECT or "减脂计划 · YYYY-MM-DD"
 *
 * Flags:
 *   --dry-run   print what would be sent, do not send
 *   --file PATH plan markdown/text file
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import nodemailer from "nodemailer";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

function todayInEastern() {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/New_York",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

function parseArgs(argv) {
  const out = { dryRun: false, file: null };
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (a === "--dry-run") out.dryRun = true;
    else if (a === "--file") {
      out.file = argv[i + 1];
      i += 1;
    }
  }
  return out;
}

function readStdinSync() {
  try {
    if (process.stdin.isTTY) return "";
    return fs.readFileSync(0, "utf8").trim();
  } catch {
    return "";
  }
}

function loadBody(args, dateStr) {
  if (args.file) {
    const p = path.isAbsolute(args.file) ? args.file : path.join(ROOT, args.file);
    return fs.readFileSync(p, "utf8");
  }
  if (process.env.EMAIL_BODY_FILE) {
    const p = path.isAbsolute(process.env.EMAIL_BODY_FILE)
      ? process.env.EMAIL_BODY_FILE
      : path.join(ROOT, process.env.EMAIL_BODY_FILE);
    return fs.readFileSync(p, "utf8");
  }
  const fromStdin = readStdinSync();
  if (fromStdin) return fromStdin;

  const defaultPlan = path.join(ROOT, "logs", "plans", `${dateStr}.md`);
  if (fs.existsSync(defaultPlan)) return fs.readFileSync(defaultPlan, "utf8");

  throw new Error(
    `No email body found. Pass --file, EMAIL_BODY_FILE, stdin, or create logs/plans/${dateStr}.md`,
  );
}

function markdownToPlainishHtml(text) {
  const escaped = text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
  return `<pre style="font-family:ui-sans-serif,system-ui,sans-serif;font-size:14px;line-height:1.5;white-space:pre-wrap;">${escaped}</pre>`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const dateStr = todayInEastern();
  const to = process.env.EMAIL_TO || "pwyw000@gmail.com";
  const subject =
    process.env.EMAIL_SUBJECT || `减脂计划 · ${dateStr}`;
  const body = loadBody(args, dateStr);

  if (args.dryRun) {
    console.log("--- dry-run ---");
    console.log(`to: ${to}`);
    console.log(`subject: ${subject}`);
    console.log(`body chars: ${body.length}`);
    console.log(body.slice(0, 500) + (body.length > 500 ? "\n…" : ""));
    return;
  }

  const user = process.env.GMAIL_USER;
  const pass = (process.env.GMAIL_APP_PASSWORD || "").replace(/\s+/g, "");
  if (!user || !pass) {
    throw new Error(
      "Missing GMAIL_USER or GMAIL_APP_PASSWORD. Set them in the environment / Cloud Agent secrets.",
    );
  }

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: { user, pass },
  });

  const info = await transporter.sendMail({
    from: `"Fat Burn Daily" <${user}>`,
    to,
    subject,
    text: body,
    html: markdownToPlainishHtml(body),
  });

  console.log(`Sent: ${info.messageId} → ${to}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
