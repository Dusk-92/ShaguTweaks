local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["No Toggle Auto-Attack"],
  description = T["Keeps Auto Attack, Auto Shot, and Shoot active when re-pressed, preventing accidental cancellation."],
  expansions = { ["vanilla"] = true, ["tbc"] = true },
  category = T["Action Bar"],
  enabled = true,
  order = 12,
})

module.enable = function(self)
  local attacking, shooting

  local combatFrame = CreateFrame("Frame")
  combatFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
  combatFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
  combatFrame:SetScript("OnEvent", function()
    attacking = event == "PLAYER_ENTER_COMBAT"
  end)

  local shootFrame = CreateFrame("Frame")
  shootFrame:RegisterEvent("START_AUTOREPEAT_SPELL")
  shootFrame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
  shootFrame:SetScript("OnEvent", function()
    shooting = event == "START_AUTOREPEAT_SPELL"
  end)

  local function active(name)
    if not name then return false end
    name = strlower(name)
    return (name == "attack" and attacking) or
           ((name == "auto shot" or name == "shoot") and shooting)
  end

  local origCastSpell = CastSpell
  function _G.CastSpell(index, booktype)
    if active(GetSpellName(index, booktype)) then return end
    return origCastSpell(index, booktype)
  end

  local origCastSpellByName = CastSpellByName
  function _G.CastSpellByName(text, onself)
    if active(text) then return end
    return origCastSpellByName(text, onself)
  end

  local tt = CreateFrame("GameTooltip", "ShaguTweaksNoToggleTT", nil, "GameTooltipTemplate")
  tt:SetOwner(UIParent, "ANCHOR_NONE")

  local origUseAction = UseAction
  function _G.UseAction(slot, clicked, onself)
    if HasAction(slot) and not GetActionText(slot) then
      tt:SetOwner(UIParent, "ANCHOR_NONE")
      tt:SetAction(slot)
      local label = _G["ShaguTweaksNoToggleTTTextLeft1"]
      if label and active(label:GetText()) then return end
    end
    return origUseAction(slot, clicked, onself)
  end
end
