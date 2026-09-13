# You Died (World of Warcraft Addon)

**"You Died"** is a World of Warcraft death recap addon that shows you exactly which life saving cooldowns you had available when you died.

Instead of showing you a generic combat log of what killed you, this addon reminds you of all the defensive cooldowns, healthstones, and potions you *could* have used to save yourself. 

## Features

- **Available Defensives**: Display which defensives you had available when you die. Adjusts to talents you select. Also includes potions and Healthstones. Supports all classes and specs.
- **Dynamic Health Potions**: Automatically scans your bags to find and track your highest Item Level healing potion. Should be future proof for when new health potions come out.
- **100% Language Agnostic**: Works for all languages. There are apparently more languages than English.
- **Healing Potion Reminder**: If you die without any healing potions in your bags at all, the addon will make sure to remind you to stock up.
- **Configurable Environments**: Includes a settings menu (`Esc -> Options -> Addons -> You Died`) to selectively enable or disable the UI in:
  - Dungeons
  - Raids
  - Delves / Scenarios
  - Open World
  - Arenas
  - Battlegrounds

## Installation

1. Download the latest release.
2. Extract the `YouDied` folder into your World of Warcraft addons directory:
   `_retail_\Interface\AddOns\YouDied`
3. Launch the game and ensure the addon is enabled.

## Commands

- `/youdied` - Forces the UI to appear anywhere, anytime, so you can test and preview the layout without having to jump off a cliff.
- `/youdied options` (or `config`, `settings`) - Instantly opens the Interface Options panel to the You Died settings page.

## Future Updates (Roadmap)

This is new, immediate roadmap will be fixing bugs and incorporating user feedback. Beyond that:
- **Raid Review**: Review deaths after a raid wipe and see what you (and your team) could have done to survive.

## Can't Do

- **Avoidable Damage**: I wanted to add a feature that would show how much avoidable damage you took when you died, but unfortunately this isn't possible with the current API. 
