# Adding a locale

The narrator speaks **English by default**; `esES`/`esMX` ship in the box.
Any other language is a 3-step PR — missing keys automatically fall back to
English, so a partial translation still works.

## 1. Create `Locale/<code>.lua`

Copy `Locale/enUS.lua` to e.g. `Locale/frFR.lua` and translate. You only need
to keep the keys you translate — the merger in `Core.lua` (`N:SetLocale`)
starts from English and lets your table override.

Minimal viable locale file:

```lua
if not Narrator then return end
Narrator.LOCALES = Narrator.LOCALES or {}

local L = {}
L.name = "Français"                       -- shown by /nar lang
L.font = "Fonts\\MORPHEUS.TTF"            -- see "Fonts" below
L.lootPrefixes = { "Vous recevez" }       -- chat-line prefixes for YOUR client locale
L.deathHeaderFormat = "MORT Nº %d — %s"

L.headers = { ... }                       -- small-caps toast titles
L.times   = { night = "la nuit", ... }    -- time-of-day words
L.phrases = { death = { "..." }, ... }    -- the narration itself
L.generator = { closers = { ... }, templates = { death = { "..." }, ... } }  -- optional
L.slash   = { ... }                       -- /nar command output

Narrator.LOCALES.frFR = L
```

## 2. Register it in `Narrator.toc`

```
Locale\frFR.lua
```

## 3. Test in game

```
/nar lang frFR
/nar demo
```

No relog needed; the language switches live.

## Placeholders

Phrases are format templates using `{placeholders}` (not `%s` — the filler
handles them):

| Token | Meaning | Used by |
|---|---|---|
| `{name}` | attacker / victim / player name | death, pvpdeath, pvpkill, login |
| `{amount}` | critical hit damage | crit |
| `{level}` | new level | levelup |
| `{item}` | looted item name | loot, legendary |
| `{deaths}` | lifetime death count | milestone |
| `{zone}` | current zone name | static phrases + generator |
| `{tod}` | time-of-day word (`L.times`) | static phrases + generator |
| `{closer}` | trailing clause (generator only) | generator templates |

## Event kinds

`death`, `pvpdeath`, `milestone` (every 10 deaths), `fall`, `fire`,
`drown`, `fatigue`, `unknown`, `crit`, `levelup`, `loot`, `legendary`,
`pvpkill`, `login`.

## `lootPrefixes` — important

Loot chat lines arrive in the **client** language regardless of the
narration language, so every shipped locale contributes its prefixes to a
shared list. If your client locale isn't covered, loot narration silently
does nothing — include at least one prefix.

## Fonts

The toast body uses `L.font`. `Fonts\\MORPHEUS.TTF` (the WoW storybook font)
covers Latin scripts. For zhCN/koKR use the client's own font files
(e.g. `Fonts\\FZLBJW.TTF`); ruRU usually prefers `Fonts\\FRIZQT__.TTF`.

## The generator (optional but fun)

`L.generator` powers the `/nar style impro` and `mixed` modes: templates
× `closers` × live context (zone, time of day) produce endless combinations.
Skip it and improvisation falls back to your static phrases.

## AI packs

`tools/refresh-phrases.mjs` can mass-generate packs for any locale code —
even ones not shipped — into `Locale/gen.lua`:

```
node tools/refresh-phrases.mjs --locales frFR,deDE --per 8
```

It uses `OLLAMA_BASE_URL`, `ZAI_API_KEY` or `OPENAI_API_KEY` from the
environment. The addon never calls the network itself.
