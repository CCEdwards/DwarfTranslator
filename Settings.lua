local _, addon = ...
local panel, category
local checks = {}
local function notice(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66Dwarf Translator:|r " .. text)
end
function addon.RefreshSettings()
    for _, check in ipairs(checks) do check:SetChecked(check.read()) end
end
function addon.InitializeSettings(db, channels)
    if panel or not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    panel = CreateFrame("Frame", "DwarfTranslatorSettingsPanel", UIParent)
    panel:Hide()
    local function label(text, x, y, font)
        local field = panel:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
        field:SetPoint("TOPLEFT", x, y)
        field:SetText(text)
    end
    label("Dwarf Translator", 16, -16, "GameFontNormalLarge")
    label("Changes apply immediately and are saved for this character.", 16, -44)
    local function checkbox(text, x, y, read, write)
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", x, y)
        check:SetSize(26, 26)
        local caption = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        caption:SetPoint("LEFT", check, "RIGHT", 4, 0)
        caption:SetText(text)
        check.read = read
        check:SetScript("OnClick", function(self) write(self:GetChecked() and true or false) end)
        checks[#checks + 1] = check
    end
    checkbox("Enable Dwarf Translator", 16, -76,
        function() return db.enabled end, function(value)
            db.enabled = value
            if addon.RefreshMinimap then addon.RefreshMinimap() end
        end)
    label("Translate in these chat types", 16, -154, "GameFontNormal")
    local labels = {
        SAY = "Say", YELL = "Yell", PARTY = "Party", PARTY_LEADER = "Party leader",
        RAID = "Raid", RAID_LEADER = "Raid leader", RAID_WARNING = "Raid warning",
        GUILD = "Guild", OFFICER = "Officer", WHISPER = "Whispers",
        BN_WHISPER = "Battle.net whispers", INSTANCE_CHAT = "Instance chat",
        INSTANCE_CHAT_LEADER = "Instance leader", CHANNEL = "Numbered channels",
        EMOTE = "Custom emotes",
    }
    local names = {}
    for name in pairs(channels) do names[#names + 1] = name end
    table.sort(names)
    for i, name in ipairs(names) do
        local channel = name
        local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
        checkbox(labels[channel] or channel, 16 + column * 260, -180 - row * 30,
            function() return db.channels[channel] ~= false end,
            function(value) db.channels[channel] = value end)
    end
    checkbox("Show minimap button", 276, -76,
        function() return db.showMinimap ~= false end,
        function(value) addon.SetMinimapVisible(value) end)
    checkbox("Always Dwarvish (Say/Yell)", 16, -108,
        function() return db.alwaysDwarven end,
        function(value)
            if value ~= db.alwaysDwarven then addon.ToggleAlwaysDwarven() end
            addon.RefreshSettings()
        end)
    checkbox("Use female dwarf icon", 276, -108,
        function() return db.femaleIcon == true end,
        function(value)
            db.femaleIcon = value
            if addon.RefreshMinimap then addon.RefreshMinimap() end
            if addon.RefreshMailIcon then addon.RefreshMailIcon() end
        end)
    local y = -190 - math.ceil(#names / 2) * 30
    label("d: message - Switch Dwarvish/Common for one Say/Yell.", 16, y)
    label("~~ message - Skip the accent for one message.", 16, y - 24)
    label("Combat pauses translation. /dwarf help lists all commands.", 16, y - 48)
    panel:SetScript("OnShow", addon.RefreshSettings)
    category = Settings.RegisterCanvasLayoutCategory(panel, "Dwarf Translator")
    Settings.RegisterAddOnCategory(category)
    addon.InitializeTranslationSettings(category)
    addon.InitializePreviewSettings(category)
    addon.InitializeSharingSettings(category)
    addon.RefreshSettings()
end
function addon.OpenSettings()
    if InCombatLockdown and InCombatLockdown() then
        notice("Open settings when you're out of combat.")
        return
    end
    if category and Settings and Settings.OpenToCategory then
        addon.RefreshSettings()
        Settings.OpenToCategory(category:GetID())
    else
        notice("Settings are unavailable on this client. Use /dwarf help.")
    end
end
