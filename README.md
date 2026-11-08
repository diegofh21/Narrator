# Narrator

A **Baldur's Gate 3 style narrator** for **WoW Forever** (Classic+): an
ominous, dry-witted voice that comments your deaths, critical hits, loot and
favorite mishaps while you explore the world.

> *Wake, wanderer. The mist parts. The story continues.*

English by default; **Español incluido** — see [README.es.md](README.es.md).
Any language is welcome: [LOCALES.md](LOCALES.md) explains how.

## How it looks

A dark plate with a thin gold border fades in near the top of the screen:
a small-caps golden header and the narration line below, set in Morpheus —
the WoW storybook font. The narrator is a voice, not a UI: text only,
centered, elegant. (Drag it to move it; it remembers.)

## What it narrates

| Event | Sample |
|---|---|
| Death — mob, player, falling, fire/lava, drowning, fatigue | «You die to {name}. The world barely notices.» |
| Every 10th death (milestone) | «Death number {deaths}. By now, the narrator and you are old friends.» |
| Big criticals (≥ 35% of max HP, configurable) | «The dice roll in your favor: {amount} in a single blow.» |
| Level up | «Level {level}. Destiny watches you with renewed interest.» |
| Epic / legendary loot | «A legendary: {item}. Some are born lucky. Today, it is you.» |
| Killing another player | «{name} falls before you. The narrator smiles, dark and pleased.» |
| Login greeting | «Wake, {name}. The mist parts. The story continues.» |

Phrases are context-aware where it matters: the narrator knows the zone,
the time of day and your lifetime death count.

## Spoken narration

The narrator talks. Render spoken lines with:

```
node tools/generate-voice.mjs
```

On macOS this uses the built-in `say` voices — Daniel (English UK) for
English, Mónica for Spanish — free and offline (override with `--voice`).
An `OPENAI_API_KEY` or `ELEVENLABS_API_KEY` unlocks higher quality voices.
Audio lands in `media/audio/` (git-ignored) plus a manifest the addon
reads: `/reload` in game and every event plays a real voice line — up to
three variants per event kind, randomly chosen. `/nar voice` toggles it.

Spoken lines are written *for* the voice (no dynamic names or numbers), so
audio is per-event while the text plate keeps the exact phrase with names
and amounts.

## Not always static — three phrase sources

`/nar style` controls where lines come from:

- **static** — the curated tables in `Locale/<lang>.lua`.
- **impro** — the procedural generator: grammar templates × closers × live
  context (zone, time of day, death count). Runs fully offline, endless
  variety, no repeated lines for a very long time.
- **mixed** *(default)* — a blend of everything available.

### AI-generated packs (optional)

WoW addons cannot touch the network — the Lua sandbox has no HTTP — so real
LLM generation happens **outside** the game. The companion script
`tools/refresh-phrases.mjs` mass-generates fresh packs into
`Locale/gen.lua`, which the addon loads like any other pool:

```
ZAI_API_KEY=... node tools/refresh-phrases.mjs --locales enUS,esES --per 6
# or OLLAMA_BASE_URL=http://localhost:11434/v1, or OPENAI_API_KEY=...
```

Then `/reload` in game. Delete `Locale/gen.lua` anytime; the stub is
committed and the addon works without it.

## Installation

Symlink (or copy) the folder into your WoW Forever `Interface/AddOns`:

```
ln -s ~/Repositories/Personal/Narrator \
  "/Volumes/SSD/Applications/World of Warcraft/_forever_/Interface/AddOns/Narrator"
```

If the client flags it out of date, enable **Load out of date AddOns** at
the character screen. The TOC interface (`16001`, client 1.60.x) is a best
guess until the game ships its first build notes — adjust if needed.

## Commands

```
/nar            help
/nar on|off     enable / disable
/nar mode       toast | rw | both      (where it narrates)
/nar lang       auto | enUS | esES ... (narration language)
/nar style      static | mixed | impro (phrase source)
/nar test <kind>  death, pvpdeath, fall, fire, drown, crit,
                   levelup, loot, legendary, pvpkill, login, milestone
/nar demo       a short gala with a bit of everything
/nar interval <s>   min seconds between minor narrations
/nar crit <0.1-1>   crit threshold as a fraction of max health
/nar voice     spoken narration on / off
/nar sound      mute / unmute
/nar media      use your own mp3s (see below)
/nar stats      your death & glory counters
/nar reset      reset counters
```

## Custom sounds

Create `media/` inside the addon and drop: `death.mp3`, `crit.mp3`,
`level.mp3`, `loot.mp3`, `kill.mp3`, `login.mp3`, then `/nar media`.
Without them, built-in game sound kits are used. MP3 only — this client
does not play OGG.

## Project layout

```
Narrator.toc              addon metadata (interface 16001 = client 1.60.x)
Core.lua                    events, i18n merger, phrase picker, generator, slash
Toast.lua                   the BG3-style plate (black, gold border, Morpheus)
Locale/enUS.lua             DEFAULT locale + fallback base (keep complete!)
Locale/esES.lua, esMX.lua   Spanish (esMX aliases esES)
Locale/gen.lua              AI phrase packs (auto-managed by tools/)
Locale/voice.lua            spoken-line manifest (auto-managed by tools/)
tools/refresh-phrases.mjs   AI phrase generator (Z.ai / OpenAI / Ollama)
tools/generate-voice.mjs    TTS voice line renderer (say / OpenAI / ElevenLabs)
media/audio/                rendered voice lines (git-ignored, regenerate anytime)
LOCALES.md                  how to add a language
```

## Contributing translations

See [LOCALES.md](LOCALES.md) — it's a 3-step PR, with English fallback for
anything untranslated. Inspired by the narrative feel of addons like
**Spoken**.

## Roadmap ideas

- Interface Options panel (beyond slash commands).
- "Cruel vs. merciful" narrator modes (two phrase sets per locale).
- Persistent earned titles from your stats («The Fallen», «Lover of Lava»).
- A Paparazzi companion addon: auto-screenshots on milestone lines.
- Sync narrations to /say or party chat.
