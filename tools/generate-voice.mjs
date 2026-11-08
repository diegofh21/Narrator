#!/usr/bin/env node
// Narrator — voice line generator.
//
// Renders spoken narrator lines (one to three variants per event kind) with a
// TTS provider and writes them to media/audio/<locale>/, plus the manifest
// Locale/voice.lua the addon reads to play them in game. Lines are written
// FOR the voice (no placeholders), so they always read naturally.
//
// Usage:
//   node tools/generate-voice.mjs                       # esES,enUS
//   node tools/generate-voice.mjs --locales enUS --rate 150
//   node tools/generate-voice.mjs --voice esES=Mónica,enUS="Daniel (English (UK))"
//   node tools/generate-voice.mjs --dry                 # print plan only
//
// Providers (first match, or --provider say|openai|elevenlabs):
//   say        macOS built-in TTS (free, offline). Default on macOS.
//   openai     OPENAI_API_KEY  -> gpt-4o-mini-tts, voice "onyx" (mp3)
//   elevenlabs ELEVENLABS_API_KEY + ELEVENLABS_VOICE_ID  (mp3)
//
// Requires Node 18+. Output is idempotent: existing files are kept. Rendered
// filenames hash the voice config too, so switching voice/provider regenerates
// automatically, and stale renders are cleaned up after each run.

import { createHash } from "node:crypto";
import { execFile } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const AUDIO_DIR = join(ROOT, "media", "audio");
const MANIFEST = join(ROOT, "Locale", "voice.lua");

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

// Voice-native narrator lines (no placeholders: they must read well aloud).
// Add a locale here to give it spoken narration; others stay text-only.
const LINES = {
  enUS: {
    death: [
      "Another chapter closes. The world barely notices.",
      "You fall. The narrator, ever patient, takes note.",
      "So ends another brave and foolish endeavor.",
    ],
    pvpdeath: [
      "Cut down by a fellow mortal. The gods look away, as they always do.",
      "Another adventurer writes your ending tonight.",
      "Not fate this time. Someone very much like you.",
    ],
    milestone: [
      "The count grows heavier. So does the legend.",
      "Another mark upon the tally. The narrator has lost count. On purpose.",
      "Deaths beyond counting. Or perhaps he simply stopped trying.",
    ],
    fall: [
      "The ground, patient as ever, keeps what it catches.",
      "Gravity collects its due. Again.",
      "A brief flight. A definitive landing.",
    ],
    fire: [
      "The flames are pleased. They always are.",
      "Fire does not negotiate. It simply wins.",
      "The lava was warmer than it looked. Now you know.",
    ],
    drown: [
      "The deep claims its own.",
      "The water calls in its loan. Silence answers.",
      "The ocean keeps its secrets. And now, you.",
    ],
    fatigue: [
      "The sea does not forgive dreamers.",
      "The horizon lied. The sea told the truth.",
    ],
    unknown: [
      "A death, unrecorded. Even the void keeps secrets.",
      "You died. The details hardly matter to eternity.",
    ],
    crit: [
      "The dice land in your favor.",
      "A blow for the sagas. Somewhere, a lesser god applauds.",
      "Magnificent. Briefly, you are a force of nature.",
    ],
    levelup: [
      "The legend grows.",
      "Another rung upon an endless ladder. Climb on.",
      "Destiny watches you with renewed interest.",
    ],
    loot: [
      "Fortune smiles. For now.",
      "The gods of chance show favor. Do not waste it.",
      "A relic found. A story deepened.",
    ],
    legendary: [
      "The narrator falls silent, in reverence.",
      "Some are born under luckier stars. Today, it is you.",
      "The dice of the universe all landed your way.",
    ],
    pvpkill: [
      "One story ends. Yours continues.",
      "The narrator smiles. Darkly. Approvingly.",
      "Another name crossed out of the ledger.",
    ],
    login: [
      "The mist parts. The story continues.",
      "Wake, wanderer. Azeroth has been waiting.",
      "A new chapter begins. The ravens settle in to listen.",
    ],
  },
  esES: {
    death: [
      "Otro capítulo se cierra. El mundo apenas lo nota.",
      "Caes. El narrador, siempre paciente, toma nota.",
      "Así termina otra hazaña valiente y absurda.",
    ],
    pvpdeath: [
      "Abatido por otro mortal. Los dioses miran a otro lado, como siempre.",
      "Otro aventurero escribe tu final esta noche.",
      "No fue el destino. Fue alguien muy parecido a ti.",
    ],
    milestone: [
      "La cuenta pesa más. Y la leyenda también.",
      "Otra marca en el tanteo. El narrador perdió la cuenta. A propósito.",
      "Muertes más allá de toda cuenta. O quizá dejó de contar.",
    ],
    fall: [
      "El suelo, paciente como siempre, se queda con lo que atrapa.",
      "La gravedad cobra su deuda. Otra vez.",
      "Un vuelo breve. Un aterrizaje definitivo.",
    ],
    fire: [
      "Las llamas están complacidas. Siempre lo están.",
      "El fuego no negocia. Simplemente gana.",
      "La lava estaba más caliente de lo que parecía. Ahora lo sabes.",
    ],
    drown: [
      "Las profundidades reclaman lo suyo.",
      "El agua cobra su préstamo. El silencio responde.",
      "El océano guarda sus secretos. Y ahora, también a ti.",
    ],
    fatigue: [
      "El mar no perdona a los soñadores.",
      "El horizonte mintió. El mar dijo la verdad.",
    ],
    unknown: [
      "Una muerte, sin registrar. Hasta el vacío guarda secretos.",
      "Has muerto. Los detalles poco importan a la eternidad.",
    ],
    crit: [
      "Los dados caen de tu lado.",
      "Un golpe para las sagas. En algún lugar, un dios menor aplaude.",
      "Magnífico. Por un instante, eres fuerza de la naturaleza.",
    ],
    levelup: [
      "La leyenda crece.",
      "Otro peldaño en una escalera infinita. Sigue subiendo.",
      "El destino te observa con renovado interés.",
    ],
    loot: [
      "La fortuna sonríe. Por ahora.",
      "Los dioses del azar te favorecen. No lo desperdicies.",
      "Una reliquia hallada. Una historia profundizada.",
    ],
    legendary: [
      "El narrador guarda silencio, con reverencia.",
      "Algunos nacen bajo estrellas más afortunadas. Hoy, tú.",
      "Los dados del universo cayeron todos de tu lado.",
    ],
    pvpkill: [
      "Una historia termina. La tuya continúa.",
      "El narrador sonríe. Oscuro. Aprobador.",
      "Otro nombre tachado del registro.",
    ],
    login: [
      "La niebla se aparta. La historia continúa.",
      "Despierta, caminante. Azeroth esperaba.",
      "Un capítulo nuevo comienza. Los cuervos se acomodan para escuchar.",
    ],
  },
};

// esMX mirrors esES text (the lines are already neutral Spanish) but gets its
// own audio renders, so it can speak with a Latin American voice. Copy the
// esES block above into its own esMX entry if you want the words to diverge.
LINES.esMX = LINES.esES;

// Preferred macOS voices, in order (matched against `say -v ?`).
const SAY_PREFS = {
  enUS: ["Daniel (English (UK))", "Reed (English (UK))", "Daniel", "Samantha"],
  esES: ["Mónica", "Monica", "Sandy (Spanish (Spain))", "Reed (Spanish (Spain))"],
  esMX: ["Paulina", "Sandy (Spanish (Mexico))", "Reed (Spanish (Mexico))", "Rocko (Spanish (Mexico))"],
};
const SAY_LOCALE = { enUS: "en_GB", esES: "es_ES", esMX: "es_MX" };

// Fallback voices for the cloud providers (override per locale, see below).
const OPENAI_TTS_FALLBACK = "onyx";
const ELEVEN_VOICE_FALLBACK = "JBFqnCBsd6RMkjVDRZzb"; // "George"

// Per-locale voice resolution for cloud providers, first match wins:
//   --voice-id esMX=...   (CLI flag, repeatable comma pairs)
//   ELEVENLABS_VOICE_ID_ESMX / OPENAI_TTS_VOICE_ESMX  (env, locale appended)
//   ELEVENLABS_VOICE_ID / OPENAI_TTS_VOICE            (env, global)
//   built-in fallback
function cloudVoiceFor(provider, locale, flagMap) {
  const base = provider === "openai" ? "OPENAI_TTS_VOICE" : "ELEVENLABS_VOICE_ID";
  const fallback = provider === "openai" ? OPENAI_TTS_FALLBACK : ELEVEN_VOICE_FALLBACK;
  return flagMap[locale]
    || process.env[base + "_" + locale.toUpperCase()]
    || process.env[base]
    || fallback;
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const out = { locales: ["esES", "esMX", "enUS"], rate: 155, provider: null, voice: {}, voiceId: {}, providers: {}, dry: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--locales") out.locales = (argv[++i] || "").split(",").map(s => s.trim()).filter(Boolean);
    else if (a === "--rate") out.rate = parseInt(argv[++i], 10) || 155;
    else if (a === "--provider") out.provider = argv[++i];
    else if (a === "--dry") out.dry = true;
    else if (a === "--providers") {
      for (const pair of (argv[++i] || "").split(",")) {
        const [loc, ...rest] = pair.split("=").map(s => s.trim());
        if (loc && rest.length) out.providers[loc] = rest.join("=");
      }
    }
    else if (a === "--voice" || a === "--voice-id") {
      const target = a === "--voice" ? out.voice : out.voiceId;
      for (const pair of (argv[++i] || "").split(",")) {
        const [loc, ...rest] = pair.split("=").map(s => s.trim());
        if (loc && rest.length) target[loc] = rest.join("=");
      }
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

function pickProvider(args) {
  if (args.provider) return args.provider;
  if (process.env.ELEVENLABS_API_KEY) return "elevenlabs";
  if (process.env.OPENAI_API_KEY) return "openai";
  if (process.platform === "darwin") return "say";
  return "say"; // pre-flight check below explains the options if it can't run
}

function checkProvider(provider) {
  if (provider === "elevenlabs" && !process.env.ELEVENLABS_API_KEY) {
    console.error("No ELEVENLABS_API_KEY found.");
    console.error("  1. Sign up at https://elevenlabs.io (free tier ~10 min/month)");
    console.error("  2. Profile -> API Keys -> Create API Key");
    console.error("  3. Put it in .env at the repo root (see .env.example):");
    console.error('       ELEVENLABS_API_KEY=your_key_here');
    return false;
  }
  if (provider === "openai" && !process.env.OPENAI_API_KEY) {
    console.error("No OPENAI_API_KEY found.");
    console.error("  1. Sign up at https://platform.openai.com and add billing (cents per pack)")
    console.error("  2. API Keys -> Create new secret key");
    console.error("  3. Put it in .env at the repo root (see .env.example):");
    console.error('       OPENAI_API_KEY=sk-your_key_here');
    return false;
  }
  if (provider === "say" && process.platform !== "darwin") {
    console.error("The 'say' provider only exists on macOS.");
    console.error("Set ELEVENLABS_API_KEY or OPENAI_API_KEY in .env (see .env.example),");
    console.error("or copy the media/ folder from a Mac.");
    return false;
  }
  return true;
}

async function sayVoiceFor(locale, override) {
  if (override) return override;
  const { stdout } = await execFileAsync("say", ["-v", "?"]);
  const installed = stdout.split("\n").map(l => l.trim()).filter(Boolean);
  const cleanVoiceName = line => {
    // "Daniel (English (UK)) en_GB  # Hello!" -> "Daniel (English (UK))"
    return line.split(/\s{2,}/)[0].replace(/\s+[A-Za-z]{2}_[A-Za-z]{2}\s*$/, "").trim();
  };
  for (const pref of SAY_PREFS[locale] || []) {
    const hit = installed.find(l => l.startsWith(pref));
    if (hit) return cleanVoiceName(hit);
  }
  // Last resort: any voice of the locale (line format: "Name   xx_XX  # ...").
  const tag = SAY_LOCALE[locale];
  const any = installed.find(l => l.includes(tag));
  if (any) return cleanVoiceName(any);
  throw new Error(`no ${tag} voice installed (System Settings > Live Speech)`);
}

async function renderSay(text, wavPath, voice, rate) {
  await execFileAsync("say", [
    "-v", voice, "-r", String(rate),
    "-o", wavPath, "--data-format=LEI16@22050",
    text,
  ]);
}

async function renderOpenAI(text, mp3Path, voice) {
  const base = (process.env.OPENAI_BASE_URL || "https://api.openai.com/v1").replace(/\/+$/, "");
  const res = await fetch(base + "/audio/speech", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: process.env.OPENAI_TTS_MODEL || "gpt-4o-mini-tts",
      voice: voice,
      input: text,
      response_format: "mp3",
    }),
  });
  if (!res.ok) throw new Error(`openai tts HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
  writeFileSync(mp3Path, Buffer.from(await res.arrayBuffer()));
}

async function renderEleven(text, mp3Path, voiceId) {
  const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
    method: "POST",
    headers: {
      "xi-api-key": process.env.ELEVENLABS_API_KEY,
      "Content-Type": "application/json",
      Accept: "audio/mpeg",
    },
    body: JSON.stringify({ text, model_id: "eleven_multilingual_v2" }),
  });
  if (!res.ok) throw new Error(`elevenlabs HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
  writeFileSync(mp3Path, Buffer.from(await res.arrayBuffer()));
}

// ---------------------------------------------------------------------------
// Manifest
// ---------------------------------------------------------------------------

function renderManifest(packs) {
  const out = [
    "-- Narrator — voice manifest (auto-managed).",
    `-- Produced by tools/generate-voice.mjs (${packs.map(p => p.locale + ":" + p.count).join(", ")}).`,
    "-- Safe to delete; the addon then falls back to text + game sounds.",
    "",
    "Narrator = Narrator or {}",
    "Narrator.VOICE = Narrator.VOICE or {}",
  ];
  for (const { locale, files } of packs) {
    out.push(`Narrator.VOICE[${JSON.stringify(locale)}] = {`);
    for (const kind of KINDS) {
      if (!files[kind]) continue;
      out.push(`  ${kind} = {`);
      for (const f of files[kind]) out.push(`    ${JSON.stringify(f)},`);
      out.push(`  },`);
    }
    out.push("}");
  }
  // esMX aliases esES in the text locales; keep that for voice only when it
  // wasn't rendered as its own pack (own accent/voice).
  if (packs.some(p => p.locale === "esES") && !packs.some(p => p.locale === "esMX")) {
    out.push('Narrator.VOICE["esMX"] = Narrator.VOICE["esES"]');
  }
  out.push("");
  return out.join("\n");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const provider = pickProvider(args);
  const providersUsed = new Set([provider, ...Object.values(args.providers || {})]);
  for (const p of providersUsed) {
    if (!checkProvider(p)) process.exit(1);
  }
  console.log(`provider: ${provider}${Object.keys(args.providers || {}).length ? " (+per-locale overrides)" : ""}  rate: ${args.rate}  locales: ${args.locales.join(",")}`);

  const packs = [];
  for (const locale of args.locales) {
    const lines = LINES[locale];
    if (!lines) {
      console.warn(`  ${locale}: no voice lines defined (text-only); edit LINES in this script to add it`);
      continue;
    }
    process.stdout.write(`  ${locale} ... `);
    try {
      const prov = (args.providers && args.providers[locale]) || provider;
      const ext = prov === "say" ? "wav" : "mp3";

      const dir = join(AUDIO_DIR, locale);
      mkdirSync(dir, { recursive: true });

      let sayVoice, cloudVoice;
      if (prov === "say") sayVoice = await sayVoiceFor(locale, args.voice[locale]);
      else cloudVoice = cloudVoiceFor(prov, locale, args.voiceId);
      // Hash signature: changing provider/voice/rate re-renders instead of
      // silently reusing files spoken by the previous voice.
      const sig = `${prov}|${sayVoice || cloudVoice}|${args.rate}`;

      const files = {};
      let count = 0;
      for (const kind of KINDS) {
        const texts = lines[kind] || [];
        if (!texts.length) continue;
        files[kind] = [];
        for (const text of texts) {
          const hash = createHash("sha1").update(sig + "|" + locale + text).digest("hex").slice(0, 10);
          const name = `${locale}/${kind}_${hash}.${ext}`;
          const path = join(AUDIO_DIR, name);
          if (existsSync(path)) {
            files[kind].push(name);
            count++;
            continue;
          }
          if (args.dry) {
            console.log(`\n    would render [${kind}] ${JSON.stringify(text)} (via ${sayVoice || cloudVoice})`);
            files[kind].push(name);
            count++;
            continue;
          }
          if (prov === "say") await renderSay(text, path, sayVoice, args.rate);
          else if (prov === "openai") await renderOpenAI(text, path, cloudVoice);
          else if (prov === "elevenlabs") await renderEleven(text, path, cloudVoice);
          else throw new Error("unknown provider " + prov);
          files[kind].push(name);
          count++;
        }
      }
      packs.push({ locale, files, count });
      console.log(`${count} lines (voice: ${sayVoice || cloudVoice})`);
    } catch (err) {
      // One locale failing (402 paid_plan_required, network...) shouldn't
      // kill the rest; note it and move on.
      console.error(`SKIPPED: ${err.message}`);
      if (String(err.message).includes("paid_plan_required")) {
        console.error("  (Voice Library voices need a paid plan; free tier only allows premade voices)");
      }
    }
  }

  if (!packs.length) {
    console.error("Nothing generated; manifest left untouched.");
    process.exit(1);
  }

  const manifest = renderManifest(packs);
  if (args.dry) {
    console.log("\n----- dry run, Locale/voice.lua preview -----\n" + manifest);
  } else {
    writeFileSync(MANIFEST, manifest);

    // Sweep stale renders (old voice, removed lines): keep only what the
    // fresh manifest references, and only touch our naming pattern.
    let swept = 0;
    for (const { locale, files } of packs) {
      const dir = join(AUDIO_DIR, locale);
      const keep = new Set(Object.values(files).flat().map(f => f.split("/")[1]));
      for (const name of readdirSync(dir)) {
        if (keep.has(name)) continue;
        if (/^[a-z]+_[0-9a-f]{10}\.(wav|mp3)$/.test(name)) {
          unlinkSync(join(dir, name));
          swept++;
        }
      }
    }
    console.log(`\nwrote Locale/voice.lua + audio in media/audio/ (${swept} stale file(s) swept) — /reload in game to hear it.`);
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
