# Changelog

## v0.4.0-beta (2026-11-14)

### New
- Enchanting: CRAFT puts the enchant straight onto the cheapest matching item in your bags (a bracer for
  Enchant Bracer, a cloak for Enchant Cloak ...; grey or white items first, never gear you're wearing) and
  confirms replacing its old enchant for that item only. The route shows which item each enchant goes on, or
  that you need a cheap one in your bags. If the game won't let the enchant be put on the item for you, you keep
  the targeting hand and the chat says which item to click.

### Fixed
- SETTINGS and LISTS sat on top of each other in the top right corner.
- The list didn't open next to the profession window: that placement never ran.
- Taking more than a moment to pick the item for an enchant counted as "didn't start".
- In the newer profession window an enchant could be started several times at once. Enchants now always go one
  at a time.

## v0.3.0-beta (2026-11-14)

First release on CurseForge (beta).

### New
- The cheapest skill-up route for every crafting profession (Alchemy, Blacksmithing, Leatherworking,
  Tailoring, Engineering, Enchanting, Cooking, First Aid, Poisons, and Mining's smelts), worked out from
  your auction house prices: for each skill point the recipe that costs least per point, counting the chance
  of a skill-up, what the result sells to a vendor for, and whether making a reagent yourself is cheaper than
  buying it.
- A material checklist for the route that counts your bags, bank, mailbox and alts (and what GoldSense has
  recorded), and lists what's left to buy.
- SCAN AH in the Profession Wizard window prices the route's reagents at the auction house. Auctionator's prices are
  used when there's no recent scan.
- Lists: each crafter's missing materials, so an alt can see what to send it, and a mailbox panel that sends
  them in one click.
- CRAFT, MAKE and SMELT buttons, and SMELT ALL for every smelt the route needs.
- A first-time walkthrough the first time the list opens: your target skill, prices (SCAN AH), FIND CHEAPEST
  ROUTE, the switches, and how to read the route. SETTINGS > SHOW TUTORIAL or `/pw tutorial` plays it again.
- A hint above the route while its materials have no auction house prices yet, or only ones older than a day:
  where to go and what to click (it knows whether you have Auctionator and whether you're at the auction house).
- The list opens with your profession window (SETTINGS > OPEN WITH PROFESSIONS) and, until you drag it
  somewhere, right next to it. Each character keeps its own place; `/pw reset` forgets it.
- A minimap button (SETTINGS > MINIMAP BUTTON or `/pw minimap` to hide it).
- Profession Wizard learns as you play: the recipes you know, a recipe's colours when the profession window shows
  them differently, and vendor prices when you open a vendor.

### Known
- SCAN AH, SMELT ALL and the OPEN buttons are new and not much tested yet. `/pw debug` shows what Profession Wizard
  sees in the open profession window; please paste it into a comment if something doesn't work.
- Trainer costs aren't counted in a route's cost yet.
