local addon = ...

local locale = GetLocale()
local chinese = locale == "zhCN" or locale == "zhTW"
local label = {
    drag = chinese and "拖动到聊天输入框的位置" or "Drag to position the chat input",
    save = chinese and "保存" or "Save",
    cancel = chinese and "取消" or "Cancel",
    saved = chinese and "已保存。按回车查看输入框。" or "Position saved. Press Enter to open chat.",
    reset = chinese and "已恢复聊天输入框的原有位置。" or "Restored the original chat input position.",
    help = chinese and "/fci 调整位置，/fci reset 恢复原位。" or "/fci to position the input, /fci reset to restore it.",
}

local frame, originalPoints, pending
local hookedLayouts = {}

local function IsReadable(value)
    if canaccessvalue then return canaccessvalue(value) end
    return not issecretvalue or not issecretvalue(value)
end

local function IsNumber(value)
    return IsReadable(value) and type(value) == "number" and math.abs(value) < math.huge
end

local function SavePosition(x, y)
    ForeverChatInputDB.x = x
    ForeverChatInputDB.y = y
end

local function IsPermanentBox(box)
    if not IsReadable(box) or not box then return false end
    local forbidden = box:IsForbidden()
    if not IsReadable(forbidden) or forbidden then return false end
    local name = box:GetName()
    if not IsReadable(name) or not name then return false end
    local index = tonumber(name:match("^ChatFrame(%d+)EditBox$"))
    return index and index >= 1 and index <= 10
end

local function ReadPoints(box)
    local count = box:GetNumPoints()
    if not IsNumber(count) then return end
    local points = {}
    for i = 1, count do
        local point, relative, relativePoint, x, y = box:GetPoint(i)
        if not (IsReadable(point) and IsReadable(relative) and IsReadable(relativePoint)
            and point and relativePoint and IsNumber(x) and IsNumber(y)) then return end
        points[#points + 1] = { point, relative, relativePoint, x, y }
    end
    return points
end

local function SetPoints(box, points)
    box:ClearAllPoints()
    for _, point in ipairs(points) do
        box:SetPoint(point[1], point[2], point[3], point[4], point[5])
    end
end

local function CanMove(box)
    local forbidden = box:IsForbidden()
    if not IsReadable(forbidden) or forbidden then return false end
    local restricted = box.IsAnchoringRestricted and box:IsAnchoringRestricted()
    if not IsReadable(restricted) or restricted then return false end
    local protected = box:IsProtected()
    return IsReadable(protected) and not (protected and InCombatLockdown())
end

local function ScreenScale(box)
    local scale = box:GetEffectiveScale()
    if IsNumber(scale) and scale > 0 then
        return scale / UIParent:GetEffectiveScale()
    end
end

local function BoxSize(box)
    local width, height = box:GetSize()
    if not (IsNumber(width) and IsNumber(height) and width > 0 and height > 0) then return end
    local scale = ScreenScale(box)
    if scale then return width * scale, height * scale end
end

local function ClampCenter(value, halfSize, span)
    local margin = math.min(halfSize + 4, span / 2)
    return math.max(margin, math.min(span - margin, value))
end

local function PlaceOnScreen(widget, x, y)
    local screenWidth, screenHeight = UIParent:GetSize()
    local width, height = widget:GetSize()
    widget:ClearAllPoints()
    widget:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
        ClampCenter(x * screenWidth, width / 2, screenWidth),
        ClampCenter(y * screenHeight, height / 2, screenHeight))
end

local function ReadScreenCenter(widget)
    local x, y = widget:GetCenter()
    if not (IsNumber(x) and IsNumber(y)) then return end
    local screenWidth, screenHeight = UIParent:GetSize()
    local scale = ScreenScale(widget)
    if scale then return x * scale / screenWidth, y * scale / screenHeight end
end

local function NewBackdrop(strata)
    local widget = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    widget:SetFrameStrata(strata)
    widget:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    widget:SetBackdropColor(0.025, 0.025, 0.025, 0.92)
    widget:SetBackdropBorderColor(0.65, 0.47, 0.25, 0.95)
    widget:Hide()
    return widget
end

local anchor = NewBackdrop("LOW")
local attachedPoints = {
    { "TOPLEFT", anchor, "TOPLEFT", 0, 0 },
    { "BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0 },
}

local function UsesOurAnchor(points)
    for _, point in ipairs(points) do
        if point[2] == anchor then return true end
    end
    return false
end

local function MatchesPlacement(points)
    if #points ~= #attachedPoints then return false end
    for index, point in ipairs(points) do
        local expected = attachedPoints[index]
        for column = 1, 5 do
            if point[column] ~= expected[column] then return false end
        end
    end
    return true
end

local function Restore()
    anchor:Hide()
    if not frame then return true end
    if not CanMove(frame) then return false end
    local points = ReadPoints(frame)
    if not points then return false end
    if UsesOurAnchor(points) then SetPoints(frame, originalPoints) end
    frame, originalPoints = nil, nil
    return true
end

local function Refresh()
    pending = false
    local db = ForeverChatInputDB
    local box = ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow()
    local visible = IsPermanentBox(box) and box:IsVisible()
    if not (db and IsNumber(db.x) and IsNumber(db.y) and IsReadable(visible) and visible) then
        Restore()
        return
    end

    if frame ~= box and not Restore() then return end
    if not CanMove(box) then return end
    local points = ReadPoints(box)
    local width, height = BoxSize(box)
    if not (points and #points > 0 and width) then return end

    -- An EllesmereUI layout pass may have replaced our points while the box
    -- was open. Keep the latest original points for when the box closes.
    if not UsesOurAnchor(points) then
        frame, originalPoints = box, points
    end
    anchor:SetSize(width, height)
    PlaceOnScreen(anchor, db.x, db.y)
    local strata, level = box:GetFrameStrata(), box:GetFrameLevel()
    anchor:SetFrameStrata(IsReadable(strata) and strata or "LOW")
    anchor:SetFrameLevel(IsNumber(level) and math.max(0, level - 1) or 0)
    if not MatchesPlacement(points) then SetPoints(box, attachedPoints) end
    anchor:Show()
end

local function QueueRefresh()
    if pending then return end
    pending = true
    C_Timer.After(0, Refresh)
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd18aForeverChatInput|r " .. message)
end

local preview = NewBackdrop("DIALOG")
preview:SetMovable(true)
preview:SetClampedToScreen(true)
preview:EnableMouse(true)
preview:RegisterForDrag("LeftButton")
preview:SetScript("OnDragStart", preview.StartMoving)
preview:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = ReadScreenCenter(self)
    if x then PlaceOnScreen(self, x, y) end
end)
preview:SetScript("OnHide", preview.StopMovingOrSizing)

local prompt = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
prompt:SetPoint("TOP", 0, -12)
prompt:SetText(label.drag)

local function AddPreviewButton(text, x, click)
    local button = CreateFrame("Button", nil, preview, "UIPanelButtonTemplate")
    button:SetSize(84, 23)
    button:SetPoint("BOTTOM", preview, "BOTTOM", x, 9)
    button:SetText(text)
    button:SetScript("OnClick", click)
end

AddPreviewButton(label.save, -45, function()
    local x, y = ReadScreenCenter(preview)
    if x then
        SavePosition(x, y)
        QueueRefresh()
        Print(label.saved)
    end
    preview:Hide()
end)
AddPreviewButton(label.cancel, 45, function() preview:Hide() end)

SLASH_FOREVERCHATINPUT1 = "/fci"
SlashCmdList.FOREVERCHATINPUT = function(input)
    local command = input:match("^%s*(.-)%s*$"):lower()
    if command == "reset" then
        preview:Hide()
        SavePosition(nil, nil)
        QueueRefresh()
        Print(label.reset)
    elseif command == "" or command == "move" then
        if preview:IsShown() then
            preview:Hide()
            return
        end
        local db = ForeverChatInputDB
        local box = ChatFrame1EditBox
        if not (IsPermanentBox(box) and CanMove(box)) then box = nil end
        local width = box and BoxSize(box)
        preview:SetSize(math.max(width or 300, 220), 64)
        local x, y
        if IsNumber(db.x) and IsNumber(db.y) then
            x, y = db.x, db.y
        elseif box then
            x, y = ReadScreenCenter(box)
        end
        PlaceOnScreen(preview, x or 0.5, y or 0.5)
        preview:Show()
    else
        Print(label.help)
    end
end

local function HookEllesmereLayout()
    local modules = EllesmereUI and EllesmereUI._ModuleNS
    local chat = modules and modules.EllesmereUIChat
    local layout = chat and chat.ECHAT
    if not layout then return end
    if hookedLayouts[layout] or type(layout.ApplyInputPosition) ~= "function" then return end
    hookedLayouts[layout] = true
    hooksecurefunc(layout, "ApplyInputPosition", function()
        if frame then QueueRefresh() end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == addon then
            if type(ForeverChatInputDB) ~= "table" then ForeverChatInputDB = {} end
        elseif name ~= "EllesmereUIChat" then
            return
        end
        HookEllesmereLayout()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        HookEllesmereLayout()
    end
    QueueRefresh()
end)

-- Chat state callbacks stay out of Blizzard's input scripts. The actual
-- geometry changes run after the native activation or deactivation ends.
for _, event in ipairs({ "OnEditBoxShow", "OnEditBoxHide", "OnEditBoxFocusGained", "OnEditBoxFocusLost" }) do
    EventRegistry:RegisterCallback("ChatFrame." .. event, QueueRefresh, addon)
end
