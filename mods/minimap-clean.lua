local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Minimap Clean"],
  description = T["Hides minimap addon buttons automatically when the cursor leaves the minimap area."],
  expansions = { ["vanilla"] = true },
  category = T["World & MiniMap"],
  enabled = false,
})

-- Liste noire : tout ce qu'on ne veut PAS toucher (trackers, blips, boutons systeme...)
local ignoreList = {
    "MiniMapTrackingFrame",
    "MiniMapMeetingStoneFrame",
    "MiniMapMailFrame",
    "MiniMapPing",
    "MinimapBackdrop",
    "MinimapZoomIn",
    "MinimapZoomOut",
    "BookOfTracksFrame",
    "GatherNote",
    "FishingExtravaganzaMini",
    "MiniNotePOI",
    "RecipeRadarMinimapIcon",
    "FWGMinimapPOI",
    "MBB_MinimapButtonFrame",
    "QuestieNote",
    "MetaMap",
    "LootLinkMinimapButton",
    "TimeManagerClockButton",
    "pfMiniMapPin",
    "Clock",
    "Timer",
    "GameTimeFrame",
    "MinimapToggleButton",
    "TWMinimapShopFrame",
    "LFT_Minimap"
}

local function ShouldIgnore(name)
    if not name then return true end
    for _, needle in ipairs(ignoreList) do
        if string.find(name, needle, 1, true) then
            return true
        end
    end
    return false
end

-- Vanilla 1.12 can throw an error when GetScript() is queried with a script
-- type that the frame object doesn't support (AtlasCFMButtonFrame is one
-- example). pcall keeps detection harmless for every frame type.
local function GetScriptSafe(frame, script)
    if not frame or type(frame.GetScript) ~= "function" then return nil end

    local ok, handler = pcall(frame.GetScript, frame, script)
    if ok then return handler end
    return nil
end

local function IsAddonButton(child)
    if not child or not child.GetName then return false end

    local name = child:GetName()
    if ShouldIgnore(name) then return false end

    local hasClick = GetScriptSafe(child, "OnClick")
    local hasMouseUp = GetScriptSafe(child, "OnMouseUp")
    local hasMouseDown = GetScriptSafe(child, "OnMouseDown")

    -- Parfois, le bouton cliquable est cache dans un enfant de la frame principale
    if not (hasClick or hasMouseUp or hasMouseDown) and child.GetChildren then
        for _, subchild in ipairs({child:GetChildren()}) do
            if GetScriptSafe(subchild, "OnClick") then
                return true
            end
        end
    end

    return hasClick or hasMouseUp or hasMouseDown
end

local function SetButtonsAlpha(alpha)
    local children = {Minimap:GetChildren()}
    for _, child in ipairs(children) do
        if IsAddonButton(child) then
            child:SetAlpha(alpha)
        end
    end
end

module.enable = function(self)
    -- Etat interne stocke sur le module -> propre a chaque enable
    self.isShown = true
    self.leaveTime = nil
    self.elapsed = 0

    local HIDE_DELAY = 3
    local THROTTLE = 0.1
    local MARGIN = 30

    self.frame = self.frame or CreateFrame("Frame")

    self.frame:SetScript("OnUpdate", function()
        -- En vanilla 1.12, OnUpdate utilise la variable globale arg1.
        self.elapsed = self.elapsed + arg1
        if self.elapsed < THROTTLE then return end
        self.elapsed = 0

        local x, y = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local mx, my = x / scale, y / scale

        local left = Minimap:GetLeft()
        local right = Minimap:GetRight()
        local bottom = Minimap:GetBottom()
        local top = Minimap:GetTop()

        local isOver = left and mx >= (left - MARGIN) and mx <= (right + MARGIN)
                        and my >= (bottom - MARGIN) and my <= (top + MARGIN)

        if isOver then
            self.leaveTime = nil
            if not self.isShown then
                SetButtonsAlpha(1)
                self.isShown = true
            end
        else
            if self.isShown then
                if not self.leaveTime then
                    self.leaveTime = GetTime()
                elseif GetTime() - self.leaveTime >= HIDE_DELAY then
                    SetButtonsAlpha(0)
                    self.isShown = false
                    self.leaveTime = nil
                end
            end
        end
    end)
end

module.disable = function(self)
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
    -- On remet tous les boutons visibles quand on desactive le module
    SetButtonsAlpha(1)
end
