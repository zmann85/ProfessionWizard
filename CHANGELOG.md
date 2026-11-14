# Changelog

## Unreleased

### Fixed
- Thorium Greatsword was planned as taught by trainers. It needs Plans: Thorium Greatsword, so the route only
  uses it when the plans are on the auction house or at a vendor. Click FIND CHEAPEST ROUTE to plan around it.

## v1.0.0 (2026-11-14)

First full release.

### Changed
- The mailbox panel's button fills the mail (the crafter's name, a subject and what it needs from your bags) and
  leaves sending to you: FILL MAIL, check it, click Send. What you send still counts on the crafter's list. With
  more than 12 stacks, fill and send again.

### Fixed
- Profession Wizard didn't load at all ("main function has more than 200 local variables"). The code is
  reorganised to stay well inside Lua's limit.
- A batch the game ended without saying so (out of materials, stopped in the profession window, after a
  disconnect) stayed "running": the bar stuck at e.g. 78 / 104 and every CRAFT or SMELT answered "already
  crafting". Casting nothing for a few seconds now ends it ("stopped after 78").
- What you buy out at the auction house counts straight away, as on the way to you, not only once you've
  taken it out of the mailbox. A crafter's list viewed on an alt (LISTS) counts that alt's mail too, says how much
  of "send" is still in the mail, and counts its finished bars for the ore the crafter would smelt.
- The mailbox panel showed on the Inbox tab too. It's only on Send Mail now, opening and closing with that tab.
- The mailbox panel kept a gap for another addon's panel even when that wasn't showing. It sits right next to
  the mail window unless something else is there.
- Alts only offered the ore for bars the crafter smelts itself, not the bars they already have. Finished items
  (bars, grinding stones ...) are now sent first, then the material for the rest. The crafter's list has to be
  saved once more for this (log in on it).
- Your crafters' lists never reached your alts: logging out saved every character's bags and skills as empty
  (that's how the game reports them by then), and the crafter's lists were deleted with them. Nothing is saved
  at logout any more, and an empty read never replaces what was saved before. Log in on each crafter once
  (open its profession window) to save its list again.

## v0.4.1-beta (2026-11-14)

### New
- Recipes that aren't taught by trainers show what the recipe costs on their route line ("recipe ~1g 20s AH", or
  "vendor", or "no price yet"), also before you can learn them. The tooltip has the details, and clicking the line
  searches the auction house for the recipe (shift-click links it).

### Fixed
- The list opened noticeably after the profession window. It now opens with it and reads the window's recipes
  right after.
- The summary under the materials (still to buy, the whole route's cost) was squeezed next to the buttons and cut
  off. It now has its own lines across the window, with the buttons in a row underneath.

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
