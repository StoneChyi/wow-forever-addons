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
AddText(panel, "GameFontHighlight", "Tab 正向切换，Shift+Tab 反向切换。只轮换所选且当前可用的频道。", 18, 48)

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
input:SetSize(200, 26)
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

local scroll = CreateFrame("ScrollFrame", "ForeverChatTabChannelScroll", panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 14, -325)
scroll:SetPoint("BOTTOMRIGHT", -39, 18)

local list = CreateFrame("Frame", nil, scroll)
list:SetSize(1, 1)
scroll:SetScrollChild(list)
scroll:HookScript("OnSizeChanged", function(_, width)
    list:SetWidth(math.max(width, 1))
end)

local empty = AddText(list, "GameFontDisable", "当前没有可选的编号频道。", 4, 7)
local numberedChecks = {}
local function RefreshNumberedChannels()
    allNumbered:SetChecked(ns.AreAllNumberedSelected())
    local channels = ns.GetNumberedChannels()
    for index, channel in ipairs(channels) do
        local check = numberedChecks[index]
        if not check then
            check = AddCheckbox(list, "", 0, (index - 1) * 26, 266)
            check.label:SetPoint("RIGHT", list, "RIGHT", -4, 0)
            check.label:SetWordWrap(false)
            check:SetScript("OnClick", function(self)
                ns.SetNumberedSelected(self.channelKey, not not self:GetChecked())
            end)
            numberedChecks[index] = check
        end
        check.channelKey = channel.key
        local suffix = channel.available and "" or "（暂不可用）"
        check.label:SetText(string.format("/%d  %s%s", channel.id, channel.name, suffix))
        local brightness = channel.available and 1 or 0.6
        check.label:SetTextColor(brightness, brightness, brightness)
        check:SetChecked(ns.IsNumberedSelected(channel.key))
        check:Show()
    end
    for index = #channels + 1, #numberedChecks do
        numberedChecks[index]:Hide()
    end
    empty:SetShown(#channels == 0)
    list:SetHeight(math.max(#channels * 26, 26))
end

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
