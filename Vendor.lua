local _, ns = ...

-- Reagents sold by trade supply vendors. Until you've seen one at a vendor, its price is
-- taken as 4x what the vendor pays for it (how Classic vendor prices work for these).
-- Every vendor you open is read too, so this list fills in by itself (/pw vendors).
ns.VENDOR_ITEMS = {}
for _, id in ipairs({
  2320, 2321, 4291, 8343, 14341,             -- threads
  2880, 3466, 18567,                         -- flux
  3371, 3372, 8925, 18256,                   -- vials
  2678, 2692, 3713, 159, 1179, 2596, 4536,   -- cooking
  17194, 17196,                              -- holiday spices and spirits
  4289,                                      -- salt
  2324, 2604, 6260, 2605, 4340, 6261, 2325, 4342, 10290, -- bleach and dyes
  6217, 4470, 4399, 4400, 11291,             -- rods and wood
  10647, 10648,                              -- engineer's ink, blank parchment
  2930, 5173, 8923, 8924, 2931,              -- poison reagents
}) do ns.VENDOR_ITEMS[id] = true end

-- Trainer recipes that the ordinary profession trainers don't teach: where to learn them instead.
-- The route shows these as "special trainer", the tooltip says who.
ns.TRAINER_NOTES = {
  -- the Discolored Healing Potion line (new in WoW Forever)
  [1244645] = "the Odd Child in Westfall (Alliance) or Apothecary Renferrel at the Sepulcher in Silverpine Forest (Horde), after a short questline",
  [1244646] = "the Odd Child in Westfall (Alliance) or Apothecary Renferrel at the Sepulcher in Silverpine Forest (Horde), after a short questline",
  [1244647] = "the Odd Child in Westfall (Alliance) or Apothecary Renferrel at the Sepulcher in Silverpine Forest (Horde), after a short questline",
  [1244648] = "the Odd Child in Westfall (Alliance) or Apothecary Renferrel at the Sepulcher in Silverpine Forest (Horde), after a short questline",
  -- taught by a quest, not a trainer (timesaver.gg, 19 Nov 2026)
  [19435] = "the quest Sacred Cloth",
  -- no trainer teaches these and their source isn't confirmed
  [11447] = "a quest or special source (not confirmed)",
  [22430] = "a quest or special source (not confirmed)",
  [26011] = "a quest or special source (not confirmed)",
}

-- recipes in the client data that nothing is known to teach in WoW Forever: routes never use them
ns.NO_SOURCE = {
  [12719] = true, -- Explosive Arrow
  [12900] = true, -- Mobile Alarm
}

-- recipes with a cooldown (besides every Transmute): routes and material plans never use them
ns.COOLDOWN = {
  [18560] = true, -- Mooncloth
  [19047] = true, -- Cured Rugged Hide (Salt Shaker)
}
