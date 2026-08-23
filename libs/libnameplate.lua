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

local function InitializePlate(plate)
  if not IsNamePlate(plate) or registry[plate] then return end

  plate.healthbar = plate:GetChildren()
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

  registry[plate] = true
end

-- ClassicAPI exposes real nameplate lifecycle events and nameplateN unit
-- tokens. Prefer those so ShaguTweaks no longer scans every WorldFrame child
-- on every rendered frame.
if API.nameplates and _G.C_NamePlate and _G.C_NamePlate.GetNamePlates then
  ShaguTweaks.libnameplate:RegisterEvent("NAME_PLATE_CREATED")
  ShaguTweaks.libnameplate:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  ShaguTweaks.libnameplate:RegisterEvent("PLAYER_ENTERING_WORLD")

  ShaguTweaks.libnameplate:SetScript("OnEvent", function()
    if event == "NAME_PLATE_CREATED" then
      InitializePlate(arg1)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
      InitializePlate(API.GetNamePlateForUnit(arg1))
    elseif event == "PLAYER_ENTERING_WORLD" then
      local plates = _G.C_NamePlate.GetNamePlates()
      if plates then
        for _, plate in pairs(plates) do
          InitializePlate(plate)
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
        InitializePlate(plate)
      end
      initialized = parentcount
    end
  end)
end
