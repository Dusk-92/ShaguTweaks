local L, T = ShaguTweaks.L, ShaguTweaks.T

local module = ShaguTweaks:register({
	title = T["Skip Gossip Text"],
	description = T["Skip gossip text when interacting with NPCs unless holding shift."],
	expansions = { ["vanilla"] = true, ["tbc"] = nil },
	category = nil,
	enabled = nil,
})

module.enable = function(self)
	local actions = CreateFrame("Frame", nil, UIParent)

	local professions = {
		"battlemaster",
		"taxi",
		"trainer",
		"vendor",
		"banker",
	}

	local phrases = {
		-- Bank
		"I would like to check my deposit box",

		-- Vanilla
		"Teleport me to the Molten Core",

		-- Turtle WoW
		-- Alliance
		"Please open a portal to Alah'Thalas",
		"Please open a portal to Stormwind",
		-- Horde
		"Open a portal to Amani'Alor",

		-- ruRU
		"Я хотел бы проверить свою ячейку.", -- Bank
		"*Прикоснуться к нестабильному кристаллу Провала.*", -- MC entrance
		"\*Положить руку на сферу.\*", -- BWL entrance
		--"Thank you, Stable Master. Please take the animal.", -- AV quest locales_broadcast_text id6681
		"Благодарю тебя. Пожалуйста, возьми питомца.", -- AV quest locales_broadcast_text id6681
		"С удовольствием. Уж очень они воняют!", -- AV quest
		"Конфета или Жизнь!",
	}

	local ignore = {
		-- npcs named here will be ignored
		"Goblin Brainwashing Device",
	}

	function actions:Gossip()
		if actions.gossip then
			local name = GossipFrameNpcNameText:GetText()
			local GossipOptions = {}
			local title

			title,GossipOptions[1],_,GossipOptions[2],_,GossipOptions[3],_,GossipOptions[4],_,GossipOptions[5] = GetGossipOptions()

			-- Ported from LazyPig: "title" here is actually the text of the
			-- FIRST gossip option. Keep an unmutated copy before the
			-- word-stripping below, so we can gate the talent trainer
			-- confirmation on it.
			local rawTitle = title

			if name then
				for _, npc in pairs(ignore) do
					if name == npc then
						return true
					end
				end
			end

			-- Ported from LazyPig: if a "binder" (innkeeper hearthstone)
			-- option is present and we are NOT currently at our bind
			-- point, don't auto-skip anything in this menu at all.
			for i = 1, 5 do
				if not GossipOptions[i] then break end
				if GossipOptions[i] == "binder" then
					local bind = GetBindLocation()
					if not (bind == GetSubZoneText() or bind == GetZoneText()
						or bind == GetRealZoneText() or bind == GetMinimapZoneText()) then
						return
					end
				end
			end

			for i = 1, 5 do
				if not GossipOptions[i] then break end

				if GossipOptions[i] == "gossip" then
					title = string.gsub(title, "%W", "")

					for _, phrase in pairs(phrases) do
						phrase = string.gsub(phrase, "%W", "")

						if phrase == title then
							SelectGossipOption(i)
							break
						end
					end
				elseif GossipOptions[i] == "trainer" and rawTitle == "Reset my talents." then
					-- Ported from LazyPig: don't auto-confirm a talent
					-- reset, always require a manual click.
				else
					for _, profession in pairs(professions) do
						if profession == GossipOptions[i] then
							SelectGossipOption(i)
							break
						end
					end
				end
			end
		end
	end

	actions:RegisterEvent("GOSSIP_SHOW")
	actions:RegisterEvent("GOSSIP_CLOSED")
	actions:SetScript("OnEvent", function()
		if (event == "GOSSIP_SHOW") then
			actions.gossip = true
			if not IsShiftKeyDown() then
				actions:Gossip()
			end
		elseif (event == "GOSSIP_CLOSED") then
			actions.gossip = nil
		end
	end)
end