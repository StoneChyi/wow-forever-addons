local addonName = ...
local WIM, EUI = WIM, EllesmereUI
if EUI_CLIENT_BLOCKED or not (WIM and WIM.RegisterSkin and EUI) then return end

local title = "EllesmereUI"
local media = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
local icons = "Interface\\AddOns\\EllesmereUI\\media\\icons\\"
local highlight = media .. "ButtonHighlight.png"
local close = icons .. "eui-close.png"
local hide = media .. "Minimize.png"
local locale = GetLocale()
-- WIM applies a file path directly, so use a face with native CJK glyphs on CJK clients.
local font = ((locale == "zhCN" or locale == "zhTW" or locale == "koKR")
    and EUI.LocaleGlyphFont and EUI.LocaleGlyphFont(locale))
    or (EUI.GetFontPath and EUI.GetFontPath("chat")) or "ChatFontNormal"

local function arrow(icon, size)
    local texture = icons .. "eui-arrow-" .. icon .. ".png"
    return {
        NormalTexture = texture, PushedTexture = texture,
        DisabledTexture = media .. "Transparent.png",
        HighlightTexture = highlight, HighlightAlphaMode = "BLEND",
        width = size, height = size,
    }
end

local scrollUp, scrollDown = arrow("up3", 18), arrow("down3", 18)
scrollUp.points = {{"TOPRIGHT", "window", "TOPRIGHT", -7, -53}}
scrollDown.points = {{"BOTTOMRIGHT", "window", "BOTTOMRIGHT", -7, 39}}

local skin = {
    title = title,
    author = "WIM EllesmereUI Skin",
    version = "1.0.0",
    -- Explicitly opt out of WIM's metal chrome and its legacy-skin upgrade prompt.
    schema_version = false,
    message_window = {
        texture = media .. "Window.png",
        min_width = 256,
        min_height = 236,
        backdrop = {
            top_left = { width = 8, height = 8 },
            top_right = { width = 8, height = 8 },
            bottom_left = { width = 8, height = 8 },
            bottom_right = { width = 8, height = 8 },
        },
        widgets = {
            class_icon = { width = 28, height = 28, points = {{"TOPLEFT", "window", "TOPLEFT", 12, -10}} },
            from = {
                font = font, font_height = 14, font_color = "eef5f7",
                points = {
                    {"TOPLEFT", "window", "TOPLEFT", 49, -8},
                    {"BOTTOMRIGHT", "window", "TOPRIGHT", -51, -25},
                },
            },
            char_info = {
                font = font, font_height = 11,
                points = {
                    {"TOPLEFT", "window", "TOPLEFT", 49, -26},
                    {"BOTTOMRIGHT", "window", "TOPRIGHT", -51, -42},
                },
            },
            close = {
                width = 18, height = 18,
                points = {{"TOPRIGHT", "window", "TOPRIGHT", -8, -8}},
                state_hide = { NormalTexture = hide, PushedTexture = hide,
                    HighlightTexture = highlight, HighlightAlphaMode = "BLEND" },
                state_close = { NormalTexture = close, PushedTexture = close,
                    HighlightTexture = highlight, HighlightAlphaMode = "BLEND" },
            },
            history = { width = 16, height = 16, points = {{"TOPRIGHT", "window", "TOPRIGHT", -30, -9}} },
            w2w = { points = {{"TOPLEFT", "class_icon", "TOPLEFT", 4, -4},
                {"BOTTOMRIGHT", "class_icon", "BOTTOMRIGHT", -4, 4}} },
            chat_info = { points = {{"TOPLEFT", "class_icon", "TOPLEFT", 4, -4},
                {"BOTTOMRIGHT", "class_icon", "BOTTOMRIGHT", -4, 4}} },
            scroll_up = scrollUp,
            scroll_down = scrollDown,
            chat_display = {
                font = font,
                points = {{"TOPLEFT", "window", "TOPLEFT", 12, -55},
                    {"BOTTOMRIGHT", "window", "BOTTOMRIGHT", -36, 40}},
            },
            msg_box = {
                font = font, font_height = 14,
                points = {{"TOPLEFT", "window", "BOTTOMLEFT", 14, 28},
                    {"BOTTOMRIGHT", "window", "BOTTOMRIGHT", -24, 9}},
            },
            resize = { width = 18, height = 18, NormalTexture = icons .. "eui-resize-5.png",
                points = {{"BOTTOMRIGHT", "window", "BOTTOMRIGHT", 0, 0}} },
            shortcuts = {
                points = {{"TOPLEFT", "window", "TOPRIGHT", -25, -72},
                    {"BOTTOMRIGHT", "window", "BOTTOMRIGHT", -7, 61}},
                buttons = {
                    NormalTexture = media .. "Transparent.png", PushedTexture = highlight,
                    HighlightTexture = highlight, HighlightAlphaMode = "BLEND",
                },
            },
        },
    },
    tab_strip = {
        height = 21, gap = 3, scrollMargin = 2,
        points = {{"BOTTOMLEFT", "window", "TOPLEFT", 20, 2},
            {"BOTTOMRIGHT", "window", "TOPRIGHT", -20, 2}},
        textures = {
            tab = {
                NormalTexture = media .. "Tab.png", PushedTexture = media .. "TabSelected.png",
                HighlightTexture = media .. "TabHighlight.png", HighlightAlphaMode = "ADD",
            },
            prev = arrow("left", 16),
            next = arrow("right", 16),
        },
        text = { font = font, font_height = 12, padding = {8, 8, 0, 2} },
    },
}

local windows, tabGroups = {}, {}

local function isSelected()
    return WIM.GetSelectedSkin() == skin
end

local function accent()
    if EUI.GetAccentColor then return EUI.GetAccentColor() end
    return 0.047, 0.824, 0.616
end

local function horizontalLine(parent, layer, anchor, y, thickness)
    local line = parent:CreateTexture(nil, layer)
    line:SetPoint(anchor .. "LEFT", parent, anchor .. "LEFT", 1, y)
    line:SetPoint(anchor .. "RIGHT", parent, anchor .. "RIGHT", -1, y)
    line:SetHeight(thickness)
    return line
end

local function createWindowArt(window)
    local widgets = window.widgets
    local backdrop = widgets.Backdrop
    local header = backdrop:CreateTexture(nil, "ARTWORK", nil, -2)
    header:SetColorTexture(0.05, 0.065, 0.08)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(46)

    local divider = horizontalLine(backdrop, "ARTWORK", "TOP", -47, 1)
    divider:SetColorTexture(1, 1, 1, 0.07)

    local marker = backdrop:CreateTexture(nil, "ARTWORK")
    marker:SetPoint("TOPLEFT", 1, -10)
    marker:SetSize(2, 28)

    local box = widgets.msg_box
    local input = backdrop:CreateTexture(nil, "ARTWORK", nil, -2)
    input:SetColorTexture(0.05, 0.065, 0.08)
    input:SetPoint("TOPLEFT", box, "TOPLEFT", -5, 1)
    input:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 5, -1)

    local inputLine = backdrop:CreateTexture(nil, "ARTWORK")
    inputLine:SetPoint("BOTTOMLEFT", input, "BOTTOMLEFT")
    inputLine:SetPoint("BOTTOMRIGHT", input, "BOTTOMRIGHT")
    inputLine:SetHeight(1)

    local function refreshInput()
        local active = isSelected() and box:IsShown()
        input:SetShown(active)
        inputLine:SetShown(active)
        if active then
            if box:HasFocus() then
                local r, g, b = accent()
                inputLine:SetColorTexture(r, g, b, 0.85)
            else
                inputLine:SetColorTexture(1, 1, 1, 0.12)
            end
        end
    end

    box:HookScript("OnShow", refreshInput)
    box:HookScript("OnHide", refreshInput)
    box:HookScript("OnEditFocusGained", refreshInput)
    box:HookScript("OnEditFocusLost", refreshInput)

    local iconLayer, iconSublevel = widgets.class_icon:GetDrawLayer()
    return {
        header = header, divider = divider, marker = marker, refreshInput = refreshInput,
        iconLayer = iconLayer, iconSublevel = iconSublevel,
        nameJustify = widgets.from:GetJustifyH(), detailsJustify = widgets.char_info:GetJustifyH(),
    }
end

local function applyWindowArt(window)
    local active = isSelected()
    local art = windows[window]
    if active and not art then
        art = createWindowArt(window)
        windows[window] = art
    end
    if not art then return end

    local widgets = window.widgets
    art.header:SetShown(active)
    art.divider:SetShown(active)
    art.marker:SetShown(active)
    art.refreshInput()

    -- WIM's demo omits the close button's normal hover/state handler.
    if window.type == "demo" then
        local state = WIM.GetSelectedSkin().message_window.widgets.close.state_close
        local paint = WIM.utils.skin
        paint.applyNormalTexture(widgets.close, state.NormalTexture)
        paint.applyPushedTexture(widgets.close, state.PushedTexture)
        paint.applyHighlightTexture(widgets.close, state.HighlightTexture, state.HighlightAlphaMode)
    end
    if active then
        local r, g, b = accent()
        art.marker:SetColorTexture(r, g, b, 0.9)
        -- WIM's backdrop is normally drawn over the class icon.
        widgets.class_icon:SetDrawLayer("ARTWORK", 1)
        widgets.from:SetJustifyH("LEFT")
        widgets.char_info:SetJustifyH("LEFT")
    else
        widgets.class_icon:SetDrawLayer(art.iconLayer, art.iconSublevel)
        -- WIM Modern lays these out itself before this hook runs.
        if WIM.GetSelectedSkin().schema_version ~= 2 then
            widgets.from:SetJustifyH(art.nameJustify)
            widgets.char_info:SetJustifyH(art.detailsJustify)
        end
    end
end

local function paintTab(tab, line, selected)
    local active = isSelected() and selected and tab.childObj ~= nil
    line:SetShown(active)
    if active then
        local r, g, b = accent()
        line:SetColorTexture(r, g, b)
    end
end

local function refreshTabs()
    for _, tabs in pairs(tabGroups) do
        for tab, line in pairs(tabs) do
            paintTab(tab, line, tab.smiddle:IsShown())
        end
    end
end

local function decorateTabs(group)
    local tabs = {}
    tabGroups[group] = tabs
    for _, tab in ipairs(group.tabs) do
        local line = horizontalLine(tab, "OVERLAY", "BOTTOM", 1, 2)
        tabs[tab] = line
        hooksecurefunc(tab, "SetSelected", function(self, selected)
            paintTab(self, line, selected)
        end)
        paintTab(tab, line, tab.smiddle:IsShown())
    end
end

hooksecurefunc(WIM, "ApplySkinToWindow", applyWindowArt)
hooksecurefunc(WIM, "ApplySkinToTabs", refreshTabs)

-- The tab strip is created lazily. Keep WIM's allocator and return its strip intact.
local getTabGroup = WIM.GetAvailableTabGroup
WIM.GetAvailableTabGroup = function(...)
    local group = getTabGroup(...)
    if group and not tabGroups[group] then decorateTabs(group) end
    return group
end

if EUI.RegAccent then
    EUI.RegAccent({ type = "callback", fn = function()
        if not isSelected() then return end
        for window in pairs(windows) do applyWindowArt(window) end
        refreshTabs()
    end })
end

WIM.RegisterSkin(skin)
