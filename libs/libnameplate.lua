local _G = ShaguTweaks.GetGlobalEnv()
local GetExpansion = ShaguTweaks.GetExpansion
local API = ShaguTweaks.API or {}

local NAMEPLATE_OBJECTORDER = { "border", "glow", "name", "level", "levelicon", "raidicon" }
local NAMEPLATE_TYPE = "Button"
if GetExpansion() == "tbc" then
  NAMEPLATE_OBJECTORDER = { "border", "castborder", "casticon", "glow", "name", "level", "levelicon", "raidicon" }
  NAMEPLATE_TYPE = "Frame"
end

local function IsNamePlate(frame)
  if not frame or frame:GetObjectType() ~= NAMEPLATE_TYPE then return nil end
  local regions = frame:GetRegions()

  if not regions then return nil end
  if not regions.GetObjectType then return nil end
  if not regions.GetTexture then return nil end

  if regions:GetObjectType() ~= "Texture" then return nil end
  return regions:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" or nil
end

local registry = {}
ShaguTweaks.libnameplate = CreateFrame("Frame", nil, UIParent)
ShaguTweaks.libnameplate.OnInit = {}
ShaguTweaks.libnameplate.OnShow = {}
ShaguTweaks.libnameplate.OnUpdate = {}

local function GetHealthBar(plate)
  -- Other nameplate addons may already have attached the authoritative bar.
  if plate.healthbar and plate.healthbar.GetStatusBarColor and
    plate.healthbar.SetStatusBarColor then
    return plate.healthbar
  end

  -- Once another addon has added children, the health bar is no longer
  -- guaranteed to be the first value returned by GetChildren().
  local children = { plate:GetChildren() }
  for i = 1, table.getn(children) do
    local child = children[i]
    if child and child.GetStatusBarColor and child.SetStatusBarColor then
      return child
    end
  end

  return children[1]
end

local function SetupPlate(plate, unit)
  if not plate or not IsNamePlate(plate) then return end

  local healthbar = GetHealthBar(plate)
  if not healthbar then return end

  local registered = registry[healthbar]
  if registered then
    if unit then
      registered.unit = unit
      registered.guid = API.UnitGUID and API.UnitGUID(unit) or nil
    end
    return registered
  end

  plate.healthbar = healthbar
  if unit then
    plate.unit = unit
    plate.guid = API.UnitGUID and API.UnitGUID(unit) or nil
  end

  for i, object in pairs({plate:GetRegions()}) do
    if NAMEPLATE_OBJECTORDER[i] then
      plate[NAMEPLATE_OBJECTORDER[i]] = object
    end
  end

  -- run OnInit functions
  for id, func in pairs(ShaguTweaks.libnameplate.OnInit) do
    func(plate)
  end

  -- preserve the plate's existing scripts and append ShaguTweaks callbacks
  local oldUpdate = plate:GetScript("OnUpdate")
  plate:SetScript("OnUpdate", function(self, elapsed)
    if oldUpdate then oldUpdate(self, elapsed) end
    for id, func in pairs(ShaguTweaks.libnameplate.OnUpdate) do
      func(self, elapsed)
    end
  end)

  local oldShow = plate:GetScript("OnShow")
  plate:SetScript("OnShow", function(self)
    if oldShow then oldShow(self) end
    for id, func in pairs(ShaguTweaks.libnameplate.OnShow) do
      func(self)
    end
  end)

  registry[healthbar] = plate
  return plate
end

-- ClassicAPI exposes real nameplate lifecycle events and nameplateN unit
-- tokens. Prefer those so ShaguTweaks no longer scans every WorldFrame child
-- on every rendered frame. Keep the unit token/GUID on each plate so modules
-- can query precise unit data without identifying enemies by displayed name.
if API.nameplates and _G.C_NamePlate and _G.C_NamePlate.GetNamePlates then
  ShaguTweaks.libnameplate:RegisterEvent("NAME_PLATE_CREATED")
  ShaguTweaks.libnameplate:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  ShaguTweaks.libnameplate:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  ShaguTweaks.libnameplate:RegisterEvent("PLAYER_ENTERING_WORLD")

  ShaguTweaks.libnameplate:SetScript("OnEvent", function()
    if event == "NAME_PLATE_CREATED" then
      SetupPlate(arg1)

    elseif event == "NAME_PLATE_UNIT_ADDED" then
      local unit = arg1
      SetupPlate(API.GetNamePlateForUnit(unit), unit)

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
      -- ClassicAPI resolves the leaving token during the removal handler,
      -- before positional nameplateN indices shift.
      local plate = API.GetNamePlateForUnit(arg1)
      if plate then
        plate.unit = nil
        plate.guid = nil
      end

    elseif event == "PLAYER_ENTERING_WORLD" then
      local plates = _G.C_NamePlate.GetNamePlates()
      if plates then
        for i = 1, table.getn(plates) do
          local unit = "nameplate" .. i
          local plate = API.GetNamePlateForUnit(unit)
          if plate then SetupPlate(plate, unit) end
        end
      end
    end
  end)
else
  -- Compatibility fallback for clients without the ClassicAPI nameplate API.
  local initialized = 0
  local parentcount, childs, plate

  ShaguTweaks.libnameplate:SetScript("OnUpdate", function()
    parentcount = WorldFrame:GetNumChildren()
    if initialized < parentcount then
      childs = { WorldFrame:GetChildren() }
      for i = initialized + 1, parentcount do
        plate = childs[i]
        if IsNamePlate(plate) then SetupPlate(plate) end
      end
      initialized = parentcount
    end
  end)
end
