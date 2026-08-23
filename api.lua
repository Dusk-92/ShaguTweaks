local _G = ShaguTweaks.GetGlobalEnv()

-- Central capability layer for ClassicAPI / SuperWoW integration.
-- Keep feature checks here so individual modules don't scatter DLL-specific
-- detection logic all over the codebase.
ShaguTweaks.API = ShaguTweaks.API or {}
local API = ShaguTweaks.API

API.classicapi_version = tonumber(_G.CLASSIC_API_VERSION) or 0
API.classicapi = type(_G.C_NamePlate) == "table"
  or type(_G.C_Spell) == "table"
  or type(_G.UnitGUID) == "function"

API.nameplates = type(_G.C_NamePlate) == "table"
  and type(_G.C_NamePlate.GetNamePlateForUnit) == "function"

API.casts = type(_G.C_Spell) == "table"
  and type(_G.C_Spell.UnitCastingInfo) == "function"
  and type(_G.C_Spell.UnitChannelInfo) == "function"

API.unitguid = type(_G.UnitGUID) == "function"

-- SuperWoW remains optional. It can still provide useful extra cast/GUID
-- information, but ClassicAPI is the primary compatibility layer.
API.superwow = type(_G.SpellInfo) == "function"
  and type(_G.CombatLogAdd) == "function"

API.GetNamePlateForUnit = function(unit)
  if API.nameplates then
    return _G.C_NamePlate.GetNamePlateForUnit(unit)
  end
end

API.UnitCastingInfo = function(unit)
  if API.casts then
    return _G.C_Spell.UnitCastingInfo(unit)
  end
end

API.UnitChannelInfo = function(unit)
  if API.casts then
    return _G.C_Spell.UnitChannelInfo(unit)
  end
end

API.UnitGUID = function(unit)
  if API.unitguid then
    return _G.UnitGUID(unit)
  end
end
