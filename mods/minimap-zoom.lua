local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Enlarged Minimap"],
  description = T["Increases the minimap size and shifts buff icons left to prevent overlap."],
  expansions = { ["vanilla"] = true },
  category = T["World & MiniMap"],
  enabled = false,
  order = 73,
  config = {
    ["minimap.scale"] = 1.2,
  }
})

module.enable = function(self)
  local scale = module.config["minimap.scale"]
  if scale < 1.0 then scale = 1.0 end
  if scale > 2.0 then scale = 2.0 end

  MinimapCluster:SetScale(scale)

  -- BuffFrame is anchored to UIParent TOPRIGHT/TOPRIGHT x=-205 y=-13 by vanilla.
  -- The C engine resets this after every PLAYER_AURAS_CHANGED event, overwriting
  -- any Lua SetPoint. The only reliable fix is to enforce on every frame via
  -- OnUpdate, which always runs after the C layout pass for that frame.
  -- We skip the call when the position is already correct to minimise overhead.

  local extra = MinimapCluster:GetWidth() * (scale - 1.0)
  local targetX = -205 - extra
  local targetY = -13

  -- BuffButton16 is the anchor for the player debuff row in vanilla 1.12.
  -- It sits just to the left of the minimap independently of BuffFrame.
  -- We calculate its target position to match the same leftward shift.
  local debuffX = -205 - extra
  local debuffY = -13 - 70  -- tuned value: one row below buffs without overlap

  -- BuffButton8 ends the top buff row; it is not reanchored by the C engine
  -- so it can overlap the minimap when scaled up. Pin it one icon height
  -- above BuffButton16 to keep both rows aligned with the leftward shift.
  local buffRowX = -205 - extra
  local buffRowY = debuffY + 26  -- one icon height above the debuff row

  -- TempEnchant1 sits to the right of BuffFrame, TempEnchant2 just below it.
  -- Both are re-anchored every frame to prevent the C engine from resetting them.

  -- IMPORTANT: enable() can be called multiple times (reload UI, toggling the
  -- module in ShaguTweaks settings, expansion switch, etc). Without reusing a
  -- single persistent frame, every call created a brand new anonymous
  -- CreateFrame("Frame") with its own OnUpdate, and the old ones were never
  -- released -- they kept running forever in the background, stacking up and
  -- fighting each other over the same anchors every frame. That's the source
  -- of the micro-stutter. We now store the enforcer on the module and just
  -- refresh its OnUpdate closure (with the new target values) if it already
  -- exists, instead of creating a new frame.
  if not self.enforcer then
    self.enforcer = CreateFrame("Frame")
  end
  local enforcer = self.enforcer

  enforcer:SetScript("OnUpdate", function()
    local _, _, _, x, y = BuffFrame:GetPoint(1)
    if x ~= targetX or y ~= targetY then
      BuffFrame:ClearAllPoints()
      BuffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", targetX, targetY)
    end

    if BuffButton16 then
      local _, _, _, dx, dy = BuffButton16:GetPoint(1)
      if dx ~= debuffX or dy ~= debuffY then
        BuffButton16:ClearAllPoints()
        BuffButton16:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", debuffX, debuffY)
      end
    end

    -- BuffButton8 ends the top buff row; force it leftward to clear the minimap.
    if BuffButton8 then
      local _, _, _, bx, by = BuffButton8:GetPoint(1)
      if bx ~= buffRowX or by ~= buffRowY then
        BuffButton8:ClearAllPoints()
        BuffButton8:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", buffRowX, buffRowY)
      end
    end

    -- TempEnchant1 to the right of BuffFrame, TempEnchant2 just below it.
    if TempEnchant1 then
      TempEnchant1:ClearAllPoints()
      TempEnchant1:SetPoint("TOPLEFT", BuffFrame, "TOPRIGHT", 5, 0)
    end

    if TempEnchant2 and TempEnchant1 then
      TempEnchant2:ClearAllPoints()
      TempEnchant2:SetPoint("TOP", TempEnchant1, "BOTTOM", 0, -2)
    end
  end)
end

module.disable = function(self)
  if self.enforcer then
    self.enforcer:SetScript("OnUpdate", nil)
  end
end
