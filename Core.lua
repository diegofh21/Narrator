-- Narrator — core engine.
-- A Baldur's Gate 3 style narrator for WoW Forever: comments your deaths,
-- crits, loot and mishaps with ominous, dry-witted narration.
--
-- Phrases come from three sources (see /nar style):
--   static — curated tables in Locale/<locale>.lua
--   impro  — procedural grammar (Locale generator section) mixed with
--            AI packs written by tools/refresh-phrases.mjs into Locale/gen.lua
--   mixed  — a blend of both (default)
--
-- Locale files load after this one and fill N.LOCALES; enUS is the always
-- loaded fallback base. See LOCALES.md to add a language.

Narrator = Narrator or {}
local N = Narrator
N.VERSION = "0.2.0"

-- Icons per event (language-neutral; edit freely: any Interface\Icons\...).
N.ICONS = {
    death     = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    milestone = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    pvpdeath  = "Interface\\Icons\\Ability_Rogue_Ambush",
    fall      = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    fire      = "Interface\\Icons\\Spell_Fire_Fire",
    drown     = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    fatigue   = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    unknown   = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    crit      = "Interface\\Icons\\Ability_Warrior_BattleShout",
    levelup   = "Interface\\Icons\\Spell_Holy_SurgeOfLight",
    loot      = "Interface\\Icons\\INV_Box_03",
    legendary = "Interface\\Icons\\INV_Box_03",
    pvpkill   = "Interface\\Icons\\Ability_Rogue_Ambush",
    login     = "Interface\\Icons\\INV_Misc_Book_09",
}

local DEFAULTS = {
    enabled       = true,
    mode          = "toast",   -- "toast" | "rw" | "both"
    lang          = "auto",    -- "auto" = follow client locale, else a locale code
    style         = "mixed",   -- "static" | "mixed" | "impro"
    minInterval   = 12,        -- seconds between minor narrations
    critCooldown  = 30,        -- seconds between crit narrations
    critPct       = 0.35,      -- crit must be >= this fraction of max health
    critMin       = 60,        -- ...and at least this much raw damage
    sound         = true,
    loginGreeting = true,
    media         = false,     -- play custom mp3s from media/ if present
}

local CHAR_DEFAULTS = {
    deaths = 0, falls = 0, fires = 0, drowns = 0, fatigues = 0,
    crits = 0, pvpKills = 0, level = 1,
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function Print(msg)
    local prefix = (N.L and N.L.slash and N.L.slash.prefix) or "Narrator"
    DEFAULT_CHAT_FRAME:AddMessage("|cffffc66a[" .. prefix .. "]|r " .. msg)
end
N.Print = Print

local function S(key)
    return (N.L and N.L.slash and N.L.slash[key]) or key
end

local function GUIDType(guid)
    if not guid then return nil end
    return strsplit("-", guid)
end

local function MergeDefaults(db, defaults)
    if type(db) ~= "table" then db = {} end
    for k, v in pairs(defaults) do
        if db[k] == nil then db[k] = v end
    end
    return db
end

local function CopyList(src)
    local out = {}
    for i = 1, #src do out[i] = src[i] end
    return out
end

-- ---------------------------------------------------------------------------
-- Locale resolution: enUS is the base; the active locale overrides it.
-- Missing keys keep English, so half-finished fork translations still work.
-- ---------------------------------------------------------------------------

function N:ResolveLocale()
    local want = (self.db and self.db.lang) or "auto"
    if want == "auto" then want = GetLocale() end
    if self.LOCALES[want] then return want end
    return "enUS"
end

function N:SetLocale()
    local base = self.LOCALES.enUS
    if not base then return end
    local key = self:ResolveLocale()
    local target = self.LOCALES[key] or base

    local L = {}
    for k, v in pairs(base) do L[k] = v end
    for k, v in pairs(target) do
        if k ~= "phrases" then L[k] = v end
    end

    L.phrases = {}
    for kind, pool in pairs(base.phrases) do
        L.phrases[kind] = CopyList(pool)
    end
    for kind, pool in pairs(target.phrases or {}) do
        L.phrases[kind] = L.phrases[kind] or {}
        for _, p in ipairs(pool) do
            L.phrases[kind][#L.phrases[kind] + 1] = p
        end
    end

    self.localeKey = key
    self.L = L

    -- Loot lines arrive in the CLIENT language, so collect prefixes from
    -- every shipped locale, not just the narration language.
    self.lootPrefixes = {}
    for _, locale in pairs(self.LOCALES) do
        for _, prefix in ipairs(locale.lootPrefixes or {}) do
            self.lootPrefixes[#self.lootPrefixes + 1] = prefix
        end
    end

    if self.RefreshToastFont then self:RefreshToastFont() end
end

function N:LocaleList()
    local keys = {}
    for code in pairs(self.LOCALES) do keys[#keys + 1] = code end
    table.sort(keys)
    return table.concat(keys, ", ")
end

-- ---------------------------------------------------------------------------
-- Sounds: user mp3s in media/ first, then built-in sound kits (guarded).
-- ---------------------------------------------------------------------------

local MEDIA_SOUNDS = {
    death = "death.mp3", milestone = "death.mp3", pvpdeath = "death.mp3",
    fall = "death.mp3", fire = "death.mp3", drown = "death.mp3",
    fatigue = "death.mp3", unknown = "death.mp3",
    crit = "crit.mp3", levelup = "level.mp3", loot = "loot.mp3",
    legendary = "loot.mp3", pvpkill = "kill.mp3", login = "login.mp3",
}

local KIT_SOUNDS = {
    death     = { "IG_QUEST_FAILED_BOOM" },
    milestone = { "IG_QUEST_FAILED_BOOM" },
    pvpdeath  = { "IG_QUEST_FAILED_BOOM" },
    fall      = { "IG_QUEST_FAILED_BOOM" },
    fire      = { "IG_QUEST_FAILED_BOOM" },
    drown     = { "IG_QUEST_FAILED_BOOM" },
    fatigue   = { "IG_QUEST_FAILED_BOOM" },
    unknown   = { "IG_QUEST_FAILED_BOOM" },
    crit      = { "UI_EPICLOOT_TOAST", "IG_PLAYER_INVITE" },
    levelup   = { "LEVEL_UP" },
    loot      = { "UI_EPICLOOT_TOAST", "IG_PLAYER_INVITE" },
    legendary = { "UI_EPICLOOT_TOAST", "IG_PLAYER_INVITE" },
    pvpkill   = { "PVP_ENTER_QUEUE", "IG_PLAYER_INVITE" },
    login     = { "IG_PLAYER_INVITE" },
}

function N:PlayKindSound(kind)
    if not self.db or not self.db.sound then return end
    if self.db.media and MEDIA_SOUNDS[kind] then
        local file = "Interface\\AddOns\\Narrator\\media\\" .. MEDIA_SOUNDS[kind]
        pcall(PlaySoundFile, file, "master")
        return
    end
    if type(SOUNDKIT) == "table" then
        for _, key in ipairs(KIT_SOUNDS[kind] or {}) do
            local id = SOUNDKIT[key]
            if id then
                pcall(PlaySound, id, "master")
                return
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Phrase selection: static pools, AI packs (gen.lua), and the procedural
-- generator. See LOCALES.md for the placeholder reference.
-- ---------------------------------------------------------------------------

local function AIPool(kind)
    local gen = N.GENERATED and N.GENERATED.phrases and N.GENERATED.phrases[N.localeKey]
    return (gen and gen[kind]) or {}
end

local function Fill(template, vars)
    return (template:gsub("{(%w+)}", function(k)
        local v = vars[k]
        if v == nil then return nil end
        return tostring(v)
    end))
end

function N:Generate(kind, vars)
    local g = self.L.generator
    if not (g and g.templates and g.templates[kind]) then return nil end
    local templates = g.templates[kind]
    local closers = g.closers or {}
    local chosen = {}
    for k, v in pairs(vars) do chosen[k] = v end
    if closers[1] then chosen.closer = closers[math.random(#closers)] end
    return Fill(templates[math.random(#templates)], chosen)
end

function N:PickPhrase(kind, vars)
    local static = self.L.phrases[kind] or {}
    local ai = AIPool(kind)
    local style = self.db.style or "mixed"

    if style == "static" then
        if static[1] then return static[math.random(#static)] end
        return nil
    end

    if style == "impro" then
        if ai[1] and (math.random(3) > 1 or not static[1]) then
            return ai[math.random(#ai)]
        end
        return self:Generate(kind, vars) or (static[1] and static[math.random(#static)] or nil)
    end

    -- mixed
    local roll = math.random(10)
    if roll <= 5 and static[1] then
        return static[math.random(#static)]
    elseif roll <= 8 and ai[1] then
        return ai[math.random(#ai)]
    end
    return self:Generate(kind, vars) or (static[1] and static[math.random(#static)] or nil)
end

-- ---------------------------------------------------------------------------
-- Narration gate: major events always speak; minor ones respect a cooldown.
-- ---------------------------------------------------------------------------

local MAJOR = {
    death = true, pvpdeath = true, milestone = true, fall = true, fire = true,
    drown = true, fatigue = true, unknown = true, levelup = true,
    legendary = true, pvpkill = true, login = true,
}

local lastSpokeAt, lastCritAt = 0, 0

function N:ContextVars(extra)
    local vars = {
        zone = GetZoneText() or "",
        deaths = self.cdb.deaths or 0,
        tod = self:TimeOfDayWord(),
    }
    if extra then
        for k, v in pairs(extra) do vars[k] = v end
    end
    return vars
end

function N:TimeOfDayWord()
    local hour = GetGameTime and (GetGameTime()) or 12
    local slot
    if hour >= 22 or hour < 6 then slot = "night"
    elseif hour < 9 then slot = "dawn"
    elseif hour < 12 then slot = "morning"
    elseif hour < 18 then slot = "afternoon"
    else slot = "dusk" end
    return (self.L.times and self.L.times[slot]) or ""
end

function N:Say(kind, extraVars, opts)
    opts = opts or {}
    local db = self.db
    if not (db and db.enabled and self.L) then return end

    local now = GetTime()
    if not MAJOR[kind] and now - lastSpokeAt < (db.minInterval or 12) then return end
    if kind == "crit" and now - lastCritAt < (db.critCooldown or 30) then return end
    lastSpokeAt = now
    if kind == "crit" then lastCritAt = now end

    local vars = self:ContextVars(extraVars)
    local phrase = self:PickPhrase(kind, vars)
    if not phrase then return end
    local text = Fill(phrase, vars)

    local header
    if MAJOR[kind] and (kind == "death" or kind == "pvpdeath" or kind == "fall"
        or kind == "fire" or kind == "drown" or kind == "fatigue"
        or kind == "unknown" or kind == "milestone") then
        header = string.format(self.L.deathHeaderFormat or "%d — %s",
            self.cdb.deaths or 0, self.L.headers[kind] or "")
    else
        header = self.L.headers[kind] or "..."
    end

    self:PlayKindSound(kind)

    local mode = db.mode or "toast"
    if mode == "toast" or mode == "both" then
        self:ShowToast(header, text, self.ICONS[kind])
    end
    if mode == "rw" or mode == "both" then
        if RaidNotice_AddMessage and RaidWarningFrame then
            RaidNotice_AddMessage(RaidWarningFrame, text, { r = 0.95, g = 0.85, b = 0.55 }, 5)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Death-cause tracking (combat log)
-- ---------------------------------------------------------------------------

local lastAttackerName, lastAttackerIsPlayer, lastEnv

local function ResetDeathCause()
    lastAttackerName, lastAttackerIsPlayer, lastEnv = nil, nil, nil
end
N.ResetDeathCause = ResetDeathCause

function N:OnCombatLog()
    local t = { CombatLogGetCurrentEventInfo() }
    local subevent = t[2]
    local srcGUID, srcName = t[4], t[5]
    local dstGUID, dstName = t[8], t[9]
    local me = self.meGUID
    if not me then return end

    -- Damage taken: remember who/what gets blamed if we die.
    if dstGUID == me and srcGUID ~= me then
        if subevent == "SWING_DAMAGE" then
            if (t[12] or 0) > 0 then
                lastAttackerName, lastAttackerIsPlayer, lastEnv = srcName, GUIDType(srcGUID) == "Player", nil
            end
        elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
            if (t[15] or 0) > 0 then
                lastAttackerName, lastAttackerIsPlayer, lastEnv = srcName, GUIDType(srcGUID) == "Player", nil
            end
        elseif subevent == "ENVIRONMENTAL_DAMAGE" then
            if (t[13] or 0) > 0 then
                lastEnv = t[12]
                lastAttackerName, lastAttackerIsPlayer = nil, nil
            end
        end
        return
    end

    -- Damage done: big crits get narrated; killing players gets celebrated.
    if srcGUID == me then
        local amount, critical
        if subevent == "SWING_DAMAGE" then
            amount, critical = t[12], t[18]
        elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
            amount, critical = t[15], t[21]
        end
        if amount and critical then
            local maxHp = UnitHealthMax("player") or 0
            local floorAmt = math.floor(amount + 0.5)
            if floorAmt >= (self.db.critMin or 60)
                and maxHp > 0
                and amount >= maxHp * (self.db.critPct or 0.35) then
                self.cdb.crits = (self.cdb.crits or 0) + 1
                self:Say("crit", { amount = floorAmt })
            end
        end
        if subevent == "PARTY_KILL" and GUIDType(dstGUID) == "Player" then
            self.cdb.pvpKills = (self.cdb.pvpKills or 0) + 1
            self:Say("pvpkill", { name = dstName })
        end
    end
end

function N:OnPlayerDead()
    local cdb = self.cdb
    cdb.deaths = (cdb.deaths or 0) + 1

    local kind, name
    if lastEnv == "FALLING" then
        cdb.falls = cdb.falls + 1
        kind = "fall"
    elseif lastEnv == "FIRE" or lastEnv == "LAVA" or lastEnv == "SLIME" then
        cdb.fires = cdb.fires + 1
        kind = "fire"
    elseif lastEnv == "DROWNING" then
        cdb.drowns = cdb.drowns + 1
        kind = "drown"
    elseif lastEnv == "FATIGUE" then
        cdb.fatigues = cdb.fatigues + 1
        kind = "fatigue"
    elseif lastAttackerIsPlayer and lastAttackerName then
        kind, name = "pvpdeath", lastAttackerName
    elseif lastAttackerName then
        kind, name = "death", lastAttackerName
    else
        kind = "unknown"
    end

    if cdb.deaths % 10 == 0 then
        self:Say("milestone", {})
    else
        self:Say(kind, { name = name })
    end
    ResetDeathCause()
end

function N:OnLootMsg(msg)
    local isSelf = false
    for _, prefix in ipairs(self.lootPrefixes or {}) do
        if msg:find(prefix, 1, true) then
            isSelf = true
            break
        end
    end
    if not isSelf then return end

    local link = msg:match("(|c%x+|Hitem:.-|h.-|h|r)")
    if not link then return end

    local _, item, _, _, _, _, _, _, _, _, _, _, quality = GetItemInfo(link)
    if not quality then
        if link:find("|cffff8000", 1, true) then quality = 5
        elseif link:find("|cffa335ee", 1, true) then quality = 4 end
    end

    if quality == 5 then
        self:Say("legendary", { item = item or "the unnameable" })
    elseif quality == 4 then
        self:Say("loot", { item = item or "something epic" })
    end
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------

local DEMO = {
    { "death",    { name = "a Ratchet Guard" } },
    { "pvpdeath", { name = "Gnomorc" } },
    { "fall",     {} },
    { "fire",     {} },
    { "crit",     { amount = 842 } },
    { "pvpkill",  { name = "Stabmaster" } },
    { "loot",     { item = "Shadowfang" } },
    { "levelup",  { level = 60 } },
}

local function RunDemo()
    Print(S("demo_msg"))
    for i, entry in ipairs(DEMO) do
        C_Timer.After(0.8 * i, function()
            N:Say(entry[1], entry[2])
        end)
    end
end

local function TestContext(kind)
    local ctx = {
        death = { name = "an enraged boar" },
        pvpdeath = { name = "a ruthless gnome" },
        crit = { amount = 753 },
        pvpkill = { name = "your nemesis" },
        loot = { item = "an epic trinket" },
        legendary = { item = "a legendary blade" },
        levelup = { level = (UnitLevel and UnitLevel("player") or 1) + 1 },
        login = { name = (UnitName and UnitName("player")) or "wanderer" },
        milestone = { deaths = N.cdb.deaths or 42 },
    }
    return ctx[kind] or {}
end

SLASH_NARRATOR1 = "/narrator"
SLASH_NARRATOR2 = "/nar"
function SlashCmdList.NARRATOR(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "test" then
        local kind = arg ~= "" and arg or "death"
        N:Say(kind, TestContext(kind))
    elseif cmd == "demo" then
        RunDemo()
    elseif cmd == "on" or cmd == "off" then
        N.db.enabled = (cmd == "on")
        Print(cmd == "on" and S("on_msg") or S("off_msg"))
    elseif cmd == "mode" then
        if arg == "toast" or arg == "rw" or arg == "both" then
            N.db.mode = arg
            Print(string.format(S("mode_set"), arg))
        else
            Print(string.format(S("mode_usage"), tostring(N.db.mode)))
        end
    elseif cmd == "lang" then
        if arg == "" then
            Print(string.format(S("lang_usage"), N:LocaleList()))
        elseif arg == "auto" then
            N.db.lang = "auto"
            N:SetLocale()
            Print(string.format(S("lang_auto"), N.localeKey))
        elseif N.LOCALES[arg] then
            N.db.lang = arg
            N:SetLocale()
            Print(string.format(S("lang_set"), N.LOCALES[arg].name or arg))
        else
            Print(string.format(S("lang_unknown"), arg, N:LocaleList()))
        end
    elseif cmd == "style" then
        if arg == "static" or arg == "mixed" or arg == "impro" then
            N.db.style = arg
            Print(string.format(S("style_set"), arg))
        else
            Print(string.format(S("style_usage"), tostring(N.db.style)))
        end
    elseif cmd == "sound" then
        N.db.sound = not N.db.sound
        Print(N.db.sound and S("sound_on") or S("sound_off"))
    elseif cmd == "media" then
        N.db.media = not N.db.media
        Print(N.db.media and S("media_on") or S("media_off"))
    elseif cmd == "interval" then
        local v = tonumber(arg)
        if v and v >= 0 then
            N.db.minInterval = v
            Print(string.format(S("interval_set"), v))
        else
            Print(S("interval_usage"))
        end
    elseif cmd == "crit" then
        local v = tonumber(arg)
        if v and v > 0 and v <= 1 then
            N.db.critPct = v
            Print(string.format(S("crit_set"), math.floor(v * 100)))
        else
            Print(string.format(S("crit_usage"), tostring(N.db.critPct)))
        end
    elseif cmd == "stats" then
        local c = N.cdb
        Print(string.format(S("stats_format"),
            c.deaths or 0, c.falls or 0, c.fires or 0, c.drowns or 0,
            c.fatigues or 0, c.crits or 0, c.pvpKills or 0, c.level or 1))
    elseif cmd == "reset" then
        local fresh = {}
        for k, v in pairs(CHAR_DEFAULTS) do fresh[k] = v end
        N.cdb = fresh
        NarratorCharDB = fresh
        Print(S("reset_msg"))
    else
        Print(string.format(S("help_title"), N.VERSION))
        for _, line in ipairs(S("help_lines")) do Print(line) end
    end
end

-- ---------------------------------------------------------------------------
-- Boot
-- ---------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("PLAYER_UNGHOST")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Narrator" then
            N.db = MergeDefaults(NarratorDB, DEFAULTS)
            N.cdb = MergeDefaults(NarratorCharDB, CHAR_DEFAULTS)
            NarratorDB, NarratorCharDB = N.db, N.cdb
            N:SetLocale()
        end
    elseif event == "PLAYER_LOGIN" then
        N.meGUID = UnitGUID("player")
        N.cdb.level = UnitLevel("player") or N.cdb.level
        math.randomseed(time())
        if N.db.loginGreeting then
            C_Timer.After(6, function()
                N:Say("login", { name = UnitName("player") or "wanderer" })
            end)
        end
    elseif event == "PLAYER_DEAD" then
        N:OnPlayerDead()
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        ResetDeathCause()
    elseif event == "PLAYER_LEVEL_UP" then
        N.cdb.level = arg1
        C_Timer.After(1.5, function()
            N:Say("levelup", { level = arg1 })
        end)
    elseif event == "CHAT_MSG_LOOT" then
        N:OnLootMsg(arg1)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        N:OnCombatLog()
    end
end)
