if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2RedactedCensorClient")
	util.AddNetworkString("TTT2RedactedCensorEntity")
	util.AddNetworkString("TTT2RedactedCensorArea")
	util.AddNetworkString("TTT2RedactedCensorStop")
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
	self.disabledTeamChat = GetConVar("ttt2_redact_can_commune"):GetBool()
	self.disabledTeamChatRecv = GetConVar("ttt2_redact_can_commune"):GetBool()
	self.disabledTeamVoice = GetConVar("ttt2_redact_can_commune"):GetBool()
	self.disabledTeamVoiceRecv = GetConVar("ttt2_redact_can_commune"):GetBool()

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
	
	local function RedactEntity(ply)
		--TODO: black bounding box
	end
	
	local function UnRedactEntity(ply)
		--TODO: remove black bounding box
	end
	
	local function RedactLocation(pos)
		--TODO: black bounding box
	end
	
	local function UnRedactLocation(pos)
		--TODO: remove black bounding box
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
	end)

	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		--By the time we call this function at the start of the game, all players have been loaded in.
		--So we don't have to worry about a late join, who would otherwise fail to see ply as redacted.
		--BMF REMOVE--RedactPlayer(ply)
		ply:SetNWBool("IsRedacted", true)
		
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
		--BMF REMOVE--UnRedactPlayer(ply)
		ply:SetNWBool("IsRedacted", false)
	end

	hook.Add("PlayerSay", "PlayerSayTTT2Redacted", function(ply, text)
		--Any message the Redacted tries to send is redacted.
		--Honestly not sure how to use LANG here, as LANG.TryTranslation is Client only. Hopefully noone needs this to be translated.
		if not GetConVar("ttt2_redact_can_commune"):GetBool() and IsValid(ply) and ply:IsPlayer() and ply:GetSubRole() == ROLE_REDACTED and not speaker:IsSpec() then
			ply:ChatPrint(ply:GetName() .. ": [REDACTED]")
			return ""
		end
	end)

	hook.Add("TTT2CanUseVoiceChat", "TTT2CanUseVoiceChatRedacted", function(speaker, isTeamVoice)
		--Presumably unnecessary, but TTT2 doesn't explicitly indicate that voice has been disabled. This should alleviate confusion.
		if not GetConVar("ttt2_redact_can_commune"):GetBool() and IsValid(speaker) and speaker:IsPlayer() and speaker:GetSubRole() == ROLE_REDACTED and not speaker:IsSpec() then
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
	
	hook.Add("TTT2ModifyRadarRole", "TTT2ModifyRadarRoleCopycat", function(ply, target)
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
		--TODO: Redact the corpse (black bounding box).
		--TODO: Use ConVar to redact the corpse's team
		--  (false by default: If the Detective/Traitor wants to waste credits to revive the player, they may do so by default. Otherwise, they may kill the Redacted on sight through some errant logic).
	end)

	local function ResetRedactedForServer()
		REDACT_SETUP_COMPLETE = nil
		
		for _, ply in ipairs(player.GetAll()) do
			ply:SetNWBool("IsRedacted", false)
		end
	end
	hook.Add("TTTEndRound", "TTTEndRoundRedacted", ResetRedactedForServer)
	hook.Add("TTTPrepareRound", "TTTPrepareRoundRedacted", ResetRedactedForServer)
end

if CLIENT then
	local function DrawBlackBoxAroundEntity(ent, alpha)
		local client = LocalPlayer()
		local obb_mins = ent:OBBMins()
		local obb_maxs = ent:OBBMaxs()
		local obb_mins_world = ent:LocalToWorld(obb_mins)
		local obb_maxs_world = ent:LocalToWorld(obb_maxs)
		local cube_vertex_obbs_world = {
			Vector(obb_mins_world.x, obb_mins_world.y, obb_mins_world.z),
			Vector(obb_mins_world.x, obb_mins_world.y, obb_maxs_world.z),
			Vector(obb_mins_world.x, obb_maxs_world.y, obb_mins_world.z),
			Vector(obb_mins_world.x, obb_maxs_world.y, obb_maxs_world.z),
			Vector(obb_maxs_world.x, obb_mins_world.y, obb_mins_world.z),
			Vector(obb_maxs_world.x, obb_mins_world.y, obb_maxs_world.z),
			Vector(obb_maxs_world.x, obb_maxs_world.y, obb_mins_world.z),
			Vector(obb_maxs_world.x, obb_maxs_world.y, obb_maxs_world.z)
		}
		local cube_vertex_obbs = {
			Vector(obb_mins.x, obb_mins.y, obb_mins.z),
			Vector(obb_mins.x, obb_mins.y, obb_maxs.z),
			Vector(obb_mins.x, obb_maxs.y, obb_mins.z),
			Vector(obb_mins.x, obb_maxs.y, obb_maxs.z),
			Vector(obb_maxs.x, obb_mins.y, obb_mins.z),
			Vector(obb_maxs.x, obb_mins.y, obb_maxs.z),
			Vector(obb_maxs.x, obb_maxs.y, obb_mins.z),
			Vector(obb_maxs.x, obb_maxs.y, obb_maxs.z)
		}
		local is_on_screen = false
		local is_in_line_of_sight = false
		local left_most_point = ScrW()
		local up_most_point = ScrH()
		local right_most_point = 0
		local down_most_point = 0

		--TODO: Perform additional traces to make sure that the entity is not visually blocked by the environment
		--  No solution is perfect here, in that we'd have to fire a zillion ray traces just to check if the player is visible, even if by a single pixel of information
		--  Proposed steps:
		--    Start with a hull trace the size of the entity in question. Use MASK_VISIBLE here and the client's entity as the filter.
		--      If this hits the redacted entity, then we're done
		--    If it doesn't, then there's something that is at least partially blocking the redacted entity.
		--      In this case, use 5 line traces post for-loop

		--According to the wiki, ToScreen requires a 3D rendering context to work correctly.
		--https://wiki.facepunch.com/gmod/Vector:ToScreen
		cam.Start3D()
			local hull_offset_vec = Vector(7, 7, 7)
			local tr_center = util.TraceHull({start = client:GetPos(), endpos = ent:GetPos(), filter = client, mask = MASK_SHOT_HULL, mins = obb_mins + hull_offset_vec, maxs = obb_maxs - hull_offset_vec})
			if IsValid(tr_center.Entity) and tr_center.Entity:EntIndex() == ent:EntIndex() then
				is_in_line_of_sight = true
				--print("  TraceHull was successful") --REDACT_DEBUG
			end

			--REDACT_DEBUG
			print("  TraceHull: IsValid(tr_center.Entity)=" .. tostring(IsValid(tr_center.Entity)))
			if IsValid(tr_center.Entity) then
				print("    " .. tostring(tr_center.Entity:EntIndex()) .. " versus expected value of " .. tostring(ent:EntIndex()) .. ", is_in_line_of_sight=" .. tostring(is_in_line_of_sight))
			end
			render.DrawWireframeBox(tr_center.HitPos, Angle(0, 0, 0), ent:OBBMins() + hull_offset_vec, ent:OBBMaxs() - hull_offset_vec, COLOR_BLUE, true)
			--REDACT_DEBUG

			--Edge case: The player is right in front of the redacted entity, such that the vertices of the OBB are all off screen.
			is_on_screen = is_on_screen or not util.IsOffScreen((ent:GetPos() + ent:OBBCenter()):ToScreen())

			for i = 1, 8 do
				local screen_pos = cube_vertex_obbs_world[i]:ToScreen()

				is_on_screen = is_on_screen or not util.IsOffScreen(screen_pos)

				if not is_in_line_of_sight then
					--BMF--local tr_corner = util.TraceLine({start = client:GetPos(), endpos = cube_vertex_obbs_world[i], filter = client, mask = MASK_SHOT_HULL})
					local tr_corner = util.TraceHull({start = client:GetPos(), endpos = ent:GetPos(), filter = client, mask = MASK_SHOT_HULL, mins = cube_vertex_obbs[i] - hull_offset_vec, maxs = cube_vertex_obbs[i] + hull_offset_vec})
					if IsValid(tr_corner.Entity) and tr_corner.Entity:EntIndex() == ent:EntIndex() then
						is_in_line_of_sight = true
					end

					--REDACT_DEBUG
					print("  TraceLine(" .. tostring(i) .. ") IsValid(tr_corner.Entity)=" .. tostring(IsValid(tr_corner.Entity)))
					if IsValid(tr_corner.Entity) then
						print("    " .. tostring(tr_corner.Entity:EntIndex()) .. " versus expected value of " .. tostring(ent:EntIndex()) .. ", is_in_line_of_sight=" .. tostring(is_in_line_of_sight))
					end
					render.DrawWireframeBox(tr_corner.HitPos, Angle(0, 0, 0), cube_vertex_obbs[i] - hull_offset_vec, cube_vertex_obbs[i] + hull_offset_vec, COLOR_GREEN, true)
					--BMF BAD MINS/MAXS--render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), cube_vertex_obbs[i] - hull_offset_vec, cube_vertex_obbs[i] + hull_offset_vec, COLOR_GREEN, true)
					--BMF GOOD--render.DrawWireframeBox(tr_corner.HitPos, ent:GetAngles(), ent:OBBMins() - hull_offset_vec, ent:OBBMins() + hull_offset_vec, COLOR_WHITE, true)
					--BMF GOOD--render.DrawWireframeBox(tr_corner.HitPos, ent:GetAngles(), ent:OBBMaxs() - hull_offset_vec, ent:OBBMaxs() + hull_offset_vec, COLOR_BLACK, true)
					--REDACT_DEBUG
				end

				--BMF DOESN'T WORK--render.DrawLine(client:EyePos(), cube_vertex_obbs_world[i], COLOR_GREEN) --REDACT_DEBUG
				--BMF DOESN'T WORK--render.DrawLine(client:EyePos(), client:EyePos() + client:EyeAngles():Forward() * 100, COLOR_GREEN) --REDACT_DEBUG

				left_most_point = math.min(screen_pos.x, left_most_point)
				up_most_point = math.min(screen_pos.y, up_most_point)
				right_most_point = math.max(screen_pos.x, right_most_point)
				down_most_point = math.max(screen_pos.y, down_most_point)
			end
		cam.End3D()

		if not is_on_screen or not is_in_line_of_sight then
			--print("  Not on screen") --REDACT_DEBUG
			return
		end

		--The box's position is centered in its middle.
		local box_width = right_most_point - left_most_point
		local box_height = down_most_point - up_most_point

		--REDACT_DEBUG
		--print("  left_most_point=" .. tostring(left_most_point) .. ", up_most_point=" .. tostring(up_most_point) .. ", right_most_point=" .. tostring(right_most_point) .. ", down_most_point=" .. tostring(down_most_point))
		--REDACT_DEBUG

		surface.SetDrawColor(Color(0, 0, 0, alpha))
		surface.DrawRect(left_most_point, up_most_point, box_width, box_height)
	end

	hook.Add("HUDPaint", "HUDPaintRedacted", function()
		local client = LocalPlayer()

		--TODO: Check all redacted entities, not players. May need to maintain a list in case the number of entities is too large? Not sure how much that would save on performance...
		for _, ply in ipairs(player.GetAll()) do
			if (ply:GetSubRole() == ROLE_REDACTED or ply:GetNWBool("IsRedacted")) and ply:SteamID64() ~= client:SteamID64() then
				local alpha = 255
				if client:GetSubRole() == ROLE_REDACTED then
					alpha = 190
				end

				--REDACT_DEBUG
				cam.Start3D()
					print("REDACT_DEBUG HUDPaint: Calling DrawBlackBox for " .. ply:GetName())
					render.DrawWireframeBox(ply:GetPos(), ply:GetAngles(), ply:OBBMins(), ply:OBBMaxs(), COLOR_RED)
				cam.End3D()
				--REDACT_DEBUG

				DrawBlackBoxAroundEntity(ply, alpha)
			end
		end
	end)
end