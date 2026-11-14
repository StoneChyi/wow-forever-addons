local _, ns = ...

local nativeChatTypes = {
    WHISPER = true,
    BN_WHISPER = true,
    SMART_WHISPER = true,
    COMMUNITIES_CHANNEL = true,
    VOICE_TEXT = true,
}

ns.builtInChannels = {
    { key = "SAY", label = "说话", isAvailable = function() return true end },
    { key = "PARTY", label = "小队", isAvailable = function() return IsInGroup(LE_PARTY_CATEGORY_HOME) end },
    { key = "RAID", label = "团队", isAvailable = function() return IsInRaid(LE_PARTY_CATEGORY_HOME) end },
    { key = "GUILD", label = "公会", isAvailable = IsInGuild },
    { key = "INSTANCE_CHAT", label = "副本", isAvailable = function() return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) end },
}

local pendingJoins = {}

local function GetDB()
    if type(ForeverChatTabDB) ~= "table" then ForeverChatTabDB = {} end
    return ForeverChatTabDB
end

function ns.IsEnabled()
    return type(ForeverChatTabDB) ~= "table" or ForeverChatTabDB.enabled ~= false
end

function ns.SetEnabled(enabled)
    GetDB().enabled = enabled == true
end

function ns.IsBuiltInSelected(key)
    local selected = GetDB().builtIn
    return type(selected) ~= "table" or selected[key] ~= false
end

function ns.SetBuiltInSelected(key, enabled)
    local db = GetDB()
    if type(db.builtIn) ~= "table" then db.builtIn = {} end
    db.builtIn[key] = enabled == true
end

function ns.AreAllNumberedSelected()
    return GetDB().allNumbered ~= false
end

function ns.SetAllNumberedSelected(enabled)
    GetDB().allNumbered = enabled == true
end

function ns.IsNumberedSelected(key)
    local selected = GetDB().numbered
    if type(selected) == "table" and type(selected[key]) == "boolean" then
        return selected[key]
    end
    return ns.AreAllNumberedSelected()
end

function ns.SetNumberedSelected(key, enabled)
    local db = GetDB()
    if type(db.numbered) ~= "table" then db.numbered = {} end
    db.numbered[key] = enabled == true
end

function ns.GetChannelAlias(key)
    local aliases = GetDB().channelAliases
    local alias = type(aliases) == "table" and aliases[key]
    if type(alias) == "string" and alias ~= "" then return alias end
end

function ns.SetChannelAlias(key, input)
    if input:find("[%c|]") then return false, "短名不能包含控制字符或竖线。" end
    local alias = input:match("^ *(.-) *$")
    local _, length = alias:gsub("[^\128-\191]", "")
    if length > 16 then return false, "短名最多 16 个字符。" end

    local db = GetDB()
    if type(db.channelAliases) ~= "table" then db.channelAliases = {} end
    db.channelAliases[key] = alias ~= "" and alias or nil
    return true, alias ~= "" and "已保存短名。" or "已恢复自动短名。"
end

function ns.GetNumberedChannelKey(name)
    local info = C_ChatInfo.GetChannelInfoFromIdentifier(name)
    local zoneID = info and tonumber(info.zoneChannelID)
    if zoneID and zoneID > 0 then return "zone:" .. zoneID, zoneID end
    return "name:" .. name:lower()
end

local function IsCommunityChannel(id)
    local _, _, _, isCommunity = GetChannelName(id)
    return isCommunity
end

local function ReadNumberedChannels(...)
    local channels, byID = {}, {}
    for index = 1, select("#", ...), 3 do
        local id, name, disabled = select(index, ...)
        if type(id) == "number" and id > 0 and type(name) == "string"
            and not byID[id] and not IsCommunityChannel(id) then
            local channel = {
                id = id,
                name = name,
                key = ns.GetNumberedChannelKey(name),
                available = not disabled and (not C_ChatInfo.IsChannelRegional(id)
                    or C_ChatInfo.IsRegionalServiceAvailable()),
            }
            channels[#channels + 1] = channel
            byID[id] = channel
        end
    end
    table.sort(channels, function(a, b) return a.id < b.id end)
    return channels, byID
end

function ns.GetNumberedChannels()
    local channels, byID = ReadNumberedChannels(GetChannelList())
    for name, expires in pairs(pendingJoins) do
        local channel = byID[GetChannelName(name)]
        if expires <= GetTime() then
            pendingJoins[name] = nil
        elseif channel then
            pendingJoins[name] = nil
            ns.SetNumberedSelected(channel.key, true)
        end
    end
    return channels, byID
end

function ns.JoinChannel(input)
    local name = input:match("^%s*(.-)%s*$")
    if name == "" or name:find("[%s%c|/]") or name:match("^%d+$") then
        return false, "请输入一个频道名，名称中不能有空格。"
    end
    if C_ChatInfo.InChatMessagingLockdown() then
        return false, "游戏当前限制聊天，请稍后再加入频道。"
    end

    local id, _, _, isCommunity = GetChannelName(name)
    if isCommunity then return false, "社区频道使用游戏原有的聊天入口。" end
    if id and id > 0 then
        local _, byID = ns.GetNumberedChannels()
        local channel = byID[id]
        if channel then
            ns.SetNumberedSelected(channel.key, true)
            return true, "已将该频道加入轮换名单。"
        end
    end

    local join = SlashCmdList.JOIN
    if type(join) ~= "function" then return false, "请在聊天框使用 /join 加入频道。" end
    local pendingKey = name:lower()
    if (pendingJoins[pendingKey] or 0) > GetTime() then
        return true, "已请求加入，请查看游戏提示。"
    end
    pendingJoins[pendingKey] = GetTime() + 10
    if not pcall(join, name) then
        pendingJoins[pendingKey] = nil
        return false, "暂时无法从设置加入，请在聊天框使用 /join。"
    end
    ns.GetNumberedChannels()
    return true, "已请求加入，请查看游戏提示。"
end

local function GetCycle()
    local cycle = {}
    for _, channel in ipairs(ns.builtInChannels) do
        if ns.IsBuiltInSelected(channel.key) and channel.isAvailable() then
            cycle[#cycle + 1] = channel.key
        end
    end
    for _, channel in ipairs(ns.GetNumberedChannels()) do
        if channel.available and ns.IsNumberedSelected(channel.key) then
            cycle[#cycle + 1] = channel.id
        end
    end
    return cycle
end

local function NextChannel(cycle, current, reverse)
    local step = reverse and -1 or 1
    for index, channel in ipairs(cycle) do
        if channel == current then
            return cycle[(index - 1 + step) % #cycle + 1]
        end
    end
    return cycle[reverse and #cycle or 1]
end

local function IsReadable(value)
    return not canaccessvalue or canaccessvalue(value)
end

local function OnChatTab(editBox)
    if not ns.IsEnabled() or C_ChatInfo.InChatMessagingLockdown() then return end

    local chatType, text = editBox:GetChatType(), editBox:GetText()
    if not IsReadable(chatType) or not IsReadable(text) or not IsReadable(editBox:GetTellTarget()) then return end
    if not chatType or nativeChatTypes[chatType] or text:match("^%s*/") then return end

    local current = chatType
    if chatType == "CHANNEL" then
        current = editBox:GetChannelTarget()
        if not IsReadable(current) or (current > 0 and IsCommunityChannel(current)) then return end
    end

    local nextChannel = NextChannel(GetCycle(), current, IsShiftKeyDown())
    if not nextChannel or nextChannel == current then return end

    local numbered = type(nextChannel) == "number"
    local oldTarget = numbered and editBox:GetAttribute("channelTarget")
    if numbered and not IsReadable(oldTarget) then return end
    local ok = pcall(function()
        if numbered then editBox:SetChannelTarget(nextChannel) end
        editBox:SetChatType(numbered and "CHANNEL" or nextChannel)
        editBox:UpdateHeader()
    end)
    if not ok then
        pcall(function()
            if numbered then editBox:SetChannelTarget(oldTarget) end
            editBox:SetChatType(chatType)
            editBox:UpdateHeader()
        end)
        return
    end
    -- Finish the label in the same Tab callback so the full name cannot render first.
    ns.ApplyChannelLabel(editBox, nextChannel)
end

-- The chat frame calls this extension point after handling autocomplete.
hooksecurefunc("ChatEdit_CustomTabPressed", OnChatTab)

local channelEvents = CreateFrame("Frame")
channelEvents:RegisterEvent("CHANNEL_UI_UPDATE")
channelEvents:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
channelEvents:SetScript("OnEvent", function()
    if next(pendingJoins) then ns.GetNumberedChannels() end
end)

SLASH_FOREVERCHATTAB1 = "/fct"
SlashCmdList.FOREVERCHATTAB = function(input)
    local command = input:match("^%s*(.-)%s*$"):lower()
    if command == "on" or command == "off" then
        ns.SetEnabled(command == "on")
        local state = ns.IsEnabled() and "已开启" or "已关闭"
        DEFAULT_CHAT_FRAME:AddMessage("ForeverChatTab 「Tab 切换发言频道」" .. state)
    elseif command == "" then
        ns.OpenSettings()
    else
        DEFAULT_CHAT_FRAME:AddMessage("ForeverChatTab：/fct 打开设置，/fct on 开启，/fct off 关闭。")
    end
end
