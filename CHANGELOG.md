# Changelog

## v1.9.0 (2026-11-23)

### Added
- Plan a profession you haven't learned: click + next to the profession buttons and pick one. You get its route,
  materials and shopping list from skill 1 (SEARCH MISSING and the lists for your alts work too). It shows with a
  "?" until you learn it; right-click its button to remove it.

- Settings: LOW UPFRONT (off by default). The route is picked mostly by what its materials cost you now; what the
  crafts sell for (vendor, or the AH with AH RETURNS on) counts only partly. Click to step through 0%, 25%, 50%
  and 75% of the sale counting (right-click steps back).

### Fixed
- Characters are told apart by their full name. WoW Forever characters can share a first name (Ghaani Block and
  Ghaani Shield), and Profession Wizard mixed up their known recipes, routes, bags and crafter lists. Saved
  characters and crafter lists under a first name alone are dropped once; they come back as each one logs in (or
  right away from GoldSense). Your routes, targets and window place carry over.
- Mail to your alts counts on the right one: by full name, or by first name only when just one has it.

## v1.8.0 (2026-11-23)

### Added
- Settings: AH RETURNS (off by default). What you craft counts at its auction house price, less the 5% cut, where
  that beats the vendor, so recipes whose results sell well get cheaper in the route. Items that bind on pickup
  still count at the vendor price. SCAN AH then looks up the crafted items too.

## v1.7.3 (2026-11-23)

### Added
- Hovering a craft step lists the materials it uses for all its crafts, with how many you have of each (green when
  you have enough).

## v1.7.2 (2026-11-22)

### Fixed
- The "no prices yet, scan the AH" warning showed right after a full Auctionator scan. It counted the recipes you
  could buy and every material any recipe could use, many of which nobody lists. With a route it now checks just
  the auction house materials the route uses; without one it leaves the recipes out.

## v1.7.1 (2026-11-19)

### Fixed
- LEARN AT TRAINER never learned anything: WoW Forever's trainer list gives its entries in a different order than
  Classic, so no recipe ever looked "available". It reads both now.
- LEARN AT TRAINER learns everything due in one go (it waited for the list to update after each one), and the
  trainer window gets a LEARN FOR ROUTE button that does the same with a click.
- LEARN AT TRAINER could miss the trainer's list when it wasn't filled in yet as the window opened; it now looks
  again a moment later, and says in chat if something goes wrong. `/pw trainer` lists what it sees.

## v1.7.0 (2026-11-19)

### Added
- Talking to a trainer learns the recipes your routes use that it can teach you now, and the next rank when a
  route goes past your cap. Each one is listed in chat with its cost; nothing is bought you can't afford.
  Settings: LEARN AT TRAINER (on by default).
- Settings: USE WHAT I HAVE (off by default). Materials you already own count as free until they run out, so the
  route spends them before anything you'd have to buy. What counts follows COUNT BANK, COUNT ALTS and COUNT MAIL.

### Fixed
- Recipes stayed "known" after dropping a profession and learning it again, so a fresh Alchemy could still plan the
  Discolored potions as known (special trainers off or not). Known recipes are now checked against the
  character's spells.
- A route marked out of date (after changing SPECIAL TRAINERS, USE WHAT I HAVE or a data fix) kept showing the
  old steps until you clicked FIND CHEAPEST ROUTE, so the Discolored potions could stay in it with special
  trainers off. It's now worked out again by itself.
- Camping recipes (Mana Well, Camp Tent, Sharpening Wheel, the campfires, Anvil, Loom and the rest) are left out
  of routes: they give no skill points. Saved routes show as out of date.

## v1.6.0 (2026-11-19)

### Added
- Training costs count toward the route. Each trainer recipe carries its fee (shown next to "trainer" on its step
  and in its tooltip), so a cheap recipe with a dear fee can lose to a better one, and every TRAIN row adds the
  rank's price (Journeyman 5s, Expert 50s, Artisan 5g). "Whole route" now covers materials, recipes and training.
- Trainer windows you open are read, so their real fees replace the built-in ones from then on.

### Changed
- The window no longer grows past 10 craft steps and 12 materials: both lists scroll with the mouse wheel, and
  their headings show which part you're looking at (e.g. "1-10 of 14").

### Fixed
- A recipe the route came back to later was paid for twice in "Whole route".
- "Whole route" only added up the steps that fit on screen, so on a long route it could be less than "Still to
  buy". It now covers every step.
- "a Alchemy trainer" now reads "an Alchemy trainer".

## v1.5.0 (2026-11-19)

### Added
- Routes stop at your rank cap. A step that went from 137 to 163 is now 137-150, then a TRAIN EXPERT row that
  names the trainer for your faction (or the book or quest for Cooking and First Aid) and the level needed,
  then 150-163. CRAFT stays hidden on steps past your cap, so no crafts and materials are wasted at 150.
- Trainer recipes past 150 or 225 name a trainer of that rank in their tooltip, since city trainers of a lower
  rank don't teach them.

- SEARCH MISSING also searches the recipes your route needs from the auction house (the ones you don't know or
  carry yet; vendor recipes stay out).

### Fixed
- Trade supply items (vials, thread, flux, spices...) are bought from the vendor unless the AH is at least 20%
  cheaper. Crystal Vials showed as an AH buy because the AH was a few copper under the vendor's 5s.
- Routes no longer use recipes with a cooldown: every Transmute (Iron to Gold was planned for 225-271), Mooncloth
  and Cured Rugged Hide. They aren't used to make materials either. Saved routes show as out of date.
- At a cap of 150 the header said "train Artisan (level 35)"; it now says Expert (level 20).

## v1.4.0 (2026-11-19)

### Added
- Settings: SPECIAL TRAINERS (on by default). Switch it off and routes only use recipes from the usual trainers,
  recipes you know and bought recipes, never ones that need a questline or a single NPC somewhere.

### Fixed
- Checked every recipe against a second WoW Forever source (timesaver.gg) and corrected 123 of them. Learn levels
  only ever went up, so no route plans a recipe before you can learn it. Among them the First Aid healing potions
  (Minor 55, Lesser 85, Healing Potion 135), the First Aid Kit, poultices and tourniquets, the new chain and leather sets, the dyes, Shining Mithril
  Helm, Prefect's Waistguard, the Hearts of the Mountain, the weaponsmith and Dark Iron 300 plans, and most of the
  new cooking recipes, whose colours were also wrong (Swiftstrike Steak and Clam Linguine are 280 recipes, not 175).
- Mooncloth Boots come from the quest Sacred Cloth, not a trainer. Draught of Water Walking, Refined Scale of
  Onyxia and Tranquil Mechanical Yeti have no trainer either and show as special. Explosive Arrow and Mobile Alarm
  are left out of routes: nothing is known to teach them.
- The Discolored Healing Potion line (Lesser, normal, Greater, Superior) isn't taught by the usual alchemy
  trainers: the route now says "special trainer" and the tooltip names them (the Odd Child in Westfall or
  Apothecary Renferrel in Silverpine Forest, after a short questline). They were also planned 25 skill too early
  (Lesser Discolored Healing Potion is learned at 85, not 60). Saved routes show as out of date once more.

## v1.3.1 (2026-11-19)

### Fixed
- 25 trainer recipes could be planned before a trainer teaches them. Among them Mana Well and the other new
  camping recipes (Sharpening Wheel, Enchanted Lute, Reagent Bot, Camp Tent, Faction Banner: 20, not 1), the
  dyes, Sulfuric Acid, Elixir of Minor Strength, the bronze weapons, Medium Armor Kit and the weaponsmith swords
  (The Shatterer, Phantom Blade, Blight, Truesilver Champion). Saved routes show as out of date once more.

## v1.3.0 (2026-11-19)

### New
- With Auctionator, SEARCH MISSING and clicking a material search for the amount you still need, so Auctionator's
  buy screen starts at that amount (a recipe line: 1). In a crafter's list on an alt, it's the amount to buy.

## v1.2.3 (2026-11-18)

### Fixed
- SCAN AH, checked against Auctionator's prices (they agree for materials) and how Auctionator searches:
  - Recipes and other single items were priced 15-20 times too cheap (the price per item was divided by the
    listing's quantity again).
  - Items the game hadn't loaded yet were often skipped: the game ignores those searches. The scan now waits for
    the item first and tries it again at the end if it doesn't come.
  - An empty or incomplete first answer counted as "not on the auction house"; the scan now asks again.
- SCAN AH skipped everything scanned in the last hour. It now looks everything up again every time.

## v1.2.2 (2026-11-18)

### Fixed
- A recipe you learned while the profession window was open (from a recipe item in your bags) only got its count
  and CRAFT button after the list was reopened. The list now updates right after.

## v1.2.1 (2026-11-18)

### Fixed
- SCAN AH didn't work in WoW Forever ("stopped after 0 items"): Forever's auction house looks like Classic's but
  is the modern one underneath. The scan now uses the modern auction house's search (one item at a time, waiting
  for the game's throttle), and still the Classic one on clients that have it. SEARCH MISSING without
  Auctionator also fills the modern auction house's search box.

## v1.2.0 (2026-11-14)

### Fixed
- 39 more recipe sources, checked against wowcraft.io's WoW Forever data: the new Forever chain sets (Veteran's,
  Guard's, Protector's, Acolyte's, Crusader's), the leather Helm/Pants/Armor sets, Shining Mithril Helm,
  Prefect's Waistguard, Greater Mender's Potion, the Heart of the Mountain variants and the 9-60 Battery Pack
  are taught by recipe items, not trainers. Elixir of Minor Fortitude is a trainer recipe (it was tied to a
  recipe item that never existed). Saved routes show as out of date once more.

### New
- SETTINGS > MAILBOX PANEL switches the panel next to Send Mail on or off (on by default).
- SETTINGS > Color scheme: Copper, Itinerary, Amethyst, Frost, Ember and Slate, the same schemes as Itinerary.
  Picking one reloads the UI. Until you pick one, Profession Wizard uses Itinerary's scheme when Itinerary is
  installed (SAME AS ITINERARY switches back to that), otherwise Copper.

## v1.1.0 (2026-11-14)

### Changed
- Materials you only need to make something else on the list (ore for the bars you smelt, stone for grinding
  stones) are an indented line under that item. When a recipe needs some of it as it is, that part keeps its own
  line; what you have counts toward that first.

## v1.0.1 (2026-11-14)

### Fixed
- 45 recipes were planned as taught by trainers although they need plans, a pattern or a recipe item, so a
  route could have you buy materials for a recipe no trainer teaches. Among them Ornate Mithril Breastplate, Boots
  and Helm, Bleakwood Hew, Inlaid Thorium Hammer, Rune Edge, Ironforge Chain and Gauntlets, Orcish War Leggings,
  Green Woolen Robe and Boots of Darkness. A route now only uses them when you know the recipe or its item is on
  the auction house or at a vendor. Saved routes show as out of date: click FIND CHEAPEST ROUTE.
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
