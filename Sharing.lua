local _, addon = ...
local panel
function addon.InitializeSharingSettings(parent)
    if panel or not Settings.RegisterCanvasLayoutSubcategory then return end
    panel = CreateFrame("Frame", "DwarfTranslatorSharingPanel", UIParent)
    panel:Hide()
    local function label(text, y)
        local f = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        f:SetPoint("TOPLEFT", 16, y)
        f:SetWidth(510)
        f:SetJustifyH("LEFT")
        f:SetText(text)
        return f
    end
    label("Import / Export translations", -16)
    label("Export your current list, then copy it to share or save. Paste an export below to import it. Only translations are included.", -48)
    local border = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    border:SetPoint("TOPLEFT", 16, -106)
    border:SetSize(510, 310)
    border:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
    border:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
    local scroll = CreateFrame("ScrollFrame", nil, border, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local input = CreateFrame("EditBox", "DwarfTranslatorSharingText", scroll)
    input:SetSize(460, 290)
    input:SetFontObject("GameFontHighlight")
    input:SetMultiLine(true)
    input:SetAutoFocus(false)
    input:SetMaxLetters(50000)
    scroll:SetScrollChild(input)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local offset = scroll:GetVerticalScroll()
        local cursor = -y
        if cursor < offset then scroll:SetVerticalScroll(cursor)
        elseif cursor + height > offset + scroll:GetHeight() then
            scroll:SetVerticalScroll(cursor + height - scroll:GetHeight())
        end
    end)
    local status = label("", -474)
    label("Import replaces your entire translation list, including removals. Export first to keep a backup. Other addon options stay unchanged.", -514)
    local function button(text, x, click)
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(160, 24)
        b:SetPoint("TOPLEFT", x, -434)
        b:SetText(text)
        b:SetScript("OnClick", click)
    end
    button("Export translations", 16, function()
        input:SetText(addon.ExportTranslations())
        input:SetFocus()
        input:HighlightText()
        status:SetText("Press Ctrl+C to copy. Save the text or share it with another player.")
    end)
    StaticPopupDialogs["DWARFTRANSLATOR_IMPORT"] = {
        text = "Replace all your translations with this imported list? Your current custom words, edits and removals will be replaced. Export first to keep a backup.",
        button1 = "Import", button2 = "Cancel", timeout = 0,
        whileDead = true, hideOnEscape = true, preferredIndex = 3,
        OnAccept = function(_, text)
            local _, message = addon.ImportTranslations(text)
            status:SetText(message)
        end,
    }
    button("Import translations", 190, function()
        local text = input:GetText()
        local parsed, message = addon.ParseTranslationImport(text)
        if not parsed then status:SetText(message); return end
        input:ClearFocus()
        StaticPopup_Show("DWARFTRANSLATOR_IMPORT", nil, nil, text)
    end)
    Settings.RegisterCanvasLayoutSubcategory(parent, panel, "Import / Export")
end
