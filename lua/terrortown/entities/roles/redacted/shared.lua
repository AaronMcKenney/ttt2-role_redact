if SERVER then
	AddCSLuaFile()
end

roles.InitCustomTeam(ROLE.name, {
	icon = "vgui/ttt/dynamic/roles/icon_redact",
	color = Color(0, 0, 0, 255)
})
roles.InitCustomTeam(ROLE.name .. "_SETUP", {
	icon = "vgui/ttt/dynamic/roles/icon_redact",
	color = Color(0, 0, 0, 255)
})

function ROLE:PreInitialize()
	self.color = Color(0, 0, 0, 255)
	self.abbr = "redact"

	--Scoring is less punishing here than on other roles, since the Redacted knows little about their own team.
	--teamKillsMultiplier is the same as Innocents. killsMultiplier is the same as Serial Killer.
	self.score.teamKillsMultiplier = -8
	self.score.killsMultiplier = 5

	self.preventFindCredits = false

	self.fallbackTable = {}

	--Redacted doesn't know who their fellow teammates are, nor do they have an open channel of communication
	--This is primarily to prevent the other players from deciphering whose team the Redacted is on.
	--Ex. Traitor team should be confounded as to who the Redacted as is as everyone else (Note: By default, a gambling Traitor will most likely try to kill the Redacted)
	self.unknownTeam = true
	--I think setting unknownTeam to true should be enough, but we set these other params just to be safe
	self.disabledTeamChat = true
	self.disabledTeamChatRecv = true
	self.disabledTeamVoice = true
	self.disabledTeamVoiceRecv = true

	--The Redacted starts off on TEAM_REDACTED_SETUP, for role selection calculations
	--  However, they quickly change teams based on RNG upon spawn or role change.
	--StartWinChecks() creates a winchecker timer, which runs every second.
	--  Therefore, there is an absurdly small chance that the Redacted player will trigger the end of the round right as they're given this role, but before their team has been updated.
	--  It is a bit hacky, but we use TEAM_REDACTED_SETUP to prevent this scenario from occuring, as the server will prevent a round from ending due to the two different teams.
	--  If we don't do this, then for this edge case the other players will be confused as to how the game suddenly ended, and how this happens somewhat randomly.
	self.defaultTeam = TEAM_REDACTED_SETUP
	--The Redacted prevents win if they stand alone.
	self.preventWin = false

	self.defaultEquipment = SPECIAL_EQUIPMENT

	--The player's role and team are not broadcasted to all other players.
	self.isPublicRole = false

	--The Redacted does not have detective-like abilities
	self.isPolicingRole = false

	--The Redacted is not able to see missing in action players and does not have the haste mode timer, as they may not necessarily be innocent
	self.isOmniscientRole = false

	-- ULX ConVars
	self.conVarData = {
		pct = 0.15,
		maximum = 1,
		minPlayers = 6,
		random = 30,
		traitorButton = 0,

		--Redacted can't access shop, has no credits.
		credits = 0,
		creditsAwardDeadEnable = 0,
		creditsAwardKillEnable = 0,
		shopFallback = SHOP_DISABLED,

		togglable = true
	}
end

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end

	return false
end

if SERVER then
	--Used to only set the Redacted's team in the beginning of the game when TTTBeginRound occurs
	--Reason 1: If we want to set the Redacted's role to some other non-Redacted evil Team, then we'll want all players to be given their role to figure out if we can set it to another evil player's team.
	local REDACT_SETUP_COMPLETE = nil
	
	local function IsStickyTeam(team)
		--A hack. True if the supported team is not to be altered for balancing reasons.
		if (DOPPELGANGER and team == TEAM_DOPPELGANGER) or (COPYCAT and team == TEAM_COPYCAT) then
			return true
		end

		return false
	end

	local function GetOtherTeamList()
		local other_team_list = {}
		--Use other_team_set here so that we can prevent other_team_list from having duplicates.
		--Need to resturn other_team_list instead of other_team_set since (as far as I'm aware) lua's random function can't really handle sets, as #set doesn't necessarily return the number of elements within it.
		local other_team_set = {}
		
		--local debug_str_otl = "REDACT_DEBUG GetOtherTeamList: other_team_list=[ " --REDACT_DEBUG
		
		for _, ply in ipairs(player.GetAll()) do
			local ply_team = ply:GetTeam()
			if ply_team ~= TEAM_INNOCENT and ply_team ~= TEAM_TRAITOR and ply_team ~= TEAM_NONE and ply_team ~= TEAM_REDACTED_SETUP and ply_team ~= TEAM_REDACTED and not other_team_set[ply_team] then
				other_team_list[#other_team_list + 1] = ply_team
				other_team_set[ply_team] = true
				
				--debug_str_otl = debug_str_otl .. tostring(ply_team) .. " " --REDACT_DEBUG
			end
		end
		
		--REDACT_DEBUG
		--debug_str_otl = debug_str_otl .. "]"
		--print(debug_str_otl)
		--REDACT_DEBUG
		
		return other_team_list
	end

	local function GetNewTeamForRedacted(other_team_list)
		local inn_weight = GetConVar("ttt2_redact_weight_innocent"):GetInt()
		local tra_weight = GetConVar("ttt2_redact_weight_traitor"):GetInt()
		local red_weight = GetConVar("ttt2_redact_weight_redacted"):GetInt()
		local oth_weight = GetConVar("ttt2_redact_weight_other"):GetInt()
		local tot_weight = inn_weight + tra_weight + red_weight + oth_weight
		
		--print("REDACT_DEBUG GetNewTeamForRedacted: inn_weight=" .. tostring(inn_weight) .. ", tra_weight=" .. tostring(tra_weight) .. ", red_weight=" .. tostring(red_weight) .. ", oth_weight=" .. tostring(oth_weight) .. ", tot_weight=" .. tostring(tot_weight)) --REDACT_DEBUG
		
		if tot_weight <= 0 then
			--print("  returning TEAM_REDACTED as tot_weight is 0") --REDACT_DEBUG
			return TEAM_REDACTED
		end
		
		local r = math.random(tot_weight)
		--print("  r=" .. tostring(r)) --REDACT_DEBUG

		if inn_weight > 0 and r <= inn_weight then
			--print("  returning TEAM_INNOCENT") --REDACT_DEBUG
			return TEAM_INNOCENT
		elseif tra_weight > 0 and r <= inn_weight + tra_weight then
			--print("  returning TEAM_TRAITOR") --REDACT_DEBUG
			return TEAM_TRAITOR
		elseif (red_weight > 0 and r <= inn_weight + tra_weight + red_weight) or #other_team_list <= 0 then
			--print("  returning TEAM_REDACTED") --REDACT_DEBUG
			return TEAM_REDACTED
		else --(r > inn_weight + tra_weight + red_weight) and #other_team_list > 0 --this is true regardless
			local r_oth = math.random(#other_team_list)
			--print("  Returning other team. r_oth=" .. tostring(r_oth) .. ", other_team_list[r_oth]=" .. tostring(other_team_list[r_oth])) --REDACT_DEBUG
			return other_team_list[r_oth]
		end
	end
	
	hook.Add("TTTBeginRound", "TTTBeginRoundRedacted", function()
		local other_team_list = GetOtherTeamList()

		for _, ply in ipairs(player.GetAll()) do
			if ply:GetTeam() == TEAM_REDACTED_SETUP then
				--print("REDACT_DEBUG TTTBeginRound: Getting new team for " .. ply:GetName()) --REDACT_DEBUG
				local new_team = GetNewTeamForRedacted(other_team_list)
				ply:UpdateTeam(new_team, true, true)
				SendFullStateUpdate()
			end
		end
		
		REDACT_SETUP_COMPLETE = true

		--BMF
		--timer.Simple(5, function()
		--	for _, ply in ipairs(player.GetAll()) do
		--		REDACT_DATA.RedactEntity(ply)
		--	end
		--end)
		--timer.Simple(10, function()
		--	for _, ply in ipairs(player.GetAll()) do
		--		REDACT_DATA.RedactEntity(ply)
		--	end
		--end)
		--timer.Simple(15, function()
		--	for _, ply in ipairs(player.GetAll()) do
		--		REDACT_DATA.RedactEntity(ply)
		--	end
		--end)
		--timer.Simple(20, function()
		--	for _, ply in ipairs(player.GetAll()) do
		--		REDACT_DATA.RedactEntity(ply)
		--	end
		--end)
		--BMF
	end)

	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		if GetConVar("ttt2_redact_deagle_enable"):GetBool() then
			ply:GiveEquipmentWeapon('weapon_ttt2_redact_deagle')
		end

		--By the time we call this function at the start of the game, all players have been loaded in.
		--So we don't have to worry about a late join, who would otherwise fail to see ply as redacted.
		REDACT_DATA.RedactEntity(ply)
		
		--UpdateTeam is called when the player is first given this role in SetRole (and a hook for UpdateTeam won't be run for this)
		--GiveRoleLoadout is the last function called during SetRole
		--Therefore, we can safely change the team here, as the player's team has already been set.
		if REDACT_SETUP_COMPLETE and isRoleChange and ply:GetTeam() == TEAM_REDACTED_SETUP then
			--print("REDACT_DEBUG GiveRoleLoadout: Getting new team for " .. ply:GetName()) --REDACT_DEBUG
			local other_team_list = GetOtherTeamList()
			local new_team = GetNewTeamForRedacted(other_team_list)
			--The following bools are set to true, which can prevent other addons from dealing with the extra UpdateTeam call, which they shouldn't need to worry about.
			--suppressEvent is set to true, which prevents TTT2 from triggering a role change event
			--suppressHook is set to true, which prevents TTT2 from running the TTT2UpdateTeam hook
			ply:UpdateTeam(new_team, true, true)
			SendFullStateUpdate()
		--else --REDACT_DEBUG
		--	print("REDACT_DEBUG GiveRoleLoadout: " .. ply:GetName() .. " with team " .. tostring(ply:GetTeam()) .. " will not have team changed. isRoleChange=" .. tostring(isRoleChange)) --REDACT_DEBUG
		end
	end

	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
		ply:StripWeapon('weapon_ttt2_redact_deagle')

		REDACT_DATA.UnredactEntity(ply)
	end

	hook.Add("PlayerSay", "PlayerSayTTT2Redacted", function(ply, text)
		--Any message the Redacted tries to send is redacted.
		--Honestly not sure how to use LANG here, as LANG.TryTranslation is Client only. Hopefully noone needs this to be translated.
		if not GetConVar("ttt2_redact_can_commune"):GetBool() and IsValid(ply) and ply:IsPlayer() and ply:GetSubRole() == ROLE_REDACTED and not ply:IsSpec() and not IsInSpecDM(ply) then
			ply:ChatPrint(ply:GetName() .. ": [REDACTED]") --BMF TODO
			return ""
		end
	end)

	hook.Add("TTT2AvoidTeamChat", "TTT2AvoidTeamChatRedacted", function(sender, tm, msg)
		--Presumably unnecessary, but TTT2 doesn't explicitly indicate that voice has been disabled. This should alleviate confusion.
		if not IsValid(sender) or not sender:IsPlayer() or sender:GetSubRole() ~= ROLE_REDACTED or sender:IsSpec() or IsInSpecDM(sender) then
			return
		end

		LANG.Msg(speaker, "voice_prevented_" .. REDACTED.name, nil, MSG_CHAT_WARN)
		return false
	end)

	hook.Add("TTT2CanUseVoiceChat", "TTT2CanUseVoiceChatRedacted", function(speaker, isTeamVoice)
		--Presumably unnecessary, but TTT2 doesn't explicitly indicate that voice has been disabled. This should alleviate confusion.
		if not IsValid(speaker) or not speaker:IsPlayer() or speaker:GetSubRole() ~= ROLE_REDACTED or speaker:IsSpec() or IsInSpecDM(speaker) then
			return
		end

		if isTeamVoice or not GetConVar("ttt2_redact_can_commune"):GetBool() then
			LANG.Msg(speaker, "voice_prevented_" .. REDACTED.name, nil, MSG_CHAT_WARN)
			return false
		end
	end)

	hook.Add("TTT2SpecialRoleSyncing", "TTT2SpecialRoleSyncingRedacted", function (ply, tbl)
		if GetRoundState() == ROUND_POST then
			return
		end

		for ply_i in pairs(tbl) do
			if ply == ply_i or not ply_i:Alive() or IsInSpecDM(ply_i) then
				continue
			end

			if ROLE_COPYCAT and (ply:HasWeapon("weapon_ttt2_copycat_files") and ply_i:HasWeapon("weapon_ttt2_copycat_files")) then
				--A Copycat that has stolen the role of the Redacted may still see their teammates and vice versa.
				continue
			end

			if ply_i:GetSubRole() == ROLE_REDACTED then
				--The teammates of the Redacted can't see that they are on their team.
				--If they could, Traitors wouldn't hesitate to kill the Redacted, removing some of the social intrigue.
				--This effectively bypasses roles with unknownTeam set to false (i.e. essentially all non-Innocents)
				tbl[ply_i] = {ROLE_NONE, TEAM_NONE}
			end
		end
	end)
	
	hook.Add("TTT2ModifyRadarRole", "TTT2ModifyRadarRoleRedacted", function(ply, target)
		--This function uses the same general logic as TTT2SpecialRoleSyncing, for consistency
		if GetRoundState() == ROUND_POST then
			return
		end

		local ply_subrole_data = ply:GetSubRoleData()
		local target_subrole_data = target:GetSubRoleData()

		if ROLE_COPYCAT and (ply:HasWeapon("weapon_ttt2_copycat_files") and target:HasWeapon("weapon_ttt2_copycat_files")) then
			return
		elseif target:GetSubRole() == ROLE_REDACTED and ply:GetTeam() == target:GetTeam() then
			return ROLE_NONE, TEAM_NONE
		end
	end)

	hook.Add("TTTOnCorpseCreated", "TTTOnCorpseCreatedRedacted", function(rag, ply)
		if ply:GetNWBool("TTT2IsRedacted") then
			REDACT_DATA.RedactEntity(rag)
		end
	end)

	local function ResetRedactedForServer()
		REDACT_SETUP_COMPLETE = nil
		REDACT_DATA.ResetRedactData()
	end
	hook.Add("TTTEndRound", "TTTEndRoundRedacted", ResetRedactedForServer)
	hook.Add("TTTPrepareRound", "TTTPrepareRoundRedacted", ResetRedactedForServer)
end

if CLIENT then
	-------------
	-- CONVARS --
	-------------
	function ROLE:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

		form:MakeSlider({
			serverConvar = "ttt2_redact_weight_innocent",
			label = "label_redact_weight_innocent",
			min = 0,
			max = 100,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_redact_weight_traitor",
			label = "label_redact_weight_traitor",
			min = 0,
			max = 100,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_redact_weight_redacted",
			label = "label_redact_weight_redacted",
			min = 0,
			max = 100,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_redact_weight_other",
			label = "label_redact_weight_other",
			min = 0,
			max = 100,
			decimal = 0
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_redact_can_commune",
			label = "label_redact_can_commune"
		})

		form:MakeComboBox({
			serverConvar = "ttt2_redact_mode",
			label = "label_redact_mode",
			choices = {{
				value = 0,
				title = LANG.GetTranslation("label_redact_mode_0")
			},{
				value = 1,
				title = LANG.GetTranslation("label_redact_mode_1")
			},{
				value = 2,
				title = LANG.GetTranslation("label_redact_mode_2")
			}}
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_redact_error",
			label = "label_redact_error"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_redact_deagle_enable",
			label = "label_redact_deagle_enable"
		})

		form:MakeSlider({
			serverConvar = "ttt2_redact_deagle_starting_ammo",
			label = "label_redact_deagle_starting_ammo",
			min = 0,
			max = 12,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_redact_deagle_capacity",
			label = "label_redact_deagle_capacity",
			min = 1,
			max = 12,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_redact_deagle_refill_time",
			label = "label_redact_deagle_refill_time",
			min = 0,
			max = 120,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_redact_duration",
			label = "label_redact_duration",
			min = 0,
			max = 30,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_redact_speed_multi",
			label = "label_redact_speed_multi",
			min = 0.1,
			max = 1.0,
			decimal = 0
		})
	end
end

--TODO:
--0. Problem Statement: Our current setup draws the black rectangle in 2D space. It requires little math to cover up the entity, but requires a lot of raycasting to determine if the entity is partially covered by the world.
--   If we imbue the rectangle with depth, then it will always be drawn in a manner that can handle partial visibility scenarios.
--1. Migrate logic to PostDrawTranslucentRenderables and clean up code, especially by removing TraceHull and TraceLine. Keep the ToScreen logic, as it will likely be used for specific edge cases.
--2. Similar to how the Impostor Station's GUI is drawn, it must be possible to place the black rectangle in a manner that:
--   It always faces the client
--   Its size is equal to or greater than the OBB that the entity has
--   It is always in front of the entity
--
--Idea 0:
--  Retrieve the OBBs from the redacted entity with OBBMins and OBBMaxs
--  Construct a list of 8 vertices that are the OBB's world coordinates (utilize LocalToWorld for this)
--  Make these vertices "camera oriented" via vertex - client's position
--  Find the projection of each of these vertices about the client's right and up axes (see wiki article on vector projection)
--  The width and height will be the largest difference in the magnitudes of these projections across the right axis projection and the up axis projection respectively.
--  The position is almost the entity's position + OBBCenter, but it needs to be pushed forward to the forward-most vertex in the OBB at least (assuming we don't go right in front of the entity and into its OBB)
--    The extra vector that will be added here is computed by:
--    Finding the forward projection of all 8 vertices
--    Pick out the vertex that has the smallest magnitude and call it "forward-most"
--    Project the entity's center (GetPos + GetOBBCenter) onto the client's forward axis.
--    The vector created by (forward-projected-center - "forward-most") is the vector that will need to be added.
--  Edge case: the client is too close to the entity for a 3D projected rectangle to feasibly cover up the entire entity
--    i.e. the magnitude of the vector (forward-projected-center - "forward-most") is greater or equal to the magnitude of forward-projected-center
--    To handle this, save the entity's current texture/material/whatever. It is colored pure black to give the aesthetic of being censored even though the client can see it.
--      Calling ent:SetColor(COLOR_BLACK) will make them black (must be done on the server), but they will still have lighting/texture. May also need to call ent:SetMaterial("").
--    In addition, the Redacted STATUS is applied to the client for as long as they are too close to the entity, which:
--      Reduces the client's speed by 20%
--      Darkens their screen
--      Makes random black squares appear on their screen, popping into and out of existence
--      Adds in audible static noise.
--
--Idea 1:
--  Construct the black rectangle as usual (i.e. by mapping the OBB vertices to world and finding the (x,y,w,h) dimensions of the box through min/max compares
--  Let its normal be equal to the eye angles.
--  Determine the rectangle's depth. This is as simple as finding the position of the entity, technically.
--  If needed, reshape the rectangle such that it will still cover the entity at its new depth. This is the hard part. Presumably requires some math pertaining to FOV.
--  Draw the rectangle with DrawQuadEasy.
