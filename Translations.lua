local _, addon = ...
local defaults = {}
for key, value in pairs(addon.Replacements) do defaults[key] = value end
local db, panel

local function normalize(word)
    if type(word) ~= "string" then return nil end
    word = word:gsub("\226\128\153", "'"):match("^%s*(.-)%s*$"):lower()
    if #word == 0 or #word > 64 or not word:match("^%a[%a']*$") then return nil end
    return word
end
local function validValue(value)
    return type(value) == "string" and #value > 0 and #value <= 120
        and not value:find("[%c|]") and not value:match("^%s*/")
end
function addon.InitializeTranslations(settings)
    db = settings
    -- Saved overrides take precedence over bundled defaults on every addon update.
    if type(db.translations) ~= "table" then db.translations = {} end
    -- Migrate legacy word exceptions once into persistent removed translations.
    if type(db.keep) == "table" then
        for word, enabled in pairs(db.keep) do
            local key = normalize(word)
            if enabled and key then db.translations[key] = false end
        end
    end
    db.keep = nil
    for key in pairs(addon.Replacements) do addon.Replacements[key] = nil end
    for key, value in pairs(defaults) do addon.Replacements[key] = value end
    for key, value in pairs(db.translations) do
        if normalize(key) == key then
            if value == false then addon.Replacements[key] = nil
            elseif validValue(value) then addon.Replacements[key] = value end
        end
    end
end
function addon.ResetTranslations()
    if not db then return end
    db.translations = {}
    addon.InitializeTranslations(db)
end
function addon.SaveTranslation(originalKey, word, value)
    if not db then return false, "Translations are not ready yet." end
    local key = normalize(word)
    if not key then return false, "Enter one English word (apostrophes are allowed)." end
    if type(value) == "string" then value = value:match("^%s*(.-)%s*$") end
    if not validValue(value) then
        return false, "Enter 1-120 characters without chat markup, newlines or slash commands."
    end
    if originalKey and not addon.Replacements[originalKey] then
        return false, "That translation no longer exists. Choose New translation."
    end
    if key ~= originalKey and addon.Replacements[key] then
        return false, "That word already exists. Select it in the list to edit it."
    end
    if originalKey and originalKey ~= key then
        if defaults[originalKey] then db.translations[originalKey] = false else db.translations[originalKey] = nil end
        addon.Replacements[originalKey] = nil
    end
    db.translations[key] = value
    addon.Replacements[key] = value
    return true, "Translation saved.", key
end
function addon.RemoveTranslation(key)
    if not db or not key or not addon.Replacements[key] then
        return false, "Select a translation to remove."
    end
    -- A false override remembers removal of a built-in entry across reloads.
    if defaults[key] then db.translations[key] = false else db.translations[key] = nil end
    addon.Replacements[key] = nil
    return true, "Translation removed."
end
-- A versioned text format, never executable Lua.
function addon.ExportTranslations()
    local lines = { "DwarfTranslator:1" }
    local keys = addon.ListTranslations()
    for _, key in ipairs(keys) do
        local value = addon.Replacements[key]:gsub("%%", "%%25"):gsub("=", "%%3D")
        lines[#lines + 1] = key .. "=" .. value
    end
    return table.concat(lines, "\n")
end
function addon.ParseTranslationImport(text)
    if type(text) ~= "string" or #text > 50000 then return nil, "Import is too large (maximum 50,000 bytes)." end
    text = text:gsub("\r\n", "\n"):match("^%s*(.-)%s*$")
    local header, body = text:match("^([^\n]+)\n?(.*)$")
    if header ~= "DwarfTranslator:1" then return nil, "This is not a supported Dwarf Translator export." end
    local imported, count = {}, 0
    for line in body:gmatch("[^\n]+") do
        local key, value = line:match("^([^=]+)=(.*)$")
        if not key or normalize(key) ~= key or imported[key] ~= nil then
            return nil, "Invalid or duplicate translation word. Nothing was imported."
        end
        -- Only the escapes produced by our exporter are accepted.
        if value:gsub("%%25", ""):gsub("%%3D", ""):find("%", 1, true) then
            return nil, "Invalid escaped translation. Nothing was imported."
        end
        value = value:gsub("%%3D", "="):gsub("%%25", "%%")
        if not validValue(value) then return nil, "Invalid replacement text. Nothing was imported." end
        imported[key] = value
        count = count + 1
        if count > 1000 then return nil, "Too many translations (maximum 1,000)." end
    end
    return imported, nil, count
end
function addon.ImportTranslations(text)
    local imported, message, count = addon.ParseTranslationImport(text)
    if not imported then return false, message end
    local overrides = {}
    for key in pairs(defaults) do overrides[key] = false end
    for key, value in pairs(imported) do overrides[key] = value end
    db.translations = overrides
    addon.InitializeTranslations(db)
    return true, "Imported " .. count .. " translations."
end
function addon.ListTranslations(filter)
    local keys = {}
    filter = (filter or ""):lower()
    for key, value in pairs(addon.Replacements) do
        if filter == "" or key:find(filter, 1, true) or value:lower():find(filter, 1, true) then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)
    return keys
end

function addon.InitializeTranslationSettings(parentCategory)
    if panel or not Settings.RegisterCanvasLayoutSubcategory then return end
    panel = CreateFrame("Frame", "DwarfTranslatorTranslationsPanel", UIParent)
    panel:Hide()
    local selected, page, keys = nil, 1, {}
    local rows, pageSize = {}, 9
    local function label(text, x, y, font)
        local field = panel:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
        field:SetPoint("TOPLEFT", x, y)
        field:SetText(text)
        return field
    end
    local function edit(name, x, y, width, maxLetters)
        local field = CreateFrame("EditBox", name, panel, "InputBoxTemplate")
        field:SetSize(width, 24)
        field:SetPoint("TOPLEFT", x, y)
        field:SetAutoFocus(false)
        field:SetMaxLetters(maxLetters)
        field:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        return field
    end
    local function button(name, text, x, y, width, click)
        local control = CreateFrame("Button", name, panel, "UIPanelButtonTemplate")
        control:SetSize(width, 24)
        control:SetPoint("TOPLEFT", x, y)
        control:SetText(text)
        control:SetScript("OnClick", click)
        return control
    end
    label("Translations", 16, -16, "GameFontNormalLarge")
    label("Select a row to edit it, or choose New translation. Changes save immediately.", 16, -44)
    label("Search", 16, -76)
    local search = edit("DwarfTranslatorTranslationSearch", 80, -70, 400, 120)
    label("Original word", 24, -108, "GameFontNormal")
    label("Replacement", 260, -108, "GameFontNormal")
    local source = edit("DwarfTranslatorTranslationSource", 24, -420, 210, 64)
    local target = edit("DwarfTranslatorTranslationTarget", 270, -420, 240, 120)
    label("Original word", 24, -398)
    label("Replacement", 270, -398)
    local status = label("", 16, -494)
    status:SetWidth(520)
    status:SetJustifyH("LEFT")
    local pageLabel = label("", 180, -365)
    local previous, nextPage, remove
    local function clearSelection()
        selected = nil
        source:SetText("")
        target:SetText("")
        remove:SetEnabled(false)
    end
    local function refresh()
        keys = addon.ListTranslations(search:GetText())
        local pages = math.max(1, math.ceil(#keys / pageSize))
        page = math.max(1, math.min(page, pages))
        for i, row in ipairs(rows) do
            local key = keys[(page - 1) * pageSize + i]
            row.key = key
            if key then
                row.left:SetText((selected == key and "> " or "") .. key)
                row.right:SetText(addon.Replacements[key])
                row:Show()
            else row:Hide() end
        end
        pageLabel:SetText("Page " .. page .. " / " .. pages .. "  (" .. #keys .. " translations)")
        previous:SetEnabled(page > 1)
        nextPage:SetEnabled(page < pages)
    end
    for i = 1, pageSize do
        local row = CreateFrame("Button", "DwarfTranslatorTranslationRow" .. i, panel)
        row:SetSize(510, 24)
        row:SetPoint("TOPLEFT", 16, -130 - (i - 1) * 24)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.left = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.left:SetPoint("LEFT", 8, 0)
        row.left:SetWidth(225)
        row.left:SetJustifyH("LEFT")
        row.right = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.right:SetPoint("LEFT", 244, 0)
        row.right:SetWidth(255)
        row.right:SetJustifyH("LEFT")
        row:SetScript("OnClick", function(self)
            selected = self.key
            source:SetText(selected)
            target:SetText(addon.Replacements[selected])
            remove:SetEnabled(true)
            status:SetText("")
            refresh()
        end)
        rows[i] = row
    end
    previous = button("DwarfTranslatorTranslationsPrevious", "Previous", 16, -358, 100,
        function() page = page - 1; refresh() end)
    nextPage = button("DwarfTranslatorTranslationsNext", "Next", 426, -358, 100,
        function() page = page + 1; refresh() end)
    button("DwarfTranslatorTranslationNew", "New translation", 16, -458, 150, function()
        clearSelection(); status:SetText("Enter a word and its replacement, then click Save.")
        refresh(); source:SetFocus()
    end)
    button("DwarfTranslatorTranslationSave", "Save", 180, -458, 100, function()
        local ok, message, key = addon.SaveTranslation(selected, source:GetText(), target:GetText())
        status:SetText(message)
        if ok then
            selected = key
            source:SetText(key)
            target:SetText(addon.Replacements[key])
            remove:SetEnabled(true)
            source:ClearFocus(); target:ClearFocus()
            search:SetText("")
            keys = addon.ListTranslations()
            for i, entry in ipairs(keys) do if entry == key then page = math.ceil(i / pageSize) end end
            refresh()
        end
    end)
    remove = button("DwarfTranslatorTranslationRemove", "Remove", 294, -458, 100, function()
        local ok, message = addon.RemoveTranslation(selected)
        status:SetText(message)
        if ok then clearSelection(); refresh() end
    end)
    remove:SetEnabled(false)
    StaticPopupDialogs["DWARFTRANSLATOR_RESET_TRANSLATIONS"] = {
        text = "Reset all translations? Custom words and edits will be lost, and removed default translations will return. Other addon settings will be kept.",
        button1 = "Reset translations",
        button2 = "Cancel",
        OnAccept = function()
            addon.ResetTranslations()
            clearSelection()
            search:SetText("")
            page = 1
            refresh()
            status:SetText("Default translations restored.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    button("DwarfTranslatorTranslationReset", "Reset translations", 16, -526, 160, function()
        source:ClearFocus(); target:ClearFocus(); search:ClearFocus()
        StaticPopup_Show("DWARFTRANSLATOR_RESET_TRANSLATIONS")
    end)
    search:SetScript("OnTextChanged", function() page = 1; refresh() end)
    panel:SetScript("OnShow", function() clearSelection(); status:SetText(""); refresh() end)
    panel:SetScript("OnHide", function() source:ClearFocus(); target:ClearFocus(); search:ClearFocus() end)
    Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, "Translations")
end
