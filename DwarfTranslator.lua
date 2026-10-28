local addonName, addon = ...
local db, registered
function addon.GetDwarfIcon()
    return "Interface\\Icons\\Achievement_Character_Dwarf_" .. ((db and db.femaleIcon) and "Female" or "Male")
end
local channels = {
    SAY = true, YELL = true, PARTY = true, PARTY_LEADER = true,
    RAID = true, RAID_LEADER = true, RAID_WARNING = true,
    GUILD = true, OFFICER = true, WHISPER = true, BN_WHISPER = true,
    INSTANCE_CHAT = true, INSTANCE_CHAT_LEADER = true, CHANNEL = true,
    EMOTE = true,
}
local function say(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66Dwarf Translator:|r " .. message) end
end
-- Never mutate Blizzard's chat edit box while protected chat is restricted.
local function chatRestricted()
    if InCombatLockdown and InCombatLockdown() then return true end
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
        and C_ChatInfo.InChatMessagingLockdown() or false
end
-- WoW's Dwarvish language ID; availability is checked for the character.
local DWARVEN_LANGUAGE_ID = 6
local COMMON_LANGUAGE_ID = 7
local pendingLanguages = setmetatable({}, { __mode = "k" })
local function restoreLanguage(editBox, pending)
    if chatRestricted() then return end
    if pendingLanguages[editBox] ~= pending then return end
    if editBox.languageID == pending.target then
        editBox.languageID = pending.previous
    end
    pendingLanguages[editBox] = nil
end
local function knowsLanguage(target)
    if C_ChatInfo and C_ChatInfo.CanPlayerSpeakLanguage then
        return C_ChatInfo.CanPlayerSpeakLanguage(target)
    end
    if GetNumLanguages and GetLanguageByIndex then
        for i = 1, GetNumLanguages() do
            local _, languageID = GetLanguageByIndex(i)
            if languageID == target then return true end
        end
    end
    return false
end
local function knowsDwarven() return knowsLanguage(DWARVEN_LANGUAGE_ID) end
function addon.ToggleAlwaysDwarven()
    if not db then return end
    if not db.alwaysDwarven then
        if not knowsDwarven() then
            say("Your character cannot speak Dwarvish.")
            return
        end
        if not C_Timer or not C_Timer.After then
            say("This client cannot safely restore your chat language.")
            return
        end
    end
    db.alwaysDwarven = not db.alwaysDwarven
    if addon.RefreshMinimap then addon.RefreshMinimap() end
    if addon.RefreshSettings then addon.RefreshSettings() end
    say("Always Dwarvish: " .. (db.alwaysDwarven and "on (Say/Yell)." or "off."))
end
-- Read-only preview: determine whether this pause actually skips a change.
local nextPauseNotice = 0
local function skippedTranslation(editBox)
    if not db or not db.enabled or not editBox then return false end
    if editBox.IsForbidden and editBox:IsForbidden() then return false end
    local chatType = editBox:GetAttribute("chatType")
    if issecretvalue and issecretvalue(chatType) then return false end
    if not channels[chatType] or db.channels[chatType] == false then return false end
    local original = editBox:GetText()
    if issecretvalue and issecretvalue(original) then return false end
    if type(original) ~= "string" or not original:match("%S")
        or original:match("^%s*/") or original:sub(1, 3) == "~~ " then
        return false
    end
    local body = original:match("^d:%s*(.*)$")
    if body then
        return body:match("%S") ~= nil and not body:match("^%s*/")
            and (chatType == "SAY" or chatType == "YELL")
            and knowsLanguage(db.alwaysDwarven and COMMON_LANGUAGE_ID or DWARVEN_LANGUAGE_ID)
            and C_Timer and C_Timer.After ~= nil, true
    end
    if db.alwaysDwarven and (chatType == "SAY" or chatType == "YELL")
        and editBox.languageID ~= DWARVEN_LANGUAGE_ID and knowsDwarven()
        and C_Timer and C_Timer.After then
        return true, true
    end
    local converted = addon.Convert(original)
    local limit = editBox.GetMaxBytes and editBox:GetMaxBytes() or 0
    if not limit or limit <= 0 then limit = 255 end
    return converted ~= original and #converted <= limit, false
end
local function notifySkippedTranslation(editBox)
    if not db or not db.enabled then return end
    local now = GetTime()
    if now < nextPauseNotice then return end
    -- A failed preview must never interfere with Blizzard's normal send.
    local ok, skipped, languageSkipped = pcall(skippedTranslation, editBox)
    if not ok or not skipped then return end
    nextPauseNotice = now + 30
    local reason = (InCombatLockdown and InCombatLockdown()) and "Combat pause" or "Chat restrictions"
    local message = reason .. ": sending without translation."
    if languageSkipped then message = message .. " Language switch skipped." end
    say(message)
end
local function preSend(_, editBox)
    -- No edit-box mutations during lockdown, including pending restoration.
    -- Only inspect readable text to report a genuinely skipped translation.
    if chatRestricted() then
        notifySkippedTranslation(editBox)
        return
    end
    if not editBox then return end
    -- Restore before another send even if it happens before the timer runs.
    local pending = pendingLanguages[editBox]
    if pending then restoreLanguage(editBox, pending) end
    if not db or not db.enabled then return end
    local chatType = editBox:GetAttribute("chatType")
    if not channels[chatType] or db.channels[chatType] == false then return end
    local original = editBox:GetText()
    if issecretvalue and issecretvalue(original) then return end
    if type(original) ~= "string" or original == "" or original:match("^%s*/") then return end
    if original:sub(1, 3) == "~~ " then
        local raw = original:sub(4)
        if not raw:match("^%s*/") then editBox:SetText(raw) end
        return
    end
    local body = original:match("^d:%s*(.*)$")
    if body then
        local reason
        local target = db.alwaysDwarven and COMMON_LANGUAGE_ID or DWARVEN_LANGUAGE_ID
        if not body:match("%S") or body:match("^%s*/") then
            reason = "Type a message after d:, not a slash command."
        elseif chatType ~= "SAY" and chatType ~= "YELL" then
            reason = "Use d: in Say or Yell to switch language."
        elseif not knowsLanguage(target) then
            reason = "Your character cannot speak " .. (target == COMMON_LANGUAGE_ID and "Common." or "Dwarvish.")
        elseif not C_Timer or not C_Timer.After then
            reason = "This client cannot safely restore your chat language."
        end
        if reason then
            -- Do not silently send a requested racial-language message in Common.
            editBox:SetText("")
            say("Message not sent. " .. reason)
            return
        end
    end
    local targetLanguage
    if body then
        targetLanguage = db.alwaysDwarven and COMMON_LANGUAGE_ID or DWARVEN_LANGUAGE_ID
    elseif db.alwaysDwarven and (chatType == "SAY" or chatType == "YELL") then
        if knowsDwarven() and C_Timer and C_Timer.After then
            targetLanguage = DWARVEN_LANGUAGE_ID
        else
            db.alwaysDwarven = false
            if addon.RefreshMinimap then addon.RefreshMinimap() end
            if addon.RefreshSettings then addon.RefreshSettings() end
            say("Always Dwarvish turned off: language switching is unavailable.")
        end
    end
    local converted = addon.Convert(body or original)
    local limit = editBox.GetMaxBytes and editBox:GetMaxBytes() or 0
    if not limit or limit <= 0 then limit = 255 end
    if #converted > limit then
        say("Accent skipped: the converted message would exceed the chat limit.")
        converted = body or original
    end
    if converted ~= original then editBox:SetText(converted) end
    if targetLanguage then
        pending = { previous = editBox.languageID, target = targetLanguage }
        pendingLanguages[editBox] = pending
        -- Blizzard reads languageID immediately after this callback returns.
        editBox.languageID = targetLanguage
        C_Timer.After(0, function() restoreLanguage(editBox, pending) end)
    end
end
local function install()
    if registered then return end
    if EventRegistry and EventRegistry.RegisterCallback
        and ChatFrameEditBoxMixin and ChatFrameEditBoxMixin.OnPreSendText then
        EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", preSend, addon)
        registered = true
    end
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
-- A language-restoration timer may fire just after combat/lockdown starts.
-- Keep it pending and restore after restrictions end, even if no new chat is sent.
local restoreElapsed = 0
frame:SetScript("OnUpdate", function(_, elapsed)
    if not next(pendingLanguages) then return end
    restoreElapsed = restoreElapsed + elapsed
    if restoreElapsed < 0.25 then return end
    restoreElapsed = 0
    if chatRestricted() then return end
    for editBox, pending in pairs(pendingLanguages) do
        restoreLanguage(editBox, pending)
    end
end)
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(DwarfTranslatorDB) ~= "table" then DwarfTranslatorDB = {} end
        db = DwarfTranslatorDB
        if type(db.enabled) ~= "boolean" then db.enabled = true end
        if type(db.alwaysDwarven) ~= "boolean" then db.alwaysDwarven = false end
        if type(db.channels) ~= "table" then db.channels = {} end
        addon.InitializeTranslations(db)
        if addon.InitializeSettings then addon.InitializeSettings(db, channels) end
        if addon.InitializeMinimap then addon.InitializeMinimap(db) end
    end
    if db then install() end
    if event == "PLAYER_LOGIN" then
        if registered then
            say((db.enabled and "On" or "Off") .. ". /dwarf help for commands.")
        else
            say("Automatic conversion unavailable: this client lacks the supported pre-send API. Use the Preview section in addon settings.")
        end
    end
end)

local function showHelp()
    say("/dwarf help (or /dwarf) - Show all commands.")
    say("/dwarf on - Enable the accent and d: language trigger.")
    say("/dwarf off - Disable the accent and d: language trigger.")
    say("/dwarf settings - Open settings (Right-click the minimap button).")
    say("/dwarf status - Show enabled state, chat hook and restriction status.")
    say("During combat/chat lockdown, messages pass through unchanged, including d: and ~~.")
    say("d: <message> - Switch one Say/Yell to Dwarvish, or Common if Always Dwarvish is on.")
    say("Left-click the minimap button - Toggle Always Dwarvish for Say/Yell.")
    say("~~ <message> - Bypass the accent and automatic language switch once.")
    say("/dwarftranslator is an alias for /dwarf. Prefixes require the addon and channel to be on.")
end
SLASH_DWARFTRANSLATOR1 = "/dwarf"
SLASH_DWARFTRANSLATOR2 = "/dwarftranslator"
SlashCmdList.DWARFTRANSLATOR = function(input)
    if not db then return end
    local command, rest = input:match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "help" or command == "" then
        showHelp()
    elseif command == "on" or command == "off" then
        db.enabled = command == "on"
        if addon.RefreshMinimap then addon.RefreshMinimap() end
        say("Accent " .. command .. ".")
        if addon.RefreshSettings then addon.RefreshSettings() end
    elseif command == "settings" then
        addon.OpenSettings()
    elseif command == "status" then
        say((db.enabled and "On" or "Off") .. "; pre-send hook " .. (registered and "registered" or "unavailable") .. (chatRestricted() and "; paused for combat/chat lockdown." or "; chat editing available."))
    else
        say("Unknown command. Use /dwarf help for all commands.")
    end
end
