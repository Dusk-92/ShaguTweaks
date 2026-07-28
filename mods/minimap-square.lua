local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local module = ShaguTweaks:register({
  title = T["MiniMap Square"],
  description = T["Draw the mini map in a squared shape instead of a round one."],
  expansions = { ["vanilla"] = true, ["tbc"] = true },
  category = T["World & MiniMap"],
  enabled = nil,
  config = {
    ["minimap.size"] = 144,
  },
})
module.enable = function(self)
  local size = module.config["minimap.size"]
  MinimapBorder:SetTexture(nil)
  Minimap:SetWidth(size)
  Minimap:SetHeight(size)
  Minimap:SetPoint("CENTER", MinimapCluster, "TOP", 9, -98)
  Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
  Minimap.border = CreateFrame("Frame", nil, Minimap)
  Minimap.border:SetFrameStrata("BACKGROUND")
  Minimap.border:SetFrameLevel(1)
  Minimap.border:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -3, 3)
  Minimap.border:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 3, -3)
  Minimap.border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }})
  Minimap.border:SetBackdropBorderColor(.9,.8,.5,1)
  Minimap.border:SetBackdropColor(.4,.4,.4,1)

  if _G.MinimapClock then
    if not self.clockOriginalPoint then
      local point, relativeTo, relativePoint, x, y = MinimapClock:GetPoint()
      self.clockOriginalPoint = { point, relativeTo, relativePoint, x, y }
    end

    MinimapClock:ClearAllPoints()
    MinimapClock:SetPoint("TOP", Minimap, "BOTTOM", 0, -2)
  end
end

module.disable = function(self)
  if _G.MinimapClock and self.clockOriginalPoint then
    MinimapClock:ClearAllPoints()
    MinimapClock:SetPoint(unpack(self.clockOriginalPoint))
  end
end