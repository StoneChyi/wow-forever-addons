local _, ns = ...

local pendingBox, pendingID, scheduled
local currentLabel
local hover = CreateFrame("Frame")
hover:Hide()
hover:SetMouseClickEnabled(false)
hover:SetMouseMotionEnabled(true)

local function AreReadable(...)
    if not canaccessvalue then return true end
    for index = 1, select("#", ...) do
        if not canaccessvalue((select(index, ...))) then return false end
    end
    return true
end

local function HasCurrentTarget(editBox, id)
    if not ns.IsEnabled() or C_ChatInfo.InChatMessagingLockdown() or not editBox:HasFocus() then
        return false
    end
    local chatType = editBox:GetChatType()
    if not AreReadable(chatType) or chatType ~= "CHANNEL" then return false end
    local currentID = editBox:GetChannelTarget()
    return AreReadable(currentID) and currentID == id
end

local function IsCurrentLabel(label)
    if not label or not HasCurrentTarget(label.editBox, label.id) then return false end
    local text = label.editBox.header:GetText()
    return AreReadable(text) and text == label.text
end

local function HideTooltip(self)
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

hover:SetScript("OnEnter", function(self)
    if not IsCurrentLabel(currentLabel) then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:AddLine(currentLabel.fullText, 1, 1, 1, true)
    GameTooltip:Show()
end)
hover:SetScript("OnLeave", HideTooltip)
hover:SetScript("OnHide", HideTooltip)

local elapsedSinceCheck = 0
hover:SetScript("OnUpdate", function(self, elapsed)
    elapsedSinceCheck = elapsedSinceCheck + elapsed
    if elapsedSinceCheck < 0.2 then return end
    elapsedSinceCheck = 0
    if not IsCurrentLabel(currentLabel) then
        currentLabel = nil
        self:Hide()
    end
end)

local function FitLabel(header, id, name, maxWidth)
    local format = CHAT_CHANNEL_SEND or "%d. %s: "
    local function Measure(text)
        local width = header:GetUnboundedStringWidthForText(text)
        if not AreReadable(width) or width <= 0 then return nil end
        return math.ceil(width)
    end

    local function FormatName(candidate)
        return string.format(format, id, (candidate:gsub("|", "||")))
    end

    local label = FormatName(name)
    local width = Measure(label)
    if not width or width <= maxWidth then return label, width end

    local bestLabel = string.format("/%d: ", id)
    local bestWidth = Measure(bestLabel)
    local prefix = ""
    for character in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        prefix = prefix .. character
        label = FormatName(prefix .. "…")
        width = Measure(label)
        if not width or width > maxWidth then break end
        bestLabel, bestWidth = label, width
    end
    return bestLabel, bestWidth
end

local function ShowHover(editBox, id, text, fullText)
    currentLabel = { editBox = editBox, id = id, text = text, fullText = fullText }
    hover:SetParent(editBox)
    hover:SetFrameLevel(editBox:GetFrameLevel() + 1)
    hover:ClearAllPoints()
    hover:SetAllPoints(editBox.header)
    hover:Show()
end

local function ShortenHeader(editBox, id)
    if not HasCurrentTarget(editBox, id) then return end
    local header, suffix = editBox.header, editBox.headerSuffix
    if not header or not suffix then return end

    local localID, name, _, community = GetChannelName(id)
    if not AreReadable(localID, name, community) or localID ~= id or not name or community then return end
    local key, zoneID = ns.GetNumberedChannelKey(name)
    local baseName = zoneID and name:match("^(.-)%s+%-%s+")
    local displayName = ns.GetChannelAlias(key) or baseName or name

    local fullText = header:GetText()
    local editWidth, originalWidth = editBox:GetWidth(), header:GetWidth()
    local suffixShown = suffix:IsShown()
    if not AreReadable(suffixShown) then return end
    local suffixWidth = suffixShown and suffix:GetWidth() or 0
    local left, right, top, bottom = editBox:GetTextInsets()
    if not AreReadable(fullText, editWidth, originalWidth, suffixWidth, left, right, top, bottom)
        or not fullText or fullText == "" or editWidth <= 0 or originalWidth <= 0 then return end

    local label, width = FitLabel(header, id, displayName, math.floor(editWidth * 0.28))
    if not width then return end
    if label ~= fullText or suffixShown then
        -- Retain the active skin's left padding and any language label space.
        local padding = left - originalWidth - suffixWidth
        if padding < 0 or padding + width + right >= editWidth then return end
        local ok = pcall(function()
            header:SetText(label)
            header:SetWidth(width)
            suffix:Hide()
            editBox:SetTextInsets(padding + width, right, top, bottom)
        end)
        if not ok then
            pcall(function()
                header:SetText(fullText)
                header:SetWidth(originalWidth)
                suffix:SetShown(suffixShown)
                editBox:SetTextInsets(left, right, top, bottom)
            end)
            return
        end
    end
    ShowHover(editBox, id, label, fullText)
end

function ns.QueueChannelLabel(editBox, target)
    currentLabel = nil
    pendingBox, pendingID = nil, nil
    if type(target) == "number" then pendingBox, pendingID = editBox, target end
    if not pendingBox and not hover:IsShown() then return end
    if scheduled then return end
    scheduled = true
    -- Keep visual changes outside the native chat input execution.
    C_Timer.After(0, function()
        scheduled = false
        local box, id = pendingBox, pendingID
        pendingBox, pendingID = nil, nil
        hover:Hide()
        if box then pcall(ShortenHeader, box, id) end
    end)
end
