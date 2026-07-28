local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local gfind = string.gmatch or string.gfind
local rgbhex = ShaguTweaks.rgbhex

local module = ShaguTweaks:register({
    title = T["Chat Levels"],
    description = T["Shows player levels in chat."],
    expansions = { ["vanilla"] = true, ["tbc"] = nil },
    category = T["Social & Chat"],
    enabled = nil,
})

module.enable = function(self)
  local events = CreateFrame("Frame", nil, UIParent)
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:SetScript("OnEvent", function()
    if this.loaded then return end
    this.loaded = true

    local playerdb = ShaguTweaks_cache and ShaguTweaks_cache["players"]

    for i=1, NUM_CHAT_WINDOWS do
      local frame = _G["ChatFrame"..i]
      if frame and not frame.HookAddMessageLevel and not Prat then
        frame.HookAddMessageLevel = frame.AddMessage
        frame.AddMessage = function(f, text, a1, a2, a3, a4, a5)
          if text and playerdb then
            for name in gfind(text, "|Hplayer:(.-)|h") do
              local data = playerdb[name]
              if data and data.level then
                local level = data.level
                local color = rgbhex(GetDifficultyColor(level))
                text = string.gsub(text,
                  "|Hplayer:" .. name .. "|h%[" .. name .. "%]|h|r",
                  "|Hplayer:" .. name .. "|h[" .. name .. "]|h|r " .. color .. level .. "|r")
              end
            end
          end
          frame.HookAddMessageLevel(f, text, a1, a2, a3, a4, a5)
        end
      end
    end
  end)
end
