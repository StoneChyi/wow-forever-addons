local _, ns = ...

local panel = CreateFrame("Frame")
panel:Hide()

local function AddText(parent, font, text, x, y)
    local label = parent:CreateFontString(nil, "ARTWORK", font)
    label:SetPoint("TOPLEFT", x, -y)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function AddCheckbox(parent, text, x, y, labelWidth)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", x, -y)
    check:SetHitRectInsets(0, -labelWidth, 0, 0)
    check.label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 3, 0)
    check.label:SetJustifyH("LEFT")
    check.label:SetText(text)
    return check
end

AddText(panel, "GameFontNormalLarge", "发言频道轮换", 18, 18)
AddText(panel, "GameFontHighlight", "Tab 正向，Shift+Tab 反向。只轮换当前可用的已选频道。", 18, 48)

local enabled = AddCheckbox(panel, "启用 Tab 切换发言频道", 14, 72, 190)
enabled:SetScript("OnClick", function(self)
    ns.SetEnabled(not not self:GetChecked())
end)

AddText(panel, "GameFontNormal", "队伍和公会等频道", 18, 115)
local builtInChecks = {}
for index, channel in ipairs(ns.builtInChannels) do
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    local check = AddCheckbox(panel, channel.label, 14 + column * 112, 132 + row * 28, 82)
    check:SetScript("OnClick", function(self)
        ns.SetBuiltInSelected(channel.key, not not self:GetChecked())
    end)
    builtInChecks[channel.key] = check
end

AddText(panel, "GameFontNormal", "已加入的编号频道", 18, 206)
local allNumbered = AddCheckbox(panel, "自动纳入已加入的频道（可逐项取消）", 14, 222, 250)

local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
input:SetSize(174, 26)
input:SetPoint("TOPLEFT", 23, -263)
input:SetAutoFocus(false)
input:SetTextInsets(7, 7, 0, 0)
input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local placeholder = input:CreateFontString(nil, "ARTWORK", "GameFontDisable")
placeholder:SetPoint("LEFT", 7, 0)
placeholder:SetText("输入频道名")
input:HookScript("OnTextChanged", function(self)
    placeholder:SetShown(self:GetText() == "")
end)

local join = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
join:SetSize(92, 24)
join:SetPoint("LEFT", input, "RIGHT", 12, 0)
join:SetText("加入频道")

local status = AddText(panel, "GameFontHighlightSmall", "加入后将频道纳入轮换。", 18, 300)
local aliasHelp = AddText(panel, "GameFontHighlightSmall", "输入框的频道名默认自动缩写，悬停可看全名。", 18, 322)
aliasHelp:SetPoint("RIGHT", panel, "RIGHT", -20, 0)

local scroll = CreateFrame("ScrollFrame", "ForeverChatTabChannelScroll", panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 14, -353)
scroll:SetPoint("BOTTOMRIGHT", -39, 18)

local list = CreateFrame("Frame", nil, scroll)
list:SetSize(1, 1)
scroll:SetScrollChild(list)
scroll:HookScript("OnSizeChanged", function(_, width)
    list:SetWidth(math.max(width, 1))
end)

local empty = AddText(list, "GameFontDisable", "当前没有可选的编号频道。", 4, 7)
local numberedRows = {}
local OpenAliasEditor

local function ShowChannelTooltip(self)
    local channel = self.channelRow.channel
    local alias = ns.GetChannelAlias(channel.key)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(channel.name)
    GameTooltip:AddLine(alias and ("输入框短名：" .. alias) or "输入框短名：自动", 1, 1, 1)
    GameTooltip:Show()
end

local function AddNumberedRow(index)
    local check = AddCheckbox(list, "", 0, (index - 1) * 26, 110)
    local aliasButton = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
    aliasButton:SetSize(64, 22)
    aliasButton:SetPoint("TOPRIGHT", -4, -((index - 1) * 26 + 2))
    check.label:SetPoint("RIGHT", aliasButton, "LEFT", -6, 0)
    check.label:SetWordWrap(false)

    local row = { check = check, aliasButton = aliasButton }
    check.channelRow = row
    aliasButton.channelRow = row
    check:SetScript("OnClick", function(self)
        ns.SetNumberedSelected(row.channel.key, not not self:GetChecked())
    end)
    aliasButton:SetScript("OnClick", function() OpenAliasEditor(row.channel) end)
    check:SetScript("OnEnter", ShowChannelTooltip)
    check:SetScript("OnLeave", GameTooltip_Hide)
    aliasButton:HookScript("OnEnter", ShowChannelTooltip)
    aliasButton:HookScript("OnLeave", GameTooltip_Hide)
    return row
end

local function RefreshNumberedChannels()
    allNumbered:SetChecked(ns.AreAllNumberedSelected())
    local channels = ns.GetNumberedChannels()
    for index, channel in ipairs(channels) do
        local row = numberedRows[index]
        if not row then
            row = AddNumberedRow(index)
            numberedRows[index] = row
        end
        row.channel = channel
        local alias = ns.GetChannelAlias(channel.key)
        local label = string.format("/%d  %s", channel.id, channel.name)
        if alias then label = label .. " · " .. alias end
        if not channel.available then label = label .. "（暂不可用）" end
        row.check.label:SetText(label)
        local brightness = channel.available and 1 or 0.6
        row.check.label:SetTextColor(brightness, brightness, brightness)
        row.check:SetChecked(ns.IsNumberedSelected(channel.key))
        row.aliasButton:SetText(alias and "改短名" or "短名")
        row.check:Show()
        row.aliasButton:Show()
    end
    for index = #channels + 1, #numberedRows do
        numberedRows[index].check:Hide()
        numberedRows[index].aliasButton:Hide()
    end
    empty:SetShown(#channels == 0)
    list:SetHeight(math.max(#channels * 26, 26))
end

local editor = CreateFrame("Frame", nil, panel)
editor:SetPoint("BOTTOMLEFT", 18, 10)
editor:SetPoint("BOTTOMRIGHT", -18, 10)
editor:SetHeight(77)
editor:Hide()

local aliasTitle = AddText(editor, "GameFontNormal", "", 0, 0)
aliasTitle:SetPoint("RIGHT", editor, "RIGHT")
aliasTitle:SetWordWrap(false)

local aliasFeedback = AddText(editor, "GameFontHighlightSmall", "", 0, 56)
aliasFeedback:SetPoint("RIGHT", editor, "RIGHT")

local aliasInput = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
aliasInput:SetPoint("TOPLEFT", 5, -26)
aliasInput:SetHeight(25)
aliasInput:SetAutoFocus(false)
aliasInput:SetTextInsets(7, 7, 0, 0)

local function AddEditorButton(text, width, right)
    local button = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("RIGHT", editor, "TOPRIGHT", -right, -38)
    button:SetText(text)
    return button
end

local aliasCancel = AddEditorButton("取消", 48, 0)
local aliasReset = AddEditorButton("恢复自动", 74, 52)
local aliasSave = AddEditorButton("保存", 48, 130)
aliasInput:SetPoint("RIGHT", aliasSave, "LEFT", -8, 0)

local editingKey
local function CloseAliasEditor()
    editingKey = nil
    aliasInput:ClearFocus()
    editor:Hide()
    scroll:SetPoint("BOTTOMRIGHT", -39, 18)
end

function OpenAliasEditor(channel)
    editingKey = channel.key
    aliasTitle:SetText("短名 · " .. channel.name)
    aliasFeedback:SetTextColor(1, 1, 1)
    aliasFeedback:SetText("仅用于聊天输入框，最多 16 字，留空恢复自动。")
    aliasInput:SetText(ns.GetChannelAlias(channel.key) or "")
    scroll:SetPoint("BOTTOMRIGHT", -39, 96)
    editor:Show()
    aliasInput:SetFocus()
    aliasInput:HighlightText()
end

local function SaveAlias(text)
    local ok, message = ns.SetChannelAlias(editingKey, text)
    if not ok then
        aliasFeedback:SetTextColor(1, 0.55, 0.45)
        aliasFeedback:SetText(message)
        return
    end
    CloseAliasEditor()
    RefreshNumberedChannels()
end

local function SaveAliasInput()
    if not aliasInput:IsInIMECompositionMode() then SaveAlias(aliasInput:GetText()) end
end

aliasSave:SetScript("OnClick", SaveAliasInput)
aliasInput:SetScript("OnEnterPressed", SaveAliasInput)
aliasReset:SetScript("OnClick", function() SaveAlias("") end)
aliasCancel:SetScript("OnClick", CloseAliasEditor)
aliasInput:SetScript("OnEscapePressed", function(self)
    if not self:IsInIMECompositionMode() then CloseAliasEditor() end
end)

allNumbered:SetScript("OnClick", function(self)
    ns.SetAllNumberedSelected(not not self:GetChecked())
    RefreshNumberedChannels()
end)

local function JoinChannel()
    local ok, message = ns.JoinChannel(input:GetText())
    if ok then
        input:SetText("")
        input:ClearFocus()
        status:SetTextColor(1, 1, 1)
        RefreshNumberedChannels()
    else
        status:SetTextColor(1, 0.55, 0.45)
    end
    status:SetText(message)
end

join:SetScript("OnClick", JoinChannel)
input:SetScript("OnEnterPressed", JoinChannel)

panel:SetScript("OnShow", function(self)
    self:RegisterEvent("CHANNEL_UI_UPDATE")
    self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
    enabled:SetChecked(ns.IsEnabled())
    for key, check in pairs(builtInChecks) do
        check:SetChecked(ns.IsBuiltInSelected(key))
    end
    RefreshNumberedChannels()
    scroll:SetVerticalScroll(0)
end)
panel:SetScript("OnHide", function(self)
    self:UnregisterEvent("CHANNEL_UI_UPDATE")
    self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")
    input:ClearFocus()
    CloseAliasEditor()
end)
panel:SetScript("OnEvent", RefreshNumberedChannels)

local category = Settings.RegisterCanvasLayoutCategory(panel, "ForeverChatTab")
Settings.RegisterAddOnCategory(category)

function ns.OpenSettings()
    if InCombatLockdown() then
        DEFAULT_CHAT_FRAME:AddMessage("ForeverChatTab：请在战斗结束后打开设置。")
        return
    end
    Settings.OpenToCategory(category:GetID())
end
