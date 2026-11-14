local addon, ns = ...

local locale = GetLocale()
local chinese = locale == "zhCN" or locale == "zhTW"
local label = {
    drag = chinese and "拖动到聊天输入框的位置" or "Drag to position the chat input",
    save = chinese and "保存" or "Save",
    cancel = chinese and "取消" or "Cancel",
    saved = chinese and "已保存。按回车查看输入框。" or "Position saved. Press Enter to open chat.",
    reset = chinese and "已恢复聊天输入框的原有位置。" or "Restored the original chat input position.",
    help = chinese and "/fci 调整位置，/fci reset 恢复原位，/fci ime show 或 hide 设置输入法标记。"
        or "/fci to move, /fci reset to restore, /fci ime show or hide to set the input language button.",
    imeShown = chinese and "已显示移出输入框的输入法标记。" or "Showing the input language button.",
    imeHidden = chinese and "已隐藏移出输入框的输入法标记。" or "Hiding the input language button.",
    mover = locale == "zhTW" and "聊天輸入框" or (chinese and "聊天输入框" or "Chat Input"),
    inUnlock = chinese and "请先退出 EllesmereUI 的解锁模式。" or "Exit EllesmereUI Unlock Mode first.",
}

local frame, originalPoints, pending
local languageButton, languageAlpha, languageMouse
local preview
local unlockFrame, unlockActive, unlockChange
local hookedLayouts = {}
local topStripLayout

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

local function CanReadAnchors(box)
    local forbidden = box:IsForbidden()
    if not IsReadable(forbidden) or forbidden then return false end
    local restricted = box.IsAnchoringRestricted and box:IsAnchoringRestricted()
    return IsReadable(restricted) and not restricted
end

local function CanMove(box)
    if not CanReadAnchors(box) then return false end
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

local function GetPlacement()
    local box = ChatFrame1EditBox
    if not (IsPermanentBox(box) and CanMove(box)) then box = nil end
    local width, height
    if box then width, height = BoxSize(box) end

    local x, y
    local db = ForeverChatInputDB
    if db and IsNumber(db.x) and IsNumber(db.y) then
        x, y = db.x, db.y
    elseif box then
        x, y = ReadScreenCenter(box)
    end
    return x or 0.5, y or 0.5, width or 300, height or 23
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

local function IsInputUp(box, imStyle)
    if not box or box == frame or not box:IsShown() then return false end
    if not imStyle or box:HasFocus() then return true end
    return box == ChatFrameUtil.GetActiveWindow() and not box:ShouldDeactivateChatOnEditFocusLost()
end

local function NeedsOriginalTopStrip(chatFrame)
    if not frame or not CanReadAnchors(frame) then return true end
    local count = frame:GetNumPoints()
    if not IsNumber(count) or count == 0 then return true end
    local _, relative = frame:GetPoint(1)
    if not IsReadable(relative) or relative ~= anchor then return true end

    local name = chatFrame:GetName()
    local id = name and tonumber(name:match("^ChatFrame(%d+)$"))
    if not id or id > 10 then return true end

    local boxName = frame:GetName()
    if not IsReadable(boxName) or not boxName then return true end
    local ownBox = _G[name .. "EditBox"]
    local owner = _G[boxName:match("^(ChatFrame%d+)EditBox$")]
    local docked = chatFrame.isDocked and chatFrame:IsShown()
    if ownBox ~= frame and not (docked and owner and owner.isDocked) then return true end

    -- Another attached box can still occupy the top of the selected dock tab.
    local imStyle = GetCVar("chatStyle") == "im"
    if IsInputUp(ownBox, imStyle) then return true end
    if docked then
        for index = 1, 10 do
            local other = _G["ChatFrame" .. index]
            if other and other ~= chatFrame and other.isDocked
                and IsInputUp(_G["ChatFrame" .. index .. "EditBox"], imStyle) then return true end
        end
    end
    return false
end

local function RefreshTopStrips()
    local layout = topStripLayout
    if layout and layout.InputOnTop(layout.DB()) then layout.RefreshInputTopStrips() end
end

local function RestoreLanguageButton()
    if not languageButton then return end
    languageButton:SetAlpha(languageAlpha)
    languageButton:EnableMouse(languageMouse)
    languageButton, languageAlpha, languageMouse = nil, nil, nil
end

local function UpdateLanguageButton(box)
    -- Blizzard owns the button's show/hide, label and language switching.
    -- Only suppress the button's drawing and mouse hit area while detached.
    local button = _G[box:GetName() .. "Language"]
    if not button or ForeverChatInputDB.hideInputLanguage == false then
        RestoreLanguageButton()
    elseif button ~= languageButton then
        RestoreLanguageButton()
        local alpha, mouse = button:GetAlpha(), button:IsMouseEnabled()
        if not (IsNumber(alpha) and IsReadable(mouse)) then return end
        languageButton, languageAlpha, languageMouse = button, alpha, mouse
        button:SetAlpha(0)
        button:EnableMouse(false)
    end
end

local function Restore()
    anchor:Hide()
    RestoreLanguageButton()
    if not frame then return true end
    if not CanMove(frame) then return false end
    local points = ReadPoints(frame)
    if not points then return false end
    if UsesOurAnchor(points) then SetPoints(frame, originalPoints) end
    frame, originalPoints = nil, nil
    RefreshTopStrips()
    return true
end

local function Refresh()
    pending = false
    if preview:IsShown() then ns.StyleInput(preview, true) end
    local db = ForeverChatInputDB
    local box = ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow()
    local visible = IsPermanentBox(box) and box:IsVisible()
    if unlockActive or not (db and IsNumber(db.x) and IsNumber(db.y) and IsReadable(visible) and visible) then
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
    ns.StyleInput(anchor)
    UpdateLanguageButton(box)
    anchor:Show()
    RefreshTopStrips()
end

local function QueueRefresh()
    if pending then return end
    pending = true
    C_Timer.After(0, Refresh)
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd18aForeverChatInput|r " .. message)
end

local function PlaceUnlockFrame()
    local x, y, width, height = GetPlacement()
    unlockFrame:SetSize(width, height)
    PlaceOnScreen(unlockFrame, x, y)
end

local function RegisterUnlockMover()
    local eui = EllesmereUI
    if unlockFrame or not (eui and eui.MakeUnlockElement and eui.RegisterUnlockElements
        and eui.RegisterUnlockModeListener) then return end

    -- The mover edits our proxy. Native input anchors stay outside Unlock Mode.
    unlockFrame = CreateFrame("Frame", nil, UIParent)
    unlockFrame:Hide()
    PlaceUnlockFrame()
    eui:RegisterUnlockElements({ eui.MakeUnlockElement({
        key = addon,
        label = label.mover,
        group = "Chat",
        order = 601,
        getFrame = function() return unlockFrame end,
        getSize = function() return unlockFrame:GetSize() end,
        noResize = true,
        ownsPosition = true,
        noAnchorTarget = true,
        noSizeMatchTarget = true,
        noSpecLayout = true,
        noInitHook = true,
        isHidden = function() return eui._specialUnlockGroup ~= nil end,
        loadPos = function()
            if not unlockActive then PlaceUnlockFrame() end
            local db = ForeverChatInputDB
            if not (db and IsNumber(db.x) and IsNumber(db.y)) then return end
            local w, h = UIParent:GetSize()
            return { point = "CENTER", relPoint = "CENTER", x = (db.x - 0.5) * w, y = (db.y - 0.5) * h }
        end,
        savePos = function(_, point, relative, x, y)
            if point ~= "CENTER" or relative ~= "CENTER" or not (IsNumber(x) and IsNumber(y)) then return end
            local w, h = UIParent:GetSize()
            x, y = 0.5 + x / w, 0.5 + y / h
            if unlockActive then
                unlockChange = { x = x, y = y }
            else
                SavePosition(x, y)
                PlaceUnlockFrame()
                QueueRefresh()
            end
        end,
        clearPos = function()
            if unlockActive then
                unlockChange = {}
            else
                SavePosition(nil, nil)
                PlaceUnlockFrame()
                QueueRefresh()
            end
        end,
        applyPos = PlaceUnlockFrame,
    }) }, addon)
    eui:RegisterUnlockModeListener(addon, function(active, action)
        unlockActive = active
        if active then
            preview:Hide()
        else
            if action == "save" and unlockChange then SavePosition(unlockChange.x, unlockChange.y) end
            unlockChange = nil
            PlaceUnlockFrame()
        end
        QueueRefresh()
    end)
end

preview = NewBackdrop("DIALOG")
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
        if unlockFrame then PlaceUnlockFrame() end
        QueueRefresh()
        Print(label.saved)
    end
    preview:Hide()
end)
AddPreviewButton(label.cancel, 45, function() preview:Hide() end)

SLASH_FOREVERCHATINPUT1 = "/fci"
SlashCmdList.FOREVERCHATINPUT = function(input)
    local command = input:match("^%s*(.-)%s*$"):lower()
    if unlockActive then
        Print(label.inUnlock)
        return
    end
    if command == "reset" then
        preview:Hide()
        SavePosition(nil, nil)
        if unlockFrame then PlaceUnlockFrame() end
        QueueRefresh()
        Print(label.reset)
    elseif command == "ime show" or command == "ime hide" then
        local hide = command == "ime hide"
        ForeverChatInputDB.hideInputLanguage = hide
        QueueRefresh()
        Print(hide and label.imeHidden or label.imeShown)
    elseif command == "" or command == "move" then
        if preview:IsShown() then
            preview:Hide()
            return
        end
        local x, y, width = GetPlacement()
        preview:SetSize(math.max(width, 220), 64)
        PlaceOnScreen(preview, x, y)
        ns.StyleInput(preview, true)
        preview:Show()
    else
        Print(label.help)
    end
end

local function HookEllesmereLayout()
    local chat = ns.GetEllesmereChat()
    local layout = chat and chat.ECHAT
    if not layout then return end
    if hookedLayouts[layout] or type(layout.ApplyInputPosition) ~= "function" then return end
    hookedLayouts[layout] = true
    -- Share EllesmereUI's reservation decision with its layout and border
    -- code. Leave the original option and the native edit box state alone.
    local inputTopStripActive = layout.InputTopStripActive
    if type(inputTopStripActive) == "function" and type(layout.RefreshInputTopStrips) == "function"
        and type(layout.InputOnTop) == "function" and type(layout.DB) == "function" then
        topStripLayout = layout
        layout.InputTopStripActive = function(chatFrame)
            return inputTopStripActive(chatFrame) and NeedsOriginalTopStrip(chatFrame)
        end
    end
    hooksecurefunc(layout, "ApplyInputPosition", function()
        if unlockFrame and not unlockActive then PlaceUnlockFrame() end
        if frame then QueueRefresh() end
    end)
    for _, method in ipairs({ "ApplyBackground", "ApplyBorders" }) do
        if type(layout[method]) == "function" then
            hooksecurefunc(layout, method, function()
                if frame or preview:IsShown() then QueueRefresh() end
            end)
        end
    end
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
        elseif name ~= "EllesmereUIChat" and name ~= "EllesmereUI" then
            return
        end
        HookEllesmereLayout()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        HookEllesmereLayout()
    end
    RegisterUnlockMover()
    if unlockFrame and not unlockActive then PlaceUnlockFrame() end
    QueueRefresh()
end)

-- Chat state callbacks stay out of Blizzard's input scripts. The actual
-- geometry changes run after the native activation or deactivation ends.
for _, event in ipairs({ "OnEditBoxShow", "OnEditBoxHide", "OnEditBoxFocusGained", "OnEditBoxFocusLost" }) do
    EventRegistry:RegisterCallback("ChatFrame." .. event, QueueRefresh, addon)
end
