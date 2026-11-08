-- Narrator — enUS locale (DEFAULT / FALLBACK BASE).
-- This file always loads and provides every key. Other locales only need to
-- override what they translate; missing keys fall back to English.
--
-- Placeholders available in phrases and templates:
--   {name}   attacker / victim / player name
--   {amount} critical hit damage
--   {level}  new level
--   {item}   looted item name
--   {zone}   current zone (generator only, but usable in static phrases)
--   {tod}    time-of-day phrase ("at dusk", ...)
--   {deaths} lifetime death count
--   {closer} generator only — trailing clause from L.generator.closers

if not Narrator then return end
local N = Narrator
N.LOCALES = N.LOCALES or {}

local L = {}

L.name = "English"
L.code = "enUS"
-- Body font for the toast. Latin scripts use Morpheus (the WoW storybook
-- font). Locales needing different glyphs (zhCN, koKR, ruRU...) override this.
L.font = "Fonts\\MORPHEUS.TTF"

-- Substrings that mark a CHAT_MSG_LOOT line as "the player received loot".
-- Used regardless of the narration language: the chat line itself is in the
-- CLIENT locale, so all shipped locales' prefixes are merged at boot.
L.lootPrefixes = { "You receive loot", "You receive" }

L.deathHeaderFormat = "DEATH No. %d — %s"

L.headers = {
    death     = "THE STORY CATCHES UP",
    milestone = "A DARK MILESTONE",
    pvpdeath  = "MORTAL TREACHERY",
    fall      = "A VERTICAL ENDING",
    fire      = "A PACT WITH FLAMES",
    drown     = "THE SEA RECLAIMS",
    fatigue   = "THE SEA RECLAIMS",
    unknown   = "A CONFUSING END",
    crit      = "THE DICE ARE CAST",
    levelup   = "THE LEGEND GROWS",
    loot      = "CHANCE SMILES",
    legendary = "CHANCE BOWS",
    pvpkill   = "ANOTHER STORY ENDS",
    login     = "THE STORY CONTINUES",
}

L.times = {
    night = "at night",
    dawn = "at dawn",
    morning = "in the morning",
    afternoon = "in the afternoon",
    dusk = "at dusk",
}

L.phrases = {
    death = {
        "You die to {name}. The world barely notices.",
        "Your story ends here. {name} writes the epilogue.",
        "You fall. {name} walks away without looking back. Such is the nature of Azeroth.",
        "Death comes by the hand of {name}. The narrator has lost count.",
        "{name} claims you. No bard will sing of this. None should.",
    },
    pvpdeath = {
        "{name} takes your life. Revenge will be sweet... or it will be nothing.",
        "Another adventurer, {name}, decides your story is over. The narrator takes note.",
        "{name} cuts you down. The gods look away. They always do.",
        "The blade of {name} whistles once, and the silence claims you.",
    },
    milestone = {
        "Death number {deaths}. By now, the narrator and you are old friends.",
        "{deaths} deaths. The saga writes itself, though nobody asked it to.",
        "{deaths} falls. Fate collects your failures with affection.",
    },
    fall = {
        "Gravity always collects its due. Today, yours.",
        "You fly. Briefly. The ground waits, patient as ever.",
        "No feather. No spell. No regret. Only the ground.",
    },
    fire = {
        "Fire does not negotiate. It only consumes. And it consumes... well.",
        "The lava was hotter than it looked. Now you know. Too late.",
        "The flames claim you. The narrator, delightfully, does not intervene.",
    },
    drown = {
        "The ocean keeps its secrets. And the unwary.",
        "Air was only ever a loan. The water calls it in.",
        "The depths whisper to you. Silence, at last.",
    },
    fatigue = {
        "No one escapes the sea. Not heroes. Not you.",
        "The horizon lied. Fatigue forgives no dreamers.",
    },
    unknown = {
        "You die. The circumstances matter little in the end. The void, less.",
        "Death finds you incognito. Even it keeps secrets.",
    },
    crit = {
        "The dice roll in your favor: {amount} in a single blow. Fate smiles.",
        "Critical strike: {amount}. Somewhere, a lesser god applauds.",
        "{amount} damage. A masterpiece of violence.",
        "A critical: {amount}. For one breath, you too are a force of nature.",
    },
    levelup = {
        "Level {level}. The legend grows, and with it the debt of untold stories.",
        "Level {level}. Destiny watches you with renewed interest.",
        "Level {level}. The shadows part... a little. Enjoy it.",
    },
    loot = {
        "Epic spoils: {item}. The gods of chance are generous. For now.",
        "An epic item: {item}. The narrator raises an eyebrow, impressed.",
        "{item}. Epic, they say. Your name and this relic are now bound.",
    },
    legendary = {
        "{item}. The narrator falls silent, for once, in true reverence.",
        "A legendary: {item}. Some are born lucky. Today, it is you.",
        "{item}. The dice of the universe all landed your way. Waste it not.",
    },
    pvpkill = {
        "{name} falls before you. The narrator smiles, dark and pleased.",
        "You have bested {name}. Another story ends so that yours may continue.",
        "{name} dies. You breathe. The arithmetic of Azeroth is simple.",
    },
    login = {
        "Wake, {name}. The mist parts. The story continues.",
        "A new chapter, {name}. Azeroth held its breath. Nobody noticed, but it did.",
        "{name} returns. The ravens shuffle closer, attentive.",
    },
}

-- Procedural generator: templates x closers x context = endless narration.
-- Optional per locale; kinds without templates fall back to static phrases.
L.generator = {
    closers = {
        "and the world does not notice",
        "and the narrator sighs",
        "as foretold",
        "again",
        "quietly",
        "without ceremony",
        "to the narrator's mild delight",
        "as the dice decreed",
    },
    templates = {
        death = {
            "{name} ends you, {closer}.",
            "In {zone}, {name} writes your final line. {closer}.",
            "You fall to {name} {tod}. {closer}.",
            "{name} was faster. {closer}.",
        },
        pvpdeath = {
            "{name}, another mortal, ends your chapter. {closer}.",
            "Felled by {name} {tod}. {closer}.",
        },
        fall = {
            "In {zone}, gravity collects its due. {closer}.",
            "You fly. Briefly. {closer}.",
        },
        fire = {
            "In {zone}, the flames keep what they take. {closer}.",
            "The fire had the last word. {closer}.",
        },
        drown = {
            "Off {zone}, the water calls in its loan. {closer}.",
            "The deep keeps you now. {closer}.",
        },
        fatigue = {
            "The sea around {zone} forgives no dreamers. {closer}.",
        },
        crit = {
            "{amount} in a single blow. The dice sing, {closer}.",
            "A critical for {amount}, {closer}.",
            "{amount} damage, {closer}.",
        },
        levelup = {
            "Level {level}. {closer}.",
            "The legend grows to level {level}. {closer}.",
        },
        loot = {
            "{item}. The gods of chance are generous, {closer}.",
            "{item} finds a new owner. {closer}.",
        },
        legendary = {
            "{item}. The dice of the universe landed your way, {closer}.",
        },
        pvpkill = {
            "{name} falls before you, {closer}.",
            "{name} dies so your story may continue, {closer}.",
        },
        login = {
            "Wake, {name}. {closer}.",
            "{name} returns {tod}. {closer}.",
        },
        milestone = {
            "{deaths} deaths now. {closer}.",
        },
    },
}

L.slash = {
    prefix = "The Narrator",
    help_title = "The Narrator v%s — commands:",
    help_lines = {
        "  /nar on|off — enable or disable",
        "  /nar mode toast|rw|both — where it narrates",
        "  /nar lang [code] — narration language (auto = follow client)",
        "  /nar style static|mixed|impro — phrase source (static, mixed, improvised)",
        "  /nar test <kind> — death, pvpdeath, fall, fire, drown, crit, levelup, loot, legendary, pvpkill, login, milestone",
        "  /nar demo — a short gala",
        "  /nar interval <s> · /nar crit <0.1-1> · /nar sound · /nar media",
        "  /nar stats · /nar reset",
    },
    on_msg = "The narrator wakes. Nothing escapes his eye.",
    off_msg = "The narrator falls silent... for now.",
    mode_usage = "Usage: /nar mode toast|rw|both — current: %s",
    mode_set = "Mode: %s (toast = plate, rw = raid warning, both)",
    sound_on = "Sound: on",
    sound_off = "Sound: muted",
    media_on = "Custom mp3s in media/: on (see README)",
    media_off = "Custom mp3s in media/: off",
    interval_usage = "Usage: /nar interval <seconds>",
    interval_set = "Minimum interval between minor narrations: %ss",
    crit_usage = "Usage: /nar crit <0.1-1> — current: %s",
    crit_set = "Critical threshold: %d%% of your max health",
    stats_format = "Deaths: |cffff6a6a%d|r (falls %d, fire %d, drowning %d, fatigue %d) · Narrated crits: %d · PvP kills: %d · Level: %d",
    reset_msg = "Counters reset. The narrator pretends to remember nothing.",
    demo_msg = "A brief demonstration of the narrator's craft...",
    lang_usage = "Usage: /nar lang auto|<code> — available: %s",
    lang_set = "The narrator will now speak %s.",
    lang_auto = "Following the client language (%s).",
    lang_unknown = "Unknown language '%s'. Available: %s",
    style_usage = "Usage: /nar style static|mixed|impro — current: %s",
    style_set = "Style: %s (static = curated, mixed = blend, impro = improvises)",
}

N.LOCALES.enUS = L
