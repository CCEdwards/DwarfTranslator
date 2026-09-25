# Dwarf Translator 0.2.0

A local, English-language dwarven accent for chat you type in World of Warcraft: Forever. Enabled by default, with one consolidated replacement list in `Accent.lua`. Conversion is either on or off. No account, API key, external service or library is needed.

## Install

1. Close WoW completely.
2. Extract DwarfTranslator.zip into your Forever client's `Interface\AddOns` directory. The beta directory is typically `World of Warcraft\_classic_beta_\Interface\AddOns`.
3. Confirm the file is at `Interface\AddOns\DwarfTranslator\DwarfTranslator.toc`, without an extra nested DwarfTranslator folder.
4. Start Forever and enable **Dwarf Translator** in the AddOns list for your character.
5. Type `/dwarf status`. It should report **On; pre-send hook registered**.
6. Chat normally. Your message changes when you press Enter, immediately before Blizzard sends it. Other players receive the converted text and do not need the addon.


## Examples

> Hello friend, are you ready to go?
>
> Hullo mate, are ye ready te go?

> Yes! Don't forget your little shield.
>
> Aye! Don't forget yer wee shield.

> I'm going to look for your friends.
>
> I'm goin' te look fer yer mates.

The style is inspired by Warcraft's Scots-flavored dwarf dialogue. It keeps the original message's meaning instead of inventing ale, beard or clan remarks. This is a predictable word-based transformation, not an AI paraphraser, a full Scots translator, or the in-game Dwarven language setting. It cannot infer every grammatical context or recognize all proper names.

## Commands

| Command | Effect |
| --- | --- |
| `/dwarf on` / `/dwarf off` | Enable or disable conversion |
| `/dwarf preview Hello friend` | Print a converted example locally; sends nothing to others |
| `/dwarf channel WHISPER off` | Disable the accent in that chat type |
| `/dwarf channel WHISPER on` | Re-enable it |
| `/dwarf keep friend` | Preserve this word, regardless of capitalization |
| `/dwarf unkeep friend` | Remove that exception |
| `/dwarf status` | Show enabled state and hook registration |
| `/dwarf` | Show help |

`/dwarftranslator` is an alias for `/dwarf`. Settings are stored per character when the client supports saving and restoring addon settings. Some Forever beta builds have reported SavedVariables issues; if settings revert, apply the commands again.

For a single unchanged message, start its body with **`~~ `** (two tildes and a space). For example, `/s ~~ You can read this normally.` sends `You can read this normally.` in Say. This prefix is processed only while DwarfTranslator is enabled for that channel. A bypass whose remaining text starts with `/` is left alone so it cannot execute a command.

Supported chat types: SAY, YELL, PARTY, PARTY_LEADER, RAID, RAID_LEADER, RAID_WARNING, GUILD, OFFICER, WHISPER, BN_WHISPER, INSTANCE_CHAT, INSTANCE_CHAT_LEADER, CHANNEL, EMOTE. All start enabled. CHANNEL controls numbered channels together. EMOTE includes custom `/e` text; use `/dwarf channel EMOTE off` if you prefer unchanged action descriptions.

## Preservation and scope

- Keeps item/spell/quest/player hyperlinks, color spans, textures, atlas markup, raid markers, square-bracketed text and backtick-delimited text intact. Backticks remain in the message.
- Keeps common URLs, email addresses, identifiers and UTF-8 words intact. English word substitutions preserve uppercase or initial capitalization.
- Blizzard parses chat commands and whisper recipients before the callback. DwarfTranslator changes only the remaining message body, not recipient/channel selection. Other slash commands are not rewritten.
- Does not intercept `SendChatMessage`, automate sending, or alter addon communication. Macros, addon-generated messages, custom third-party chat editors and separate community/Discord interfaces are outside the supported scope unless they use Blizzard's standard pre-send event.
- If conversion would exceed the edit box's byte limit (255-byte fallback), sends the original message and prints a local explanation. Never splits or truncates it to make the accent fit.
- Uses a supported pre-send notification. Missing API support produces a login notice rather than replacing protected send functions. Hook registration alone is not proof that a changed beta client will dispatch the event.

## Validation and in-game check

After installing:

1. Run `/dwarf preview Hello friend, are you ready to go?` and check the example above.
2. Send `/s Hello friend, are you ready to go?` somewhere appropriate and check the received line.
3. Whisper someone you choose with an item link and confirm the recipient and link remain correct.
4. Send `/s ~~ You are ready.` and check that it stays unchanged.
5. Run `/dwarf off`, send a test line, then `/dwarf on`.
6. Test your usual party/guild channels and test during combat. If conversion is blocked, use `/dwarf off`; this addon does not bypass client restrictions.
7. Reload and check `/dwarf status` to see whether this beta build restores saved settings.

To uninstall, close WoW and remove only the `DwarfTranslator` folder from AddOns. To customize vocabulary, edit the tables in `Accent.lua`, then reload the UI.

