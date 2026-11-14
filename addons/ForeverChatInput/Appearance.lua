local _, ns = ...

local artwork, textures = {}, {}

local function PaintFill(region, texture, r, g, b, a)
    if texture then
        region:SetTexture(texture)
        region:SetVertexColor(r, g, b, a)
    else
        region:SetVertexColor(1, 1, 1, 1)
        region:SetColorTexture(r, g, b, a)
    end
end

local function ForeverArtwork(eui, widget, kind)
    local host = CreateFrame("Frame", nil, widget)
    local heavy = kind == "heavy" and eui.ForeverHeavy and eui.ForeverHeavySeat
        and eui.ForeverHeavyFill and eui.ForeverHeavyShown and eui.FOREVER_HEAVY
    if heavy then host:SetScale(heavy.k) end
    host:SetAllPoints(widget)

    local rim = heavy and eui.ForeverHeavy(host, "BORDER")
    if not rim then
        heavy = nil
        host:SetScale(1)
        rim = eui.ForeverBorder(host, "BORDER", 0, nil, kind)
    end
    local fill = host:CreateTexture(nil, "BACKGROUND")
    local pad = 5
    if heavy then
        eui.ForeverHeavySeat(rim, widget, "TOPLEFT", -pad, pad, pad, -pad)
        eui.ForeverHeavyFill(rim, fill, widget, "TOPLEFT", -pad, pad, pad, -pad)
    else
        local inset = eui.FOREVER_BORDER.fill - pad
        fill:SetPoint("TOPLEFT", widget, "TOPLEFT", inset, -inset)
        fill:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -inset, inset)
        if rim then eui.ForeverBorderSeat(rim, widget, "TOPLEFT", -pad, pad, pad, -pad) end
    end
    return { host = host, rim = rim, fill = fill, heavy = heavy, kind = kind }
end

local function PaintForever(eui, widget, chat, kind, config)
    local art = artwork[widget]
    if not art or art.kind ~= kind then
        art = ForeverArtwork(eui, widget, kind)
        artwork[widget] = art
    end
    local fill = chat.ECHAT.FV and chat.ECHAT.FV._fill
    if fill then
        PaintFill(art.fill, fill.tex, fill.r, fill.g, fill.b, fill.a)
    else
        PaintFill(art.fill, nil, config.bgR or 0.03, config.bgG or 0.045, config.bgB or 0.05, config.bgAlpha or 0.65)
    end
    art.host:SetFrameLevel(widget:GetFrameLevel())
    if art.heavy then
        local w, h = widget:GetSize()
        if eui.ForeverHeavyFit then eui.ForeverHeavyFit(art.rim, w + 10, h + 10) end
        eui.ForeverHeavyShown(art.rim, true)
    elseif art.rim then
        eui.ForeverBorderShown(art.rim, true)
    end
    art.host:Show()
end

function ns.GetEllesmereChat()
    local eui = EllesmereUI
    return eui and eui._ModuleNS and eui._ModuleNS.EllesmereUIChat
end

local function PaintEllesmere(widget, chat, eui, config)
    local r, g, b, a = config.bgR or 0.03, config.bgG or 0.045, config.bgB or 0.05, config.bgAlpha or 0.65
    local key = config.bgTexture
    local path
    if key and key ~= "none" and chat.chatBgTextures then
        path = eui.ResolveTexturePath and eui.ResolveTexturePath(chat.chatBgTextures, key, nil)
            or chat.chatBgTextures[key]
    end
    if path then
        local texture = textures[widget]
        if not texture then
            texture = widget:CreateTexture(nil, "BACKGROUND", nil, 1)
            texture:SetPoint("TOPLEFT", widget, "TOPLEFT", 1, -1)
            texture:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -1, 1)
            textures[widget] = texture
        end
        PaintFill(texture, path, r, g, b, a)
        texture:Show()
        widget:SetBackdropColor(0, 0, 0, 0)
    else
        widget:SetBackdropColor(r, g, b, a)
    end

    local getColor = chat._internals and chat._internals.GetInnerBorderColor
    r, g, b, a = 1, 1, 1, 0.06
    if getColor then r, g, b, a = getColor(config) end
    widget:SetBackdropBorderColor(r, g, b, config.hideBorders and 0 or a)
end

function ns.StyleInput(widget, isPreview)
    local art = artwork[widget]
    if art then art.host:Hide() end
    if textures[widget] then textures[widget]:Hide() end
    local eui, chat = EllesmereUI, ns.GetEllesmereChat()
    local config = chat and chat.ECHAT and chat.ECHAT.DB and chat.ECHAT.DB()
    if config and chat.ChatForever and chat.ChatForever() and chat.ChatFvKind
        and eui.ForeverBorder and eui.ForeverBorderSeat and eui.ForeverBorderShown and eui.FOREVER_BORDER then
        widget:SetBackdropColor(0, 0, 0, 0)
        widget:SetBackdropBorderColor(0, 0, 0, 0)
        PaintForever(eui, widget, chat, chat.ChatFvKind(), config)
        return
    end

    if config and chat.ChatStockArt and chat.ChatStockArt() and not isPreview then
        -- Blizzard and Classic keep the original input artwork on the edit box.
        widget:SetBackdropColor(0, 0, 0, 0)
        widget:SetBackdropBorderColor(0, 0, 0, 0)
    elseif config then
        PaintEllesmere(widget, chat, eui, config)
    else
        widget:SetBackdropColor(0.025, 0.025, 0.025, 0.92)
        widget:SetBackdropBorderColor(0.65, 0.47, 0.25, 0.95)
    end
end
