# You Died (World of Warcraft Addon)

**"You Died"** is a World of Warcraft death recap addon that shows you exactly which life-saving cooldowns you had available when you died.

Instead of showing you a generic combat log of what killed you, this addon pops up a stylistic, semi-transparent banner upon your death to gently (or not so gently) remind you of all the defensive cooldowns, healthstones, and potions you *could* have used to save yourself. 

## Features

- **Dark Souls-Style UI**: A sleek, click-to-dismiss UI that appears upon death.
- **Taint-Free Cooldown Tracking**: Fully bypasses modern WoW secure API restrictions by using a robust, custom Combat Log background tracker.
- **Talent & Override Aware**: Correctly tracks your defensive cooldowns even if they are modified by talents (e.g., hidden spell IDs).
- **Dynamic Potion Resolution**: Automatically scans your bags to find and track your highest Item Level healing potion.
- **100% Language Agnostic**: Uses dynamic spell queries and global strings instead of English names, meaning it works flawlessly out-of-the-box on French, German, Spanish, and all other WoW client languages.
- **Tough Love**: If you die without any healing potions in your bags at all, the addon will make sure to remind you to stock up.
- **Configurable Environments**: Includes a settings menu (`Esc -> Options -> Addons -> You Died`) to selectively enable or disable the UI in:
  - Dungeons
  - Raids
  - Delves / Scenarios
  - Open World
  - Arenas
  - Battlegrounds

## Current Class Support

The addon fully supports **All 13 Classes**, covering over 70 unique defensive cooldowns across:
Death Knight, Demon Hunter, Druid, Evoker, Hunter, Mage, Monk, Paladin, Priest, Rogue, Shaman, Warlock, and Warrior (alongside generic items like Healthstones and Potions).

## Installation

1. Download the latest release.
2. Extract the `YouDied` folder into your World of Warcraft addons directory:
   `_retail_\Interface\AddOns\YouDied`
3. Launch the game and ensure the addon is enabled.

## Commands

- `/youdied` - Forces the UI to appear anywhere, anytime, so you can test and preview the layout without having to jump off a cliff.

## Future Updates (Roadmap)

This is new, immediate roadmap will be fixing bugs and incorporating user feedback. Beyond that:
- **Raid Review**: Review deaths after a raid wipe and see what you (and your team) could have done to survive.

## Can't Do

- **Avoidable Damage**: I wanted to add a feature that would show how much avoidable damage you took when you died, but unfortunately this isn't possible with the current API. 
