local _, addon = ...
local button
local function notice(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66Dwarf Translator:|r " .. text) end
end
local function install()
    if button or not SendMailFrame or not SendMailBodyEditBox or not MailFrameTab2 then return end
    button = CreateFrame("Button", "DwarfTranslatorMailTranslate", SendMailFrame)
    button:SetSize(28, 28)
    -- Anchor beside the Send Mail tab at the bottom of the mailbox.
    button:SetPoint("LEFT", MailFrameTab2, "RIGHT", 8, 0)
    button:RegisterForClicks("LeftButtonUp")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    function addon.RefreshMailIcon()
        icon:SetTexture(addon.GetDwarfIcon())
    end
    addon.RefreshMailIcon()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Translate to Dwarf", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function()
        if InCombatLockdown and InCombatLockdown() then
            notice("Translate your mail when you're out of combat.")
            return
        end
        local original = SendMailBodyEditBox:GetText()
        if issecretvalue and issecretvalue(original) then return end
        if type(original) ~= "string" or original == "" then return end
        local converted = addon.Convert(original)
        local limit = SendMailBodyEditBox.GetMaxBytes and SendMailBodyEditBox:GetMaxBytes() or 0
        local letters = SendMailBodyEditBox.GetMaxLetters and SendMailBodyEditBox:GetMaxLetters() or 0
        local count = strlenutf8 and strlenutf8(converted) or #converted
        if (limit and limit > 0 and #converted > limit)
            or (letters and letters > 0 and count > letters) then
            notice("Translation would exceed the mail limit. Your draft was kept unchanged.")
            return
        end
        if converted ~= original then SendMailBodyEditBox:SetText(converted) end
    end)
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MAIL_SHOW")
frame:SetScript("OnEvent", install)
install()
