# Changelog

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
- SCAN AH in the CraftList window prices the route's reagents at the auction house. Auctionator's prices are
  used when there's no recent scan.
- Lists: each crafter's missing materials, so an alt can see what to send it, and a mailbox panel that sends
  them in one click.
- CRAFT, MAKE and SMELT buttons, and SMELT ALL for every smelt the route needs.
- CraftList learns as you play: the recipes you know, a recipe's colours when the profession window shows
  them differently, and vendor prices when you open a vendor.

### Known
- SCAN AH, SMELT ALL and the OPEN buttons are new and not much tested yet. `/cl debug` shows what CraftList
  sees in the open profession window; please paste it into a comment if something doesn't work.
- Trainer costs aren't counted in a route's cost yet.
