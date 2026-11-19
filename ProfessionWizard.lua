local ADDON, ns = ...
local L = {} -- helper functions live here: Lua 5.1 allows only 200 locals in the main chunk

-- The recipe data is a separate add-on (ProfessionWizard_Data, GPL v2) that loads after Profession Wizard and fills
-- ns.RECIPES through this global.
ProfessionWizardAPI = ns
ns.RECIPES = ns.RECIPES or {}
local DATA_ADDON = "ProfessionWizard_Data"

local CALLER = "ProfessionWizard"
local W, PAD, ROW_H, MAX_ROWS, STEP_H, MAX_STEPS = 620, 14, 20, 18, 16, 12
local X_NEED, X_HAVE, W_HAVE, X_STAT = 250, 318, 160, 490

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
local GetItemCountRaw = (C_Item and C_Item.GetItemCount) or _G.GetItemCount
local GetIcon = (C_Item and C_Item.GetItemIconByID) or _G.GetItemIcon

local DEFAULTS = { plans = true, bank = true, buffer = 10, alts = true, mail = true, auto = true }
-- ProfessionWizardDB.minimap (LibDBIcon: hide, minimapPos) and ProfessionWizardDB.posChar[name-realm] (where each character
-- last dragged the window) are set up at load.

-- a craft that only just pays for itself isn't worth the time: every craft counts as costing this much more
local PER_CRAFT = 50
-- recipes this close to grey are skipped: too many crafts per point
local MIN_CHANCE = 0.25

local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffdca77fProfession Wizard|r: " .. msg) end

---------------------------------------------------------------------------
-- Look: same flat style as GoldSense / SmithList / Itinerary
---------------------------------------------------------------------------
local SCHEMES = {
  copper    = { accent = { 220 / 255, 167 / 255, 127 / 255 }, warm = { 1, 0.82, 0.45 }, bg = { 0.077, 0.068, 0.058 }, btn = { 0.075, 0.113, 0.141 }, onAccent = { 0.05, 0.05, 0.05 } },
  itinerary = { accent = { 0.05, 0.82, 0.62 }, warm = { 1, 0.82, 0.45 }, bg = { 0.077, 0.068, 0.058 }, btn = { 0.075, 0.113, 0.141 }, onAccent = { 0.05, 0.05, 0.05 }, ellesmere = true },
  amethyst  = { accent = { 0.47, 0.27, 0.76 }, warm = { 0.80, 0.72, 1 }, bg = { 0.075, 0.07, 0.085 }, btn = { 0.15, 0.145, 0.16 }, onAccent = { 1, 1, 1 } },
  frost     = { accent = { 0.30, 0.65, 1 }, warm = { 0.72, 0.87, 1 }, bg = { 0.05, 0.065, 0.085 }, btn = { 0.075, 0.113, 0.141 }, onAccent = { 0.03, 0.05, 0.08 } },
  ember     = { accent = { 1, 0.45, 0.15 }, warm = { 1, 0.78, 0.48 }, bg = { 0.08, 0.06, 0.05 }, btn = { 0.15, 0.10, 0.08 }, onAccent = { 0.06, 0.03, 0.02 } },
  slate     = { accent = { 0.86, 0.86, 0.86 }, warm = { 1, 1, 1 }, bg = { 0.06, 0.06, 0.065 }, btn = { 0.14, 0.14, 0.15 }, onAccent = { 0.05, 0.05, 0.05 } },
}

-- in the order and with the names Itinerary's setting uses
L.SCHEME_ORDER = {
  { "copper", "Copper" }, { "itinerary", "Itinerary" }, { "amethyst", "Amethyst" },
  { "frost", "Frost" }, { "ember", "Ember" }, { "slate", "Slate" },
}

-- SETTINGS > Color scheme (ProfessionWizardDB.scheme). Not chosen: Itinerary's scheme when it's installed,
-- otherwise copper.
local function scheme()
  local key = ProfessionWizardDB and ProfessionWizardDB.scheme
  if not key or not SCHEMES[key] then
    key = ItineraryDB and ItineraryDB.panel and ItineraryDB.panel.scheme or "copper"
  end
  return SCHEMES[key] or SCHEMES.copper
end

local function accent()
  local s = scheme()
  if s.ellesmere then
    local g = EllesmereUI and EllesmereUI.ELLESMERE_GREEN
    if g and g.r then return g.r, g.g, g.b end
  end
  return s.accent[1], s.accent[2], s.accent[3]
end

local function fontPath()
  if EllesmereUI and EllesmereUI.GetFontPath then
    local ok, path = pcall(EllesmereUI.GetFontPath)
    if ok and path then return path end
  end
  return STANDARD_TEXT_FONT
end

local function hex(r, g, b) return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255) end

local function text(parent, size, r, g, b, a)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(fontPath(), size, "")
  fs:SetTextColor(r, g, b, a or 1)
  fs:SetJustifyH("LEFT")
  fs:SetWordWrap(false)
  return fs
end

local function edges(frame, r, g, b, a)
  local px = 1 / (frame:GetEffectiveScale() or 1)
  local set = {}
  local function edge() local t = frame:CreateTexture(nil, "BORDER"); t:SetColorTexture(r, g, b, a); set[#set + 1] = t; return t end
  local t = edge(); t:SetPoint("TOPLEFT"); t:SetPoint("TOPRIGHT"); t:SetHeight(px)
  local bo = edge(); bo:SetPoint("BOTTOMLEFT"); bo:SetPoint("BOTTOMRIGHT"); bo:SetHeight(px)
  local l = edge(); l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT"); l:SetWidth(px)
  local ri = edge(); ri:SetPoint("TOPRIGHT"); ri:SetPoint("BOTTOMRIGHT"); ri:SetWidth(px)
  function set:SetColor(...) for _, e in ipairs(self) do e:SetColorTexture(...) end end
  return set
end

local function chip(parent, label, w, template, name)
  local b = CreateFrame("Button", name, parent, template)
  b:SetSize(w, 20)
  b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
  b.edges = edges(b, 1, 1, 1, 0.18)
  b.text = text(b, 11, 1, 1, 1, 0.5)
  b.text:SetPoint("CENTER"); b.text:SetText(label)
  function b:SetActive(on)
    local s = scheme()
    if on then
      local ar, ag, ab = accent()
      self.bg:SetColorTexture(ar, ag, ab, 0.9); self.edges:SetColor(ar, ag, ab, 1)
      self.text:SetTextColor(s.onAccent[1], s.onAccent[2], s.onAccent[3], 1)
    else
      self.bg:SetColorTexture(s.btn[1], s.btn[2], s.btn[3], 1); self.edges:SetColor(1, 1, 1, 0.18)
      self.text:SetTextColor(1, 1, 1, 0.5)
    end
    self.active = on
  end
  b:SetScript("OnEnter", function(self) if not self.active then self.text:SetTextColor(1, 1, 1, 0.85) end end)
  b:SetScript("OnLeave", function(self) if not self.active then self.text:SetTextColor(1, 1, 1, 0.5) end end)
  b:SetActive(false)
  return b
end

local function tip(widget, title, ...)
  local lines = { ... }
  widget:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine(title, 1, 1, 1)
    for _, l in ipairs(lines) do
      if type(l) == "function" then l() else GameTooltip:AddLine(l, 0.8, 0.8, 0.8, true) end
    end
    GameTooltip:Show()
  end)
  widget:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function insertLink(link)
  if ChatFrameUtil and ChatFrameUtil.InsertLink then return ChatFrameUtil.InsertLink(link) end
  if ChatEdit_InsertLink then return ChatEdit_InsertLink(link) end
end

local function money(c)
  c = math.floor((c or 0) + 0.5)
  local sign = c < 0 and "-" or ""
  c = math.abs(c)
  local g, s, cu = math.floor(c / 10000), math.floor((c % 10000) / 100), c % 100
  if g > 0 then return string.format("%s%dg %02ds", sign, g, s) end
  if s > 0 then return string.format("%s%ds", sign, s) end
  return string.format("%s%dc", sign, cu)
end

local function ago(t)
  if not t then return "" end
  local d = time() - t
  if d < 3600 then return math.max(1, math.floor(d / 60)) .. "m ago" end
  if d < 86400 then return math.floor(d / 3600) .. "h ago" end
  return math.floor(d / 86400) .. "d ago"
end

---------------------------------------------------------------------------
-- Professions
---------------------------------------------------------------------------
local MINING = 186
local PROFS = {
  { id = 171, spell = 2259, short = "ALCHEMY",  names = { "Alchemy", "Alchimie", "Alquimia" } },
  { id = 164, spell = 2018, short = "SMITHING", names = { "Blacksmithing", "Schmiedekunst", "Forge", "Herrería" } },
  { id = 165, spell = 2108, short = "LEATHER",  names = { "Leatherworking", "Lederverarbeitung", "Travail du cuir", "Peletería" } },
  { id = 197, spell = 3908, short = "TAILORING", names = { "Tailoring", "Schneiderei", "Couture", "Sastrería" } },
  { id = 202, spell = 4036, short = "ENGINEER", names = { "Engineering", "Ingenieurskunst", "Ingénierie", "Ingeniería" } },
  { id = 333, spell = 7411, short = "ENCHANT",  names = { "Enchanting", "Verzauberkunst", "Enchantement", "Encantamiento" } },
  { id = 185, spell = 2550, short = "COOKING",  names = { "Cooking", "Kochkunst", "Cuisine", "Cocina" } },
  { id = 129, spell = 3273, short = "FIRST AID", names = { "First Aid", "Erste Hilfe", "Secourisme", "Primeros auxilios" } },
  { id = 40,  spell = 2842, short = "POISONS",  names = { "Poisons", "Gifte", "Poisons", "Venenos" } },
  { id = 186, spell = 2575, short = "MINING",   names = { "Mining", "Bergbau", "Minage", "Minería" }, gather = true },
}
local PROF = {}
for _, p in ipairs(PROFS) do
  PROF[p.id] = p
  p.nameSet = {}
  for _, n in ipairs(p.names) do p.nameSet[n] = true end
end

function L.spellName(id)
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, id)
    if ok and n then return n end
  end
  if GetSpellInfo then
    local ok, n = pcall(GetSpellInfo, id)
    if ok and n then return n end
  end
end

local function profName(pid)
  local p = PROF[pid]
  if not p then return "?" end
  p.local_ = p.local_ or L.spellName(p.spell) or p.names[1]
  return p.local_
end

-- profession id from a skill line or window name
function L.profFromName(n)
  if not n then return nil end
  for _, p in ipairs(PROFS) do
    if p.nameSet[n] or n == profName(p.id) then return p.id end
  end
end

-- every profession this character has: { [id] = { rank, max } }
local function readSkills()
  local out = {}
  if GetNumSkillLines and GetSkillLineInfo then
    for i = 1, GetNumSkillLines() do
      local n, header, _, rank, _, _, maxRank = GetSkillLineInfo(i)
      local pid = (not header) and L.profFromName(n)
      if pid then out[pid] = { rank = rank, max = maxRank } end
    end
  end
  if next(out) == nil and GetProfessions and GetProfessionInfo then
    local list = { GetProfessions() }
    for i = 1, 6 do
      local idx = list[i]
      if idx then
        local n, _, rank, maxRank = GetProfessionInfo(idx)
        local pid = L.profFromName(n)
        if pid then out[pid] = { rank = rank, max = maxRank } end
      end
    end
  end
  return out
end

local function readSkill(pid)
  local s = readSkills()[pid]
  if s then return s.rank, s.max end
end

local function myKey() return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?") end

---------------------------------------------------------------------------
-- Recipe data (Recipes.lua), turned into tables the first time a profession is used.
-- Colors you've seen in the profession window replace the shipped ones.
---------------------------------------------------------------------------
local cache = {}

function L.applyFix(r)
  local f = ProfessionWizardDB and ProfessionWizardDB.fix and ProfessionWizardDB.fix[r.spell]
  if f then r.y, r.g = f.y or r.y, f.g or r.g end
end

local function recipes(pid)
  local c = cache[pid]
  if c then return c end
  c = { list = {}, bySpell = {}, byCreates = {}, byName = {} }
  for _, t in ipairs(ns.RECIPES[pid] or {}) do
    local r = { spell = t[1], learn = t[2], y = t[3], g = t[4], creates = t[5], made = math.max(1, t[6] or 1),
      plans = t[7], trainer = (t[8] == 1), name = t[9], mats = {}, prof = pid }
    local m = t[10] or {}
    for i = 1, #m, 2 do r.mats[#r.mats + 1] = { m[i], m[i + 1] } end
    L.applyFix(r)
    c.list[#c.list + 1] = r
    c.bySpell[r.spell] = r
    c.byName[r.name] = r
    if r.creates > 0 then
      c.byCreates[r.creates] = c.byCreates[r.creates] or {}
      table.insert(c.byCreates[r.creates], r)
    end
  end
  cache[pid] = c
  return c
end

-- chance of a skill point at skill s: orange 1, yellow 1, then falling to 0 at grey
function L.chance(r, s)
  if s < r.learn or s >= r.g then return 0 end
  if s < r.y then return 1 end
  return (r.g - s) / (r.g - r.y)
end

function L.colorAt(r, s)
  if s < r.learn then return "|cff808080" end
  if s < r.y then return "|cffff8040" end
  if s < (r.y + r.g) / 2 then return "|cffffff00" end
  if s < r.g then return "|cff40c040" end
  return "|cff808080"
end

-- recipes this character knows, read from its profession windows
function L.knownSet()
  ProfessionWizardDB.known = ProfessionWizardDB.known or {}
  local k = myKey()
  ProfessionWizardDB.known[k] = ProfessionWizardDB.known[k] or {}
  return ProfessionWizardDB.known[k]
end

-- known: seen learned in a profession window, and (once the game is known to answer for recipes) still a spell
-- of this character. A profession dropped and learned again starts empty, and old entries mustn't stay.
local function isKnown(r)
  if not L.knownSet()[r.spell] then return false end
  if ProfessionWizardDB.spellCheck and IsPlayerSpell then
    local ok, has = pcall(IsPlayerSpell, r.spell)
    if ok and not has then return false end
  end
  return true
end

function L.seenProf(pid)
  ProfessionWizardDB.seen = ProfessionWizardDB.seen or {}
  local s = ProfessionWizardDB.seen[myKey()]
  return s and s[pid]
end

---------------------------------------------------------------------------
-- Prices
---------------------------------------------------------------------------
function L.auctionatorPrice(id)
  local a = Auctionator and Auctionator.API and Auctionator.API.v1
  if not (a and a.GetAuctionPriceByItemID) then return nil end
  local ok, p = pcall(a.GetAuctionPriceByItemID, CALLER, id)
  if ok and type(p) == "number" and p > 0 then return p end
end

-- prices from Profession Wizard's own scan (SCAN AH), per realm
function L.scanStore()
  ProfessionWizardDB.scan = ProfessionWizardDB.scan or {}
  local r = GetRealmName() or "?"
  ProfessionWizardDB.scan[r] = ProfessionWizardDB.scan[r] or {}
  return ProfessionWizardDB.scan[r]
end

-- your own scan wins while it's less than a day old; otherwise Auctionator's price
local function ahPrice(id)
  local own = ProfessionWizardDB.scan and ProfessionWizardDB.scan[GetRealmName() or "?"]
  own = own and own[id]
  local a = L.auctionatorPrice(id)
  if own and own.p and (not a or time() - own.t < 86400) then return own.p end
  return a or (own and own.p)
end

function L.sellPrice(id)
  local info = { GetItemInfo(id) }
  if info[1] == nil then
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    return nil
  end
  return info[11] or 0
end

function L.vendorBuy(id)
  local seen = ProfessionWizardDB.vendor and ProfessionWizardDB.vendor[id]
  if seen then return seen end
  if ns.VENDOR_ITEMS[id] then
    local s = L.sellPrice(id)
    if s and s > 0 then return s * 4 end
  end
end

-- cheapest place to buy one, and where
local function buyPrice(id)
  local a, v = ahPrice(id), L.vendorBuy(id)
  if a and v then
    -- a trade supply vendor never runs out, so it wins unless the AH saves at least a fifth
    -- (Crystal Vials: 5s at the vendor, often 4s50 on the AH)
    if v <= a or (ns.VENDOR_ITEMS[id] and a >= v * 0.8) then return v, "vendor" end
    return a, "ah"
  end
  if v then return v, "vendor" end
  if a then return a, "ah" end
end

-- read every vendor you open, so its prices are known from then on
function L.readMerchant()
  if not (GetMerchantNumItems and GetMerchantItemInfo and GetMerchantItemLink) then return end
  ProfessionWizardDB.vendor = ProfessionWizardDB.vendor or {}
  local n = GetMerchantNumItems() or 0
  for i = 1, n do
    local _, _, cost, qty, _, _, _, extended = GetMerchantItemInfo(i)
    local link = GetMerchantItemLink(i)
    local id = link and tonumber(link:match("item:(%d+)"))
    if id and cost and cost > 0 and not extended then
      local each = cost / math.max(1, qty or 1)
      local old = ProfessionWizardDB.vendor[id]
      if not old or each < old then ProfessionWizardDB.vendor[id] = each end
    end
  end
end

---------------------------------------------------------------------------
-- Bags, bank, mail, alts
---------------------------------------------------------------------------
local WANT = {}
function L.want(id) if id and id > 0 then WANT[id] = true end end
function L.buildWant()
  for k in pairs(WANT) do WANT[k] = nil end
  for pid, list in pairs(ns.RECIPES) do
    for _, t in ipairs(list) do
      L.want(t[5])
      local m = t[10] or {}
      for i = 1, #m, 2 do L.want(m[i]) end
    end
  end
end

local function rawCount(id, withBank)
  if not GetItemCountRaw then return 0 end
  local ok, n = pcall(GetItemCountRaw, id, withBank and true or false)
  return (ok and n) or 0
end

local function count(id) return rawCount(id, ProfessionWizardDB.bank) end

local function numSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
  return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function slotInfo(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info then return info.itemID, info.stackCount, info.isLocked end
    return nil
  end
  if GetContainerItemInfo then
    local _, cnt, locked, _, _, _, _, _, _, id = GetContainerItemInfo(bag, slot)
    return id, cnt, locked
  end
end

function L.scanBags(list)
  local out = {}
  for _, bag in ipairs(list) do
    for slot = 1, numSlots(bag) do
      local id, cnt = slotInfo(bag, slot)
      if id and WANT[id] then out[id] = (out[id] or 0) + (cnt or 1) end
    end
  end
  return out
end

function L.bagList()
  local l = {}
  for b = 0, (NUM_BAG_SLOTS or 4) do l[#l + 1] = b end
  return l
end

function L.bankList()
  local l = { BANK_CONTAINER or -1 }
  local first = (NUM_BAG_SLOTS or 4) + 1
  for b = first, first + (NUM_BANKBAGSLOTS or 6) - 1 do l[#l + 1] = b end
  return l
end

-- the inbox is only read once the game has loaded it (MAIL_INBOX_UPDATE), and never while the
-- mailbox or bank is closing: by then they read as empty and would wipe what's saved
local bankOpen, mailOpen, mailShown = false, false, false

function L.readInbox()
  local out = {}
  if not (GetInboxNumItems and GetInboxItem) then return out end
  local ok, n = pcall(GetInboxNumItems)
  if not ok or not n then return out end
  for i = 1, n do
    for a = 1, (ATTACHMENTS_MAX_RECEIVE or 16) do
      local ok2, _, itemID, _, cnt = pcall(GetInboxItem, i, a)
      if ok2 and type(itemID) == "number" and WANT[itemID] then out[itemID] = (out[itemID] or 0) + (cnt or 1) end
    end
  end
  return out
end

local saveGoals -- set further down

local function snapshot()
  if not ProfessionWizardDB then return end
  ProfessionWizardDB.chars = ProfessionWizardDB.chars or {}
  local key = myKey()
  local old = ProfessionWizardDB.chars[key] or {}
  local skills = {}
  for pid, s in pairs(readSkills()) do skills[pid] = s.rank end
  -- Right after login and while logging out the game can report no skills and empty bags. Keep what we saw
  -- last instead of saving that (it wiped every character's bags and skills, and with them the crafter lists).
  if next(skills) == nil and old.skills then skills = old.skills end
  local bags = L.scanBags(L.bagList())
  if numSlots(0) == 0 and old.bags then bags = old.bags end
  local me = {
    name = UnitName("player"), realm = GetRealmName(), faction = UnitFactionGroup("player"),
    skills = skills, time = time(), bags = bags, bank = old.bank or {}, bankTime = old.bankTime,
    mail = old.mail or {}, incoming = old.incoming or {}, mailTime = old.mailTime,
  }
  if bankOpen then me.bank = L.scanBags(L.bankList()); me.bankTime = time() end
  if mailOpen then me.mail = L.readInbox(); me.incoming = {}; me.mailTime = time() end
  ProfessionWizardDB.chars[key] = me
  if saveGoals then pcall(saveGoals) end
end

-- Alts saved by GoldSense (and skills saved by SmithList) count too, so nothing has to be
-- re-learned: whatever they saw more recently than Profession Wizard is taken over.
function L.filtered(t)
  local out = {}
  for id, n in pairs(t or {}) do if WANT[id] then out[id] = n end end
  return out
end

function L.importOthers()
  local me = myKey()
  local inv = GoldSenseDB and GoldSenseDB.inv
  if type(inv) == "table" then
    for realm, chars in pairs(inv) do
      for name, c in pairs(chars) do
        local key = name .. "-" .. realm
        local mine = ProfessionWizardDB.chars[key]
        if key == me and mine and type(c) == "table" and not mine.mailTime and c.mailAt then
          mine.mail = L.filtered(c.mail); mine.mailTime = c.mailAt
        end
        if key ~= me and type(c) == "table" and (c.at or 0) > ((mine and mine.time) or 0) then
          mine = mine or { name = name, realm = realm, skills = {}, incoming = {} }
          mine.faction = c.faction or mine.faction
          mine.bags = L.filtered(c.bags)
          if c.bankAt or not mine.bank then mine.bank = L.filtered(c.bank); mine.bankTime = c.bankAt end
          if c.mailAt or not mine.mail then mine.mail = L.filtered(c.mail); mine.mailTime = c.mailAt; mine.incoming = {} end
          mine.time = c.at
          ProfessionWizardDB.chars[key] = mine
        end
      end
    end
  end
  local sl = SmithListDB and SmithListDB.chars
  if type(sl) == "table" then
    for key, c in pairs(sl) do
      local mine = ProfessionWizardDB.chars[key]
      if key ~= me and type(c) == "table" then
        if not mine and c.realm then
          mine = { name = c.name, realm = c.realm, faction = c.faction, time = c.time, skills = {},
            bags = c.bags or {}, bank = c.bank or {}, mail = c.mail or {}, incoming = c.incoming or {} }
          ProfessionWizardDB.chars[key] = mine
        end
        if mine and c.mining then
          mine.skills = mine.skills or {}
          mine.skills[MINING] = math.max(mine.skills[MINING] or 0, c.mining)
        end
      end
    end
  end
end

local function alts()
  local list, key = {}, myKey()
  local realm, faction = GetRealmName(), UnitFactionGroup("player")
  for k, c in pairs(ProfessionWizardDB.chars or {}) do
    if k ~= key and c.realm == realm and c.faction == faction then list[#list + 1] = c end
  end
  table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
  return list
end

function L.mailOf(c, id)
  if not (ProfessionWizardDB.mail and c) then return 0 end
  return ((c.mail and c.mail[id]) or 0) + ((c.incoming and c.incoming[id]) or 0)
end

local function ownMail(id) return L.mailOf(ProfessionWizardDB.chars and ProfessionWizardDB.chars[myKey()], id) end

local noAlts = false -- set while working out what this character alone still needs
function L.altCount(id)
  if noAlts or not ProfessionWizardDB.alts then return 0, {} end
  local total, parts = 0, {}
  for _, c in ipairs(alts()) do
    local m = L.mailOf(c, id)
    local n = ((c.bags and c.bags[id]) or 0) + (ProfessionWizardDB.bank and ((c.bank and c.bank[id]) or 0) or 0) + m
    if n > 0 then total = total + n; parts[#parts + 1] = { name = c.name, n = n, mail = m, time = c.time } end
  end
  return total, parts
end

function L.haveOf(id)
  local a = L.altCount(id)
  return count(id) + ownMail(id) + a
end

-- best skill among you and (if counted) your alts, e.g. Mining for smelting
local function bestSkill(pid)
  local best = readSkill(pid) or 0
  if ProfessionWizardDB.alts and not noAlts then
    for _, c in ipairs(alts()) do
      local v = c.skills and c.skills[pid]
      if v and v > best then best = v end
    end
  end
  return best
end

-- mail you send to your own characters counts on them straight away
function L.shortName(s)
  s = (s or ""):gsub("%-.*$", "")
  local sep = Constants and Constants.CharacterNameSeparatorConsts and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR
  if sep and sep ~= "" then
    local i = s:find(sep, 1, true)
    if i then s = s:sub(1, i - 1) end
  end
  return (s:match("^(%S+)") or s):lower()
end

local outgoing
function L.noteOutgoing(recipient)
  local items, any = {}, false
  if not GetSendMailItem then return end
  for i = 1, (ATTACHMENTS_MAX_SEND or 12) do
    local ok, _, itemID, _, cnt = pcall(GetSendMailItem, i)
    if ok and type(itemID) == "number" and WANT[itemID] then items[itemID] = (items[itemID] or 0) + (cnt or 1); any = true end
  end
  outgoing = any and { to = recipient, items = items } or nil
end

function L.deliverOutgoing()
  if not outgoing then return end
  local who = L.shortName(outgoing.to)
  local realm, faction = GetRealmName(), UnitFactionGroup("player")
  local target, targetKey
  for k, c in pairs(ProfessionWizardDB.chars) do
    if c.realm == realm and c.faction == faction and L.shortName(c.name) == who then target, targetKey = c, k end
  end
  if target and targetKey ~= myKey() then
    target.incoming = target.incoming or {}
    for id, n in pairs(outgoing.items) do target.incoming[id] = (target.incoming[id] or 0) + n end
    for _, g in pairs(ProfessionWizardDB.goals or {}) do
      if g.owner == targetKey then
        g.sent = g.sent or {}
        for id, n in pairs(outgoing.items) do g.sent[id] = (g.sent[id] or 0) + n end
      end
    end
  end
  outgoing = nil
end

---------------------------------------------------------------------------
-- Cheapest route: for every skill point, the recipe with the lowest
-- (materials - what the vendor pays for the result) / chance of a point.
-- Materials are bought or made, whichever is cheaper (bars you can smelt, bolts you can weave...).
---------------------------------------------------------------------------
function L.producers(id, pid)
  local out = {}
  for _, r in ipairs(recipes(pid).byCreates[id] or {}) do out[#out + 1] = r end
  if pid ~= MINING then
    for _, r in ipairs(recipes(MINING).byCreates[id] or {}) do out[#out + 1] = r end
  end
  return out
end

-- what a trainer charges for it: what you saw at a trainer, else the data, else nothing
function L.trainCost(r)
  local seen = ProfessionWizardDB.trainCost and ProfessionWizardDB.trainCost[r.name]
  return seen or (ns.TRAIN_COST or {})[r.spell] or 0
end

-- read the trainer window, so what it charges is known from then on
function L.readTrainer()
  if not (GetNumTrainerServices and GetTrainerServiceInfo and GetTrainerServiceCost) then return end
  ProfessionWizardDB.trainCost = ProfessionWizardDB.trainCost or {}
  for i = 1, GetNumTrainerServices() or 0 do
    local name, _, kind = GetTrainerServiceInfo(i)
    local cost = GetTrainerServiceCost(i)
    if name and kind ~= "header" and cost and cost > 0 then ProfessionWizardDB.trainCost[name] = cost end
  end
end

-- may the route learn this from a trainer? Not for recipes with no known source, and not for special trainers
-- (questline or one NPC) when that's switched off in the settings
function L.trainable(r)
  if not r.trainer or (ns.NO_SOURCE or {})[r.spell] then return false end
  if (ns.TRAINER_NOTES or {})[r.spell] and ProfessionWizardDB.special == false then return false end
  return true
end

-- recipes on a cooldown (transmutes, Mooncloth, the Salt Shaker): no good for levelling, nor for making materials
function L.onCooldown(r)
  return (ns.COOLDOWN or {})[r.spell] or (r.name and r.name:find("^Transmute") ~= nil)
end

-- can this be made on the way, as a material for something else?
function L.canMake(r, ctx)
  if L.onCooldown(r) then return false end
  if r.prof == MINING then return ctx.mining >= r.learn end
  if r.prof ~= ctx.pid then return false end
  if isKnown(r) then return true end
  return L.trainable(r) and r.learn <= ctx.skill
end

function L.unitCost(id, ctx, depth)
  local m = ctx.memo[id]
  if m ~= nil then return m or nil end
  ctx.memo[id] = false -- stops loops
  local best = buyPrice(id)
  local via
  if depth < 3 then
    for _, r in ipairs(L.producers(id, ctx.pid)) do
      if L.canMake(r, ctx) then
        local c = 0
        for _, mt in ipairs(r.mats) do
          local u = L.unitCost(mt[1], ctx, depth + 1)
          if not u then c = nil; break end
          c = c + u * mt[2]
        end
        if c then
          c = c / r.made
          if not best or c < best then best, via = c, r end
        end
      end
    end
  end
  ctx.memo[id] = best or false
  ctx.via[id] = via
  return best
end

local function newCtx(pid, skill)
  return { pid = pid, skill = skill, mining = bestSkill(MINING), memo = {}, via = {} }
end

-- may this recipe be used for skill-ups, and what do its plans cost?
function L.usable(r, from)
  if r.creates == 0 and r.prof ~= 333 then return false end
  if L.onCooldown(r) then return false end
  -- camping recipes (Mana Well, Camp Tent, Anvil, Campfires...) give no skill (seen in game: Mana Well at 20)
  if r.creates >= 279900 and r.creates <= 279999 then return false end
  if isKnown(r) then return true, 0 end
  if L.trainable(r) then return true, L.trainCost(r), "trainer" end
  if r.plans > 0 and ProfessionWizardDB.plans then
    local p, where = buyPrice(r.plans)
    if p then return true, p, where end
  end
  return false
end

function L.findRoute(pid, from, to)
  local ctx = newCtx(pid, from)
  local cands, waiting, unpriced = {}, 0, {}
  -- USE WHAT I HAVE: materials you own (bags, bank, mail, alts as counted) cost nothing until they run out
  local owned = ProfessionWizardDB.useOwned and {} or nil
  for _, r in ipairs(recipes(pid).list) do
    if r.g > from and r.learn < to then
      local ok, plansCost, where = L.usable(r, from)
      if ok then
        local c = 0
        for _, mt in ipairs(r.mats) do
          local u = L.unitCost(mt[1], ctx, 0)
          if not u then c = nil; unpriced[mt[1]] = (unpriced[mt[1]] or 0) + 1; break end
          c = c + u * mt[2]
        end
        if c then
          local back = 0
          if r.creates > 0 then
            local sp = L.sellPrice(r.creates)
            if sp then back = sp * r.made else waiting = waiting + 1 end
          end
          cands[#cands + 1] = { r = r, mats = c, back = back, net = c - back, plans = plansCost or 0, where = where }
          if owned then
            -- per material: what one costs, so owned ones can be taken off below
            local each = {}
            for _, mt in ipairs(r.mats) do each[#each + 1] = { mt[1], mt[2], L.unitCost(mt[1], ctx, 0) or 0 } end
            cands[#cands].each = each
          end
        end
      end
    end
  end

  local segs, bought = {}, {}
  local cur
  for s = from, to - 1 do
    local best, bestScore
    for _, cd in ipairs(cands) do
      local p = L.chance(cd.r, s)
      if p >= MIN_CHANCE then
        local score = (cd.net + PER_CRAFT) / p
        if owned and cd.each then
          local crafts, c = 1 / p, 0
          for _, e in ipairs(cd.each) do
            local id = e[1]
            if owned[id] == nil then owned[id] = L.haveOf(id) end
            c = c + e[3] * math.max(0, e[2] * crafts - owned[id])
          end
          score = (c - cd.back * crafts) + PER_CRAFT * crafts
        end
        if cd.plans > 0 and not bought[cd.r.spell] then
          local span = 0
          for t = s, to - 1 do
            if L.chance(cd.r, t) >= MIN_CHANCE then span = span + 1 else break end
          end
          score = score + cd.plans / math.max(1, span)
        end
        if not bestScore or score < bestScore then best, bestScore = cd, score end
      end
    end
    if owned and best and best.each then
      -- what this skill point uses up of what you own
      local crafts = 1 / L.chance(best.r, s)
      for _, e in ipairs(best.each) do owned[e[1]] = math.max(0, (owned[e[1]] or 0) - e[2] * crafts) end
    end
    local spell = best and best.r.spell or 0
    local first = best and not bought[spell] -- a recipe is paid for once, even if the route comes back to it
    if best then bought[spell] = true end
    if cur and cur.spell == spell then
      cur.to = s + 1
    else
      cur = { spell = spell, from = s, to = s + 1 }
      if best then cur.plans, cur.where = first and best.plans or 0, best.where end
      segs[#segs + 1] = cur
    end
  end
  local nUnpriced = 0
  for _ in pairs(unpriced) do nUnpriced = nUnpriced + 1 end
  return { pid = pid, from = from, to = to, segs = segs, time = time(), waiting = waiting, unpriced = nUnpriced, cands = #cands }
end

---------------------------------------------------------------------------
-- Saved routes, one per character and profession
---------------------------------------------------------------------------
local function routeStore()
  ProfessionWizardDB.routes = ProfessionWizardDB.routes or {}
  local k = myKey()
  ProfessionWizardDB.routes[k] = ProfessionWizardDB.routes[k] or {}
  return ProfessionWizardDB.routes[k]
end

local MILESTONES = { 75, 150, 225, 300 }
function L.nextMilestone(cur)
  for _, m in ipairs(MILESTONES) do if m > cur then return m end end
  return 300
end

local function targetFor(pid, cur)
  local t = ProfessionWizardDB.targets and ProfessionWizardDB.targets[myKey() .. ":" .. pid]
  if not t or t <= cur then t = L.nextMilestone(cur) end
  return math.min(300, t)
end

-- a route that still covers cur..target, or a fresh one
local function routeFor(pid, cur, target, force)
  local store = routeStore()
  local r = store[pid]
  -- out of date after a setting or data change: work it out again straight away, an old route can be wrong
  local stale = not r or force or r.dirty or r.from > cur or r.to < target
  -- some vendor prices weren't loaded yet: try again a couple of times once they are
  local retry = not stale and r.waiting and r.waiting > 0 and (r.retries or 0) < 3 and time() - (r.time or 0) >= 2
  if stale or retry then
    local tries = retry and (r.retries or 0) + 1 or 0
    r = L.findRoute(pid, cur, math.max(target, L.nextMilestone(cur)))
    r.retries = tries
    store[pid] = r
  end
  return r
end

-- crafts needed for each part of the route between cur and target
local function plan(route, cur, target)
  local steps = {}
  local list = recipes(route.pid)
  -- cut every segment at 75, 150 and 225: you can't craft past a cap before training the next rank
  local segs = {}
  for _, seg in ipairs(route.segs) do
    local a = seg.from
    for _, c in ipairs({ 75, 150, 225 }) do
      if a < c and c < seg.to then
        segs[#segs + 1] = { from = a, to = c, spell = seg.spell, plans = seg.plans, where = seg.where }
        a = c
      end
    end
    -- only the first part pays for the recipe
    segs[#segs + 1] = { from = a, to = seg.to, spell = seg.spell, plans = a == seg.from and seg.plans or 0, where = seg.where }
  end
  for _, seg in ipairs(segs) do
    local a, b = math.max(cur, seg.from), math.min(target, seg.to)
    if a < b then
      local r = list.bySpell[seg.spell]
      if r then
        local exp = 0
        for s = a, b - 1 do
          local p = L.chance(r, s)
          if p > 0 then exp = exp + 1 / p end
        end
        local crafts = math.ceil(exp * (1 + (ProfessionWizardDB.buffer or 0) / 100) - 0.001)
        local last = steps[#steps]
        if last and last.r == r and a ~= 75 and a ~= 150 and a ~= 225 then
          last.to = b; last.crafts = last.crafts + crafts
        else
          steps[#steps + 1] = { r = r, from = a, to = b, crafts = crafts, plans = seg.plans, where = seg.where }
        end
      else
        steps[#steps + 1] = { from = a, to = b, crafts = 0, gap = true }
      end
    end
  end
  return steps
end

---------------------------------------------------------------------------
-- Materials: what the steps need, what you have, what to make on the way
---------------------------------------------------------------------------
function L.newRow(id, n)
  local own, mail = count(id), ownMail(id)
  local onAlts, parts = L.altCount(id)
  return { id = id, need = n, own = own, mail = mail, alts = onAlts, parts = parts, have = own + mail + onAlts }
end

-- a one-material recipe you can do with what you own (ore > bars, cloth > bolts, stone > grinding stones)
function L.fromOwned(id, ctx)
  for _, r in ipairs(L.producers(id, ctx.pid)) do
    if #r.mats == 1 and L.canMake(r, ctx) then return r end
  end
end

local function materials(steps, ctx)
  local base, order, produced, seen = {}, {}, {}, {}
  local function note(id) if not seen[id] then seen[id] = true; order[#order + 1] = id end end
  for _, st in ipairs(steps) do
    if st.r then
      for _, m in ipairs(st.r.mats) do base[m[1]] = (base[m[1]] or 0) + m[2] * st.crafts; note(m[1]) end
      if st.r.creates > 0 then produced[st.r.creates] = (produced[st.r.creates] or 0) + st.crafts * st.r.made end
    end
  end
  for _, st in ipairs(steps) do if st.r then L.unitCost(st.r.creates, ctx, 0) end end
  for id in pairs(base) do L.unitCost(id, ctx, 0) end

  local extra, reserved, rows, from = {}, {}, nil, {}
  for _ = 1, 6 do
    local newExtra, newReserved, newFrom = {}, {}, {}
    rows = {}
    for _, id in ipairs(order) do
      local n = (base[id] or 0) + (extra[id] or 0)
      if n > 0 then
        local row = L.newRow(id, n)
        row.have = math.max(0, row.have - (reserved[id] or 0))
        row.reserved = reserved[id]
        row.crafted = math.min(produced[id] or 0, n)
        local left = n - row.have - row.crafted
        local makes = 0
        -- turn what you own into this first
        local r1 = left > 0 and L.fromOwned(id, ctx)
        if r1 then
          local src, k = r1.mats[1][1], r1.mats[1][2]
          local srcHave = math.max(0, L.haveOf(src) - (reserved[src] or 0) - (base[src] or 0))
          local crafts = math.min(math.floor(srcHave / k), math.ceil(left / r1.made))
          if crafts > 0 then
            makes = crafts
            row.src, row.srcN, row.srcRec = src, crafts * k, r1
            newReserved[src] = (newReserved[src] or 0) + crafts * k
            left = left - crafts * r1.made
            row.makeRec = r1
          end
        end
        -- then make the rest if that's cheaper than buying it
        local via = ctx.via[id]
        if left > 0 and via then
          local crafts = math.ceil(left / via.made)
          makes = makes + crafts
          row.makeRec = row.makeRec or via
          for _, m in ipairs(via.mats) do
            newExtra[m[1]] = (newExtra[m[1]] or 0) + m[2] * crafts
            newFrom[m[1]] = newFrom[m[1]] or {}
            newFrom[m[1]][id] = (newFrom[m[1]][id] or 0) + m[2] * crafts
            note(m[1])
          end
          left = 0
        end
        row.make = makes > 0 and makes or nil
        row.missing = math.max(0, left)
        rows[#rows + 1] = row
      end
    end
    local same = true
    for k, v in pairs(newExtra) do if extra[k] ~= v then same = false end end
    for k, v in pairs(extra) do if newExtra[k] ~= v then same = false end end
    for k, v in pairs(newReserved) do if reserved[k] ~= v then same = false end end
    for k, v in pairs(reserved) do if newReserved[k] ~= v then same = false end end
    extra, reserved, from = newExtra, newReserved, newFrom
    if same then break end
  end
  -- crafted items and makes first, then the rest by name
  return rows, base, from
end

---------------------------------------------------------------------------
-- Goals: what each crafter still needs, counting only what it has itself.
-- Your alts read these at their mailbox and send exactly that.
---------------------------------------------------------------------------
function L.fullName()
  local ok, name, surname = pcall(UnitNameUnmodified or UnitName, "player")
  if not ok or not name then return UnitName("player") end
  if type(surname) ~= "string" or surname == "" then return name end
  local sep = Constants and Constants.CharacterNameSeparatorConsts
    and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR or " "
  return name .. sep .. surname
end

function L.goalFor(pid)
  local rank = readSkill(pid)
  if not rank or rank >= 300 then return nil end
  local target = targetFor(pid, rank)
  local route = routeStore()[pid]
  if not route or route.from > rank or route.to < target then return nil end
  noAlts = true
  local ok, list, steps = pcall(function()
    local ctx = newCtx(pid, rank)
    local st = plan(route, rank, target)
    return materials(st, ctx), st
  end)
  noAlts = false
  local needs, alt, prod, rowsOut, stepsOut = {}, {}, {}, {}, {}
  if ok and list then
    for _, row in ipairs(list) do
      if row.missing > 0 then
        needs[row.id] = row.missing
        local r1 = row.makeRec
        if r1 and #r1.mats == 1 then alt[row.id] = { r1.mats[1][1], r1.mats[1][2] / r1.made } end
      end
      -- what the crafter makes itself from one material (bars from ore, grinding stones from stone): an alt
      -- with the finished item can send that in place of the material. { item, material per item, how many }
      local r2 = row.makeRec
      if (row.make or 0) > 0 and r2 and #r2.mats == 1 then
        prod[r2.mats[1][1]] = { row.id, r2.mats[1][2] / r2.made, row.make }
      end
      rowsOut[#rowsOut + 1] = { id = row.id, need = row.need, missing = row.missing, make = row.make,
        smelt = row.makeRec and row.makeRec.prof == MINING or nil }
    end
    for _, st in ipairs(steps or {}) do
      stepsOut[#stepsOut + 1] = { spell = st.r and st.r.spell, from = st.from, to = st.to, crafts = st.crafts }
    end
  end
  return {
    owner = myKey(), pid = pid, name = UnitName("player"), full = L.fullName(), realm = GetRealmName(),
    faction = UnitFactionGroup("player"), skill = rank, target = target, needs = needs, alt = alt, prod = prod,
    rows = rowsOut, steps = stepsOut, time = time(), sent = {},
  }
end

saveGoals = function()
  if not ProfessionWizardDB then return end
  ProfessionWizardDB.goals = ProfessionWizardDB.goals or {}
  local me = myKey()
  local skills = readSkills()
  if next(skills) == nil then return end -- the game isn't telling (login, logout): keep the saved lists
  for k, g in pairs(ProfessionWizardDB.goals) do
    if g.owner == me then ProfessionWizardDB.goals[k] = nil end
  end
  for pid in pairs(skills) do
    if not PROF[pid].gather then
      local g = L.goalFor(pid)
      if g then ProfessionWizardDB.goals[me .. ":" .. pid] = g end
    end
  end
end

---------------------------------------------------------------------------
-- Profession windows: crafting buttons, known recipes, real colors
---------------------------------------------------------------------------
local tsOpen, tsProf, tsMode, recipeCache = false, nil, nil, nil
local refresh -- set further down

-- scrolling the CRAFTS and MATERIALS lists: how far down each one is
L.scroll = { step = 0, mat = 0 }
L.VIS_STEPS, L.VIS_MATS = 10, 12
function L.scrollList(which, d)
  L.scroll[which] = math.max(0, (L.scroll[which] or 0) + d)
  refresh() -- clamps it to the list
end

local job     -- the batch being crafted: { name, label, total, done, st, et, casting, stopped }

function L.itemFromLink(link) return link and tonumber(link:match("item:(%d+)")) end

function L.windowProf()
  if tsMode == "craft" then
    if GetCraftDisplaySkillLine then
      local ok, name = pcall(GetCraftDisplaySkillLine)
      if ok then return L.profFromName(name) end
    end
    if GetCraftSkillLine then
      local ok, name = pcall(GetCraftSkillLine, 1)
      if ok then return L.profFromName(name) end
    end
    return nil
  end
  if C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
    local ok, info = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
    if ok and info then
      if info.professionID and PROF[info.professionID] then return info.professionID end
      local pid = L.profFromName(info.professionName)
      if pid then return pid end
    end
  end
  if GetTradeSkillLine then
    local ok, name = pcall(GetTradeSkillLine)
    if ok then return L.profFromName(name) end
  end
end

local KIND = { optimal = "orange", medium = "yellow", easy = "green", trivial = "grey", difficult = "orange" }

function L.buildRecipes()
  local byItem, byName, all = {}, {}, {}
  local function add(r, id)
    if id then byItem[id] = r end
    byName[r.name] = r
    all[#all + 1] = r
  end
  if tsMode == "craft" then
    if GetNumCrafts and GetCraftInfo then
      local ok, n = pcall(GetNumCrafts)
      for i = 1, (ok and n or 0) do
        local name, _, kind, avail = GetCraftInfo(i)
        if name and kind ~= "header" then
          add({ craftIndex = i, name = name, avail = avail or 0, kind = KIND[kind] }, nil)
        end
      end
    end
    return { byItem = byItem, byName = byName, all = all }
  end
  if GetNumTradeSkills and GetTradeSkillInfo then
    local ok, n = pcall(GetNumTradeSkills)
    for i = 1, (ok and n or 0) do
      local name, kind, avail = GetTradeSkillInfo(i)
      if name and kind ~= "header" and kind ~= "subheader" then
        local id = GetTradeSkillItemLink and L.itemFromLink(GetTradeSkillItemLink(i))
        add({ index = i, name = name, avail = avail or 0, kind = KIND[kind] }, id)
      end
    end
  end
  if #all == 0 and C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
    local ok, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
    for _, rid in ipairs((ok and ids) or {}) do
      local info = C_TradeSkillUI.GetRecipeInfo and C_TradeSkillUI.GetRecipeInfo(rid)
      if info and info.learned and info.name then
        local id
        if C_TradeSkillUI.GetRecipeOutputItemData then
          local okO, out = pcall(C_TradeSkillUI.GetRecipeOutputItemData, rid)
          id = okO and out and out.itemID
        end
        if not id and C_TradeSkillUI.GetRecipeItemLink then id = L.itemFromLink(C_TradeSkillUI.GetRecipeItemLink(rid)) end
        local kind = type(info.difficulty) == "string" and KIND[info.difficulty] or nil
        add({ recipeID = rid, spell = rid, name = info.name, avail = info.numAvailable or 0, kind = kind }, id)
      end
    end
  end
  return { byItem = byItem, byName = byName, all = all }
end

local function getRecipes()
  if not tsOpen then return nil end
  recipeCache = recipeCache or L.buildRecipes()
  return recipeCache
end

-- how many you can make from what's in your bags (the game's own count reads 0 on some windows)
function L.bagMakes(r)
  local n
  for _, m in ipairs(r.mats) do
    local k = math.floor(rawCount(m[1], false) / math.max(1, m[2]))
    if not n or k < n then n = k end
  end
  return n or 0
end

local findRecipeRaw
-- the recipe in the open window for one of ours
local function findRecipe(r)
  local w = findRecipeRaw(r)
  if w then w.avail = math.max(w.avail or 0, L.bagMakes(r)) end
  return w
end

findRecipeRaw = function(r)
  local rc = getRecipes()
  if not rc or not r or r.prof ~= tsProf then return nil end
  if r.creates > 0 and rc.byItem[r.creates] then return rc.byItem[r.creates] end
  if rc.byName[r.name] then return rc.byName[r.name] end
  local n = r.creates > 0 and GetItemInfo(r.creates)
  if n and rc.byName[n] then return rc.byName[n] end
  local want_ = r.name:lower()
  for _, w in ipairs(rc.all) do
    if w.spell == r.spell or (w.name and w.name:lower() == want_) then return w end
  end
end

-- which of ours is this window line?
function L.matchData(w, pid, itemID)
  local list = recipes(pid)
  if w.spell and list.bySpell[w.spell] then return list.bySpell[w.spell] end
  if itemID and list.byCreates[itemID] then
    local cands = list.byCreates[itemID]
    if #cands == 1 then return cands[1] end
    for _, r in ipairs(cands) do if r.name == w.name then return r end end
    return cands[1]
  end
  return list.byName[w.name]
end

-- remember what's learned and fix colors that differ from the shipped data
function L.learnWindow()
  if not tsOpen or not tsProf then return end
  local rc = getRecipes()
  if not rc then return end
  local rank = readSkill(tsProf)
  local known = L.knownSet()
  ProfessionWizardDB.fix = ProfessionWizardDB.fix or {}
  ProfessionWizardDB.seen = ProfessionWizardDB.seen or {}
  ProfessionWizardDB.seen[myKey()] = ProfessionWizardDB.seen[myKey()] or {}
  ProfessionWizardDB.seen[myKey()][tsProf] = time()
  local itemOf = {}
  for id, w in pairs(rc.byItem) do itemOf[w] = id end
  local fixed = 0
  for _, w in ipairs(rc.all) do
    local r = L.matchData(w, tsProf, itemOf[w])
    if r then
      known[r.spell] = true
      -- does the game answer IsPlayerSpell for recipes? (then isKnown can check old entries with it)
      if not ProfessionWizardDB.spellCheck and IsPlayerSpell then
        local ok, has = pcall(IsPlayerSpell, r.spell)
        if ok and has then ProfessionWizardDB.spellCheck = true end
      end
      if rank and w.kind then
        local y, g = r.y, r.g
        local green = (y + g) / 2
        if w.kind == "grey" and g > rank then g = rank
        elseif w.kind == "orange" and y <= rank then
          local span = g - y; y = rank + 1; if g <= y then g = y + math.max(5, span) end
        elseif w.kind == "yellow" and (y > rank or green <= rank) then
          if y > rank then y = rank end
          if (y + g) / 2 <= rank then g = 2 * rank - y + 2 end
        elseif w.kind == "green" and (green > rank or g <= rank) then
          if g <= rank then g = rank + 1 end
          if (y + g) / 2 > rank then y = math.max(r.learn, 2 * rank - g) end
        end
        if y ~= r.y or g ~= r.g then
          r.y, r.g = y, g
          ProfessionWizardDB.fix[r.spell] = { y = y, g = g }
          fixed = fixed + 1
        end
      end
    end
  end
  if fixed > 0 then
    -- colors changed, so the saved route may not be the cheapest any more
    local store = routeStore()
    if store[tsProf] then store[tsProf].dirty = true end
  end
end

local function clearJob(after)
  local this = job
  C_Timer.After(after or 3, function()
    if job == this then job = nil; if refresh then refresh() end end
  end)
end

local queue = {}
local nextInQueue

---------------------------------------------------------------------------
-- Enchanting: an enchant has no item to make, it goes onto an item. For each enchant we pick the cheapest
-- item of the right kind in your bags (grey or white first, never what you're wearing), CRAFT casts the
-- enchant straight onto it, and the game's "replace enchant?" question is answered for that item only.
-- If the game won't let us target the item, you keep the targeting hand and the panel says which to click.
---------------------------------------------------------------------------
local Ench = { cache = {}, pending = nil }
Ench.SLOTS = {
  ["Bracer"]    = { what = "bracer", locs = { INVTYPE_WRIST = true } },
  ["Chest"]     = { what = "chest piece", locs = { INVTYPE_CHEST = true, INVTYPE_ROBE = true } },
  ["Cloak"]     = { what = "cloak", locs = { INVTYPE_CLOAK = true } },
  ["Boots"]     = { what = "pair of boots", locs = { INVTYPE_FEET = true } },
  ["Gloves"]    = { what = "pair of gloves", locs = { INVTYPE_HAND = true } },
  ["Shield"]    = { what = "shield", locs = { INVTYPE_SHIELD = true } },
  ["2H Weapon"] = { what = "two-handed weapon", locs = { INVTYPE_2HWEAPON = true } },
  ["Weapon"]    = { what = "weapon", locs = { INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true,
                    INVTYPE_WEAPONOFFHAND = true, INVTYPE_2HWEAPON = true } },
}

-- the kind of item this recipe enchants, or nil when it isn't an enchant (rods, oils and wands make items)
function Ench.slotOf(r)
  if not r or r.prof ~= 333 or (r.creates or 0) > 0 or not r.name then return nil end
  local key = r.name:match("^Enchant (.-) %- ")
  return key and Ench.SLOTS[key] and key or nil
end

-- the cheapest matching item in your bags: { bag, slot, id, link, quality } or nil
function Ench.target(r)
  local key = Ench.slotOf(r)
  if not key then return nil end
  local c = Ench.cache[key]
  if c and GetTime() - c.at < 0.5 then return c.t end
  local locs, best, bestScore = Ench.SLOTS[key].locs, nil, nil
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = 1, numSlots(bag) do
      local id, _, locked = slotInfo(bag, slot)
      if id and not locked then
        local _, link, quality, _, _, _, _, _, loc, _, sell = GetItemInfo(id)
        if loc and locs[loc] then
          local score = ((quality or 1) >= 2 and 1e9 or 0) + (sell or 0)
          if not bestScore or score < bestScore then
            best, bestScore = { bag = bag, slot = slot, id = id, link = link, quality = quality }, score
          end
        end
      end
    end
  end
  Ench.cache[key] = { at = GetTime(), t = best }
  return best
end

function Ench.what(r)
  local key = Ench.slotOf(r)
  return key and Ench.SLOTS[key].what or "item"
end

-- right after the enchant was started (same click): put it on the chosen item
function Ench.apply(r)
  if not Ench.slotOf(r) or not (SpellIsTargeting and SpellIsTargeting()) then return end
  local t = Ench.target(r)
  if not t then
    Print("no " .. Ench.what(r) .. " in your bags to put " .. r.name .. " on. Any cheap one works (grey or white is fine); "
      .. "click an item now, or right-click to cancel.")
    return
  end
  Ench.pending = { bag = t.bag, slot = t.slot, at = GetTime() }
  local pick = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
  if pick then pcall(pick, t.bag, t.slot) end
  if SpellIsTargeting() then
    Print("click " .. (t.link or "the item") .. " in your bags to put the enchant on it.")
  end
end

-- the game asks before replacing an enchant: say yes, but only for the item we just picked
function Ench.onReplace()
  local p = Ench.pending
  if not (p and GetTime() - p.at < 5) then return end
  Ench.pending = nil
  if ReplaceEnchant and pcall(ReplaceEnchant) then
    C_Timer.After(0, function() if StaticPopup_Hide then StaticPopup_Hide("REPLACE_ENCHANT") end end)
  end
end

-- is a batch still running? One the game ended without telling us (out of materials, stopped in the
-- profession window, disconnected ...) is over once nothing has been cast for a few seconds.
local function jobBusy()
  if not job or job.stopped then return false end
  local now = GetTime()
  local overdue = job.casting and job.et and now * 1000 > job.et + 2000
  if (job.casting and not overdue) or now - (job.last or 0) < 3 then return true end
  job.stopped = job.done > 0 and ("stopped after " .. job.done) or "stopped"
  queue = {}
  clearJob(3)
  return false
end

local function startCraft(w, n, label, r)
  if not w or not n or n < 1 then return end
  local ench = Ench.slotOf(r)
  if ench then n = 1 end
  if InCombatLockdown and InCombatLockdown() then Print("can't craft in combat."); return end
  if jobBusy() then Print("already crafting. Wait for it to finish, or move to stop it."); return end
  local ok, err
  if w.craftIndex and DoCraft then
    n = 1 -- enchants go on one item at a time
    ok, err = pcall(DoCraft, w.craftIndex)
  elseif w.index and DoTradeSkill and ench then
    ok, err = pcall(DoTradeSkill, w.index, 1)
  elseif w.index and DoTradeSkill then
    ok, err = pcall(DoTradeSkill, w.index, n)
  elseif w.recipeID and C_TradeSkillUI and C_TradeSkillUI.CraftRecipe then
    ok, err = pcall(C_TradeSkillUI.CraftRecipe, w.recipeID, n)
  else
    ok, err = false, "no way to start crafting found"
  end
  if not ok then Print("couldn't start crafting: " .. tostring(err)); return end
  job = { name = w.name, label = label or w.name, total = n, done = 0, last = GetTime() }
  local this = job
  if ench or w.craftIndex then Ench.apply(r) end
  -- not started after 2.5s: it didn't work. Still choosing the item for an enchant counts as waiting (up to a minute).
  local waited = 0
  local function check()
    if job ~= this or job.st then return end
    if SpellIsTargeting and SpellIsTargeting() and waited < 60 then waited = waited + 1; C_Timer.After(1, check); return end
    job.stopped = "didn't start"; queue = {}; clearJob(4); if refresh then refresh() end
  end
  C_Timer.After(2.5, check)
  if refresh then refresh() end
end

-- several crafts in a row (SMELT ALL): the next one starts when the last finishes
nextInQueue = function(loud)
  while queue[1] do
    local q = table.remove(queue, 1)
    recipeCache = nil
    local w = findRecipe(q.r)
    if w and (w.avail or 0) > 0 then
      startCraft(w, math.min(q.n, w.avail), q.r.name .. (#queue > 0 and string.format("  (+%d more)", #queue) or ""))
      return true
    end
    if loud then
      if not tsOpen then Print("the smelting window isn't open.")
      elseif not w then Print(q.r.name .. ": not found in the open window (" .. tostring(tsProf and profName(tsProf)) .. ").")
      else
        local ore = q.r.mats[1] and GetItemInfo(q.r.mats[1][1]) or "the ore"
        Print(q.r.name .. ": nothing to smelt, " .. ore .. " isn't in your bags (bank, mail or alts don't count here).")
      end
    end
  end
end

local function onCast(event, unit)
  if unit ~= "player" or not job then return end
  if event == "UNIT_SPELLCAST_START" then
    local name, _, _, st, et = UnitCastingInfo("player")
    if name and (name == job.name or not job.st) then
      job.st, job.et, job.casting, job.last = st, et, true, GetTime()
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    if job.casting then
      job.casting = false
      job.done = job.done + 1
      job.last = GetTime()
      if job.done >= job.total then
        job.stopped = "done"; clearJob(3)
        if queue[1] then C_Timer.After(0.8, function() recipeCache = nil; nextInQueue() end) end
      else
        -- the next craft of the batch starts right away; if none does, the game ended the batch
        local this, d = job, job.done
        C_Timer.After(2.5, function()
          if job == this and not job.casting and job.done == d and not job.stopped then
            job.stopped = (d > 0 and ("stopped after " .. d)) or "stopped"
            queue = {}; clearJob(3); if refresh then refresh() end
          end
        end)
      end
    end
  elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
    if job.casting then
      job.casting = false
      job.stopped = "stopped"
      queue = {}
      clearJob(4)
    end
  end
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local frame, rows, stepLines, profChips = nil, {}, {}, {}
local current -- profession shown
local viewing -- key of another character's saved list being browsed, or nil
local toggleMenu, startScan, placeSecure
local openBtn -- secure button that opens the profession window (CRAFT needs it open)
local smeltBtn -- secure button that casts Smelting (opening the smelting window needs a real click)

local function shownProf()
  local have = readSkills()
  if current and have[current] then return current end
  if ProfessionWizardDB.last and ProfessionWizardDB.last[myKey()] and have[ProfessionWizardDB.last[myKey()]] then
    current = ProfessionWizardDB.last[myKey()]
    return current
  end
  for _, p in ipairs(PROFS) do
    if have[p.id] and not p.gather and have[p.id].rank < 300 then current = p.id; return current end
  end
  for _, p in ipairs(PROFS) do
    if have[p.id] and not p.gather then current = p.id; return current end
  end
end

local function pick(pid)
  current = pid
  ProfessionWizardDB.last = ProfessionWizardDB.last or {}
  ProfessionWizardDB.last[myKey()] = pid
  if refresh then refresh() end
end

local function setTarget(v)
  local pid = shownProf()
  if not v or not pid then return end
  local cur = readSkill(pid) or 1
  ProfessionWizardDB.targets = ProfessionWizardDB.targets or {}
  ProfessionWizardDB.targets[myKey() .. ":" .. pid] = math.max(cur + 1, math.min(300, math.floor(v)))
  refresh()
  pcall(saveGoals)
end

-- names: item names to look up; qty (optional): how many of each you still need, by name. With Auctionator
-- the searches carry that amount, so its buy screen starts at it.
local function searchAH(names, qty)
  local a = Auctionator and Auctionator.API and Auctionator.API.v1
  if #names == 0 then Print("nothing to buy."); return end
  if a and a.MultiSearchAdvanced and qty then
    local terms = {}
    for _, n in ipairs(names) do
      local q = qty[n]
      terms[#terms + 1] = { searchString = n, isExact = true, quantity = (q and q > 0) and math.ceil(q) or nil }
    end
    if pcall(a.MultiSearchAdvanced, CALLER, terms) then return end
  end
  if not (a and a.MultiSearchExact) then
    -- no Auctionator: put the first one in the auction house's own search box
    local ahf = _G.AuctionHouseFrame
    if ahf and ahf:IsShown() and ahf.SearchBar and ahf.SearchBar.SearchBox then
      ahf.SearchBar.SearchBox:SetText(names[1])
      if ahf.SearchBar.StartSearch then pcall(ahf.SearchBar.StartSearch, ahf.SearchBar) end
      if #names > 1 then Print("also on the list: " .. table.concat(names, ", ", 2)) end
      return
    end
    local box = _G.BrowseName
    if box and _G.AuctionFrame and _G.AuctionFrame:IsShown() then
      box:SetText(names[1])
      if AuctionFrameBrowse_Search then pcall(AuctionFrameBrowse_Search) end
      if #names > 1 then Print("also on the list: " .. table.concat(names, ", ", 2)) end
    else
      Print("open the auction house first, then click again.")
    end
    return
  end
  local ok = pcall(a.MultiSearchExact, CALLER, names)
  if not ok then Print("open the auction house first, then click again.") end
end

function L.makeRow(i)
  local r = CreateFrame("Button", nil, frame)
  r:SetSize(W - PAD * 2, ROW_H)
  r.hl = r:CreateTexture(nil, "BACKGROUND"); r.hl:SetAllPoints()
  r.hl:SetColorTexture(1, 1, 1, 0.06); r.hl:Hide()
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(16, 16); r.icon:SetPoint("LEFT", 0, 0)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local function col(x, w, justify, size, a)
    local t = text(r, size or 12, 1, 1, 1, a or 0.9)
    t:SetPoint("LEFT", x, 0); t:SetWidth(w); t:SetJustifyH(justify or "LEFT")
    return t
  end
  r.name   = col(22, 220)
  r.need   = col(X_NEED, 60, "RIGHT", 12, 0.85)
  r.have   = col(X_HAVE, W_HAVE, "RIGHT", 11, 0.6)
  r.status = col(X_STAT, W - PAD * 2 - X_STAT, "LEFT", 12)
  r.act = chip(r, "MAKE", 104)
  r.act:SetHeight(18); r.act:SetPoint("RIGHT", 0, 0); r.act:Hide()
  r.act:SetScript("OnClick", function() startCraft(r.actRec, r.actN, r.actLabel) end)

  r:SetScript("OnEnter", function(self)
    if not self.row then return end
    local row = self.row
    self.hl:Show()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(row.id)
    GameTooltip:AddLine(" ")
    if row.alts > 0 or row.own > 0 or row.mail > 0 then
      GameTooltip:AddDoubleLine("You", tostring(row.own), 1, 1, 1, 1, 1, 1)
      if row.mail > 0 then GameTooltip:AddDoubleLine("You, in the mail", tostring(row.mail), 1, 1, 1, 1, 1, 1) end
      for _, p in ipairs(row.parts) do
        local label = p.name .. "  |cff808080" .. ago(p.time) .. "|r"
        local num = tostring(p.n) .. (p.mail > 0 and ("  |cff808080(" .. p.mail .. " in mail)|r") or "")
        GameTooltip:AddDoubleLine(label, num, 1, 1, 1, 1, 1, 1)
      end
    end
    if row.forId then
      local fname = GetItemInfo(row.forId) or "the item above"
      GameTooltip:AddLine(string.format("%d of these are for making %s (the line above).", row.need, fname), 1, 0.82, 0.45, true)
    elseif row.haveHere then
      GameTooltip:AddLine(string.format("%d of these are needed as they are. More go into making other items (indented lines).", row.need), 1, 0.82, 0.45, true)
    end
    if (row.reserved or 0) > 0 then
      GameTooltip:AddLine(string.format("%d of yours are used to make something else on the list.", row.reserved), 0.8, 0.8, 0.8, true)
    end
    if (row.crafted or 0) > 0 then
      GameTooltip:AddLine(string.format("%d come from your skill-up crafts.", row.crafted), 0.4, 0.86, 0.5, true)
    end
    if row.src then
      GameTooltip:AddLine(string.format("Make %d from %d %s you have.", row.srcN / row.srcRec.mats[1][2] * row.srcRec.made,
        row.srcN, GetItemInfo(row.src) or "items"), 0.4, 0.86, 0.5, true)
    end
    if row.make and row.makeRec then
      GameTooltip:AddLine(string.format("Make %d yourself (%s): cheaper than buying.", row.make, row.makeRec.name), 1, 0.82, 0.45, true)
    end
    local p, where = buyPrice(row.id)
    if p then GameTooltip:AddDoubleLine(where == "vendor" and "Vendor price" or "AH price", money(p), 0.6, 0.6, 0.6, 0.6, 0.6, 0.6) end
    GameTooltip:AddLine("Click to search the AH (with Auctionator, for the amount you still need), shift-click to link.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function(self) self.hl:Hide(); GameTooltip:Hide() end)
  r:SetScript("OnClick", function(self)
    if not self.row then return end
    local name, link = GetItemInfo(self.row.id)
    if IsShiftKeyDown() and link then insertLink(link); return end
    -- all of this item still missing (it can have an indented line too), or what the list says to buy
    local q = 0
    for _, row in ipairs(frame.list or {}) do
      if row.id == self.row.id then q = q + (row.missing or 0) end
    end
    if q == 0 then q = self.row.missing or self.row.buy or 0 end
    if name then searchAH({ name }, { [name] = q }) end
  end)
  return r
end

function L.makeStep(i)
  local s = scheme()
  local l = CreateFrame("Frame", nil, frame)
  l:SetSize(W - PAD * 2, STEP_H + 4)
  l:EnableMouse(true)
  l.range = text(l, 11, 1, 1, 1, 0.5); l.range:SetPoint("LEFT", 0, 0); l.range:SetWidth(64)
  l.name = text(l, 12, 1, 1, 1, 0.9); l.name:SetPoint("LEFT", 66, 0); l.name:SetWidth(210)
  l.crafts = text(l, 12, 1, 1, 1, 0.9); l.crafts:SetPoint("LEFT", 276, 0); l.crafts:SetWidth(44); l.crafts:SetJustifyH("RIGHT")
  l.info = text(l, 11, 1, 1, 1, 0.45); l.info:SetPoint("LEFT", 332, 0); l.info:SetWidth(W - PAD * 2 - 332)
  l.go = chip(l, "CRAFT", 70)
  l.go:SetHeight(18); l.go:SetPoint("RIGHT", 0, 0)
  l.amt = CreateFrame("EditBox", nil, l)
  l.amt:SetSize(36, 18); l.amt:SetPoint("RIGHT", l.go, "LEFT", -4, 0)
  l.amt:SetAutoFocus(false); l.amt:SetNumeric(true); l.amt:SetMaxLetters(3)
  l.amt:SetFont(fontPath(), 11, ""); l.amt:SetJustifyH("CENTER"); l.amt:SetTextColor(1, 1, 1, 0.95)
  local abg = l.amt:CreateTexture(nil, "BACKGROUND"); abg:SetAllPoints()
  abg:SetColorTexture(s.btn[1], s.btn[2], s.btn[3], 1)
  edges(l.amt, 1, 1, 1, 0.18)
  l.amt:SetScript("OnTextChanged", function(self, user) if user then l.custom = tonumber(self:GetText()) end end)
  l.amt:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  l.amt:SetScript("OnEscapePressed", function(self) l.custom = nil; self:ClearFocus(); refresh() end)
  l.go:SetScript("OnClick", function()
    startCraft(l.rec, tonumber(l.amt:GetText()) or 0, l.label, l.st and l.st.r)
    l.custom = nil
  end)
  l.go:HookScript("OnEnter", function(self)
    if not l.rec then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Craft " .. (l.label or "?"), 1, 1, 1)
    GameTooltip:AddLine(string.format("You can make %d with what's in your bags.", l.rec.avail or 0), 0.8, 0.8, 0.8, true)
    local er = l.st and l.st.r
    if Ench.slotOf(er) then
      local tg = Ench.target(er)
      if tg then
        GameTooltip:AddLine("One enchant per click, put straight on " .. (tg.link or "it") .. " from your bags (the cheapest "
          .. Ench.what(er) .. " you carry). Replacing its old enchant is confirmed for you, never on gear you're wearing.", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("An item that isn't bound yet: the game asks once whether to bind it.", 0.6, 0.6, 0.6, true)
      else
        GameTooltip:AddLine("Needs a " .. Ench.what(er) .. " in your bags to enchant. Any cheap one works, grey or white is fine, "
          .. "and you can enchant the same one again and again.", 1, 0.82, 0.45, true)
      end
    elseif l.rec.craftIndex then
      GameTooltip:AddLine("One at a time: click, then pick the item.", 0.8, 0.8, 0.8, true)
    end
    GameTooltip:AddLine("Moving or getting hit stops it, like normal crafting.", 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
  end)
  l.go:HookScript("OnLeave", function() GameTooltip:Hide() end)
  l:SetScript("OnEnter", function(self)
    local st = self.st
    if st and st.rankRow then
      local rk = st.rankRow
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine("Train " .. rk.name .. " " .. profName(shownProf() or 0), 1, 1, 1)
      GameTooltip:AddLine(string.format("Your skill stops at %d until you do. It needs skill %d and level %d.", rk.cap,
        rk.skill, rk.level), 0.8, 0.8, 0.8, true)
      if st.where then GameTooltip:AddLine("Where: " .. st.where .. ".", 1, 0.82, 0.45, true) end
      GameTooltip:AddLine("The step before this one stops at " .. rk.cap .. ", so no crafts are wasted.", 0.6, 0.6, 0.6, true)
      GameTooltip:Show()
      return
    end
    if not st or not st.r then return end
    local r = st.r
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if r.creates > 0 then GameTooltip:SetItemByID(r.creates) else GameTooltip:AddLine(r.name, 1, 1, 1) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(string.format("|cffff8040%d|r  |cffffff00%d|r  |cff40c040%d|r  |cff808080%d|r", r.learn, r.y,
      math.floor((r.y + r.g) / 2), r.g), 1, 1, 1)
    if st.matCost then
      GameTooltip:AddDoubleLine("Materials each", money(st.matCost), 0.8, 0.8, 0.8, 1, 1, 1)
      if (st.back or 0) > 0 then GameTooltip:AddDoubleLine("Vendor pays each", money(st.back), 0.8, 0.8, 0.8, 1, 1, 1) end
    end
    if isKnown(r) then GameTooltip:AddLine("You know this.", 0.4, 0.86, 0.5)
    elseif r.trainer and (ns.NO_SOURCE or {})[r.spell] then
      GameTooltip:AddLine("Not known to be learnable in WoW Forever, so routes leave it out.", 1, 0.82, 0.45, true)
    elseif r.trainer and (ns.TRAINER_NOTES or {})[r.spell] then
      GameTooltip:AddLine("Not taught by the usual trainers: learn it from " .. ns.TRAINER_NOTES[r.spell] .. ".", 1, 0.82, 0.45, true)
    elseif r.trainer then
      -- recipes past 150 or 225 are only taught by trainers of that rank, so name one
      local need = (r.learn > 225 and 225) or (r.learn > 150 and 150) or nil
      local rk, where = nil, nil
      if need and ns.rankInfo then rk, where = ns.rankInfo(r.prof, need, profName(r.prof)) end
      if rk and where then
        GameTooltip:AddLine("From a trainer who teaches " .. rk.name .. ", like " .. where .. ".", 0.8, 0.8, 0.8, true)
      else
        GameTooltip:AddLine("From your trainer.", 0.8, 0.8, 0.8)
      end
      local fee = L.trainCost(r)
      if fee > 0 then GameTooltip:AddDoubleLine("Training costs", money(fee), 0.8, 0.8, 0.8, 1, 1, 1) end
    elseif r.plans > 0 then
      local _, link = GetItemInfo(r.plans)
      GameTooltip:AddLine("Needs " .. (link or "a recipe item") .. ", not taught by trainers.", 1, 0.82, 0.45, true)
      local rp, where = buyPrice(r.plans)
      if rp then
        GameTooltip:AddDoubleLine(where == "vendor" and "Recipe at a vendor" or "Recipe on the AH", money(rp), 0.8, 0.8, 0.8, 1, 1, 1)
      else
        GameTooltip:AddLine("No price for the recipe yet: SCAN AH looks it up too.", 0.8, 0.8, 0.8, true)
      end
      if (st.plans or 0) > 0 then
        GameTooltip:AddDoubleLine("Counted in this part of the route", money(st.plans), 0.6, 0.6, 0.6, 0.8, 0.8, 0.8)
      end
      if r.learn > (st.from or 0) then GameTooltip:AddLine("You can learn it at " .. r.learn .. ".", 0.8, 0.8, 0.8) end
      GameTooltip:AddLine("Click to search the auction house for the recipe, shift-click to link it.", 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  l:SetScript("OnLeave", function() GameTooltip:Hide() end)
  l:SetScript("OnMouseUp", function(self)
    local r = self.st and self.st.r
    if not r or isKnown(r) or r.trainer or (r.plans or 0) == 0 then return end
    local name, link = GetItemInfo(r.plans)
    if IsShiftKeyDown() and link then insertLink(link); return end
    if name then searchAH({ name }, { [name] = 1 }) end
  end)
  l.go:Hide(); l.amt:Hide()
  return l
end

-- Where the window goes: where this character last dragged it; until it has, next to the open profession
-- window (or the middle of the screen when none is open).
function L.savePos()
  local point, _, rel, x, y = frame:GetPoint()
  ProfessionWizardDB.posChar = ProfessionWizardDB.posChar or {}
  ProfessionWizardDB.posChar[myKey()] = { point = point, rel = rel, x = x, y = y }
end

function L.profWindow()
  for _, n in ipairs({ "TradeSkillFrame", "CraftFrame", "ProfessionsFrame" }) do
    local f = _G[n]
    if f and f.IsShown and f:IsShown() and f:GetRight() and f:GetTop() then return f end
  end
end

local function placeFrame()
  if not frame then return end
  local p = ProfessionWizardDB.posChar and ProfessionWizardDB.posChar[myKey()]
  frame:ClearAllPoints()
  if p and p.point then
    frame:SetPoint(p.point, UIParent, p.rel or p.point, p.x or 0, p.y or 0)
    return
  end
  local pf = L.profWindow()
  if not pf then frame:SetPoint("CENTER", -200, 40); return end
  local k = pf:GetEffectiveScale() / frame:GetEffectiveScale()
  local left, right, top = pf:GetLeft() * k, pf:GetRight() * k, pf:GetTop() * k
  local screenW = UIParent:GetWidth() * UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
  if right + 4 + W <= screenW or left - 4 - W < 0 then
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", right + 4, top)
  else
    frame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", left - 4, top)
  end
end

-- The minimap button (LibDBIcon: drag it around the minimap, minimap button bags collect it; on by
-- default, ProfessionWizardDB.minimap keeps its place and whether it's hidden).
function L.setupMinimap()
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
  if not (LDB and DBIcon) or DBIcon:IsRegistered("ProfessionWizard") then return end
  local obj = LDB:NewDataObject("ProfessionWizard", {
    type = "launcher", text = "Profession Wizard", icon = "Interface\\Icons\\Trade_BlackSmithing",
    OnClick = function() if frame then frame:SetShown(not frame:IsShown()) end end,
    OnTooltipShow = function(tt)
      tt:AddLine("Profession Wizard")
      tt:AddLine("|cffffffffClick|r open or close the list", 0.7, 0.7, 0.7)
      tt:AddLine("|cffffffffDrag|r move the button", 0.7, 0.7, 0.7)
      tt:AddLine("Hide it under SETTINGS in the list", 0.7, 0.7, 0.7)
    end,
  })
  DBIcon:Register("ProfessionWizard", obj, ProfessionWizardDB.minimap)
end

local function setMinimap(show)
  ProfessionWizardDB.minimap.hide = (not show) or nil
  local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
  if DBIcon and DBIcon:IsRegistered("ProfessionWizard") then
    if show then DBIcon:Show("ProfessionWizard") else DBIcon:Hide("ProfessionWizard") end
  end
end

local function build()
  local ar, ag, ab = accent()
  local s = scheme()

  frame = CreateFrame("Frame", "ProfessionWizardFrame", UIParent)
  frame:SetSize(W, 400)
  frame:SetPoint("CENTER", -200, 40)
  frame:SetMovable(true); frame:EnableMouse(true); frame:SetClampedToScreen(true)
  frame:HookScript("OnShow", placeFrame)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if not (InCombatLockdown and InCombatLockdown()) then
      if smeltBtn then smeltBtn:Hide() end
      if openBtn then openBtn:Hide() end
    end
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); L.savePos(); refresh() end)
  frame:SetFrameStrata("HIGH")
  tinsert(UISpecialFrames, "ProfessionWizardFrame")

  local bg = frame:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
  bg:SetColorTexture(s.bg[1], s.bg[2], s.bg[3], 0.94)
  edges(frame, 1, 1, 1, 0.15)
  local bar = frame:CreateTexture(nil, "ARTWORK")
  bar:SetColorTexture(ar, ag, ab, 0.25)
  bar:SetPoint("TOPLEFT", 1, -1); bar:SetPoint("TOPRIGHT", -1, -1); bar:SetHeight(2)
  frame.bar = frame:CreateTexture(nil, "OVERLAY")
  frame.bar:SetColorTexture(ar, ag, ab, 0.95)
  frame.bar:SetPoint("TOPLEFT", 1, -1); frame.bar:SetHeight(2); frame.bar:SetWidth(1)

  local eyebrow = text(frame, 11, ar, ag, ab, 0.9)
  eyebrow:SetPoint("TOPLEFT", PAD, -12); eyebrow:SetText("PROFESSION WIZARD")

  local close = CreateFrame("Button", nil, frame)
  close:SetSize(20, 20); close:SetPoint("TOPRIGHT", -8, -7)
  close.fs = text(close, 15, 1, 1, 1, 0.4); close.fs:SetPoint("CENTER"); close.fs:SetText("×")
  close:SetScript("OnEnter", function(self) self.fs:SetTextColor(1, 0.45, 0.4, 1) end)
  close:SetScript("OnLeave", function(self) self.fs:SetTextColor(1, 1, 1, 0.4) end)
  close:SetScript("OnClick", function() frame:Hide() end)

  -- SETTINGS: a small panel under the header with the window's own switches
  -- (placed left of LISTS once that exists, further down)
  local setBtn = chip(frame, "SETTINGS", 76)
  setBtn:SetHeight(18); setBtn:SetPoint("TOPRIGHT", -98, -8)
  frame.setBtn = setBtn
  local opts = CreateFrame("Frame", nil, frame)
  opts:SetSize(208, 88); opts:SetPoint("TOPRIGHT", setBtn, "BOTTOMRIGHT", 0, -2)
  opts:SetFrameLevel(frame:GetFrameLevel() + 20); opts:EnableMouse(true); opts:Hide()
  local obg = opts:CreateTexture(nil, "BACKGROUND"); obg:SetAllPoints()
  obg:SetColorTexture(s.bg[1], s.bg[2], s.bg[3], 1)
  edges(opts, 1, 1, 1, 0.25)
  opts.mini = chip(opts, "MINIMAP BUTTON", 192)
  opts.mini:SetPoint("TOP", 0, -8)
  opts.mini:SetScript("OnClick", function(self)
    setMinimap(ProfessionWizardDB.minimap.hide and true or false); self:SetActive(not ProfessionWizardDB.minimap.hide)
  end)
  tip(opts.mini, "Minimap button", "Click it to open or close the list. Drag it to move it around the minimap.")
  opts.auto = chip(opts, "OPEN WITH PROFESSIONS", 192)
  opts.auto:SetPoint("TOP", opts.mini, "BOTTOM", 0, -4)
  opts.auto:SetScript("OnClick", function(self)
    ProfessionWizardDB.auto = (ProfessionWizardDB.auto == false); self:SetActive(ProfessionWizardDB.auto)
  end)
  tip(opts.auto, "Open with your profession windows",
    "On: the list opens when you open a crafting profession window below skill 300.",
    "Until you drag the list somewhere, it opens next to the profession window.")
  opts.tut = chip(opts, "SHOW TUTORIAL", 192)
  opts.tut:SetPoint("TOP", opts.auto, "BOTTOM", 0, -4)
  opts.tut:SetScript("OnClick", function() SlashCmdList.PROFESSIONWIZARD("tutorial") end)
  -- the panel next to Send Mail that fills mails with what your crafters need (on unless switched off)
  opts.mailp = chip(opts, "MAILBOX PANEL", 192)
  opts.mailp:SetPoint("TOP", opts.tut, "BOTTOM", 0, -4)
  opts.mailp:SetScript("OnClick", function(self)
    ProfessionWizardDB.mailPanel = (ProfessionWizardDB.mailPanel == false)
    self:SetActive(ProfessionWizardDB.mailPanel)
    -- right away when the mailbox is open (showing it lets the panel check whether it belongs there)
    local panel = _G.ProfessionWizardMailPanel
    if panel then
      if not ProfessionWizardDB.mailPanel then panel:Hide()
      elseif _G.SendMailFrame and _G.SendMailFrame:IsShown() then panel:Show() end
    end
  end)
  tip(opts.mailp, "Mailbox panel",
    "On Send Mail: what your crafters still need from this character, with FILL MAIL to attach it.")
  -- recipes from special trainers (a questline, or one NPC somewhere) may be used by routes unless switched off
  opts.special = chip(opts, "SPECIAL TRAINERS", 192)
  opts.special:SetPoint("TOP", opts.mailp, "BOTTOM", 0, -4)
  opts.special:SetScript("OnClick", function(self)
    ProfessionWizardDB.special = (ProfessionWizardDB.special == false)
    self:SetActive(ProfessionWizardDB.special)
    for _, byProf in pairs(ProfessionWizardDB.routes or {}) do
      for _, r in pairs(byProf) do if type(r) == "table" then r.dirty = true end end
    end
    refresh()
  end)
  tip(opts.special, "Special trainers",
    "On: routes may use recipes that only one NPC teaches, or that need a short questline first (like the Discolored potions).",
    "Off: only recipes from the usual profession trainers, recipes you know, and bought recipes.",
    "Click FIND CHEAPEST ROUTE after changing this.")
  -- learning the route's recipes at the trainer by itself (on unless switched off)
  opts.learn = chip(opts, "LEARN AT TRAINER", 192)
  opts.learn:SetPoint("TOP", opts.special, "BOTTOM", 0, -4)
  opts.learn:SetScript("OnClick", function(self)
    ProfessionWizardDB.autoLearn = (ProfessionWizardDB.autoLearn == false)
    self:SetActive(ProfessionWizardDB.autoLearn)
  end)
  tip(opts.learn, "Learn at the trainer",
    "On: talking to a trainer learns the recipes your routes use that it can teach you now, and the next rank when a route needs it.",
    "Each one is listed in chat with what it cost. Off: you pick them yourself.")
  -- routes that use up what you already own first (off unless switched on)
  opts.owned = chip(opts, "USE WHAT I HAVE", 192)
  opts.owned:SetPoint("TOP", opts.learn, "BOTTOM", 0, -4)
  opts.owned:SetScript("OnClick", function(self)
    ProfessionWizardDB.useOwned = not ProfessionWizardDB.useOwned
    self:SetActive(ProfessionWizardDB.useOwned)
    for _, byProf in pairs(ProfessionWizardDB.routes or {}) do
      for _, r in pairs(byProf) do if type(r) == "table" then r.dirty = true end end
    end
    refresh()
  end)
  tip(opts.owned, "Use what I have",
    "On: materials you already own count as free until they run out, so the route uses them before buying anything.",
    "What counts as owned follows COUNT BANK, COUNT ALTS and COUNT MAIL.",
    "Click FIND CHEAPEST ROUTE after changing this.")
  -- Color scheme: one swatch per scheme, like Itinerary's setting; picking one reloads the UI
  opts.schemeLbl = text(opts, 10, 1, 1, 1, 0.5)
  opts.schemeLbl:SetPoint("TOPLEFT", opts.owned, "BOTTOMLEFT", 0, -10); opts.schemeLbl:SetText("COLOR SCHEME")
  opts.swatches = {}
  for i, sc in ipairs(L.SCHEME_ORDER) do
    local key, label = sc[1], sc[2]
    local b = CreateFrame("Button", nil, opts)
    b:SetSize(28, 18)
    b:SetPoint("TOPLEFT", opts.schemeLbl, "BOTTOMLEFT", (i - 1) * 32, -4)
    local c = SCHEMES[key].accent
    local tex = b:CreateTexture(nil, "ARTWORK"); tex:SetAllPoints(); tex:SetColorTexture(c[1], c[2], c[3], 1)
    b.ring = CreateFrame("Frame", nil, b); b.ring:SetPoint("TOPLEFT", -2, 2); b.ring:SetPoint("BOTTOMRIGHT", 2, -2)
    edges(b.ring, 1, 1, 1, 0.9); b.ring:Hide()
    b.key = key
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(label)
      if key == "itinerary" then GameTooltip:AddLine("Green and gold; follows EllesmereUI's colour when it's installed.", 0.8, 0.8, 0.8, true) end
      GameTooltip:AddLine("Click to use it. The UI reloads.", 0.6, 0.6, 0.6, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function()
      if ProfessionWizardDB.scheme == key then return end
      ProfessionWizardDB.scheme = key; ReloadUI()
    end)
    opts.swatches[i] = b
  end
  local hasItinerary = ItineraryDB and ItineraryDB.panel and true or false
  local h = 88 + 26 + 22 + 22 + 22 + 10 + 12 + 4 + 18 + 8
  if hasItinerary then
    opts.follow = chip(opts, "SAME AS ITINERARY", 192)
    opts.follow:SetPoint("TOPLEFT", opts.schemeLbl, "BOTTOMLEFT", 0, -28)
    opts.follow:SetScript("OnClick", function()
      if ProfessionWizardDB.scheme == nil then return end
      ProfessionWizardDB.scheme = nil; ReloadUI()
    end)
    tip(opts.follow, "Same as Itinerary", "Use whatever colour scheme Itinerary is set to. The UI reloads.")
    h = h + 26
  end
  opts:SetHeight(h)
  opts:SetScript("OnShow", function(self)
    self.mini:SetActive(not ProfessionWizardDB.minimap.hide); self.auto:SetActive(ProfessionWizardDB.auto ~= false)
    local cur = ProfessionWizardDB.scheme
    local shown = cur or (ItineraryDB and ItineraryDB.panel and ItineraryDB.panel.scheme) or "copper"
    for _, b in ipairs(self.swatches) do b.ring:SetShown(b.key == shown) end
    if self.follow then self.follow:SetActive(cur == nil) end
    self.mailp:SetActive(ProfessionWizardDB.mailPanel ~= false)
    self.special:SetActive(ProfessionWizardDB.special ~= false)
    self.learn:SetActive(ProfessionWizardDB.autoLearn ~= false)
    self.owned:SetActive(ProfessionWizardDB.useOwned and true or false)
  end)
  setBtn:SetScript("OnClick", function()
    opts:SetShown(not opts:IsShown())
    if opts:IsShown() and frame.menu then frame.menu:Hide() end
  end)
  opts:HookScript("OnShow", function() setBtn:SetActive(true) end)
  opts:HookScript("OnHide", function() setBtn:SetActive(false) end)
  frame:HookScript("OnHide", function() opts:Hide() end)
  frame.opts = opts

  frame.title = text(frame, 14, 1, 1, 1, 0.95)
  frame.title:SetPoint("TOPLEFT", PAD, -32)
  frame.sub = text(frame, 11, 1, 1, 1, 0.55)
  frame.sub:SetPoint("TOPLEFT", PAD, -52); frame.sub:SetWidth(W - PAD * 2)

  -- one chip per profession you have
  for i, pr in ipairs(PROFS) do
    if not pr.gather then
      local c = chip(frame, pr.short, 80)
      c.pid = pr.id
      c:SetScript("OnClick", function() pick(pr.id) end)
      profChips[#profChips + 1] = c
    end
  end

  -- target controls
  local lbl = text(frame, 11, 1, 1, 1, 0.5)
  lbl:SetPoint("TOPLEFT", PAD, -108); lbl:SetText("CHECK UNTIL")
  local minus = chip(frame, "-", 20)
  minus:SetPoint("TOPLEFT", PAD + 80, -104)
  local eb = CreateFrame("EditBox", nil, frame)
  eb:SetSize(44, 20); eb:SetPoint("LEFT", minus, "RIGHT", 4, 0)
  eb:SetAutoFocus(false); eb:SetNumeric(true); eb:SetMaxLetters(3)
  eb:SetFont(fontPath(), 12, ""); eb:SetJustifyH("CENTER"); eb:SetTextColor(1, 1, 1, 0.95)
  local ebg = eb:CreateTexture(nil, "BACKGROUND"); ebg:SetAllPoints()
  ebg:SetColorTexture(s.btn[1], s.btn[2], s.btn[3], 1)
  edges(eb, 1, 1, 1, 0.18)
  eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  eb:SetScript("OnEscapePressed", function(self) self.cancel = true; self:ClearFocus() end)
  eb:SetScript("OnEditFocusLost", function(self)
    if self.cancel then self.cancel = nil; refresh(); return end
    setTarget(tonumber(self:GetText()))
  end)
  frame.eb = eb
  local plus = chip(frame, "+", 20)
  plus:SetPoint("LEFT", eb, "RIGHT", 4, 0)
  minus:SetScript("OnClick", function() setTarget((frame.target or 300) - (IsShiftKeyDown() and 5 or 1)) end)
  plus:SetScript("OnClick", function() setTarget((frame.target or 1) + (IsShiftKeyDown() and 5 or 1)) end)

  frame.milestones = {}
  local prev = plus
  for _, m in ipairs(MILESTONES) do
    local c = chip(frame, tostring(m), 40)
    c:SetPoint("LEFT", prev, "RIGHT", prev == plus and 14 or 4, 0)
    c:SetScript("OnClick", function() setTarget(m) end)
    c.value = m
    frame.milestones[#frame.milestones + 1] = c
    prev = c
  end

  frame.find = chip(frame, "FIND CHEAPEST ROUTE", 160)
  frame.find:SetPoint("TOPRIGHT", -PAD, -104)
  frame.find:SetScript("OnClick", function()
    local pid = shownProf()
    if not pid then return end
    local cur = readSkill(pid) or 1
    local r = routeFor(pid, cur, targetFor(pid, cur), true)
    if not ahPrice(2589) and not ahPrice(2770) and not ahPrice(2592) then
      Print("no AH prices found: open the auction house and click SCAN AH (or scan with Auctionator) first.")
    end
    Print(string.format("%s route %d-%d worked out from %d usable recipes.", profName(pid), r.from, r.to, r.cands or 0))
    refresh()
    pcall(saveGoals)
  end)
  tip(frame.find, "Find the cheapest route",
    "Uses your Auctionator prices to pick, for every skill point, the recipe with the lowest material cost minus what a vendor pays for the result, divided by the chance of a point.",
    "Materials you can make for less than they cost (bars, bolts, stones...) are made instead of bought.",
    "Scan the auction house first for fresh prices.")

  -- options
  frame.plans = chip(frame, "BUY RECIPES", 100)
  frame.plans:SetPoint("TOPLEFT", PAD, -132)
  frame.plans:SetScript("OnClick", function()
    ProfessionWizardDB.plans = not ProfessionWizardDB.plans
    local pid = shownProf()
    if pid and routeStore()[pid] then routeStore()[pid].dirty = true end
    refresh()
  end)
  tip(frame.plans, "Recipes you'd have to buy",
    "On: the route may use plans, patterns and formulas you don't know yet, if they're on the AH or you've seen them at a vendor. Their price counts toward the route.",
    "Off: only recipes you know or can learn from your trainer.",
    "Click FIND CHEAPEST ROUTE after changing this.")
  frame.bank = chip(frame, "COUNT BANK", 96)
  frame.bank:SetPoint("LEFT", frame.plans, "RIGHT", 4, 0)
  frame.bank:SetScript("OnClick", function() ProfessionWizardDB.bank = not ProfessionWizardDB.bank; refresh() end)
  frame.alts = chip(frame, "COUNT ALTS", 90)
  frame.alts:SetPoint("LEFT", frame.bank, "RIGHT", 4, 0)
  frame.alts:SetScript("OnClick", function() ProfessionWizardDB.alts = not ProfessionWizardDB.alts; refresh() end)
  tip(frame.alts, "Your other characters", function()
    local list = alts()
    if #list == 0 then
      GameTooltip:AddLine("None yet. Log in on an alt once and its bags are saved. Open its bank once to save that too.", 0.8, 0.8, 0.8, true)
    else
      for _, c in ipairs(list) do GameTooltip:AddDoubleLine(c.name, ago(c.time), 1, 1, 1, 0.6, 0.6, 0.6) end
      GameTooltip:AddLine("Saved when you play them. Open each bank once so it's counted.", 0.8, 0.8, 0.8, true)
    end
  end)
  frame.mail = chip(frame, "COUNT MAIL", 86)
  frame.mail:SetPoint("LEFT", frame.alts, "RIGHT", 4, 0)
  frame.mail:SetScript("OnClick", function() ProfessionWizardDB.mail = not ProfessionWizardDB.mail; refresh() end)
  tip(frame.mail, "Mail", "Your mailbox is read each time you open it. Things you mail to your own characters count on them straight away.")
  frame.buffer = chip(frame, "SPARE 10%", 86)
  frame.buffer:SetPoint("LEFT", frame.mail, "RIGHT", 4, 0)
  frame.buffer:SetScript("OnClick", function()
    local b = ProfessionWizardDB.buffer or 0
    ProfessionWizardDB.buffer = (b == 0 and 10) or (b == 10 and 25) or 0
    refresh()
  end)
  tip(frame.buffer, "Spare crafts", "Yellow and green crafts don't always give a point. This adds extra materials for bad luck.")

  frame.scanBtn = chip(frame, "SCAN AH", 92)
  frame.scanBtn:SetPoint("TOPRIGHT", -PAD, -132)
  frame.scanBtn:SetScript("OnClick", function() startScan() end)
  tip(frame.scanBtn, "Scan the auction house",
    "Searches the auction house for just the materials (and recipes) this profession could use from your skill up to your target. Then works the route out again.",
    "Prices less than an hour old are skipped. Click again to stop.",
    "Your own scan is used over Auctionator's prices while it's less than a day old. Works without Auctionator.")

  frame.ctrl = { lbl, minus, eb, plus, frame.find, frame.plans, frame.bank, frame.alts, frame.mail, frame.buffer, frame.scanBtn }

  local cast = CreateFrame("Frame", nil, frame)
  cast:SetSize(W - PAD * 2, 18)
  local ctrack = cast:CreateTexture(nil, "BACKGROUND"); ctrack:SetAllPoints()
  ctrack:SetColorTexture(s.btn[1], s.btn[2], s.btn[3], 1)
  edges(cast, 1, 1, 1, 0.15)
  cast.fill = cast:CreateTexture(nil, "ARTWORK")
  cast.fill:SetColorTexture(ar, ag, ab, 0.85)
  cast.fill:SetPoint("TOPLEFT", 1, -1); cast.fill:SetPoint("BOTTOMLEFT", 1, 1); cast.fill:SetWidth(1)
  cast.text = text(cast, 11, 1, 1, 1, 0.95)
  cast.text:SetPoint("CENTER"); cast.text:SetJustifyH("CENTER"); cast.text:SetWidth(W - PAD * 2 - 8)
  cast:SetScript("OnUpdate", function(self)
    if not job then self:Hide(); return end
    local now = GetTime() * 1000
    local frac, left = 0, 0
    if job.st and job.et and job.et > job.st then
      local per = (job.et - job.st) / 1000
      if job.casting then
        frac = math.max(0, math.min(1, (now - job.st) / (job.et - job.st)))
        left = math.max(0, (job.et - now) / 1000) + math.max(0, job.total - job.done - 1) * per
      else
        left = math.max(0, job.total - job.done) * per
      end
    end
    local whole = math.min(1, (job.done + frac) / math.max(1, job.total))
    self.fill:SetWidth(math.max(1, (self:GetWidth() - 2) * whole))
    local tail
    if job.stopped then tail = "  ·  " .. job.stopped
    elseif left > 0 then tail = string.format("  ·  %d:%02d left", math.floor(left / 60), math.floor(left % 60))
    else tail = "" end
    self.text:SetText(string.format("%s   %d / %d%s", job.label or "", job.done, job.total, tail))
  end)
  cast:Hide()
  frame.cast = cast

  -- the price hint: shown above the route while the prices for it are missing or old
  local hint = CreateFrame("Frame", nil, frame)
  hint:SetSize(W - PAD * 2, 30)
  local hbg = hint:CreateTexture(nil, "BACKGROUND"); hbg:SetAllPoints()
  hbg:SetColorTexture(s.warm[1], s.warm[2], s.warm[3], 0.08)
  local hbar = hint:CreateTexture(nil, "ARTWORK")
  hbar:SetColorTexture(s.warm[1], s.warm[2], s.warm[3], 0.9)
  hbar:SetPoint("TOPLEFT"); hbar:SetPoint("BOTTOMLEFT"); hbar:SetWidth(2)
  hint.fs = text(hint, 11, s.warm[1], s.warm[2], s.warm[3], 0.95)
  hint.fs:SetPoint("TOPLEFT", 10, -6); hint.fs:SetWidth(W - PAD * 2 - 20); hint.fs:SetWordWrap(true)
  hint:Hide()
  frame.hint = hint

  frame.stepsHead = text(frame, 11, ar, ag, ab, 0.9)
  frame.stepsHead:SetText("CRAFTS")
  for i = 1, MAX_STEPS do stepLines[i] = L.makeStep(i) end
  for _, l in ipairs(stepLines) do
    l:EnableMouseWheel(true)
    l:SetScript("OnMouseWheel", function(_, d) L.scrollList("step", -d) end)
  end

  frame.matHead = text(frame, 11, ar, ag, ab, 0.9)
  frame.matHead:SetText("MATERIALS")
  frame.colNeed = text(frame, 11, 1, 1, 1, 0.4); frame.colNeed:SetText("NEED"); frame.colNeed:SetJustifyH("RIGHT"); frame.colNeed:SetWidth(60)
  frame.colHave = text(frame, 11, 1, 1, 1, 0.4); frame.colHave:SetText("HAVE"); frame.colHave:SetJustifyH("RIGHT"); frame.colHave:SetWidth(W_HAVE)
  frame.colStat = text(frame, 11, 1, 1, 1, 0.4); frame.colStat:SetText("STILL NEED")

  for i = 1, MAX_ROWS do rows[i] = L.makeRow(i) end
  -- both lists scroll with the mouse wheel once they're longer than fits
  for _, r in ipairs(rows) do
    r:EnableMouseWheel(true)
    r:SetScript("OnMouseWheel", function(_, d) L.scrollList("mat", -d) end)
  end
  frame.more = text(frame, 11, 1, 1, 1, 0.45)

  frame.foot = text(frame, 11, 1, 1, 1, 0.55)
  frame.foot:SetWidth(W - PAD * 2); frame.foot:SetWordWrap(true); frame.foot:SetSpacing(3)
  frame.buy = chip(frame, "SEARCH MISSING", 120)
  frame.buy:SetScript("OnClick", function()
    local names, qty = {}, {}
    for _, row in ipairs(frame.list or {}) do
      local miss = row.missing or row.buy or 0
      local n = miss > 0 and GetItemInfo(row.id)
      if n then
        if not qty[n] then names[#names + 1] = n end
        qty[n] = (qty[n] or 0) + miss -- an item with an indented line too: both parts
      end
    end
    for _, id in ipairs(frame.planBuys or {}) do
      local n = GetItemInfo(id)
      if n and not qty[n] then names[#names + 1] = n; qty[n] = 1 end
    end
    searchAH(names, qty)
  end)

  frame.empty = text(frame, 12, 1, 1, 1, 0.7)
  frame.empty:SetWidth(W - PAD * 2); frame.empty:SetWordWrap(true)

  -- SMELT ALL: every bar on the list, one after another (needs the smelting window open)
  frame.smeltAll = chip(frame, "SMELT ALL", 120)
  frame.smeltAll:SetScript("OnClick", function(self)
    if jobBusy() then Print("already crafting."); return end
    queue = {}
    for _, q in ipairs(self.list or {}) do queue[#queue + 1] = { r = q.r, n = q.n } end
    if #queue == 0 then Print("nothing to smelt.") end
    nextInQueue(true)
  end)
  tip(frame.smeltAll, "Smelt everything on the list", "Smelts each kind of bar in turn, from ore you have in your bags.",
    "Moving or getting hit stops it.")
  frame.smeltAll:Hide()

  -- OPEN SMELTING: a real spell cast, so it has to be a secure button
  smeltBtn = chip(UIParent, "OPEN SMELTING", 120, "SecureActionButtonTemplate", "ProfessionWizardSmeltButton")
  smeltBtn:SetFrameStrata("DIALOG")
  local down = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
  smeltBtn:RegisterForClicks(down and "AnyDown" or "AnyUp")
  smeltBtn:SetAttribute("type", "spell")
  smeltBtn:SetAttribute("spell", L.spellName(2656) or "Smelting")
  tip(smeltBtn, "Open smelting", "Opens your smelting window. Then SMELT ALL turns the ore on the list into bars.")
  smeltBtn:Hide()

  -- OPEN SMITHING etc.: opens the profession window so the CRAFT buttons can work
  openBtn = chip(UIParent, "OPEN", 116, "SecureActionButtonTemplate", "ProfessionWizardOpenButton")
  openBtn:SetFrameStrata("DIALOG")
  openBtn:RegisterForClicks(down and "AnyDown" or "AnyUp")
  openBtn:SetAttribute("type", "spell")
  tip(openBtn, "Open the profession window", "Crafting only works while its window is open. Then a CRAFT button with an amount shows up here.")
  openBtn:Hide()

  frame:HookScript("OnHide", function()
    if smeltBtn and not (InCombatLockdown and InCombatLockdown()) then smeltBtn:Hide() end
    if openBtn and not (InCombatLockdown and InCombatLockdown()) then openBtn:Hide() end
    if frame.menu then frame.menu:Hide() end
  end)

  -- LISTS: browse the lists your other characters saved
  frame.lists = chip(frame, "LISTS", 60)
  frame.lists:SetPoint("TOPRIGHT", -34, -8)
  frame.lists:SetHeight(18)
  frame.lists:SetScript("OnClick", function() if frame.opts then frame.opts:Hide() end; toggleMenu() end)
  frame.setBtn:ClearAllPoints(); frame.setBtn:SetPoint("RIGHT", frame.lists, "LEFT", -4, 0)
  tip(frame.lists, "Your characters' lists",
    "See what another character still needs: what you can send it from here and what to buy for it.",
    "Lists are saved whenever you play the crafter.")

  frame:HookScript("OnShow", function() refresh() end)
  frame:Hide()
end

-- every saved list from your other characters on this realm and faction, newest first
function L.sheetList()
  local list = {}
  local realm, faction, me = GetRealmName(), UnitFactionGroup("player"), myKey()
  for k, g in pairs(ProfessionWizardDB.goals or {}) do
    if g.owner ~= me and g.realm == realm and g.faction == faction and g.rows then g.key = k; list[#list + 1] = g end
  end
  table.sort(list, function(a, b) return (a.time or 0) > (b.time or 0) end)
  return list
end

toggleMenu = function()
  local m = frame.menu
  if not m then
    local s = scheme()
    m = CreateFrame("Frame", nil, frame)
    m:SetFrameLevel(frame:GetFrameLevel() + 30)
    m:SetPoint("TOPRIGHT", frame.lists, "BOTTOMRIGHT", 0, -2)
    m:SetWidth(300)
    local bg = m:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
    bg:SetColorTexture(s.bg[1], s.bg[2], s.bg[3], 0.98)
    edges(m, 1, 1, 1, 0.25)
    m.items = {}
    m:EnableMouse(true)
    m:Hide()
    frame.menu = m
  end
  if m:IsShown() then m:Hide(); return end
  local entries = {}
  if shownProf() then entries[#entries + 1] = { label = "YOUR OWN LIST", key = false } end
  for _, g in ipairs(L.sheetList()) do
    entries[#entries + 1] = { label = string.format("%s  %s %d>%d  ·  %s", (g.name or "?"):upper(),
      PROF[g.pid] and PROF[g.pid].short or "?", g.skill or 0, g.target or 0, ago(g.time)), key = g.key }
  end
  if #entries == 0 then
    entries[1] = { label = "NO LISTS SAVED YET", key = false, none = true }
  end
  local y = 6
  for i, e in ipairs(entries) do
    local c = m.items[i]
    if not c then
      c = chip(m, "", 288); c:SetHeight(20)
      c:SetScript("OnClick", function(self)
        m:Hide()
        if self.none then return end
        viewing = self.key or nil
        refresh()
      end)
      m.items[i] = c
    end
    c.key, c.none = e.key, e.none
    c.text:SetText(e.label)
    c:SetActive((e.key or nil) == viewing and not e.none)
    c:ClearAllPoints(); c:SetPoint("TOPLEFT", 6, -y); c:Show()
    y = y + 24
  end
  for i = #entries + 1, #m.items do m.items[i]:Hide() end
  m:SetHeight(y + 2)
  m:Show()
end

-- secure buttons hang off UIParent at the right spot over the window (anchoring them to the
-- window would lock the window during combat); they're only moved out of combat
placeSecure = function(btn, x, y)
  if not btn or (InCombatLockdown and InCombatLockdown()) then return end
  local l, t = frame:GetLeft(), frame:GetTop()
  if not l or not t then btn:Hide(); return end
  -- same scale as the window, so its coordinates line up
  btn:SetScale(frame:GetScale())
  btn:ClearAllPoints()
  btn:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l + x, t - y)
  btn:Show()
end

function L.hideSecure(btn)
  if btn and not (InCombatLockdown and InCombatLockdown()) then btn:Hide() end
end

local function placeSmelt(list, y, buyShown, hide)
  local total = 0
  for _, q in ipairs(list or {}) do total = total + q.n end
  if hide then total = 0 end
  local right = buyShown and (PAD + 124) or PAD
  local miningOpen = tsOpen and tsProf == MINING
  local smeltShown = false
  if total > 0 and miningOpen then
    frame.smeltAll.list = list
    frame.smeltAll.text:SetText("SMELT ALL " .. total)
    frame.smeltAll:ClearAllPoints(); frame.smeltAll:SetPoint("TOPRIGHT", -right, -y)
    frame.smeltAll:SetActive(not (job and not job.stopped)); frame.smeltAll:Show()
    smeltShown = true
  else
    frame.smeltAll:Hide()
  end
  local wantOpen = total > 0 and not miningOpen and (readSkill(MINING) or 0) > 0
  if smeltBtn and not (InCombatLockdown and InCombatLockdown()) then
    if wantOpen then
      placeSecure(smeltBtn, W - right - 120, y)
      smeltShown = true
    else
      smeltBtn:Hide()
    end
  end
end

-- the summary gets its own lines across the window, the buttons (SEARCH MISSING, SMELT ...) a row under it
local function placeFooter(y, buyShown, smeltList, hideSmelt)
  frame.foot:ClearAllPoints(); frame.foot:SetPoint("TOPLEFT", PAD, -y)
  frame.foot:Show()
  y = y + math.ceil(frame.foot:GetStringHeight()) + 8
  frame.buy:ClearAllPoints(); frame.buy:SetPoint("TOPRIGHT", -PAD, -y)
  frame.buy:SetShown(buyShown)
  placeSmelt(smeltList, y, buyShown, hideSmelt)
  local row = buyShown or frame.smeltAll:IsShown() or (smeltBtn and smeltBtn:IsShown())
  frame:SetHeight(y + (row and 34 or 10))
end

---------------------------------------------------------------------------
-- Own auction house scan: only the items this profession could use in your range
---------------------------------------------------------------------------
local ahOpen = false
local scan -- { list, i, total, pid, id, name, waiting, sentAt, found, none, tries }
local scanFrame = CreateFrame("Frame")
scanFrame:Hide()

local function scanLabel()
  if not frame or not frame.scanBtn then return end
  if scan then
    frame.scanBtn.text:SetText(string.format("STOP %d/%d", math.min(scan.i, scan.total), scan.total))
    frame.scanBtn:SetActive(true)
  else
    frame.scanBtn.text:SetText("SCAN AH")
    frame.scanBtn:SetActive(false)
  end
end

-- materials (and plans, and what bars/bolts are made from) for recipes in from..to
local function scanList(pid, from, to)
  local ctx = newCtx(pid, from)
  local seen, list = {}, {}
  local function add(id, depth)
    if not id or id == 0 or seen[id] then return end
    seen[id] = true
    if not ns.VENDOR_ITEMS[id] then list[#list + 1] = id end
    if depth < 2 then
      for _, r in ipairs(L.producers(id, pid)) do
        if L.canMake(r, ctx) then
          for _, m in ipairs(r.mats) do add(m[1], depth + 1) end
        end
      end
    end
  end
  for _, r in ipairs(recipes(pid).list) do
    if r.g > from and r.learn < to and (r.creates > 0 or r.prof == 333) then
      local known = isKnown(r)
      if known or L.trainable(r) or (r.plans > 0 and ProfessionWizardDB.plans) then
        for _, m in ipairs(r.mats) do add(m[1], 0) end
        if not known and not r.trainer then add(r.plans, 2) end
      end
    end
  end
  return list
end

-- How good the prices are for what this profession needs from cur to target:
--   "none"  most materials have no auction house price at all (never scanned)
--   "old"   they have prices, but most are older than a day (own scan or Auctionator)
--   "ok"    fresh enough
-- plus whether Auctionator is installed and how old the newest price is (days). Cached for a few seconds.
local priceCache = {}
function L.auctionatorAge(id)
  local a = Auctionator and Auctionator.API and Auctionator.API.v1
  if not (a and a.GetAuctionAgeByItemID) then return nil end
  local ok, d = pcall(a.GetAuctionAgeByItemID, CALLER, id)
  if ok and type(d) == "number" then return d end
end

local function priceState(pid, cur, target)
  local key = pid .. ":" .. cur .. ":" .. target
  local c = priceCache[key]
  if c and GetTime() - c.at < 10 then return c end
  local hasAuctionator = (Auctionator and Auctionator.API and Auctionator.API.v1) and true or false
  local own = ProfessionWizardDB.scan and ProfessionWizardDB.scan[GetRealmName() or "?"] or {}
  local total, priced, fresh, newest = 0, 0, 0, nil
  local ok, list = pcall(scanList, pid, cur, target)
  for _, id in ipairs(ok and list or {}) do
    total = total + 1
    local o = own[id]
    local ageO = o and o.p and o.t and (time() - o.t) / 86400
    local ageA = L.auctionatorPrice(id) and (L.auctionatorAge(id) or 0)
    local age = (ageO and ageA and math.min(ageO, ageA)) or ageO or ageA
    if age then
      priced = priced + 1
      if age < 1 then fresh = fresh + 1 end
      if not newest or age < newest then newest = age end
    end
  end
  local state = "ok"
  if total > 0 and priced < total * 0.5 then state = "none"
  elseif total > 0 and fresh < priced * 0.5 then state = "old" end
  c = { at = GetTime(), state = state, auctionator = hasAuctionator, newest = newest, total = total, priced = priced }
  priceCache[key] = c
  return c
end

-- the words for the price hint, or nil when the prices are fine
local function priceHint(ps)
  if not ps or ps.state == "ok" then return nil end
  local n = ps.total
  if ps.state == "none" then
    if ahOpen then
      return string.format("No prices yet for this route's %d materials. You're at the auction house: click SCAN AH, then FIND CHEAPEST ROUTE.", n)
    elseif ps.auctionator then
      return "Auctionator has no prices for these materials yet, so the route can't be worked out. Go to an auction house and click SCAN AH (it looks up just what this route needs), then FIND CHEAPEST ROUTE."
    end
    return "No auction house prices yet, so the route can't be worked out. Go to an auction house and click SCAN AH: Profession Wizard looks up just the materials this route needs, no other addon required. Then click FIND CHEAPEST ROUTE."
  end
  if ahOpen then
    return "Most of your prices are over a day old. You're at the auction house: click SCAN AH for fresh ones, then FIND CHEAPEST ROUTE."
  end
  return "Most of your prices for this route are over a day old and the cheapest route may have changed. Next time you're at an auction house, click SCAN AH, then FIND CHEAPEST ROUTE."
end

local function finishScan(stopped)
  local s = scan
  scan = nil
  for k in pairs(priceCache) do priceCache[k] = nil end
  scanFrame:Hide()
  scanLabel()
  if not s then return end
  Print(string.format("%s %d items: %d listed, %d not on the AH.", stopped and "stopped after" or "scanned",
    s.found + s.none, s.found, s.none))
  if s.found + s.none > 0 then
    -- work the route out again from the new prices
    local cur = readSkill(s.pid) or 1
    routeFor(s.pid, cur, targetFor(s.pid, cur), true)
    pcall(saveGoals)
  end
  if refresh then refresh() end
end

-- The auction house: WoW Forever looks like Classic but runs the modern auction house underneath
-- (C_AuctionHouse: search by item, commodities and items, a throttle between searches). Older clients have
-- the Classic one (QueryAuctionItems / GetAuctionItemInfo). The scan uses whichever this client has.
function L.modernAH()
  return C_AuctionHouse and C_AuctionHouse.SendSearchQuery and C_AuctionHouse.MakeItemKey and true or false
end

function L.readResults()
  if not scan or not scan.waiting then return end
  local n = (GetNumAuctionItems and GetNumAuctionItems("list")) or 0
  local units, qty = {}, 0
  for i = 1, n do
    local info = { GetAuctionItemInfo("list", i) }
    local cnt, buyout, iid = info[3] or 1, info[10] or 0, info[17]
    if buyout > 0 and cnt > 0 and (iid == scan.id or (iid == nil and info[1] == scan.name)) then
      units[#units + 1] = { p = buyout / cnt, n = cnt }
      qty = qty + cnt
    end
  end
  L.storeUnits(units, qty)
end

-- modern auction house results for the item we searched: "commodity" (materials, arg = itemID) or
-- "item" (gear, recipes ..., arg = itemKey)
function L.readModern(kind, arg)
  if not scan or not scan.waiting then return end
  local A = C_AuctionHouse
  local units, qty = {}, 0
  -- The game sometimes answers before the results are there (none, or "not complete yet" with 0). Like
  -- Auctionator, search again then (up to 3 times) instead of taking it as "not on the auction house".
  local function incomplete(key, full, quantity)
    local has = A.HasSearchResults and A.HasSearchResults(key)
    if has == nil then return false end
    return (not has) or (not full and (quantity or 0) == 0)
  end
  if kind == "commodity" and arg == scan.id then
    local full = A.HasFullCommoditySearchResults and A.HasFullCommoditySearchResults(scan.id)
    local quantity = A.GetCommoditySearchResultsQuantity and A.GetCommoditySearchResultsQuantity(scan.id)
    if incomplete(scan.key, full, quantity) and (scan.again or 0) < 3 then
      scan.again = (scan.again or 0) + 1; scan.waiting = false; scan.resend = true; return
    end
  elseif kind == "item" and (type(arg) ~= "table" or not arg.itemID or arg.itemID == scan.id) then
    local full = A.HasFullItemSearchResults and A.HasFullItemSearchResults(scan.key)
    local quantity = A.GetItemSearchResultsQuantity and A.GetItemSearchResultsQuantity(scan.key)
    if incomplete(scan.key, full, quantity) and (scan.again or 0) < 3 then
      scan.again = (scan.again or 0) + 1; scan.waiting = false; scan.resend = true; return
    end
  end
  if kind == "commodity" then
    if arg ~= scan.id then return end
    local n = (A.GetNumCommoditySearchResults and A.GetNumCommoditySearchResults(scan.id)) or 0
    for i = 1, n do
      local r = A.GetCommoditySearchResultInfo(scan.id, i)
      if r and (r.unitPrice or 0) > 0 and (r.quantity or 0) > 0 then
        units[#units + 1] = { p = r.unitPrice, n = r.quantity }
        qty = qty + r.quantity
      end
    end
  else
    if type(arg) == "table" and arg.itemID and arg.itemID ~= scan.id then return end
    local key = scan.key
    local n = (A.GetNumItemSearchResults and A.GetNumItemSearchResults(key)) or 0
    for i = 1, n do
      local r = A.GetItemSearchResultInfo(key, i)
      local q = r and math.max(1, r.quantity or 1)
      if r and (r.buyoutAmount or 0) > 0 then
        -- buyoutAmount is the price of one (that's how Auctionator reads it too); dividing it by the quantity
        -- made recipes and other single items look 15-20 times cheaper than they are
        units[#units + 1] = { p = r.buyoutAmount, n = q }
        qty = qty + q
      end
    end
  end
  L.storeUnits(units, qty)
end

function L.storeUnits(units, qty)
  table.sort(units, function(a, b) return a.p < b.p end)
  local st = L.scanStore()
  if #units == 0 then
    st[scan.id] = { t = time() } -- none listed right now
    scan.none = scan.none + 1
  else
    -- the price you'd pay for the cheapest 15% of what's listed: one odd cheap stack can't skew it
    local want_, acc, price = math.max(1, math.ceil(qty * 0.15)), 0, units[1].p
    for _, u in ipairs(units) do
      acc = acc + u.n; price = u.p
      if acc >= want_ then break end
    end
    st[scan.id] = { p = math.floor(price + 0.5), t = time() }
    scan.found = scan.found + 1
  end
  scan.waiting = false
  scanLabel()
end

scanFrame:SetScript("OnUpdate", function(self)
  if not scan then self:Hide(); return end
  if not ahOpen then finishScan(true); return end
  if scan.waiting then
    if GetTime() - scan.sentAt > 8 then
      -- no answer: try this item once more at the end, then move on
      scan.waiting = false
      if scan.id then
        scan.tries[scan.id] = (scan.tries[scan.id] or 0) + 1
        if scan.tries[scan.id] < 2 then scan.list[#scan.list + 1] = scan.id; scan.total = #scan.list end
      end
    end
    return
  end
  if L.modernAH() then
    -- one search at a time, and only when the game's throttle lets the next one through
    local A = C_AuctionHouse
    if A.IsThrottledMessageSystemReady and not A.IsThrottledMessageSystemReady() then return end
    local sorts = { { sortOrder = Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0, reverseSort = false } }
    if scan.resend and scan.key then
      -- the last answer came back empty or incomplete: ask again for the same item
      scan.resend, scan.waiting, scan.sentAt = false, true, GetTime()
      if not pcall(A.SendSearchQuery, scan.key, sorts, true) then scan.waiting = false end
      return
    end
    if not scan.pending then
      scan.i = scan.i + 1
      local id = scan.list[scan.i]
      if not id then finishScan(); return end
      local okKey, key = pcall(A.MakeItemKey, id)
      if not okKey or not key then return end
      scan.pending, scan.pendingKey, scan.pendingAt = id, key, GetTime()
    end
    -- the game ignores a search for an item it hasn't cached yet: wait for its item key info first
    -- (up to 3 seconds; then try it once more at the end)
    if A.GetItemKeyInfo and not A.GetItemKeyInfo(scan.pendingKey) then
      if GetTime() - scan.pendingAt < 3 then return end
      local id = scan.pending
      scan.pending = nil
      scan.tries[id] = (scan.tries[id] or 0) + 1
      if scan.tries[id] < 2 then scan.list[#scan.list + 1] = id; scan.total = #scan.list end
      return
    end
    scan.id, scan.key, scan.name, scan.again = scan.pending, scan.pendingKey, GetItemInfo(scan.pending), 0
    scan.pending = nil
    scan.waiting, scan.sentAt = true, GetTime()
    if not pcall(A.SendSearchQuery, scan.key, sorts, true) then scan.waiting = false end
    scanLabel()
    return
  end
  if not CanSendAuctionQuery then finishScan(true); return end
  local ok, can = pcall(CanSendAuctionQuery)
  if not ok or not can then return end
  scan.i = scan.i + 1
  local id = scan.list[scan.i]
  if not id then finishScan(); return end
  local name = GetItemInfo(id)
  if not name then
    -- item not loaded yet: try it again at the end
    scan.tries[id] = (scan.tries[id] or 0) + 1
    if scan.tries[id] < 4 then scan.list[#scan.list + 1] = id end
    return
  end
  scan.id, scan.name, scan.waiting, scan.sentAt = id, name, true, GetTime()
  if SortAuctionClearSort then pcall(SortAuctionClearSort, "list") end
  if SortAuctionSetSort then pcall(SortAuctionSetSort, "list", "unitprice", false) end
  local sent = pcall(QueryAuctionItems, name, nil, nil, 0, false, nil, false, true)
  if not sent then scan.waiting = false end
  scanLabel()
end)

startScan = function()
  if scan then finishScan(true); return end
  if not ahOpen then Print("open the auction house first, then click SCAN AH."); return end
  local pid = shownProf()
  if not pid then return end
  local cur = readSkill(pid) or 1
  local target = targetFor(pid, cur)
  local list = scanList(pid, cur, math.max(target, L.nextMilestone(cur)))
  if #list == 0 then Print("nothing to look up for this range."); return end
  for _, id in ipairs(list) do
    if not GetItemInfo(id) and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
  end
  scan = { list = list, i = 0, total = #list, pid = pid, found = 0, none = 0, tries = {} }
  Print(string.format("scanning %d items for %s %d-%d.", #list, profName(pid), cur, math.max(target, L.nextMilestone(cur))))
  scanLabel()
  scanFrame:Show()
end

local function onAuction(event, arg1)
  if event == "AUCTION_HOUSE_SHOW" then ahOpen = true
  elseif event == "AUCTION_HOUSE_CLOSED" then ahOpen = false
  elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" then pcall(L.readModern, "commodity", arg1)
  elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then pcall(L.readModern, "item", arg1)
  elseif event == "AUCTION_ITEM_LIST_UPDATE" and scan and scan.waiting and not scan.reading then
    scan.reading = true
    C_Timer.After(0.2, function() if scan then scan.reading = false; L.readResults() end end)
  end
end

-- another character's saved list: what it still needs, what you can send, what to buy
local function renderSheet(g, warm, green, red, dim)
  for _, c in ipairs(profChips) do c:Hide() end
  for _, c in ipairs(frame.ctrl) do c:Hide() end
  for _, c in ipairs(frame.milestones) do c:Hide() end
  frame.cast:Hide(); frame.empty:Hide(); frame.more:Hide()
  frame.title:SetText(string.format("%s: %s %d  >  %d", g.name or "?", profName(g.pid), g.skill or 0, g.target or 0))
  frame.sub:SetText("saved " .. ago(g.time) .. "  ·  send what you have, buy the rest  ·  LISTS to go back")
  frame.bar:SetWidth(math.max(1, (frame:GetWidth() - 2) * math.max(0, math.min(1, (g.skill or 0) / 300))))

  local y = 80
  frame.stepsHead:ClearAllPoints(); frame.stepsHead:SetPoint("TOPLEFT", PAD, -y); frame.stepsHead:Show()
  y = y + 16
  local data = recipes(g.pid)
  for i, l in ipairs(stepLines) do
    local st = g.steps and g.steps[i]
    local r = st and st.spell and data.bySpell[st.spell]
    if st then
      l:ClearAllPoints(); l:SetPoint("TOPLEFT", PAD, -y); y = y + STEP_H
      l.st = r and { r = r } or nil
      l.range:SetText(st.from .. "-" .. st.to)
      l.name:SetText(r and (L.colorAt(r, st.from) .. r.name .. "|r") or (red .. "no recipe found|r"))
      l.crafts:SetText(r and ("x" .. st.crafts) or "")
      l.info:SetText(""); l.go:Hide(); l.amt:Hide()
      l:Show()
    else
      l.st = nil; l:Hide()
    end
  end

  y = y + 10
  frame.matHead:ClearAllPoints(); frame.matHead:SetPoint("TOPLEFT", PAD, -y); frame.matHead:Show()
  frame.colNeed:ClearAllPoints(); frame.colNeed:SetPoint("TOPLEFT", PAD + X_NEED, -y); frame.colNeed:Show()
  frame.colHave:ClearAllPoints(); frame.colHave:SetPoint("TOPLEFT", PAD + X_HAVE, -y); frame.colHave:Show()
  frame.colStat:ClearAllPoints(); frame.colStat:SetPoint("TOPLEFT", PAD + X_STAT, -y); frame.colStat:Show()
  frame.colNeed:SetText("NEEDS"); frame.colHave:SetText("YOU HAVE"); frame.colStat:SetText("TO DO")
  y = y + 18

  g.sent = g.sent or {}
  local list = {}
  for _, row in ipairs(g.rows or {}) do
    local left = (row.missing or 0) - (g.sent[row.id] or 0)
    local alt = g.alt and g.alt[row.id]
    if alt then left = left - math.floor((g.sent[alt[1]] or 0) / math.max(alt[2], 0.0001)) end
    local pr = g.prod and g.prod[row.id]
    if pr then left = left - math.floor((g.sent[pr[1]] or 0) * pr[2]) end
    if (row.missing or 0) > 0 then
      local it = L.newRow(row.id, math.max(0, left))
      -- yours here: bags and bank, plus mail and auction house buys on the way (send them once looted),
      -- plus finished items it would make itself (your bars cover the ore for them)
      it.mine = rawCount(row.id, true) + ownMail(row.id)
      it.inMail = ownMail(row.id)
      if pr then
        local own = rawCount(pr[1], true) + ownMail(pr[1])
        it.mine = it.mine + math.floor(math.min(own, math.max(0, pr[3] - (g.sent[pr[1]] or 0))) * pr[2])
        it.inMail = it.inMail + math.floor(ownMail(pr[1]) * pr[2])
      end
      it.send = math.max(0, math.min(left, it.mine))
      it.missing = math.max(0, left - it.send)
      it.left = left
      list[#list + 1] = it
    end
  end
  table.sort(list, function(a, b) return (GetItemInfo(a.id) or "") < (GetItemInfo(b.id) or "") end)
  frame.list = list

  local cost, toBuy, toSend = 0, 0, 0
  for i, r in ipairs(rows) do
    local it = list[i]
    r.act:Hide()
    if it then
      r.row = it
      r:ClearAllPoints(); r:SetPoint("TOPLEFT", PAD, -y); y = y + ROW_H
      r.icon:ClearAllPoints(); r.icon:SetPoint("LEFT", 0, 0)
      r.name:ClearAllPoints(); r.name:SetPoint("LEFT", 22, 0); r.name:SetWidth(220)
      r.icon:SetTexture(GetIcon and GetIcon(it.id) or 134400)
      r.name:SetText(GetItemInfo(it.id) or ("item " .. it.id))
      r.need:SetText(tostring(math.max(0, it.left)))
      r.have:SetText(tostring(it.mine))
      local parts = {}
      if it.left <= 0 then parts[1] = green .. "sent|r" end
      if it.send > 0 then
        local m = math.min(it.send, it.inMail or 0)
        parts[#parts + 1] = warm .. "send " .. it.send .. "|r" .. (m > 0 and (dim .. " (" .. m .. " in your mail)|r") or "")
      end
      if it.missing > 0 then
        local p = buyPrice(it.id)
        parts[#parts + 1] = red .. "buy " .. it.missing .. "|r" .. (p and (dim .. " ~" .. money(p * it.missing) .. "|r") or "")
      end
      r.status:SetText(table.concat(parts, "  "))
      r.name:SetTextColor(1, 1, 1, it.left > 0 and 0.9 or 0.45)
      r:Show()
    else
      r.row = nil; r:Hide()
    end
  end
  for _, it in ipairs(list) do
    if it.missing > 0 then
      toBuy = toBuy + 1
      local p = buyPrice(it.id)
      if p then cost = cost + p * it.missing end
    end
    toSend = toSend + it.send
  end
  if #list > #rows then
    frame.more:SetText(string.format("+ %d more (they're in SEARCH MISSING)", #list - #rows))
    frame.more:ClearAllPoints(); frame.more:SetPoint("TOPLEFT", PAD + 22, -y - 2); frame.more:Show()
    y = y + 16
  end
  y = y + 8
  local foot
  if #list == 0 then foot = green .. (g.name or "They") .. " has everything for this.|r"
  elseif toBuy == 0 then foot = green .. "You can send all of it.|r"
  else foot = string.format("Buy here: ~%s", money(cost)) end
  if toSend > 0 then foot = foot .. "\nThe mailbox panel sends what you have in one click." end
  frame.foot:SetText(foot)
  placeFooter(y, toBuy > 0, nil, true)
  L.hideSecure(openBtn)
end

-- order: things to make first, then missing, then done
function L.sortRows(list)
  local function rank(r)
    if r.make then return 0 end
    if r.missing > 0 then return 1 end
    return 2
  end
  table.sort(list, function(a, b)
    local ra, rb = rank(a), rank(b)
    if ra ~= rb then return ra < rb end
    return (GetItemInfo(a.id) or "") < (GetItemInfo(b.id) or "")
  end)
end

-- Materials only needed to make something else on the list (ore for the bars you smelt, stone for grinding
-- stones) go under that item as an indented line. When a recipe also needs some directly, that part keeps its
-- own line. What you have counts toward the direct need first, then toward what gets made.
function L.nestRows(list, base, from)
  if not from or not next(from) then return list end
  local out, kids = {}, {}
  local function piece(row, n, pool)
    local take = math.min(pool, n)
    local c = {}
    for k, v in pairs(row) do c[k] = v end
    c.need, c.haveHere, c.missing = n, take, n - take
    c.make, c.makeRec, c.src, c.srcN, c.srcRec = nil, nil, nil, nil, nil
    return c, pool - take
  end
  for _, row in ipairs(list) do
    local parents = from[row.id]
    if parents and not row.make and not row.src then
      local pool = row.have + (row.crafted or 0)
      local direct = math.min(base[row.id] or 0, row.need)
      if direct > 0 then
        local c; c, pool = piece(row, direct, pool)
        out[#out + 1] = c
      end
      for pid, n in pairs(parents) do
        local c; c, pool = piece(row, n, pool)
        c.child, c.forId = true, pid
        kids[pid] = kids[pid] or {}
        table.insert(kids[pid], c)
      end
    else
      out[#out + 1] = row
    end
  end
  -- put each indented line right under the item it's for
  local final, placed = {}, {}
  for _, row in ipairs(out) do
    final[#final + 1] = row
    if not row.child and kids[row.id] and not placed[row.id] then
      placed[row.id] = true
      for _, c in ipairs(kids[row.id]) do final[#final + 1] = c end
    end
  end
  for pid, list_ in pairs(kids) do
    if not placed[pid] then for _, c in ipairs(list_) do c.child = nil; final[#final + 1] = c end end
  end
  return final
end

---------------------------------------------------------------------------
-- First-time tutorial: walks a new user through the window once (ProfessionWizardDB.tutorialDone);
-- SETTINGS > SHOW TUTORIAL or /pw tutorial plays it again.
---------------------------------------------------------------------------
local tut -- { step, box, hl }
local Tut = {}

function Tut.steps()
  local hasA = Auctionator and Auctionator.API and Auctionator.API.v1
  return {
    { from = function() return frame.eb, -28 end, to = function() return frame.milestones[#frame.milestones] end,
      title = "Your goal",
      body = "How far do you want to level? Type a skill or click a milestone. The route and the shopping list cover everything up to here.\n\nTip: go to the skill your trainer rank allows (75, 150, 225), then train and come back for the next part." },
    { from = function() return frame.scanBtn end,
      title = "Prices first",
      body = hasA and "The route is worked out from auction house prices. Auctionator's are used when they're recent, but SCAN AH at an auction house gets fresh prices for exactly the materials this route needs (about a minute)."
        or "The route is worked out from auction house prices. Go to an auction house and click SCAN AH: it looks up exactly the materials this route needs (about a minute). No other addon needed." },
    { from = function() return frame.find end,
      title = "Find the cheapest route",
      body = "With prices in, click FIND CHEAPEST ROUTE. It lights up whenever the route is out of date (new prices, a new target, your skill moved past it)." },
    { from = function() return frame.plans end, to = function() return frame.buffer end,
      title = "What counts",
      body = "BUY RECIPES lets the route use recipes from the auction house or a vendor. COUNT BANK, ALTS and MAIL count what you already own there. SPARE adds a few extra materials for crafts that don't give a point." },
    { from = function() return frame.stepsHead end, area = true,
      title = "Your route and shopping list",
      body = "CRAFTS: which recipe to make for which skill range, with CRAFT to make the next one. MATERIALS: what you need, what you have (bags, bank, mail, alts) and what's still to buy. SEARCH MISSING looks the rest up at the auction house."
        .. (shownProf() == 333 and "\n\nEnchanting: each enchant goes on the cheapest matching item in your bags (it says which next to the recipe). Carry a cheap bracer, cloak, chest piece and so on, grey or white is fine, and enchant the same one again and again." or "") },
  }
end

function Tut.stop(done)
  if tut then tut.box:Hide(); tut.hl:Hide() end
  if done then ProfessionWizardDB.tutorialDone = true end
  if tut then tut.step = nil end
end

function Tut.show()
  local steps = Tut.steps()
  local st = steps[tut.step]
  if not st then Tut.stop(true); return end
  local a, dx = st.from()
  if not (a and a:IsShown()) then tut.step = tut.step + 1; return Tut.show() end
  local b = st.to and st.to() or a
  if not b:IsShown() then b = a end
  local hl, box = tut.hl, tut.box
  hl:ClearAllPoints()
  hl:SetPoint("TOPLEFT", a, "TOPLEFT", (dx or 0) - 4, 4)
  if st.area then hl:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD + 4, PAD - 4)
  else hl:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 4, -4) end
  hl:Show()
  box.title:SetText(string.format("%d/%d  %s", tut.step, #steps, st.title:upper()))
  box.body:SetText(st.body)
  box.next.text:SetText(tut.step == #steps and "GOT IT" or "NEXT")
  box:SetHeight(math.ceil(box.body:GetStringHeight()) + 70)
  box:ClearAllPoints()
  if st.area then box:SetPoint("TOP", hl, "TOP", 0, -24)
  elseif (a:GetLeft() or 0) - (frame:GetLeft() or 0) > W / 2 then box:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", 0, -10)
  else box:SetPoint("TOPLEFT", a, "BOTTOMLEFT", dx or 0, -10) end
  box:Show()
end

function Tut.start()
  if not frame then return end
  if not tut then
    local ar, ag, ab = accent()
    local s = scheme()
    local hl = CreateFrame("Frame", nil, frame)
    hl:SetFrameLevel(frame:GetFrameLevel() + 25)
    local e1 = edges(hl, ar, ag, ab, 1)
    local glow = hl:CreateTexture(nil, "BACKGROUND"); glow:SetAllPoints(); glow:SetColorTexture(ar, ag, ab, 0.12)
    local ag2 = hl:CreateAnimationGroup(); ag2:SetLooping("BOUNCE")
    local fade = ag2:CreateAnimation("Alpha"); fade:SetFromAlpha(1); fade:SetToAlpha(0.35); fade:SetDuration(0.7)
    hl:SetScript("OnShow", function() ag2:Play() end)
    hl:SetScript("OnHide", function() ag2:Stop() end)
    local box = CreateFrame("Frame", nil, frame)
    box:SetSize(300, 120); box:SetFrameLevel(frame:GetFrameLevel() + 30); box:EnableMouse(true)
    local bg = box:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(s.bg[1], s.bg[2], s.bg[3], 1)
    edges(box, ar, ag, ab, 0.9)
    box.title = text(box, 11, ar, ag, ab, 1); box.title:SetPoint("TOPLEFT", 12, -10)
    box.body = text(box, 12, 1, 1, 1, 0.9); box.body:SetPoint("TOPLEFT", 12, -28)
    box.body:SetWidth(276); box.body:SetWordWrap(true)
    box.next = chip(box, "NEXT", 80); box.next:SetPoint("BOTTOMRIGHT", -10, 10); box.next:SetActive(true)
    box.next:SetScript("OnClick", function() tut.step = tut.step + 1; Tut.show() end)
    box.skip = CreateFrame("Button", nil, box); box.skip:SetSize(110, 20); box.skip:SetPoint("BOTTOMLEFT", 8, 10)
    box.skip.fs = text(box.skip, 11, 1, 1, 1, 0.45); box.skip.fs:SetPoint("LEFT", 4, 0); box.skip.fs:SetText("SKIP TUTORIAL")
    box.skip:SetScript("OnEnter", function(self) self.fs:SetTextColor(1, 1, 1, 0.85) end)
    box.skip:SetScript("OnLeave", function(self) self.fs:SetTextColor(1, 1, 1, 0.45) end)
    box.skip:SetScript("OnClick", function() Tut.stop(true) end)
    frame:HookScript("OnHide", function() if tut and tut.step then Tut.stop(false) end end)
    tut = { hl = hl, box = box }
  end
  if frame.opts then frame.opts:Hide() end
  tut.step = 1
  Tut.show()
end

refresh = function()
  if not frame or not frame:IsShown() then return end
  local s = scheme()
  local warm = hex(s.warm[1], s.warm[2], s.warm[3])
  local green, red, dim = "|cff66dd80", "|cffff7366", "|cff808080"

  local skills = readSkills()
  local pid = shownProf()
  frame.lists:SetActive(viewing and true or false)
  -- a character without a crafting profession shows the newest saved list instead
  if not viewing and not pid then
    local first = L.sheetList()[1]
    if first then viewing = first.key end
  end
  if viewing then
    local g = ProfessionWizardDB.goals and ProfessionWizardDB.goals[viewing]
    if g and g.rows then renderSheet(g, warm, green, red, dim); return end
    viewing = nil
  end
  for _, c in ipairs(frame.ctrl) do c:Show() end
  frame.colNeed:SetText("NEED"); frame.colHave:SetText("HAVE"); frame.colStat:SetText("STILL NEED")

  -- profession chips
  local x = PAD
  for _, c in ipairs(profChips) do
    if skills[c.pid] then
      c:ClearAllPoints(); c:SetPoint("TOPLEFT", x, -76); x = x + 84
      c:SetActive(c.pid == pid); c:Show()
    else
      c:Hide()
    end
  end

  local function hideAll()
    for _, l in ipairs(stepLines) do l:Hide() end
    for _, r in ipairs(rows) do r:Hide(); r.row = nil end
    frame.matHead:Hide(); frame.colNeed:Hide(); frame.colHave:Hide(); frame.colStat:Hide()
    frame.stepsHead:Hide(); frame.foot:Hide(); frame.buy:Hide(); frame.more:Hide(); frame.cast:Hide()
    for _, c in ipairs(frame.ctrl) do c:Hide() end
    for _, c in ipairs(frame.milestones) do c:Hide() end
    placeSmelt(nil, 0, false, true)
    L.hideSecure(openBtn)
  end

  if not pid then
    hideAll()
    frame.title:SetText("No crafting profession found")
    frame.sub:SetText("")
    frame.empty:SetText("No crafting profession here, and no saved lists from your other characters yet. Log in on a crafter once and its list is saved for your alts.")
    frame.empty:ClearAllPoints(); frame.empty:SetPoint("TOPLEFT", PAD, -80); frame.empty:Show()
    frame:SetHeight(130)
    return
  end
  frame.empty:Hide()
  frame.stepsHead:Show(); frame.matHead:Show(); frame.colNeed:Show(); frame.colHave:Show(); frame.colStat:Show(); frame.foot:Show()

  local cur = (skills[pid] and skills[pid].rank) or 1
  local cap = skills[pid] and skills[pid].max
  local target = targetFor(pid, cur)
  frame.target = target

  if cur >= 300 then
    frame.title:SetText(profName(pid) .. " 300. You're done!")
  else
    frame.title:SetText(string.format("%s %d  >  %d", profName(pid), cur, target))
  end
  frame.bar:SetWidth(math.max(1, (frame:GetWidth() - 2) * math.max(0, math.min(1, cur / 300))))

  if not frame.eb:HasFocus() then frame.eb:SetText(tostring(target)) end
  for _, c in ipairs(frame.milestones) do c:SetActive(c.value == target); c:SetShown(c.value > cur) end
  frame.plans:SetActive(ProfessionWizardDB.plans and true or false)
  frame.bank:SetActive(ProfessionWizardDB.bank and true or false)
  frame.alts:SetActive(ProfessionWizardDB.alts and true or false)
  frame.mail:SetActive(ProfessionWizardDB.mail and true or false)
  frame.buffer.text:SetText("SPARE " .. (ProfessionWizardDB.buffer or 0) .. "%")
  frame.buffer:SetActive((ProfessionWizardDB.buffer or 0) > 0)
  scanLabel()

  local route = cur < 300 and routeFor(pid, cur, target) or nil
  frame.find:SetActive(route and route.dirty or false)

  -- sub line
  local nAlts = ProfessionWizardDB.alts and #alts() or 0
  local what = "bags"
  if ProfessionWizardDB.bank then what = what .. ", bank" end
  if ProfessionWizardDB.mail then what = what .. ", mail" end
  local sub = string.format("counting %s%s", what, nAlts > 0 and string.format(" on you + %d alt%s", nAlts, nAlts == 1 and "" or "s") or "")
  local mining = bestSkill(MINING)
  if mining > 0 then sub = "Mining " .. mining .. "  ·  " .. sub end
  if route then sub = "route from " .. ago(route.time) .. (route.dirty and (warm .. " (out of date)|r") or "") .. "  ·  " .. sub end
  if cap and cap < target and cap < 300 then
    local rank = (cap <= 75 and "Journeyman (level 10)") or (cap <= 150 and "Expert (level 20)") or (cap <= 225 and "Artisan (level 35)") or "the next rank"
    sub = sub .. "  ·  " .. warm .. "your cap is " .. cap .. ": train " .. rank .. "|r"
  end
  if not L.seenProf(pid) then sub = sub .. "  ·  " .. warm .. "open your " .. profName(pid) .. " window once|r" end
  frame.sub:SetText(sub)

  -- steps
  local steps = route and plan(route, cur, target) or {}
  -- a row "train Expert" where the route reaches a cap you have (or will have) to train past
  local stepRows = {}
  for _, st in ipairs(steps) do
    if cap and (st.from == 75 or st.from == 150 or st.from == 225) and st.from >= cap and ns.rankInfo then
      local rk, where = ns.rankInfo(pid, st.from, profName(pid))
      if rk then stepRows[#stepRows + 1] = { rankRow = rk, where = where, from = st.from, rankCost = ns.rankCost(pid, st.from) } end
    end
    stepRows[#stepRows + 1] = st
  end
  local ctx = newCtx(pid, cur)
  local y = 160
  if job then jobBusy() end -- a batch the game ended quietly stops showing as running
  if job then
    frame.cast:ClearAllPoints(); frame.cast:SetPoint("TOPLEFT", PAD, -y); frame.cast:Show()
    y = y + 26
  else
    frame.cast:Hide()
    y = y + 4
  end
  local hintText = cur < 300 and priceHint(priceState(pid, cur, target)) or nil
  if hintText then
    frame.hint.fs:SetText(hintText)
    local h = math.ceil(frame.hint.fs:GetStringHeight()) + 12
    frame.hint:SetHeight(h)
    frame.hint:ClearAllPoints(); frame.hint:SetPoint("TOPLEFT", PAD, -y); frame.hint:Show()
    y = y + h + 8
    if not scan then frame.scanBtn:SetActive(ahOpen) end
  else
    frame.hint:Hide()
  end
  frame.stepsHead:ClearAllPoints(); frame.stepsHead:SetPoint("TOPLEFT", PAD, -y)
  y = y + 16
  local vendorBack, matTotal, plansTotal = 0, 0, 0
  -- what each step costs, and the whole route's totals (all steps, not only the ones in view)
  for _, st in ipairs(stepRows) do
    local r = st.r
    if r then
      local mc = 0
      for _, m in ipairs(r.mats) do mc = mc + (L.unitCost(m[1], ctx, 0) or 0) * m[2] end
      local back = r.creates > 0 and (L.sellPrice(r.creates) or 0) * r.made or 0
      st.matCost, st.back = mc, back
      matTotal = matTotal + mc * st.crafts
      vendorBack = vendorBack + back * st.crafts
      if not isKnown(r) then plansTotal = plansTotal + (st.plans or 0) end
    elseif st.rankRow then
      plansTotal = plansTotal + (st.rankCost or 0)
    end
  end
  -- scrolling: show VIS_STEPS of them from the scroll position
  local nVis = math.min(L.VIS_STEPS, #stepLines)
  local maxOff = math.max(0, #stepRows - nVis)
  if L.scroll.pid ~= pid then L.scroll.pid, L.scroll.step, L.scroll.mat = pid, 0, 0 end
  L.scroll.step = math.min(L.scroll.step, maxOff)
  local sOff = L.scroll.step
  frame.stepsHead:SetText(#stepRows > nVis and string.format("CRAFTS  " .. dim .. "%d-%d of %d  ·  scroll for more|r",
    sOff + 1, sOff + nVis, #stepRows) or "CRAFTS")
  local stepH = STEP_H + 4
  local openY -- first step that could be crafted once the window is open
  for i, l in ipairs(stepLines) do
    local st = i <= nVis and stepRows[i + sOff] or nil
    if st then
      l.st = st
      l:ClearAllPoints(); l:SetPoint("TOPLEFT", PAD, -y); y = y + stepH
      l.range:SetText(st.rankRow and ("at " .. st.from) or (st.from .. "-" .. st.to))
      if st.rankRow then
        local rk = st.rankRow
        l.name:SetText(warm .. "TRAIN " .. rk.name:upper() .. "|r")
        l.crafts:SetText("")
        l.info:SetWidth(W - PAD * 2 - 332)
        l.info:SetText(warm .. (st.where or ("a " .. rk.name .. " trainer")) .. "|r  ·  level " .. rk.level
          .. (st.rankCost and ("  ·  " .. money(st.rankCost)) or ""))
        l.go:Hide(); l.amt:Hide()
      elseif st.gap then
        l.name:SetText(red .. "no recipe found|r")
        l.crafts:SetText("")
        l.info:SetText("missing AH prices? scan, then FIND CHEAPEST ROUTE")
        l.go:Hide(); l.amt:Hide()
      else
        local r = st.r
        l.name:SetText(L.colorAt(r, st.from) .. r.name .. "|r")
        l.crafts:SetText("x" .. st.crafts)
        -- cost per craft from today's prices (worked out above)
        local mc, back = st.matCost or 0, st.back or 0
        -- money, not time: what one craft costs after the vendor pays for the result
        local net = mc - back
        local info = net >= 0 and ("costs " .. money(net) .. "/craft") or ("+" .. money(-net) .. "/craft profit")
        if not isKnown(r) then
          -- where the recipe comes from (and what it costs when it's an item), then when you can learn it
          if r.trainer then
            local fee = L.trainCost(r)
            info = info .. "  ·  " .. warm .. ((ns.TRAINER_NOTES or {})[r.spell] and "special trainer" or "trainer")
              .. (fee > 0 and (" " .. money(fee)) or "") .. "|r"
          elseif r.plans > 0 then
            local rp, where = buyPrice(r.plans)
            if rp then
              info = info .. "  ·  " .. warm .. "recipe ~" .. money(rp) .. (where == "vendor" and " vendor" or " AH") .. "|r"
            else
              info = info .. "  ·  " .. warm .. "recipe: no price yet|r"
            end
          end
          if r.learn > cur then info = info .. "  ·  at " .. r.learn end
        end
        if Ench.slotOf(r) then
          local tg = Ench.target(r)
          info = info .. "  ·  " .. (tg and ("on " .. (tg.link or "?")) or (warm .. "needs a cheap " .. Ench.what(r) .. " in your bags|r"))
        end
        -- past your cap a craft gives no skill, so no CRAFT button until you've trained
        local w = tsOpen and not (cap and cap < 300 and st.from >= cap) and findRecipe(r) or nil
        if l.key ~= r.spell then l.custom = nil; l.key = r.spell end
        l.rec, l.label = w, r.name
        if w then
          if not l.amt:HasFocus() then
            local default = st.crafts
            if (w.avail or 0) > 0 then default = math.min(default, w.avail) end
            if w.craftIndex or Ench.slotOf(r) then default = 1 end
            l.amt:SetText(tostring(l.custom or default))
          end
          l.go:SetActive((w.avail or 0) > 0 and not (job and not job.stopped))
          l.go:Show(); l.amt:Show()
          l.info:SetWidth(W - PAD * 2 - 332 - 116)
        else
          l.go:Hide(); l.amt:Hide()
          l.info:SetWidth(W - PAD * 2 - 332)
          if not openY and tsProf ~= pid and (isKnown(r) or (L.trainable(r) and r.learn <= cur)) then
            openY = y - stepH + (stepH - 20) / 2
            l.info:SetWidth(W - PAD * 2 - 332 - 124)
          end
        end
        l.info:SetText(info)
      end
      l:Show()
    else
      l.st = nil
      l:Hide()
    end
  end

  if openY and openBtn and not (InCombatLockdown and InCombatLockdown()) then
    openBtn:SetAttribute("spell", profName(pid))
    openBtn.text:SetText("OPEN " .. PROF[pid].short)
    placeSecure(openBtn, W - PAD - 116, openY)
  elseif not openY then
    L.hideSecure(openBtn)
  end

  -- materials
  y = y + 10
  frame.matHead:ClearAllPoints(); frame.matHead:SetPoint("TOPLEFT", PAD, -y)
  frame.colNeed:ClearAllPoints(); frame.colNeed:SetPoint("TOPLEFT", PAD + X_NEED, -y)
  frame.colHave:ClearAllPoints(); frame.colHave:SetPoint("TOPLEFT", PAD + X_HAVE, -y)
  frame.colStat:ClearAllPoints(); frame.colStat:SetPoint("TOPLEFT", PAD + X_STAT, -y)
  y = y + 18

  local list, mbase, mfrom = {}, nil, nil
  if #steps > 0 then list, mbase, mfrom = materials(steps, ctx) end
  L.sortRows(list)
  list = L.nestRows(list, mbase, mfrom)
  frame.list = list
  local cost, missingKinds = 0, 0
  local toSmelt = {}
  for _, row in ipairs(list) do
    if row.make and row.makeRec and row.makeRec.prof == MINING then toSmelt[#toSmelt + 1] = { r = row.makeRec, n = row.make } end
    if row.missing > 0 then
      missingKinds = missingKinds + 1
      local p = buyPrice(row.id)
      if p then cost = cost + p * row.missing end
    end
  end
  local mVis = math.min(L.VIS_MATS, #rows)
  L.scroll.mat = math.min(L.scroll.mat, math.max(0, #list - mVis))
  local mOff = L.scroll.mat
  frame.matHead:SetText(#list > mVis and string.format("MATERIALS  " .. dim .. "%d-%d of %d  ·  scroll|r",
    mOff + 1, mOff + mVis, #list) or "MATERIALS")
  for i, r in ipairs(rows) do
    local row = i <= mVis and list[i + mOff] or nil
    if row then
      r.row = row
      r:ClearAllPoints(); r:SetPoint("TOPLEFT", PAD, -y); y = y + ROW_H
      local name = GetItemInfo(row.id)
      local indent = row.child and 18 or 0
      r.icon:ClearAllPoints(); r.icon:SetPoint("LEFT", indent, 0)
      r.name:ClearAllPoints(); r.name:SetPoint("LEFT", 22 + indent, 0); r.name:SetWidth(220 - indent)
      r.icon:SetTexture(GetIcon and GetIcon(row.id) or 134400)
      r.name:SetText(name or ("item " .. row.id))
      r.need:SetText(tostring(row.need))
      local smelt = row.makeRec and row.makeRec.prof == MINING
      if row.haveHere then
        -- a share of what you have (the rest counts on the item's other line)
        r.have:SetText(tostring(row.haveHere))
      else
        local parts = { tostring(row.own) }
        if row.mail > 0 then parts[#parts + 1] = row.mail .. " mail" end
        if row.alts > 0 then parts[#parts + 1] = row.alts .. " alts" end
        if (row.crafted or 0) > 0 then parts[#parts + 1] = row.crafted .. " crafted" end
        if row.src then parts[#parts + 1] = row.srcN .. (smelt and " ore" or " to use") end
        r.have:SetText(table.concat(parts, " + "))
      end
      if row.make and row.missing == 0 then
        r.status:SetText(warm .. (smelt and "smelt " or "make ") .. row.make .. "|r")
      elseif row.missing > 0 then
        local p, where = buyPrice(row.id)
        local tail = p and (dim .. "  ~" .. money(p * row.missing) .. (where == "vendor" and " vendor" or "") .. "|r") or (dim .. "  no price|r")
        r.status:SetText(red .. row.missing .. "|r" .. (row.make and (warm .. (smelt and " +smelt " or " +make ") .. row.make .. "|r") or "") .. tail)
      else
        r.status:SetText(green .. "done|r")
      end
      r.name:SetTextColor(1, 1, 1, (row.missing > 0 or row.make) and 0.9 or 0.45)
      -- MAKE / SMELT right from the list while that profession window is open
      r.actRec, r.actN, r.actLabel = nil, nil, nil
      if tsOpen and row.make and row.makeRec and row.makeRec.prof == tsProf then
        local w = findRecipe(row.makeRec)
        if w and (w.avail or 0) > 0 then
          local n = math.min(row.make, w.avail)
          r.actRec, r.actN, r.actLabel = w, n, row.makeRec.name
          r.act.text:SetText((row.makeRec.prof == MINING and "SMELT " or "MAKE ") .. n)
        end
      end
      if r.actRec then
        r.act:SetActive(not (job and not job.stopped)); r.act:Show(); r.status:SetText("")
      else
        r.act:Hide()
      end
      r:Show()
    else
      r.row = nil
      r:Hide()
    end
  end
  frame.more:Hide() -- the list scrolls instead

  y = y + 8
  local foot
  if cur >= 300 then
    foot = "Nothing left to learn here."
  elseif #steps == 0 then
    foot = "No route yet: click FIND CHEAPEST ROUTE."
  elseif missingKinds == 0 then
    foot = green .. "You have everything up to " .. target .. ".|r"
  else
    foot = "|cffffffffStill to buy: ~" .. money(cost) .. "|r"
  end
  if matTotal > 0 then
    foot = foot .. "\n" .. string.format("Whole route: ~%s in materials, recipes and training", money(matTotal + plansTotal))
    if vendorBack > 0 then foot = foot .. string.format("  ·  selling what you craft to a vendor gets ~%s back", money(vendorBack)) end
  end
  frame.foot:SetText(foot)
  -- recipes the route needs that you don't have yet and would buy on the AH go into SEARCH MISSING too
  local planBuys = {}
  for _, st in ipairs(steps) do
    local r = st.r
    if r and not isKnown(r) and not L.trainable(r) and (r.plans or 0) > 0 and L.haveOf(r.plans) == 0 then
      local _, where = buyPrice(r.plans)
      if where ~= "vendor" then planBuys[#planBuys + 1] = r.plans; GetItemInfo(r.plans) end -- asks the server for the name early
    end
  end
  frame.planBuys = planBuys
  placeFooter(y, missingKinds > 0 or #planBuys > 0, toSmelt)
end

---------------------------------------------------------------------------
-- At a trainer: learn what your routes need right away (one at a time, the list changes after each)
---------------------------------------------------------------------------
local learnTried = {}
function L.autoLearn()
  if ProfessionWizardDB.autoLearn == false then return end
  if not (GetNumTrainerServices and GetTrainerServiceInfo and BuyTrainerService) then return end
  if SetTrainerServiceTypeFilter then pcall(SetTrainerServiceTypeFilter, "available", 1) end
  -- what the routes of this character still need: recipe names, and the next rank's profession
  local want, rankFor = {}, {}
  local skills = readSkills()
  for pid, route in pairs(routeStore()) do
    local sk = skills[pid]
    if type(route) == "table" and route.segs and sk then
      local target = targetFor(pid, sk.rank)
      for _, st in ipairs(plan(route, sk.rank, target)) do
        local r = st.r
        if r and not isKnown(r) and L.trainable(r) then want[r.name] = r end
      end
      if sk.max and sk.max < 300 and sk.max < target then rankFor[profName(pid)] = true end
    end
  end
  for i = 1, GetNumTrainerServices() or 0 do
    local name, sub, kind = GetTrainerServiceInfo(i)
    -- a rank shows as "Alchemy" with "Expert" under it, or as "Expert Alchemist"
    local isRank = name and rankFor[name]
    if not isRank and name then
      local full = (name .. " " .. (sub or "")):lower()
      if full:find("journeyman") or full:find("expert") or full:find("artisan") then
        for pn in pairs(rankFor) do if full:find(pn:lower():sub(1, 4), 1, true) then isRank = true end end
      end
    end
    if kind == "available" and name and not learnTried[name] and (want[name] or isRank) then
      local cost = GetTrainerServiceCost and GetTrainerServiceCost(i) or 0
      if cost > GetMoney() then
        learnTried[name] = true
        Print("not enough money to learn " .. name .. " (" .. money(cost) .. ").")
      else
        learnTried[name] = true
        BuyTrainerService(i)
        Print("learned " .. (isRank and ("the next rank: " .. name .. (sub and sub ~= "" and (" (" .. sub .. ")") or "")) or name)
          .. (cost > 0 and (" for " .. money(cost)) or "") .. ".")
        return -- TRAINER_UPDATE comes back for the next one
      end
    end
  end
end

---------------------------------------------------------------------------
-- Mailbox panel on your alts: one click mails a crafter what it still needs
---------------------------------------------------------------------------
local MP_W, MP_PAD, MP_ROW, MP_ROWS = 230, 10, 20, 12
local MAX_ATTACH = ATTACHMENTS_MAX_SEND or 12
local mp, mpRows, mpChips, busy = nil, {}, {}, false
local mpPick

function L.bagStacks(id)
  local out = {}
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = 1, numSlots(bag) do
      local iid, cnt, locked = slotInfo(bag, slot)
      if iid == id and not locked then out[#out + 1] = { bag = bag, slot = slot, count = cnt or 1 } end
    end
  end
  table.sort(out, function(a, b) return a.count > b.count end)
  return out
end

function L.bagCount(id)
  local n = 0
  for _, st in ipairs(L.bagStacks(id)) do n = n + st.count end
  return n
end

-- goals of your other characters on this realm and faction, newest first
function L.otherGoals()
  local list = {}
  local realm, faction, me = GetRealmName(), UnitFactionGroup("player"), myKey()
  for k, g in pairs(ProfessionWizardDB.goals or {}) do
    if g.owner ~= me and g.realm == realm and g.faction == faction and next(g.needs or {}) then g.key = k; list[#list + 1] = g end
  end
  table.sort(list, function(a, b) return (a.time or 0) > (b.time or 0) end)
  return list
end

function L.sendPlan(g)
  local items = {}
  g.sent = g.sent or {}
  for id, n in pairs(g.needs or {}) do
    local alt = g.alt and g.alt[id]
    local left = n - (g.sent[id] or 0)
    if alt then left = left - math.floor((g.sent[alt[1]] or 0) / math.max(alt[2], 0.0001)) end
    -- finished items first (bars for the ore it would smelt), then the material for the rest
    local pr = g.prod and g.prod[id]
    if pr and left > 0 then
      left = left - math.floor((g.sent[pr[1]] or 0) * pr[2])
      local made = math.min(math.ceil(left / math.max(pr[2], 0.0001)), pr[3] - (g.sent[pr[1]] or 0))
      local give = math.max(0, math.min(made, L.bagCount(pr[1])))
      if give > 0 then
        items[#items + 1] = { id = pr[1], n = give, bank = 0, raw = true }
        left = left - math.ceil(give * pr[2])
      end
    end
    if left > 0 then
      local give = math.min(left, L.bagCount(id))
      local bankMore = math.max(0, math.min(left - give, rawCount(id, true) - rawCount(id, false)))
      if give > 0 or bankMore > 0 then items[#items + 1] = { id = id, n = give, bank = bankMore } end
      left = left - give
      if left > 0 and alt then
        local want_ = math.ceil(left * alt[2])
        local o = math.min(want_, L.bagCount(alt[1]))
        if o > 0 then items[#items + 1] = { id = alt[1], n = o, bank = 0, raw = true } end
      end
    end
  end
  table.sort(items, function(a, b) return (GetItemInfo(a.id) or "") < (GetItemInfo(b.id) or "") end)
  return items
end

function L.attachQueue(items)
  local q = {}
  for _, it in ipairs(items) do
    local left = it.n
    for _, st in ipairs(L.bagStacks(it.id)) do
      if left <= 0 then break end
      local take = math.min(left, st.count)
      q[#q + 1] = { bag = st.bag, slot = st.slot, count = take, whole = (take == st.count) }
      left = left - take
    end
  end
  return q
end

function L.findToBox()
  if GoldSense and GoldSense.FindMailToBox then
    local ok, box = pcall(GoldSense.FindMailToBox)
    if ok and box then return box end
  end
  if _G.SendMailNameEditBox then return _G.SendMailNameEditBox end
  local root = _G.SendMailFrame
  if not root then return nil end
  local first
  local function walk(f, depth)
    if depth > 5 then return nil end
    for _, c in ipairs({ f:GetChildren() }) do
      if c.GetObjectType and c:GetObjectType() == "EditBox" then
        local n = ((c.GetName and c:GetName()) or ""):lower()
        if n:find("name") or n:find("recipient") then return c end
        first = first or c
      end
      local hit = walk(c, depth + 1)
      if hit then return hit end
    end
  end
  return walk(root, 0) or first
end

local mpRefresh

function L.chosenGoal()
  local list = L.otherGoals()
  for _, g in ipairs(list) do if g.key == mpPick then return g, list end end
  return list[1], list
end

local function sendNow()
  if busy then return end
  local g = L.chosenGoal()
  if not g then return end
  if InCombatLockdown and InCombatLockdown() then Print("can't send mail in combat."); return end
  local queue = L.attachQueue(L.sendPlan(g))
  if #queue == 0 then return end
  if _G.SendMailFrame and not _G.SendMailFrame:IsShown() then
    if _G.MailFrameTab2 and _G.MailFrameTab2.Click then _G.MailFrameTab2:Click()
    elseif MailFrameTab_OnClick then pcall(MailFrameTab_OnClick, nil, 2) end
  end
  if GetSendMailItem then
    for i = 1, MAX_ATTACH do
      if GetSendMailItem(i) then Print("take the items off the mail you're writing first."); return end
    end
  end
  busy = true
  mp.send.text:SetText("ATTACHING...")
  local pickup = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
  local split = (C_Container and C_Container.SplitContainerItem) or SplitContainerItem
  local subject = "Profession Wizard: " .. profName(g.pid)
  local i = 0
  local function finish()
    local box = L.findToBox()
    if box and box.SetText then box:SetText(g.full or g.name) end
    local subj = _G.SendMailSubjectEditBox
    if subj and subj.SetText then subj:SetText(subject) end
    Print(string.format("mail to %s is filled. Check it and click Send.", g.name or "?"))
    C_Timer.After(0.5, function() busy = false; if mpRefresh then mpRefresh() end end)
  end
  local function step()
    i = i + 1
    local q = queue[i]
    if not q or i > MAX_ATTACH then finish(); return end
    ClearCursor()
    if q.whole then pickup(q.bag, q.slot) else split(q.bag, q.slot, q.count) end
    ClickSendMailItemButton(i)
    if CursorHasItem and CursorHasItem() then ClearCursor() end
    C_Timer.After(0.15, step)
  end
  step()
end

function L.mpMakeRow()
  local r = CreateFrame("Frame", nil, mp)
  r:SetSize(MP_W - MP_PAD * 2, MP_ROW)
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(16, 16); r.icon:SetPoint("LEFT", 0, 0)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.name = text(r, 12, 1, 1, 1, 0.9); r.name:SetPoint("LEFT", 22, 0); r.name:SetWidth(130)
  r.count = text(r, 12, 1, 1, 1, 0.9); r.count:SetPoint("RIGHT", 0, 0); r.count:SetWidth(60); r.count:SetJustifyH("RIGHT")
  return r
end

local function mpBuild()
  local anchor = _G.MailFrame
  if not anchor then return end
  local ar, ag, ab = accent()
  local s = scheme()
  mp = CreateFrame("Frame", "ProfessionWizardMailPanel", anchor)
  mp:SetSize(MP_W, 120)
  mp:SetFrameStrata(anchor:GetFrameStrata())
  local bg = mp:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
  bg:SetColorTexture(s.bg[1], s.bg[2], s.bg[3], 0.94)
  edges(mp, 1, 1, 1, 0.15)
  local top = mp:CreateTexture(nil, "ARTWORK"); top:SetColorTexture(ar, ag, ab, 0.95)
  top:SetPoint("TOPLEFT", 1, -1); top:SetPoint("TOPRIGHT", -1, -1); top:SetHeight(2)
  local head = text(mp, 11, ar, ag, ab, 0.9); head:SetPoint("TOPLEFT", MP_PAD, -11); head:SetText("PROFESSION WIZARD")
  for i = 1, 4 do
    local c = chip(mp, "", MP_W - MP_PAD * 2)
    c:SetHeight(18)
    c:SetScript("OnClick", function(self) mpPick = self.key; mpRefresh() end)
    mpChips[i] = c
  end
  mp.title = text(mp, 12, 1, 1, 1, 0.95); mp.title:SetWidth(MP_W - MP_PAD * 2)
  mp.sub = text(mp, 11, 1, 1, 1, 0.5); mp.sub:SetWidth(MP_W - MP_PAD * 2)
  for i = 1, MP_ROWS do mpRows[i] = L.mpMakeRow() end
  mp.note = text(mp, 11, s.warm[1], s.warm[2], s.warm[3], 0.85); mp.note:SetWidth(MP_W - MP_PAD * 2)
  mp.note:SetWordWrap(true)
  mp.send = chip(mp, "FILL MAIL", MP_W - MP_PAD * 2)
  mp.send:SetScript("OnClick", sendNow)
  tip(mp.send, "Fill the mail",
    "Opens Send Mail, puts the crafter's name and a subject in and attaches what it needs from your bags (up to 12 stacks a mail). You check it and click Send.",
    "What you send is counted on the crafter's list straight away. More than 12 stacks: fill and send again.")
  mp:SetScript("OnShow", function() if mpRefresh then mpRefresh() end end)
  mp:Hide()
  local later = function() C_Timer.After(0, function() if mpRefresh then mpRefresh() end end) end
  if _G.SendMailFrame then
    _G.SendMailFrame:HookScript("OnShow", later)
    _G.SendMailFrame:HookScript("OnHide", function() mp:Hide() end)
  end
  if _G.GoldSenseMailAlts then
    _G.GoldSenseMailAlts:HookScript("OnShow", later)
    _G.GoldSenseMailAlts:HookScript("OnHide", later)
  end
end

-- next to the mail window; when another addon's panel is showing there (GoldSense's alt list), next to that
function L.mpPlace()
  mp:ClearAllPoints()
  local other = _G.GoldSenseMailAlts
  if other and other:IsShown() then
    mp:SetPoint("TOPLEFT", other, "TOPRIGHT", 6, 0)
  else
    mp:SetPoint("TOPLEFT", _G.MailFrame, "TOPRIGHT", 6, 0)
  end
end

-- only on the Send Mail tab: open with it, close with it
function L.sendTabShown()
  return _G.SendMailFrame and _G.SendMailFrame:IsShown() and _G.MailFrame and _G.MailFrame:IsShown()
end

mpRefresh = function()
  if not mp then mpBuild() end
  if not mp then return end
  local g, list = L.chosenGoal()
  if not g or not L.sendTabShown() or ProfessionWizardDB.mailPanel == false then mp:Hide(); return end
  L.mpPlace()
  mp:Show()
  local y = 28
  -- one chip per crafter goal when there's more than one
  for i, c in ipairs(mpChips) do
    local gi = list[i]
    if gi and #list > 1 then
      c.key = gi.key
      c.text:SetText(string.format("%s  %s", (gi.name or "?"):upper(), PROF[gi.pid] and PROF[gi.pid].short or ""))
      c:SetActive(gi == g)
      c:ClearAllPoints(); c:SetPoint("TOPLEFT", MP_PAD, -y); c:Show()
      y = y + 22
    else
      c:Hide()
    end
  end
  if #list > 1 then y = y + 4 end
  mp.title:ClearAllPoints(); mp.title:SetPoint("TOPLEFT", MP_PAD, -y)
  mp.title:SetText(string.format("For %s, %s %d", g.name or "?", profName(g.pid), g.target or 0))
  y = y + 16
  mp.sub:ClearAllPoints(); mp.sub:SetPoint("TOPLEFT", MP_PAD, -y)
  mp.sub:SetText("list from " .. ago(g.time))
  y = y + 18
  local items = L.sendPlan(g)
  local count_, bankMore = 0, 0
  for i, r in ipairs(mpRows) do
    local it = items[i]
    if it and it.n > 0 then
      r:ClearAllPoints(); r:SetPoint("TOPLEFT", MP_PAD, -y); y = y + MP_ROW
      r.icon:SetTexture(GetIcon and GetIcon(it.id) or 134400)
      r.name:SetText(GetItemInfo(it.id) or ("item " .. it.id))
      r.count:SetText("x" .. it.n)
      r:Show()
      count_ = count_ + it.n
    else
      r:Hide()
    end
    if it then bankMore = bankMore + (it.bank or 0) end
  end
  local queue = L.attachQueue(items)
  local mails = math.ceil(#queue / MAX_ATTACH)
  local note = ""
  local filled = false
  if GetSendMailItem then
    for i = 1, MAX_ATTACH do if GetSendMailItem(i) then filled = true; break end end
  end
  if filled and not busy then
    note = "The mail is filled. Check it and click Send" .. (#queue > 0 and ", then fill the next one." or ".")
    queue = {}
  elseif #queue == 0 then
    note = "Nothing " .. (g.name or "they") .. " needs is in your bags."
  end
  if bankMore > 0 then note = note .. (note ~= "" and " " or "") .. bankMore .. " more is in your bank: take it out and it shows up here." end
  mp.note:SetText(note)
  y = y + 6
  if note ~= "" then
    mp.note:ClearAllPoints(); mp.note:SetPoint("TOPLEFT", MP_PAD, -y); mp.note:Show()
    y = y + (mp.note:GetStringHeight() or 14) + 8
  else
    mp.note:Hide()
  end
  if #queue > 0 then
    mp.send:ClearAllPoints(); mp.send:SetPoint("TOPLEFT", MP_PAD, -y)
    if not busy then
      mp.send.text:SetText(mails > 1 and string.format("FILL MAIL 1 OF %d", mails) or string.format("FILL MAIL: %d ITEMS", count_))
    end
    mp.send:SetActive(true); mp.send:Show()
    y = y + 28
  else
    mp.send:Hide()
  end
  mp:SetHeight(y + 6)
end

---------------------------------------------------------------------------
-- Events and slash command
---------------------------------------------------------------------------
local pending = false
local function soon()
  if pending or not (frame and frame:IsShown()) then return end
  pending = true
  C_Timer.After(0.2, function() pending = false; refresh() end)
end

local function onWindowOpen(mode)
  tsOpen, tsMode, recipeCache = true, mode, nil
  -- Show the list as soon as the window says which profession it is (usually straight away; otherwise try
  -- again every 50ms for half a second), and read its recipes right after, so the list doesn't lag behind.
  local tries = 0
  local function go()
    if not tsOpen then return end
    tsProf = L.windowProf()
    if not tsProf then
      tries = tries + 1
      if tries <= 10 then C_Timer.After(0.05, go) end
      return
    end
    if PROF[tsProf] and not PROF[tsProf].gather then
      local rank = readSkill(tsProf)
      if rank and rank < 300 and frame then
        current = tsProf
        if ProfessionWizardDB.auto ~= false and not frame:IsShown() then frame:Show()
        elseif frame:IsShown() then placeFrame() end
      end
    end
    C_Timer.After(0.05, function()
      if not tsOpen then return end
      recipeCache = nil
      pcall(L.learnWindow)
      soon()
    end)
  end
  go()
end

-- the tutorial starts the first time the window shows a profession you can still level
do
  local inner = refresh
  refresh = function(...)
    inner(...)
    if frame and frame:IsShown() and not ProfessionWizardDB.tutorialDone and not (tut and tut.step)
      and frame.find and frame.find:IsShown() then
      C_Timer.After(0.3, function()
        if frame:IsShown() and not ProfessionWizardDB.tutorialDone and not (tut and tut.step) and frame.find:IsShown() then
          Tut.start()
        end
      end)
    end
  end
end

-- What you buy out at the auction house goes to your mailbox: count it as on the way to you straight away,
-- the way mail you send is counted. Reading your inbox replaces this with what's really there.
local function noteBought(id, cnt)
  if not (type(id) == "number" and WANT[id] and ProfessionWizardDB and ProfessionWizardDB.chars) then return end
  local c = ProfessionWizardDB.chars[myKey()]
  if not c then return end
  c.incoming = c.incoming or {}
  c.incoming[id] = (c.incoming[id] or 0) + (cnt or 1)
  local _, link = GetItemInfo(id)
  Print(string.format("bought %dx %s: counted as on the way to you.", cnt or 1, link or ("item " .. id)))
  soon()
  if mp and mp:IsShown() and mpRefresh then mpRefresh() end
end

-- the older auction house (Blizzard's window and Auctionator call PlaceAuctionBid)
function L.noteBid(listType, index, bid)
  if not GetAuctionItemInfo then return end
  local info = { GetAuctionItemInfo(listType, index) }
  local cnt, buyout, id = info[3], info[10], info[17]
  if buyout and buyout > 0 and bid and bid >= buyout then noteBought(id, cnt) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
local inited = false
ev:SetScript("OnEvent", function(self, event, arg1)
  -- Start once ProfessionWizard_Data has loaded (it loads right after Profession Wizard); at login at the latest, so
  -- Profession Wizard still opens when the data folder is missing or turned off.
  if not inited and ((event == "ADDON_LOADED" and arg1 == DATA_ADDON) or event == "PLAYER_LOGIN") then
    inited = true
    if not next(ns.RECIPES) then
      print("|cffff8800Profession Wizard:|r the ProfessionWizard_Data folder is missing or turned off, so there are no recipes. "
        .. "Install both folders from the download and turn ProfessionWizard_Data on in the AddOns list.")
    end
    L.buildWant()
    ProfessionWizardDB = ProfessionWizardDB or {}
    for k, v in pairs(DEFAULTS) do if ProfessionWizardDB[k] == nil then ProfessionWizardDB[k] = v end end
    ProfessionWizardDB.chars = ProfessionWizardDB.chars or {}
    ProfessionWizardDB.minimap = ProfessionWizardDB.minimap or {}
    ProfessionWizardDB.posChar = ProfessionWizardDB.posChar or {}
    ProfessionWizardDB.pos = nil -- the old account-wide place: each character now keeps its own
    -- recipe data corrected (recipes that need plans were marked as taught by trainers): every saved route
    -- shows as out of date, so FIND CHEAPEST ROUTE plans around them again
    if (ProfessionWizardDB.dataVersion or 1) < 9 then
      for _, byProf in pairs(ProfessionWizardDB.routes or {}) do
        for _, r in pairs(byProf) do if type(r) == "table" then r.dirty = true end end
      end
      ProfessionWizardDB.dataVersion = 9
    end
    pcall(L.importOthers)
    build()
    pcall(L.setupMinimap)
    for _, e in ipairs({ "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL", "GET_ITEM_INFO_RECEIVED",
      "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "PLAYER_LOGIN", "PLAYER_LOGOUT",
      "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "MAIL_SEND_SUCCESS", "MAIL_FAILED", "MERCHANT_SHOW", "TRAINER_SHOW", "TRAINER_UPDATE",
      "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_UPDATE", "TRADE_SKILL_LIST_UPDATE",
      "CRAFT_SHOW", "CRAFT_CLOSE", "CRAFT_UPDATE", "PLAYER_REGEN_ENABLED",
      "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "AUCTION_ITEM_LIST_UPDATE", "MAIL_SEND_INFO_UPDATE",
      "COMMODITY_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_UPDATED",
      "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED",
      "REPLACE_ENCHANT", "NEW_RECIPE_LEARNED", "LEARNED_SPELL_IN_TAB" }) do
      pcall(self.RegisterEvent, self, e)
    end
    if SendMail then pcall(hooksecurefunc, "SendMail", function(recipient) pcall(L.noteOutgoing, recipient) end) end
    if PlaceAuctionBid then
      pcall(hooksecurefunc, "PlaceAuctionBid", function(listType, index, bid) pcall(L.noteBid, listType, index, bid) end)
    end
    -- the newer auction house: ores, bars, gems and the like are bought as "commodities" by id and amount
    if C_AuctionHouse and C_AuctionHouse.ConfirmCommoditiesPurchase then
      pcall(hooksecurefunc, C_AuctionHouse, "ConfirmCommoditiesPurchase", function(id, qty) pcall(noteBought, id, qty) end)
    end
    self:UnregisterEvent("ADDON_LOADED")
    if event ~= "PLAYER_LOGIN" then return end
  end
  if event == "ADDON_LOADED" or not inited then return end
  if event == "REPLACE_ENCHANT" then Ench.onReplace(); return end
  if event:sub(1, 15) == "UNIT_SPELLCAST_" then
    onCast(event, arg1)
    if frame and frame:IsShown() and event ~= "UNIT_SPELLCAST_START" then soon() end
    return
  end
  if event == "TRADE_SKILL_SHOW" then onWindowOpen("trade"); return end
  if event == "CRAFT_SHOW" then onWindowOpen("craft"); return end
  if event == "TRADE_SKILL_CLOSE" or event == "CRAFT_CLOSE" then
    if (event == "CRAFT_CLOSE") == (tsMode == "craft") then tsOpen, tsProf, tsMode, recipeCache = false, nil, nil, nil end
    soon(); return
  end
  if event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_LIST_UPDATE" or event == "CRAFT_UPDATE"
    or event == "NEW_RECIPE_LEARNED" or event == "LEARNED_SPELL_IN_TAB" then
    recipeCache = nil
    if not self.learnPending then
      self.learnPending = true
      -- read the window's recipes (a recipe you just learned among them), then redraw with them: redrawing
      -- before that showed the new recipe without its count and CRAFT button until the list was reopened
      C_Timer.After(0.5, function()
        self.learnPending = false
        recipeCache = nil
        pcall(L.learnWindow)
        soon()
      end)
    end
    soon(); return
  end
  if event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_UPDATED" then
    onAuction(event, arg1); return
  end
  if event:sub(1, 8) == "AUCTION_" then
    onAuction(event, arg1)
    if event ~= "AUCTION_ITEM_LIST_UPDATE" then soon() end
    return
  end
  if event == "PLAYER_REGEN_ENABLED" then
    if smeltBtn and not (frame and frame:IsShown()) then smeltBtn:Hide() end
    soon(); return
  end
  if event == "MERCHANT_SHOW" then C_Timer.After(0.3, function() pcall(L.readMerchant) end); return end
  if event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
    if event == "TRAINER_SHOW" then learnTried = {} end
    C_Timer.After(0.3, function() pcall(L.readTrainer); pcall(L.autoLearn) end)
    return
  end
  if event == "GET_ITEM_INFO_RECEIVED" then soon(); return end
  if event == "BAG_UPDATE_DELAYED" then recipeCache = nil end
  if event == "MAIL_SHOW" then mailShown = true end
  if event == "MAIL_INBOX_UPDATE" and mailShown then mailOpen = true end
  if event == "MAIL_CLOSED" then
    mailOpen, mailShown = false, false
  end
  if event == "BANKFRAME_OPENED" then bankOpen = true end
  if event == "BANKFRAME_CLOSED" then
    bankOpen = false
  end
  if event == "MAIL_SEND_SUCCESS" then L.deliverOutgoing() end
  if event == "MAIL_FAILED" then outgoing = nil end
  if event == "MAIL_SHOW" or (mp and mp:IsShown()) then C_Timer.After(0.25, mpRefresh) end
  if event == "MAIL_SEND_INFO_UPDATE" then return end -- attachments changed: only the mailbox panel cares
  if event == "PLAYER_LOGIN" then pcall(L.importOthers); C_Timer.After(5, snapshot); return end
  -- no snapshot at logout: the game reads bags and skills as empty by then, and the last change is saved already
  if event == "PLAYER_LOGOUT" then mailOpen, bankOpen = false, false; return end
  if event ~= "CHAT_MSG_SKILL" then
    if not self.snapPending then
      self.snapPending = true
      C_Timer.After(1, function() self.snapPending = false; pcall(snapshot) end)
    end
  end
  soon()
end)

function L.profFromArg(a)
  a = (a or ""):lower()
  if a == "" then return nil end
  for _, p in ipairs(PROFS) do
    if p.short:lower():find(a, 1, true) == 1 then return p.id end
    for _, n in ipairs(p.names) do if n:lower():find(a, 1, true) == 1 then return p.id end end
  end
end

SLASH_PROFESSIONWIZARD1 = "/professionwizard"
SLASH_PROFESSIONWIZARD2 = "/pw"
SlashCmdList.PROFESSIONWIZARD = function(msg)
  msg = strtrim((msg or ""):lower())
  local n = tonumber(msg)
  if n then frame:Show(); setTarget(n); return end
  if msg == "reset" then
    ProfessionWizardDB.posChar[myKey()] = nil
    placeFrame(); frame:Show(); return
  end
  if msg == "tutorial" then
    frame:Show(); refresh(); Tut.start(); return
  end
  if msg == "minimap" then
    setMinimap(ProfessionWizardDB.minimap.hide and true or false)
    Print("minimap button: " .. (ProfessionWizardDB.minimap.hide and "hidden" or "shown"))
    return
  end
  if msg == "auto" then
    ProfessionWizardDB.auto = (ProfessionWizardDB.auto == false)
    Print("open with your profession windows: " .. (ProfessionWizardDB.auto and "on" or "off"))
    return
  end
  if msg == "alts" then
    local list = alts()
    if #list == 0 then Print("no alts saved yet. Log in on them once (and open their bank).") end
    for _, c in ipairs(list) do Print(string.format("%s, saved %s", c.name or "?", ago(c.time))) end
    return
  end
  if msg == "vendors" then
    local k = 0
    for _ in pairs(ProfessionWizardDB.vendor or {}) do k = k + 1 end
    Print(k .. " vendor prices seen so far.")
    return
  end
  if msg == "debug" then
    Print(string.format("window open: %s, mode: %s, profession: %s", tostring(tsOpen), tostring(tsMode), tostring(tsProf and profName(tsProf))))
    local rc = getRecipes()
    if rc then
      Print(#rc.all .. " recipes in the window:")
      for i, w in ipairs(rc.all) do
        if i > 12 then break end
        local id
        for iid, ww in pairs(rc.byItem) do if ww == w then id = iid end end
        Print(string.format("  %s  item %s  can make %s  %s", w.name, tostring(id), tostring(w.avail), w.index and ("index " .. w.index) or (w.recipeID and ("recipe " .. w.recipeID) or "")))
      end
    end
    for _, q in ipairs((frame and frame.smeltAll and frame.smeltAll.list) or {}) do
      local w = findRecipe(q.r)
      Print(string.format("to smelt: %s x%d, found in window: %s", q.r.name, q.n, w and ("yes, can make " .. tostring(w.avail)) or "no"))
    end
    return
  end
  if msg == "colors" then
    local k = 0
    for _ in pairs(ProfessionWizardDB.fix or {}) do k = k + 1 end
    Print(k .. " recipe colors corrected from your profession windows.")
    return
  end
  local who = msg:match("^forget%s+(.+)$")
  if who then
    local gone
    for k, c in pairs(ProfessionWizardDB.chars or {}) do
      if (c.name or ""):lower() == who then
        ProfessionWizardDB.chars[k] = nil; gone = c.name
        for gk, g in pairs(ProfessionWizardDB.goals or {}) do if g.owner == k then ProfessionWizardDB.goals[gk] = nil end end
      end
    end
    Print(gone and ("forgot " .. gone .. ".") or ("no saved character called " .. who .. "."))
    refresh(); return
  end
  if msg == "help" then
    Print("/pw  open or close the list")
    Print("/pw tailoring  show a profession (or alch, smith, leather, eng, ench, cook, first, poisons)")
    Print("/pw 225  check materials up to skill 225")
    Print("/pw alts  list the alts it's counting")
    Print("/pw auto  open (or not) with your profession windows")
    Print("/pw forget Name  stop counting a character")
    Print("/pw minimap  show or hide the minimap button")
    Print("/pw tutorial  the first-time walkthrough again")
    Print("/pw reset  forget where you dragged the window: it opens next to the profession window again")
    return
  end
  local pid = L.profFromArg(msg)
  if pid then
    if not readSkill(pid) then Print("this character doesn't have " .. profName(pid) .. "."); return end
    pick(pid); frame:Show(); return
  end
  frame:SetShown(not frame:IsShown())
end
