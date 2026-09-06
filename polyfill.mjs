// Node.js polyfill for Bun APIs used by opencode
import fs from "fs";
import path from "path";
import crypto from "crypto";
import { execSync } from "child_process";

function stringWidth(str) {
  if (typeof str !== "string") str = String(str);
  str = str.replace(/\u001b\[[0-9;]*[a-zA-Z]/g, "");
  let width = 0;
  for (const ch of str) {
    const code = ch.codePointAt(0);
    if (code === 0x0a || code === 0x0d || code === 0x09) continue;
    if (code >= 0x1100 && (
      code <= 0x115f || code === 0x2329 || code === 0x232a ||
      (code >= 0x2e80 && code <= 0xa4cf && code !== 0x303f) ||
      (code >= 0xac00 && code <= 0xd7a3) ||
      (code >= 0xf900 && code <= 0xfaff) ||
      (code >= 0xfe10 && code <= 0xfe19) ||
      (code >= 0xfe30 && code <= 0xfe6f) ||
      (code >= 0xff00 && code <= 0xff60) ||
      (code >= 0xffe0 && code <= 0xffe6) ||
      (code >= 0x1f300 && code <= 0x1f64f) ||
      (code >= 0x1f900 && code <= 0x1f9ff) ||
      (code >= 0x20000 && code <= 0x3fffd)
    )) { width += 2; }
    else if (code >= 0x20 && code !== 0x7f) { width += 1; }
  }
  return width;
}

function bunFile(filePath) {
  return {
    text: () => Promise.resolve(fs.readFileSync(filePath, "utf-8")),
    json: () => Promise.resolve(JSON.parse(fs.readFileSync(filePath, "utf-8"))),
    arrayBuffer: () => Promise.resolve(fs.readFileSync(filePath).buffer),
    exists: () => fs.existsSync(filePath),
  };
}

async function bunWrite(filePath, content) {
  const d = path.dirname(filePath);
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
  if (typeof content === "string") fs.writeFileSync(filePath, content, "utf-8");
  else if (content instanceof Uint8Array || Buffer.isBuffer(content)) fs.writeFileSync(filePath, content);
  else fs.writeFileSync(filePath, JSON.stringify(content), "utf-8");
}

function bun$(strings, ...values) {
  let cmd = strings[0];
  for (let i = 0; i < values.length; i++) cmd += values[i] + strings[i + 1];
  return {
    text: () => Promise.resolve(execSync(cmd, { encoding: "utf-8" })),
    json: () => Promise.resolve(JSON.parse(execSync(cmd, { encoding: "utf-8" }))),
  };
}

function bunHash(data) {
  const str = typeof data === "string" ? data : JSON.stringify(data);
  return BigInt("0x" + crypto.createHash("md5").update(str).digest("hex").slice(0, 16));
}

globalThis.Bun = {
  stringWidth,
  file: bunFile,
  write: bunWrite,
  $: bun$,
  hash: bunHash,
  stdin: { text: () => Promise.resolve(fs.readFileSync(0, "utf-8")) },
  version: "node-polyfill",
  main: false,
};
export {};
