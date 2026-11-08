-- Narrator — BG3-style narration toast.
-- Dark translucent plate, thin gold border, Morpheus (the WoW "storybook"
-- font) body, small-caps header. Text only, centered: the narrator is a
-- voice, not a UI.

local N = Narrator

local WIDTH = 540
local TEXT_WIDTH = 470
local HOLD_SECONDS = 4.5
local MAX_QUEUE = 3

local frame
local queue = {}
local hideTimer
local showing = false
local NextToast

local FONT_HEADER = "Fonts\\FRIZQT__.TTF"
local DEFAULT_FONT_BODY = "Fonts\\MORPHEUS.TTF"

-- Locales may ship their own body font (CJK/Cyrillic need other glyphs).
local function BodyFont()
    return (N.L and N.L.font) or DEFAULT_FONT_BODY
end

function N:RefreshToastFont()
    if frame and frame.body then
        frame.body:SetFont(BodyFont(), 15)
    end
end

local function BuildFrame()
    if frame then return frame end

    frame = CreateFrame("Frame", "NarratorToast", UIParent, "BackdropTemplate")
    frame:SetWidth(WIDTH)
    frame:SetHeight(86)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -110)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint(1)
        if N.db then
            N.db.toastX, N.db.toastY = x, y
        end
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.86)
    frame:SetBackdropBorderColor(0.62, 0.51, 0.28, 0.95)
    frame:Hide()

    frame.header = frame:CreateFontString(nil, "OVERLAY")
    frame.header:SetFont(FONT_HEADER, 11)
    frame.header:SetSpacing(2.5)
    frame.header:SetTextColor(0.85, 0.72, 0.42)
    frame.header:SetJustifyH("CENTER")
    frame.header:SetPoint("TOP", frame, "TOP", 0, -14)

    frame.body = frame:CreateFontString(nil, "OVERLAY")
    frame.body:SetFont(BodyFont(), 15)
    frame.body:SetTextColor(0.96, 0.93, 0.86)
    frame.body:SetJustifyH("CENTER")
    frame.body:SetWidth(TEXT_WIDTH)
    frame.body:SetPoint("TOP", frame.header, "BOTTOM", 0, -8)

    -- Entrance: fade in while sinking into place, like a caption.
    local inGroup = frame:CreateAnimationGroup()
    local inAlpha = inGroup:CreateAnimation("Alpha")
    inAlpha:SetChange(1)
    inAlpha:SetDuration(0.35)
    inAlpha:SetSmoothing("IN")
    local inSlide = inGroup:CreateAnimation("Translation")
    inSlide:SetOffset(0, -34)
    inSlide:SetDuration(0.35)
    inSlide:SetSmoothing("OUT")
    frame.inGroup = inGroup

    -- Exit: slow fade, the narrator never slams the door.
    local outGroup = frame:CreateAnimationGroup()
    local outAlpha = outGroup:CreateAnimation("Alpha")
    outAlpha:SetChange(-1)
    outAlpha:SetDuration(0.55)
    outAlpha:SetSmoothing("OUT")
    outGroup:SetScript("OnFinished", function()
        frame:Hide()
        showing = false
        NextToast()
    end)
    frame.outGroup = outGroup

    frame:SetAlpha(0)
    return frame
end

function NextToast()
    if showing or frame and frame:IsShown() then return end
    local next = table.remove(queue, 1)
    if not next then return end
    showing = true

    frame = frame or BuildFrame()
    frame.header:SetText(next.header)
    frame.body:SetText(next.text)

    local bodyHeight = frame.body:GetStringHeight()
    frame:SetHeight(bodyHeight + 48)

    if N.db and N.db.toastX then
        frame:ClearAllPoints()
        frame:SetPoint("TOP", UIParent, "TOP", N.db.toastX, N.db.toastY)
    end

    frame:SetAlpha(0)
    frame:Show()
    frame.inGroup:Stop()
    frame.outGroup:Stop()
    frame.inGroup:Play()

    hideTimer = C_Timer.NewTimer(HOLD_SECONDS, function()
        hideTimer = nil
        if frame and frame:IsShown() then
            frame.outGroup:Play()
        end
    end)
end

function N:ShowToast(header, text, icon)
    if #queue >= MAX_QUEUE then
        table.remove(queue, 1)
    end
    queue[#queue + 1] = { header = header, text = text, icon = icon }
    if not showing then
        NextToast()
    end
end
