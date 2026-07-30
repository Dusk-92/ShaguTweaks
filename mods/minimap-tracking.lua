local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Hide Tracking Icon"],
  description = T["Hides the tracking icon from the minimap."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["World & MiniMap"],
  enabled = true,
  order = 74,
})

module.enable = function(self)
  -- Désactive l'affichage automatique du bouton de suivi
  MiniMapTrackingFrame.Show = function() end
  MiniMapTrackingFrame:Hide()
end