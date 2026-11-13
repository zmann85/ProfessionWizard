**The cheapest way to level every crafting profession, from your own auction house prices, with a shopping list that counts your bags, bank, mail and alts.**

CraftList works out which recipe to craft at each skill point so that levelling a profession costs as little as possible, then tells you exactly what to buy and what you already have.

---

## What it does

- **The cheapest route** for Alchemy, Blacksmithing, Leatherworking, Tailoring, Engineering, Enchanting, Cooking, First Aid, Poisons and Mining's smelts. Each step weighs what the materials cost, how likely a skill-up is at that colour, what the result sells to a vendor for, and whether making a reagent yourself is cheaper than buying it.
- **A material checklist** that counts your **bags, bank, mailbox and alts**, and lists what's left to buy.
- **Your own prices**: click **SCAN AH** at the auction house, or let CraftList use Auctionator's.
- **Alts help out**: an alt sees what a crafter is missing and sends it with one click at the mailbox.
- **Craft from the list**: CRAFT, MAKE, SMELT and SMELT ALL buttons.
- **Opens with your profession window**, right next to it, with a **minimap button** and a short **first-time walkthrough**. If your prices are missing or old it tells you to scan first.
- **Learns as you play**: the recipes you know, recipe colours from the profession window, and vendor prices.

---

## How to use it

1. Unzip the download into `Interface\AddOns`. You get two folders: **CraftList** and **CraftList_Data** (the recipe data). Keep both.
2. Open each profession window once, so CraftList knows which recipes you have.
3. Log in on your alts once and open their bank and mailbox, so their items are counted.
4. At the auction house, click **SCAN AH** in the CraftList window.
5. `/cl` opens the list. Craft down the route.

---

## Commands

| Command | |
|---|---|
| `/cl` | open or close the list |
| `/cl tailoring` | show another profession (or `alch`, `smith`, `leather`, `eng`, `ench`, `cook`, `first`, `poisons`) |
| `/cl 225` | check materials up to skill 225 |
| `/cl alts` / `forget Name` | the alts it's counting / stop counting one |
| `/cl auto` | open (or not) with your profession windows |
| `/cl tutorial` | the first-time walkthrough again |
| `/cl minimap` | show or hide the minimap button |
| `/cl reset` | forget where you dragged the window, so it opens next to the profession window again |
| `/cl debug` | what CraftList sees in the open profession window |

---

This is a beta. Questions and bug reports are welcome in the comments; `/cl debug` output helps a lot.
