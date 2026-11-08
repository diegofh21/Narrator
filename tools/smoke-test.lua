-- El Narrador — smoke test (runs in plain Lua 5.4, no WoW needed).
-- Stubs just enough of the WoW API to exercise: locale loading & merging,
-- the phrase picker, the procedural generator, combat-log death/crit flows,
-- loot detection and live language switching.
--
--   lua tools/smoke-test.lua   (from the repo root)

local ROOT = (arg and arg[0] and arg[0]:match("^(.*)tools[/\\]")) or "./"

unpack = table.unpack or unpack -- Lua 5.4 vs WoW's Lua 5.1

-- ---------------------------------------------------------------------------
-- WoW API stubs
-- ---------------------------------------------------------------------------

local bootFrame

local function stubElement(name)
    local el = { _name = name }
    setmetatable(el, {
        __index = function(t, k)
            -- Unknown members behave as no-op methods returning the element.
            return function() return t end
        end,
    })
    function el:SetText(text) el._text = text end
    function el:GetStringHeight() return 30 end
    function el:GetText() return el._text end
    return el
end

local function stubFrame()
    local f = stubElement("Frame")
    function f:SetScript(ev, fn) f["_fn" .. ev] = fn end
    function f:CreateFontString() return stubElement("FontString") end
    function f:CreateAnimationGroup()
        local g = stubElement("AnimationGroup")
        function g:CreateAnimation() return stubElement("Animation") end
        return g
    end
    return f
end

DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) print("[game] " .. msg) end }
UIParent = stubElement("UIParent")
SlashCmdList = {}

CreateFrame = function()
    local f = stubFrame()
    if not bootFrame then bootFrame = f end
    return f
end

local clock = 100
GetTime = function() clock = clock + 1 return clock end

C_Timer = {
    After = function(_, cb) cb() end,
    NewTimer = function(_, cb) cb() return { Cancel = function() end } end,
}

GetLocale = function() return "esES" end
UnitGUID = function() return "Player-1-ABC" end
UnitName = function() return "Diego" end
UnitLevel = function() return 42 end
UnitHealthMax = function() return 1000 end
GetGameTime = function() return 20 end -- dusk
GetZoneText = function() return "Valle de Cresta" end
time = function() return 1731000000 end

function strsplit(sep, s)
    local out = {}
    for part in string.gmatch(s or "", "[^" .. sep .. "]+") do out[#out + 1] = part end
    return out[1], out[2], out[3]
end

local CLEU
CombatLogGetCurrentEventInfo = function()
    return unpack(CLEU or {})
end

GetItemInfo = function()
    return nil, "Botín Épico", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 4
end

playedSounds = {}
PlaySoundFile = function(path, chan) playedSounds[#playedSounds + 1] = path end

local fireTimerCallbacks = function() end

-- ---------------------------------------------------------------------------
-- Load the addon in TOC order
-- ---------------------------------------------------------------------------

dofile(ROOT .. "Core.lua")
dofile(ROOT .. "Locale/enUS.lua")
dofile(ROOT .. "Locale/esES.lua")
dofile(ROOT .. "Locale/esMX.lua")
dofile(ROOT .. "Locale/gen.lua")
dofile(ROOT .. "Toast.lua")

local N = Narrator

-- ---------------------------------------------------------------------------
-- Assertions
-- ---------------------------------------------------------------------------

local failures = 0
local function check(cond, label)
    if cond then
        print("  ok  " .. label)
    else
        failures = failures + 1
        print("  FAIL " .. label)
    end
end

local function fire(event, ...)
    bootFrame["_fnOnEvent"](bootFrame, event, ...)
end

print("== boot ==")
fire("ADDON_LOADED", "Narrator")
fire("PLAYER_LOGIN")

check(N.L ~= nil, "locale merged (N.L exists)")
check(N.localeKey == "esES", "client locale esES resolved")
check(#N.lootPrefixes >= 3, "loot prefixes merged from all locales")
check(N.L.font == "Fonts\\MORPHEUS.TTF", "font resolved")

print("== toast text (esES) ==")
local toastFrameTexts = {}
local realShowToast = N.ShowToast
N.ShowToast = function(self, header, text, icon)
    toastFrameTexts[#toastFrameTexts + 1] = { header = header, text = text }
    return realShowToast(self, header, text, icon)
end

N:Say("death", { name = "Guardia de Ratchet" })
local last = toastFrameTexts[#toastFrameTexts]
check(last and last.text:find("Guardia de Ratchet", 1, true) ~= nil,
    "death phrase includes attacker name")
check(last and last.header:find("MUERTE Nº 0", 1, true) ~= nil,
    "death header includes esES count format")

print("== combat log: death by mob ==")
local me = "Player-1-ABC"
CLEU = { 1, "SWING_DAMAGE", false,
    "Creature-1-777", "Guardia de Ratchet", 68, 0,
    me, "Diego", 68, 0,
    300, 0, 1, 0, 0, 0, 0, nil }
N:OnCombatLog()
fire("PLAYER_DEAD")
check(N.cdb.deaths == 1, "death counter incremented")
check(toastFrameTexts[#toastFrameTexts].text:find("Guardia", 1, true) ~= nil,
    "death narrated with combat log attacker")

print("== combat log: environmental fall death ==")
CLEU = { 2, "ENVIRONMENTAL_DAMAGE", false,
    "", nil, 0, 0,
    me, "Diego", 0, 0,
    "FALLING", 900 }
N:OnCombatLog()
fire("PLAYER_DEAD")
check(N.cdb.falls == 1, "fall death counted")
check(N.cdb.deaths == 2, "second death counted")

print("== milestone (10th death) ==")
N.cdb.deaths = 9
fire("PLAYER_DEAD")
local milestoneText = toastFrameTexts[#toastFrameTexts].text
check(N.cdb.deaths == 10, "10th death reached")
check(milestoneText:find("10", 1, true) ~= nil, "milestone mentions the number")

print("== combat log: big crit ==")
for _ = 1, 20 do GetTime() end -- advance past the minor-narration interval
local critsBefore = N.cdb.crits
CLEU = { 3, "SPELL_DAMAGE", false,
    me, "Diego", 68, 0,
    "Creature-1-888", "Mob", 68, 0,
    12345, "Bola de Fuego", 1, 500, 0, 1, 0, 0, 0, 0, true }
N:OnCombatLog()
check(N.cdb.crits == critsBefore + 1, "big crit narrated")
local critText = toastFrameTexts[#toastFrameTexts].text
check(critText:find("500", 1, true) ~= nil, "crit phrase includes damage")

print("== crit cooldown ==")
local toastsBeforeCrit = #toastFrameTexts
N:OnCombatLog()
check(#toastFrameTexts == toastsBeforeCrit, "second crit within cooldown not narrated")

print("== loot (esES client line) ==")
for _ = 1, 20 do GetTime() end -- loot is a minor event too
N:OnLootMsg("Recibes botín: |cffa335ee|Hitem:12345|h[Botín]|h|r")
local lootText = toastFrameTexts[#toastFrameTexts].text
check(lootText:find("Botín Épico", 1, true) ~= nil, "epic loot narrated with item name")

N:OnLootMsg("Gnomorc recibe botín: |cffa335ee|Hitem:12345|h[Botín]|h|r")
check(toastFrameTexts[#toastFrameTexts].text == lootText, "someone else's loot ignored")

print("== language switch (live) ==")
N.db.lang = "enUS"
N:SetLocale()
N:Say("death", { name = "Ratchet Guard" })
local enText = toastFrameTexts[#toastFrameTexts].text
check(enText:find("Ratchet Guard", 1, true) ~= nil, "narrates in English after switch")
check(toastFrameTexts[#toastFrameTexts].header:find("DEATH No. 10", 1, true) ~= nil,
    "enUS header format after switch")

print("== procedural generator ==")
local kindsWithTemplates = {}
for kind in pairs(N.L.generator.templates) do kindsWithTemplates[#kindsWithTemplates + 1] = kind end
check(#kindsWithTemplates >= 10, "generator templates present for >= 10 kinds")

local bad = 0
for i = 1, 200 do
    local vars = N:ContextVars({ name = "Jabalí", amount = 842, level = 43,
        item = "Zarpaluna", deaths = 12 })
    local phrase = N:Generate("death", vars)
    if not phrase or phrase:find("{%w+}") then bad = bad + 1 end
end
check(bad == 0, "200 generated death lines with no unresolved placeholders")

local zoneSeen = 0
for i = 1, 100 do
    local p = N:Generate("fall", N:ContextVars({}))
    if p:find("Valle de Cresta", 1, true) then zoneSeen = zoneSeen + 1 end
end
check(zoneSeen > 0, "generator uses live context (zone)")

print("== AI pack integration ==")
N.db.lang = "esES"
N:SetLocale()
N.GENERATED = { phrases = { esES = { death = { "IA: {name} cae. {closer}" } } } }
N.db.style = "impro"
local aiHits = 0
for i = 1, 40 do
    N.lastPhrase = nil
    local phrase = N:PickPhrase("death", N:ContextVars({ name = "X" }))
    if phrase and phrase:find("IA: ", 1, true) then aiHits = aiHits + 1 end
end
check(aiHits > 0, "AI packs selected in impro mode")
N.GENERATED = nil
N.db.style = "mixed"

print("== voice playback ==")
Narrator.VOICE = { esES = { death = { "esES/abc123.wav" } } }
N.db.lang = "esES"
N:SetLocale()
N.db.voice = true
N:Say("death", { name = "X" })
check(#playedSounds > 0 and playedSounds[#playedSounds]:find("abc123.wav", 1, true) ~= nil,
    "spoken line played via PlaySoundFile")
N.db.voice = false
local soundsBefore = #playedSounds
N:Say("death", { name = "X" })
check(#playedSounds == soundsBefore, "voice off plays no audio")
N.db.voice = true
Narrator.VOICE = nil

print("== slash handler smoke ==")
SlashCmdList.NARRATOR("help")
SlashCmdList.NARRATOR("lang frFR")   -- unknown -> error message, no crash
SlashCmdList.NARRATOR("lang enUS")
SlashCmdList.NARRATOR("style impro")
SlashCmdList.NARRATOR("test death")
check(true, "slash commands survive unknown input")

print("")
if failures == 0 then
    print("ALL CHECKS PASSED")
else
    print(failures .. " CHECK(S) FAILED")
    os.exit(1)
end
