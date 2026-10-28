local _, addon = ...
local button
function addon.InitializeMinimap(db)
    if button or not Minimap then return end
    button = CreateFrame("Button", "DwarfTranslatorMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    button:SetPoint("CENTER", Minimap, "BOTTOMLEFT", 16, 16)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture(addon.GetDwarfIcon())
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    -- Draw an opaque ring without relying on a client-specific highlight asset.
    -- Overlapping squares keep the ring continuous at the minimap button's size.
    local languageRing = {}
    for i = 1, 64 do
        local angle = (i - 1) * 2 * math.pi / 64
        local segment = button:CreateTexture(nil, "OVERLAY", nil, 7)
        segment:SetColorTexture(1, 0.78, 0.05, 1)
        segment:SetSize(2, 2)
        segment:SetPoint("CENTER", 14 * math.cos(angle), 14 * math.sin(angle))
        languageRing[i] = segment
    end
    function addon.RefreshMinimap()
        icon:SetTexture(addon.GetDwarfIcon())
        for _, segment in ipairs(languageRing) do
            if not db.enabled then
                segment:SetColorTexture(1, 0.1, 0.1, 1)
                segment:Show()
            elseif db.alwaysDwarven then
                segment:SetColorTexture(1, 0.78, 0.05, 1)
                segment:Show()
            else
                segment:Hide()
            end
        end
    end
    function addon.SetMinimapVisible(visible)
        db.showMinimap = visible
        if visible then button:Show() else button:Hide() end
        if addon.RefreshSettings then addon.RefreshSettings() end
    end
    addon.RefreshMinimap()
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            addon.ToggleAlwaysDwarven()
            GameTooltip:Hide()
        elseif mouseButton == "RightButton" and IsAltKeyDown() then
            GameTooltip:Hide()
            addon.SetMinimapVisible(false)
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66Dwarf Translator:|r Minimap button hidden. Show it again in /dwarf settings.")
            end
        elseif mouseButton == "RightButton" then
            GameTooltip:Hide()
            addon.OpenSettings()
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Dwarf Translator", 1, 0.82, 0)
        GameTooltip:AddLine(db.enabled and "Enabled" or "Disabled", 1, 1, 1)
        GameTooltip:AddLine("Always Dwarvish: " .. (db.alwaysDwarven and "On" or "Off"), 1, 1, 1)
        GameTooltip:AddLine("Left-click: Toggle Always Dwarvish", 1, 1, 1)
        GameTooltip:AddLine("Right-click: settings", 1, 1, 1)
        GameTooltip:AddLine("Alt + right-click: hide button", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    addon.SetMinimapVisible(db.showMinimap ~= false)
end
