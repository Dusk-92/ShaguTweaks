local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["XP Bar Text"],
  description = T["Always shows current XP and rested bonus percentage directly on the experience bar."],
  expansions = { ["vanilla"] = true, ["tbc"] = true },
  category = T["Action Bar"],
  enabled = true,
  order = 70,
})

module.enable = function(self)
  -- Create a separate overlay frame anchored to the XP bar,
  -- same approach as actionbar-improved-expbar to avoid touching bar internals
  local exp = CreateFrame("Frame", nil, UIParent)
  exp:SetAllPoints(MainMenuExpBar)
  exp:SetFrameStrata("HIGH")

  exp.text = exp:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  exp.text:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
  exp.text:SetPoint("CENTER", MainMenuExpBar, "CENTER", 0, 1)
  exp.text:SetJustifyH("CENTER")
  exp.text:SetTextColor(1, 1, 1)

  local function UpdateXPText()
    local curr = UnitXP("player")
    local max  = UnitXPMax("player")
    if not max or max == 0 then
      exp.text:Hide()
      return
    end

    local rest   = GetXPExhaustion() or 0
    local xpPct  = math.floor(curr / max * 100)

    local text
    if rest > 0 then
      -- Rested XP pool is 150% of max XP, not 100% (mécanique post-patch)
      local restPct = math.floor(math.min(rest / (max * 1.5) * 100, 100))
      text = "|cffffffff" .. xpPct .. "%|r |cffaaaaaa(|cffa78aca" .. restPct .. "%|cffaaaaaa)|r"
    else
      text = "|cffffffff" .. xpPct .. "%|r"
    end

    exp.text:SetText(text)
    exp.text:Show()
  end

  local events = CreateFrame("Frame", nil, UIParent)
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("PLAYER_XP_UPDATE")
  events:RegisterEvent("UPDATE_EXHAUSTION")
  events:RegisterEvent("PLAYER_LEVEL_UP")
  events:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
      if not this.loaded then
        this.loaded = true
        -- hide blizzard's default overlay that renders the original xp text
        MainMenuBarOverlayFrame:Hide()
        UpdateXPText()
      end
    else
      UpdateXPText()
    end
  end)
end
