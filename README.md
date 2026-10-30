# Dwarf Translator

Give your chat a little dwarven character. Dwarf Translator changes the words you type into a readable Warcraft dwarf accent, using a translation list you can make your own.

> Hello my friend! Are you coming with my family today?
>
> Hullo mi mate! Are ye comin' wi' mi kin todae?

Other players don't need the addon to see your translated messages.

## Getting started

1. Put the `DwarfTranslator` folder in your game's `Interface\AddOns` folder.
2. Start WoW and enable **Dwarf Translator** in the AddOns list.
3. Chat normally. The addon starts enabled and applies the accent when you send a message.
4. Type `/dwarf settings` to choose your preferences.

After updating an existing installation, type `/reload` to load the changes. Restart WoW after the first installation.

## Make it yours

Open **Settings > AddOns > Dwarf Translator**, or right-click the dwarf minimap icon.

- **General settings:** turn the addon on or off, choose the chat types it translates, enable Always Dwarvish, and choose a male or female dwarf icon. You can also hide or show the minimap button.
- **Translations:** add words, change replacements, or remove words you don't want translated. Changes apply immediately.
- **Preview:** try an editable sample or your own text and see the translated result without sending anything. **Reset sample text** brings back the example.
- **Import / Export:** copy your translation list to share with friends or save as a backup. Paste an exported list to import it. A confirmation warns you before replacing your current list.

Your preferences and custom translations are saved per character. Updating the addon keeps edits made through the in-game settings, including removed translations. Use the in-game editor for personal changes; edits made directly to the bundled files can be overwritten by updates.

Want to start fresh? **Reset translations** in the Translations section restores the installed addon's default list after a confirmation. It clears custom words, edits, and removals while keeping your other addon options.

## Accent or actual Dwarvish?

The accent changes the spelling of your message. **Always Dwarvish** also requests WoW's actual Dwarvish language for Say and Yell. Your character must know that language, and WoW decides which players understand it.

You can switch language for a single Say or Yell message with `d:`:

| Always Dwarvish | What `d: Hello my friend` does |
| --- | --- |
| Off | Applies the accent and sends in Dwarvish |
| On | Applies the accent and sends in Common |

The prefix is removed before sending, and the previous language is restored afterward. Your character must know the requested language. These shortcuts require the addon and chat type to be enabled.

Start a message with `~~ ` to skip both the accent and automatic language switching once.

## Minimap shortcuts

| Action | What it does |
| --- | --- |
| Left-click | Toggle Always Dwarvish |
| Left-drag | Move the button around the minimap; position saves per character |
| Right-click | Open settings |
| Alt + right-click | Hide the minimap button |

A yellow ring means Always Dwarvish is on. A red ring means the addon is off. No ring means the addon is on with Always Dwarvish off. To bring back a hidden button, open `/dwarf settings` and enable **Show minimap button**.

## Translate a mail draft

On the mailbox's **Send Mail** tab, click the dwarf icon beside the tab. Its tooltip says **Translate to Dwarf**.

This applies your accent translations to the message body so you can review it before sending. It leaves the recipient, subject, attachments, and money alone. It doesn't send the mail or select a racial language. This manual tool is available independently of automatic chat translation.

## During combat

Blizzard sometimes restricts what addons can change in chat. During combat or chat restrictions, Dwarf Translator leaves your outgoing message alone and pauses both accent changes and automatic language switching.

When a change is skipped, you may see:

> Combat pause: sending without translation or language switch.

The notice is local and limited to once every 30 seconds. Messages that don't need changes stay quiet. Sending remains handled by WoW; the notice doesn't confirm delivery.

While paused, `d:` and `~~` stay in the message as typed, and WoW uses its currently selected language. Processing resumes when restrictions end.

## Chat commands

| Command | What it does |
| --- | --- |
| `/dwarf` or `/dwarf help` | Show help |
| `/dwarf on` | Enable Dwarf Translator |
| `/dwarf off` | Disable Dwarf Translator |
| `/dwarf settings` | Open addon settings |
| `/dwarf status` | Show addon state and chat restriction status |

`/dwarftranslator` also works in place of `/dwarf`.

## A few things to know

The addon uses word replacements rather than rewriting whole sentences. Item links, URLs, and other supported chat formatting are preserved. It works with WoW's normal chat input; messages sent by macros or other addons may not pass through it.
