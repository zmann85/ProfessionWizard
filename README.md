<p align="center"><img src="logo.svg" width="128" alt="Profession Wizard logo"></p>

<h1 align="center">Profession Wizard</h1>
<p align="center"><b>The cheapest way to level every crafting profession, from your own auction house prices, with a shopping list that counts your bags, bank, mail and alts.</b><br>
A WoW Forever addon.</p>

<p align="center"><a href="https://github.com/zmann85/ProfessionWizard/releases/latest"><b>⬇️ Download the latest version</b></a> &nbsp;·&nbsp; <a href="CHANGELOG.md">What's new</a></p>

## Install
1. Open the [latest release](https://github.com/zmann85/ProfessionWizard/releases/latest) and download the `ProfessionWizard-…zip` file under **Assets**.
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns\`. You get two folders: **ProfessionWizard** and **ProfessionWizard_Data** (the recipe data). Keep both.
3. Start the game or type `/reload`.

To update, repeat this and replace both folders. Your settings, prices and alts are kept.

## What it does
For every crafting profession Profession Wizard works out which recipe to craft at each skill point so that
levelling costs as little as possible. It weighs what the materials cost at the auction house (or a vendor),
how likely a skill-up is at that colour, what the result sells to a vendor for, and whether making a reagent
yourself (smelting the bars, say) is cheaper than buying it.

The route comes with a material checklist: how much of each reagent you need, how much you already have in
your bags, bank, mailbox and on your alts, and what's left to buy. Alts can see what a crafter is missing and
send it with one click at the mailbox.

## Use
1. Open each profession window once, so Profession Wizard knows which recipes you have.
2. Log in on your alts once and open their bank and mailbox, so their items are counted.
3. At the auction house, click **SCAN AH** in the Profession Wizard window (or scan with Auctionator).
4. The list opens with your profession window (or click the minimap button, or `/pw`). Click **FIND CHEAPEST ROUTE** and craft down the route.

The first time the list opens, a short walkthrough shows where everything is.

## Commands
| Command | |
|---|---|
| `/pw` | open or close the list |
| `/pw tailoring` | show another profession (or `alch`, `smith`, `leather`, `eng`, `ench`, `cook`, `first`, `poisons`) |
| `/pw 225` | check materials up to skill 225 |
| `/pw alts` / `forget Name` | the alts it's counting / stop counting one |
| `/pw auto` | open (or not) with your profession windows |
| `/pw tutorial` | the first-time walkthrough again |
| `/pw minimap` | show or hide the minimap button |
| `/pw reset` | forget where you dragged the window, so it opens next to the profession window again |
| `/pw debug` | what Profession Wizard sees in the open profession window (paste this in a bug report) |
| `/pw help` | all commands |

## License
Profession Wizard is all rights reserved (see [LICENSE.txt](LICENSE.txt)). The recipe data in `ProfessionWizard_Data` is a
separate add-on under the GNU GPL v2 (see [ProfessionWizard_Data/LICENSE.txt](ProfessionWizard_Data/LICENSE.txt)).
