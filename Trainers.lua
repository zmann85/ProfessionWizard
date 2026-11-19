local _, ns = ...

-- Who teaches the next profession rank in WoW Forever, by the skill cap that rank lifts:
-- 75 = Journeyman, 150 = Expert, 225 = Artisan. A = Alliance, H = Horde.
-- From warcrafttavern.com's and wow-professions.com's WoW Forever trainer lists (19 Nov 2026).
ns.RANKS = {
  { cap = 75,  name = "Journeyman", skill = 50,  level = 10 },
  { cap = 150, name = "Expert",     skill = 125, level = 20 },
  { cap = 225, name = "Artisan",    skill = 200, level = 35 },
}

local JOURNEYMAN = "a %s trainer in a capital city"

ns.RANK_TRAINERS = {
  [171] = { -- Alchemy
    [150] = { A = "Ainethil in Darnassus, or Linzy Blackbolt in Dalaran", H = "Doctor Herbert Halsey in Undercity" },
    [225] = { A = "Kylanna Windwhisper at Feathermoon Stronghold, Feralas", H = "Rogvar in Stonard, Swamp of Sorrows" },
  },
  [164] = { -- Blacksmithing
    [150] = { A = "Bengus Deepforge in Ironforge, or Alard Schmied in Dalaran", H = "Saru Steelfury in Orgrimmar" },
    [225] = { A = "Brikk Keencraft in Booty Bay, Stranglethorn Vale", H = "Brikk Keencraft in Booty Bay, Stranglethorn Vale" },
  },
  [333] = { -- Enchanting
    [150] = { A = "Kitta Firewind in the Tower of Azora, Elwynn Forest", H = "Hgarth at Sun Rock Retreat, Stonetalon Mountains" },
    [225] = { A = "Annora inside Uldaman", H = "Annora inside Uldaman" },
  },
  [202] = { -- Engineering
    [150] = { A = "Springspindle Fizzlegear in Tinker Town, Ironforge", H = "Roxxik in Orgrimmar" },
    [225] = { A = "Buzzek Bracketswing in Gadgetzan, Tanaris", H = "Buzzek Bracketswing in Gadgetzan, Tanaris" },
  },
  [165] = { -- Leatherworking
    [150] = { A = "Telonis in Darnassus", H = "Una in Thunder Bluff" },
    [225] = { A = "Drakk Stonehand in Aerie Peak, The Hinterlands", H = "Hahrana Ironhide at Camp Mojache, Feralas" },
  },
  [197] = { -- Tailoring
    [150] = { A = "Georgio Bolero in Stormwind, or Charles Worth in Dalaran", H = "Josef Gregorian in Undercity" },
    [225] = { A = "Timothy Worthington on Theramore Isle, Dustwallow Marsh", H = "Daryl Stack in Tarren Mill, Hillsbrad Foothills" },
  },
  [185] = { -- Cooking: a book and a quest instead of trainers
    [150] = { A = "the Expert Cookbook, sold by Shandrina at Silverwind Refuge, Ashenvale",
              H = "the Expert Cookbook, sold by Wulan in Shadowprey Village, Desolace" },
    [225] = { A = "the quest Clamlette Surprise from Dirge Quikcleave in Gadgetzan, Tanaris",
              H = "the quest Clamlette Surprise from Dirge Quikcleave in Gadgetzan, Tanaris" },
  },
  [129] = { -- First Aid: a book and a quest instead of trainers
    [150] = { A = "the Expert First Aid book, sold by Deneb Walker at Stromgarde Keep, Arathi Highlands",
              H = "the Expert First Aid book, sold by Balai Lok'Wein in Brackenwall Village, Dustwallow Marsh" },
    [225] = { A = "the quest Triage from Doctor Gustaf VanHowzen on Theramore Isle, Dustwallow Marsh",
              H = "the quest Triage from Doctor Gregory Victor in Hammerfall, Arathi Highlands" },
  },
}

-- the rank that lifts this cap, and where to get it for your faction: rank, where
function ns.rankInfo(pid, cap, profName)
  for _, rk in ipairs(ns.RANKS) do
    if rk.cap == cap then
      local t = (ns.RANK_TRAINERS[pid] or {})[cap]
      local f = UnitFactionGroup("player") == "Horde" and "H" or "A"
      local where = t and t[f]
      if not where and cap == 75 then where = string.format(JOURNEYMAN, profName or "profession") end
      return rk, where
    end
  end
end
