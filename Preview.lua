local _, addon = ...
local panel
local sample = "Hello my friend! Yes, you're coming with my family today. We're going to look for your little shield before fighting. Isn't your small friend waiting for you? I'm talking about drinking and getting something for the journey."

function addon.InitializePreviewSettings(parentCategory)
    if panel or not Settings.RegisterCanvasLayoutSubcategory then return end
    panel = CreateFrame("Frame", "DwarfTranslatorPreviewPanel", UIParent)
    panel:Hide()
    local function label(text, y, font)
        local field = panel:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
        field:SetPoint("TOPLEFT", 16, y)
        field:SetWidth(510)
        field:SetJustifyH("LEFT")
        field:SetText(text)
        return field
    end
    label("Translation preview", -16, "GameFontNormalLarge")
    label("Try your own text below. The preview uses your current translations and sends nothing to chat.", -48)
    label("Your text", -96, "GameFontNormal")
    local inputBorder = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    inputBorder:SetPoint("TOPLEFT", 16, -118)
    inputBorder:SetSize(510, 176)
    inputBorder:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    inputBorder:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
    inputBorder:SetBackdropBorderColor(0.65, 0.65, 0.65, 1)
    local input = CreateFrame("EditBox", "DwarfTranslatorPreviewInput", inputBorder)
    input:SetFontObject("GameFontHighlight")
    input:SetJustifyH("LEFT")
    input:SetJustifyV("TOP")
    input:SetPoint("TOPLEFT", 10, -8)
    input:SetSize(490, 160)
    input:SetMultiLine(true)
    input:SetAutoFocus(false)
    input:SetMaxLetters(500)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    label("Dwarven accent preview", -314, "GameFontNormal")
    local output = label("", -342)
    local function refresh()
        output:SetText(addon.Convert(input:GetText()))
    end
    input:SetScript("OnTextChanged", refresh)
    local reset = CreateFrame("Button", "DwarfTranslatorPreviewSample", panel, "UIPanelButtonTemplate")
    reset:SetPoint("TOPLEFT", 16, -490)
    reset:SetSize(160, 24)
    reset:SetText("Reset sample text")
    reset:SetScript("OnClick", function() input:SetText(sample); input:ClearFocus() end)
    input:SetText(sample)
    panel:SetScript("OnShow", refresh)
    panel:SetScript("OnHide", function() input:ClearFocus() end)
    Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, "Preview")
end
