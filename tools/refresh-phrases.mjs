#!/usr/bin/env node
// Narrator — AI phrase refresher.
//
// Generates new phrase packs for any locale and writes them to
// Locale/gen.lua, which the addon loads at login (and merges per the
// /nar style setting). The addon itself never touches the network —
// this script does, outside the game.
//
// Usage:
//   node tools/refresh-phrases.mjs                        # enUS,esES
//   node tools/refresh-phrases.mjs --locales frFR,deDE --per 8
//   node tools/refresh-phrases.mjs --dry                  # print, don't write
//
// Providers (first match wins, any can be mixed via env):
//   OLLAMA_BASE_URL   e.g. http://localhost:11434/v1   (no key needed)
//   ZAI_API_KEY       Z.ai pay-as-you-go (glm models)
//   OPENAI_API_KEY    any OpenAI-compatible endpoint
//                     (+ OPENAI_BASE_URL / OPENAI_MODEL)
//
// Requires Node 18+ (global fetch).

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const GEN_FILE = join(ROOT, "Locale", "gen.lua");
const LOCALE_DIR = join(ROOT, "Locale");

// Auto-load .env from the repo root (KEY=VALUE lines, # comments), so users
// don't need --env-file or exports. Real environment variables win.
if (existsSync(join(ROOT, ".env"))) {
  for (const line of readFileSync(join(ROOT, ".env"), "utf8").split("\n")) {
    if (line.trim().startsWith("#")) continue;
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (!m) continue;
    const value = m[2].replace(/^["']|["']$/g, "");
    if (process.env[m[1]] === undefined) process.env[m[1]] = value;
  }
}

const KINDS = [
  "death", "pvpdeath", "milestone", "fall", "fire", "drown", "fatigue",
  "unknown", "crit", "levelup", "loot", "legendary", "pvpkill", "login",
];

// Embedded style seeds used when the enUS locale file can't be parsed.
const SEEDS = {
  death: ["You die to {name}. The world barely notices."],
  crit: ["The dice roll in your favor: {amount} in a single blow."],
  levelup: ["Level {level}. The legend grows, and with it the debt of untold stories."],
  loot: ["Epic spoils: {item}. The gods of chance are generous. For now."],
  pvpkill: ["{name} falls before you. The narrator smiles, dark and pleased."],
  login: ["Wake, {name}. The mist parts. The story continues."],
};

const LOCALE_LANGUAGE_NAMES = {
  enUS: "English", enGB: "English (UK)", esES: "Spanish (Spain)",
  esMX: "Spanish (Latin America)", frFR: "French", deDE: "German",
  ptBR: "Portuguese (Brazil)", itIT: "Italian", ruRU: "Russian",
  koKR: "Korean", zhCN: "Chinese (Simplified)", zhTW: "Chinese (Traditional)",
};

// --------------------------------------------------------------------------
// CLI args
// --------------------------------------------------------------------------

function parseArgs(argv) {
  const out = { locales: ["enUS", "esES"], per: 6, dry: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--locales") out.locales = (argv[++i] || "").split(",").map(s => s.trim()).filter(Boolean);
    else if (a === "--per") out.per = Math.max(1, Math.min(12, parseInt(argv[++i], 10) || 6));
    else if (a === "--dry") out.dry = true;
  }
  return out;
}

// --------------------------------------------------------------------------
// Provider selection
// --------------------------------------------------------------------------

function provider() {
  if (process.env.OLLAMA_BASE_URL) {
    return {
      url: joinURL(process.env.OLLAMA_BASE_URL, "/chat/completions"),
      model: process.env.OLLAMA_MODEL || "llama3.1:8b",
      key: null,
    };
  }
  if (process.env.ZAI_API_KEY) {
    return {
      url: "https://api.z.ai/api/paas/v4/chat/completions",
      model: process.env.ZAI_MODEL || "glm-5.3-flash",
      key: process.env.ZAI_API_KEY,
    };
  }
  if (process.env.OPENAI_API_KEY) {
    return {
      url: joinURL(process.env.OPENAI_BASE_URL || "https://api.openai.com/v1", "/chat/completions"),
      model: process.env.OPENAI_MODEL || "gpt-4o-mini",
      key: process.env.OPENAI_API_KEY,
    };
  }
  return null;
}

function joinURL(base, path) {
  return base.replace(/\/+$/, "") + path;
}

// --------------------------------------------------------------------------
// Style reference: mine the existing enUS phrases so the model keeps the voice
// --------------------------------------------------------------------------

function mineSeeds() {
  try {
    const src = readFileSync(join(LOCALE_DIR, "enUS.lua"), "utf8");
    const block = src.match(/L\.phrases = \{([\s\S]*?)\n\}/);
    if (!block) throw new Error("phrases block not found");
    const seeds = {};
    for (const m of block[1].matchAll(/^\s*(\w+) = \{([\s\S]*?)\},?\s*$/gm)) {
      const kind = m[1];
      const phrases = [...m[2].matchAll(/"((?:[^"\\]|\\.)*)"/g)].map(x => x[1]).slice(0, 2);
      if (phrases.length) seeds[kind] = phrases;
    }
    if (!seeds.death) throw new Error("death kind not found");
    return seeds;
  } catch {
    console.warn("! could not mine enUS.lua, using embedded seeds");
    return SEEDS;
  }
}

// --------------------------------------------------------------------------
// Prompt
// --------------------------------------------------------------------------

function buildPrompt(locale, per, seeds) {
  const language = LOCALE_LANGUAGE_NAMES[locale] || locale;
  const examples = KINDS
    .filter(k => seeds[k])
    .map(k => `  ${k}: ${JSON.stringify(seeds[k])}`)
    .join("\n");
  return {
    system:
      "You are the narrator of a fantasy game: an ominous, theatrical, dry-witted voice " +
      "in the style of the Baldur's Gate 3 narrator. You write short second-person " +
      "narration lines (6-20 words) about the player's fate. Dark humor, no emojis, " +
      "no quotation marks inside lines, no repeats of the example lines.",
    user:
      `Write ${per} new narration lines for each event kind below, in ${language}.\n` +
      `Return ONLY a JSON object: { "<kind>": ["line", ...], ... } with exactly ${per} ` +
      `lines per kind, no markdown, no commentary.\n\n` +
      `Event kinds:\n${KINDS.map(k => "  " + k).join("\n")}\n\n` +
      `Placeholders you may use (keep them verbatim where they fit):\n` +
      `  {name} attacker/victim/player name · {amount} crit damage · {level} new level\n` +
      `  {item} looted item · {zone} current zone · {tod} time of day · {deaths} death count\n\n` +
      `Style reference (English examples — translate the voice, not the words):\n${examples}`,
  };
}

// --------------------------------------------------------------------------
// LLM call + validation
// --------------------------------------------------------------------------

async function generatePack(p, locale, per, seeds) {
  const prompt = buildPrompt(locale, per, seeds);
  const body = {
    model: p.model,
    messages: [
      { role: "system", content: prompt.system },
      { role: "user", content: prompt.user },
    ],
    temperature: 1.0,
  };
  const headers = { "Content-Type": "application/json" };
  if (p.key) headers.Authorization = `Bearer ${p.key}`;

  const res = await fetch(p.url, { method: "POST", headers, body: JSON.stringify(body) });
  if (!res.ok) throw new Error(`${p.url} -> HTTP ${res.status}: ${(await res.text()).slice(0, 300)}`);
  const data = await res.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error("empty completion");

  const cleaned = content.replace(/^```(?:json)?/m, "").replace(/```\s*$/m, "").trim();
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  const parsed = JSON.parse(cleaned.slice(start, end + 1));

  const pack = {};
  for (const kind of KINDS) {
    const lines = parsed[kind];
    if (!Array.isArray(lines)) continue;
    pack[kind] = lines
      .filter(x => typeof x === "string" && x.length > 5 && !x.includes('"'))
      .slice(0, per);
  }
  const total = Object.values(pack).reduce((n, a) => n + a.length, 0);
  if (total === 0) throw new Error("no usable lines in response");
  return pack;
}

// --------------------------------------------------------------------------
// gen.lua writer
// --------------------------------------------------------------------------

function luaQuote(s) {
  return '"' + s
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/[\r\n]+/g, " ") + '"';
}

function renderGenLua(packs, per) {
  const lines = [
    "-- Narrator — AI-generated phrase packs (auto-managed).",
    `-- Produced by tools/refresh-phrases.mjs (${packs.map(p => p.locale + ":" + p.count).join(", ") || "empty"}).`,
    "-- Safe to delete or hand-edit; the addon reads this file at login.",
    "",
    "Narrator = Narrator or {}",
    "Narrator.GENERATED = Narrator.GENERATED or {}",
    "Narrator.GENERATED.phrases = Narrator.GENERATED.phrases or {}",
  ];
  for (const { locale, pack } of packs) {
    lines.push(`Narrator.GENERATED.phrases[${luaQuote(locale)}] = {`);
    for (const kind of KINDS) {
      if (!pack[kind]) continue;
      lines.push(`  ${kind} = {`);
      for (const phrase of pack[kind]) lines.push(`    ${luaQuote(phrase)},`);
      lines.push(`  },`);
    }
    lines.push(`}`);
  }
  lines.push("");
  return lines.join("\n");
}

// --------------------------------------------------------------------------
// Main
// --------------------------------------------------------------------------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const p = provider();
  if (!p) {
    console.error("No provider configured. Set one of:");
    console.error("  OLLAMA_BASE_URL=http://localhost:11434/v1");
    console.error("  ZAI_API_KEY=...");
    console.error("  OPENAI_API_KEY=... (optionally OPENAI_BASE_URL / OPENAI_MODEL)");
    process.exit(1);
  }

  console.log(`provider: ${p.url}  model: ${p.model}  locales: ${args.locales.join(",")}`);
  const seeds = mineSeeds();

  const packs = [];
  for (const locale of args.locales) {
    process.stdout.write(`  ${locale} ... `);
    try {
      const pack = await generatePack(p, locale, args.per, seeds);
      const count = Object.values(pack).reduce((n, a) => n + a.length, 0);
      packs.push({ locale, pack, count });
      console.log(`${count} lines`);
    } catch (err) {
      console.error(`FAILED: ${err.message}`);
    }
  }

  if (!packs.length) {
    console.error("Nothing generated; gen.lua left untouched.");
    process.exit(1);
  }

  const out = renderGenLua(packs, args.per);
  if (args.dry) {
    console.log("\n----- dry run, gen.lua preview -----\n" + out);
  } else {
    writeFileSync(GEN_FILE, out);
    console.log(`\nwrote Locale/gen.lua (${packs.length} locale pack(s)). /reload in game to load.`);
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
