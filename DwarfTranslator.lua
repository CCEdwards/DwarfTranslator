local addonName, addon = ...
local db, registered
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
-- WoW's Dwarvish language ID; availability is checked for the character.
local DWARVEN_LANGUAGE_ID = 6
local pendingLanguages = setmetatable({}, { __mode = "k" })
local function restoreLanguage(editBox, pending)
    if pendingLanguages[editBox] ~= pending then return end
    if editBox.languageID == DWARVEN_LANGUAGE_ID then
        editBox.languageID = pending.previous
    end
    pendingLanguages[editBox] = nil
end
local function knowsDwarven()
    if C_ChatInfo and C_ChatInfo.CanPlayerSpeakLanguage then
        return C_ChatInfo.CanPlayerSpeakLanguage(DWARVEN_LANGUAGE_ID)
    end
    if GetNumLanguages and GetLanguageByIndex then
        for i = 1, GetNumLanguages() do
            local _, languageID = GetLanguageByIndex(i)
            if languageID == DWARVEN_LANGUAGE_ID then return true end
        end
    end
    return false
end
local function preSend(_, editBox)
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
        if not body:match("%S") or body:match("^%s*/") then
            reason = "Type a message after d:, not a slash command."
        elseif chatType ~= "SAY" and chatType ~= "YELL" then
            reason = "Use d: in Say or Yell for the Dwarven language."
        elseif not knowsDwarven() then
            reason = "Your character cannot speak Dwarven."
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
    local converted = addon.Convert(body or original, db.keep)
    local limit = editBox.GetMaxBytes and editBox:GetMaxBytes() or 0
    if not limit or limit <= 0 then limit = 255 end
    if #converted > limit then
        say("Accent skipped: the converted message would exceed the chat limit.")
        converted = body or original
    end
    if converted ~= original then editBox:SetText(converted) end
    if body then
        pending = { previous = editBox.languageID }
        pendingLanguages[editBox] = pending
        -- Blizzard reads languageID immediately after this callback returns.
        editBox.languageID = DWARVEN_LANGUAGE_ID
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
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(DwarfTranslatorDB) ~= "table" then DwarfTranslatorDB = {} end
        db = DwarfTranslatorDB
        if type(db.enabled) ~= "boolean" then db.enabled = true end
        if type(db.keep) ~= "table" then db.keep = {} end
        if type(db.channels) ~= "table" then db.channels = {} end
    end
    if db then install() end
    if event == "PLAYER_LOGIN" then
        if registered then
            say((db.enabled and "On" or "Off") .. ". /dwarf for help.")
        else
            say("Automatic conversion unavailable: this client lacks the supported pre-send API. /dwarf preview still works.")
        end
    end
end)

SLASH_DWARFTRANSLATOR1 = "/dwarf"
SLASH_DWARFTRANSLATOR2 = "/dwarftranslator"
SlashCmdList.DWARFTRANSLATOR = function(input)
    if not db then return end
    local command, rest = input:match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "on" or command == "off" then
        db.enabled = command == "on"
        say("Accent " .. command .. ".")
    elseif command == "preview" then
        say(addon.Convert(rest, db.keep))
    elseif command == "keep" or command == "unkeep" then
        if rest == "" then say("Usage: /dwarf " .. command .. " word") return end
        db.keep[rest:lower()] = command == "keep" or nil
        say(command == "keep" and "Word protected." or "Word protection removed.")
    elseif command == "channel" then
        local channel, state = rest:match("^(%S+)%s+(%S+)$")
        channel = channel and channel:upper()
        state = state and state:lower()
        if channels[channel] and (state == "on" or state == "off") then
            db.channels[channel] = state == "on"
            say(channel .. " accent " .. state .. ".")
        else say("Usage: /dwarf channel SAY|YELL|PARTY|RAID|RAID_WARNING|GUILD|OFFICER|WHISPER|BN_WHISPER|INSTANCE_CHAT|CHANNEL|EMOTE on|off") end
    elseif command == "status" then
        say((db.enabled and "On" or "Off") .. "; pre-send hook " .. (registered and "registered" or "unavailable") .. ".")
    else
        say("/dwarf on|off; /dwarf preview <text>")
        say("/dwarf channel <TYPE> on|off; /dwarf keep|unkeep <word>; /dwarf status")
        say("d: <message> uses Dwarven in Say/Yell. ~~ <message> bypasses the accent.")
    end
end
