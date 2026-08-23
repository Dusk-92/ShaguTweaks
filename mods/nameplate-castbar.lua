local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API
local LegacyCastingInfo = ShaguTweaks.UnitCastingInfo
local LegacyChannelInfo = ShaguTweaks.UnitChannelInfo

local module = ShaguTweaks:register({
  title = T["Nameplate Castbar"],
  description = T["Adds a castbar to the nameplate based on combat log estimations."],
  expansions = { ["vanilla"] = true },
  category = T["Nameplates"],
  enabled = true,
})

local function QueryLegacy(query)
  if not query then return end

  local cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill = LegacyCastingInfo(query)
  if cast then
    return cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill, false
  end

  local channel
  channel, nameSubtext, text, texture, startTime, endTime, isTradeSkill = LegacyChannelInfo(query)
  if channel then
    return channel, nameSubtext, text, texture, startTime, endTime, isTradeSkill, true
  end
end

local function QueryPlateCast(plate)
  -- nameplateN is positional, so verify its GUID before trusting a token kept
  -- on the frame across nameplate pool recycling/reordering.
  local unit = plate.unit
  if unit and plate.guid and API.UnitGUID(unit) ~= plate.guid then
    unit = nil
  end

  if unit then
    local cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill = API.GetCastInfo(unit)
    if cast then
      return cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill, false
    end

    local channel
    channel, nameSubtext, text, texture, startTime, endTime, isTradeSkill = API.GetChannelInfo(unit)
    if channel then
      return channel, nameSubtext, text, texture, startTime, endTime, isTradeSkill, true
    end
  end

  -- SuperWoW remains the second source, keyed by stable GUID.
  if ShaguTweaks.superwow_active and plate.guid then
    local a, b, c, d, e, f, g, h = QueryLegacy(plate.guid)
    if a then return a, b, c, d, e, f, g, h end
  end

  -- Final compatibility fallback: ShaguTweaks' original name/combat-log DB.
  local name = plate.name and plate.name:GetText()
  return QueryLegacy(name)
end

module.enable = function(self)
  if ShaguPlates then return end

  local backdrop = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  }

  local function create_castbar(plate)
    -- create the castbar
    plate.castbar = CreateFrame("StatusBar", nil, plate)
    plate.castbar:SetPoint("BOTTOM", plate, "BOTTOM", 8, -11)
    plate.castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    plate.castbar:SetStatusBarColor(1, .8, 0, 1)
    plate.castbar:SetWidth(plate:GetWidth() - 22)
    plate.castbar:SetHeight(10)

    -- create the spell icon
    plate.castbar.texture = CreateFrame("Frame", nil, plate.castbar)
    plate.castbar.texture:SetPoint("RIGHT", plate.castbar, "LEFT", 0, 0)
    plate.castbar.texture:SetHeight(18)
    plate.castbar.texture:SetWidth(18)
    plate.castbar.texture.icon = plate.castbar.texture:CreateTexture(nil, "BACKGROUND")
    plate.castbar.texture.icon:SetPoint("CENTER", 0, 0)
    plate.castbar.texture.icon:SetWidth(12)
    plate.castbar.texture.icon:SetHeight(12)
    plate.castbar.texture:SetBackdrop(backdrop)
    plate.castbar.texture:SetBackdropBorderColor(1,.8,0)

    -- castbar background
    plate.castbar.bg = plate.castbar:CreateTexture(nil, "BACKGROUND")
    plate.castbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    plate.castbar.bg:SetVertexColor(.1, .1, 0, .8)
    plate.castbar.bg:SetAllPoints(true)

    -- castbar spark
    plate.castbar.spark = plate.castbar:CreateTexture(nil, "OVERLAY")
    plate.castbar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    plate.castbar.spark:SetWidth(20)
    plate.castbar.spark:SetHeight(20)
    plate.castbar.spark:SetBlendMode("ADD")

    -- castbar border
    plate.castbar.backdrop = CreateFrame("Frame", nil, plate.castbar)
    plate.castbar.backdrop:SetFrameLevel(plate.castbar:GetFrameLevel())
    plate.castbar.backdrop:SetPoint("TOPLEFT", plate.castbar, "TOPLEFT", -3, 3)
    plate.castbar.backdrop:SetPoint("BOTTOMRIGHT", plate.castbar, "BOTTOMRIGHT", 3, -3)
    plate.castbar.backdrop:SetBackdrop(backdrop)
    plate.castbar.backdrop:SetBackdropBorderColor(1,.8,0)

    -- castbar spellname
    plate.castbar.text = plate.castbar:CreateFontString(nil, "HIGH", "GameFontWhite")
    plate.castbar.text:SetPoint("CENTER", plate.castbar, "CENTER", 0, 0)
    local font, size, opts = plate.castbar.text:GetFont()
    plate.castbar.text:SetFont(font, size - 3, "THINOUTLINE")

    -- hide castbar by default
    plate.castbar:Hide()
  end

  -- Keep OnUpdate only for smooth bar animation. Cast discovery itself now
  -- prefers ClassicAPI's engine/server-backed unit cast state.
  table.insert(ShaguTweaks.libnameplate.OnUpdate, function(plate)
    plate = plate or this

    -- create castbar if not existing
    if not plate.castbar then create_castbar(plate) end

    local cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill, isChannel = QueryPlateCast(plate)

    if cast and startTime and endTime and endTime > startTime then
      local duration = endTime - startTime
      local max = duration / 1000
      local cur = GetTime() - startTime / 1000

      if isChannel then
        cur = max + startTime/1000 - GetTime()
      end

      cur = cur > max and max or cur
      cur = cur < 0 and 0 or cur

      plate.castbar:Show()
      plate.castbar:SetMinMaxValues(0, max)
      plate.castbar:SetValue(cur)

      local percent = cur / max
      local x = plate.castbar:GetWidth()*percent
      plate.castbar.spark:SetPoint("CENTER", plate.castbar, "LEFT", x, 0)

      plate.castbar.text:SetText(cast)

      if texture then
        plate.castbar.texture.icon:SetTexture(texture)
        plate.castbar.texture.icon:Show()
      else
        plate.castbar.texture.icon:Hide()
      end

      plate.castbar:SetAlpha(plate:GetAlpha())
    else
      plate.castbar:Hide()
    end
  end)
end
