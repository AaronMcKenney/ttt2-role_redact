if SERVER then
	AddCSLuaFile()
end

--Enum and cached variable for redact mode. Client must be restarted for changes to this mode to take effect. Cached to reduce unnecessary hook creation, as the hooks run frequently
REDACT_MODE = {SMART_2D = 0, SIMPLE_3D = 1, DUMB_2D = 2}
REDACT_DATA = {}
REDACT_DATA.REDACTED_WORLD_POINTS = {}
REDACT_DATA.MODE = GetConVar("ttt2_redact_mode"):GetInt()

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end

	return false
end

function REDACT_DATA.UnredactEntity(ent)
	if ent:GetNWBool("TTT2IsRedacted") and ent:IsPlayer() then
		for _, wep in ipairs(ent:GetWeapons()) do
			wep:SetNoDraw(false)
		end
	end

	ent:SetNWBool("TTT2IsRedacted", false)
end

function REDACT_DATA.RedactEntity(ent)
	ent:SetNWBool("TTT2IsRedacted", true)

	if ent:IsPlayer() then
		for _, wep in ipairs(ent:GetWeapons()) do
			wep:SetNoDraw(true)
		end
	end
end

function REDACT_DATA.ResetRedactData()
	for _, ent in ipairs(ents.GetAll()) do
		REDACT_DATA.UnredactEntity(ent)
	end

	REDACT_DATA.REDACTED_WORLD_POINTS = {}
end

hook.Add("PlayerSwitchWeapon", "PlayerSwitchWeaponRedacted", function(ply, old, new)
	if ply:GetNWBool("TTT2IsRedacted") then
		new:SetNoDraw(true)
	end
end)

if CLIENT then
	function REDACT_DATA.CanCensorRedactedEntity(ent)
		--local client = LocalPlayer()
		----Assumes the entity is valid and redacted
		--local can_censor = true
		--
		--if ent:IsPlayer() then
		--	--If the client is redacted, don't censor them, as that would ruin visibility
		--	--Likewise, don't censor spectators
		--	can_censor = can_censor and ent:SteamID64() ~= LocalPlayer():SteamID64() and ent:Alive() and not IsInSpecDM(ent)
		--elseif ent:IsWeapon() then
		--	--Shouldn't censor weapons if they are held by a redacted player, as players would see two redacted entities attached to each other.
		--	can_censor = can_censor and (not IsValid(ent:GetOwner()) or not IsValid(ent:GetOwner():GetActiveWeapon()) or ent:GetOwner():GetActiveWeapon() ~= ent)
		--end
		--
		--return can_censor

		--return (IsValid(ent) and ent:GetNWBool("TTT2IsRedacted") and 
		--	(not ent:IsPlayer() or (ent:SteamID64() ~= LocalPlayer():SteamID64() and ent:Alive() and not IsInSpecDM(ent))) and
		--	(not ent:IsWeapon() or (not IsValid(ent:GetOwner()) or not IsValid(ent:GetOwner():GetActiveWeapon()) or ent:GetOwner():GetActiveWeapon() ~= ent)))

		return (IsValid(ent) and ent:GetNWBool("TTT2IsRedacted") and 
			(not ent:IsPlayer() or (ent:SteamID64() ~= LocalPlayer():SteamID64() and ent:Alive() and not IsInSpecDM(ent))))
	end

	if REDACT_DATA.MODE == REDACT_MODE.SIMPLE_3D then
		hook.Add("PostDrawTranslucentRenderables", "PostDrawTranslucentRenderablesRedacted", function()
			local client = LocalPlayer()
			local alpha = 255
			if client:GetSubRole() == ROLE_REDACTED then
				alpha = 190
			end
			local color_redact = Color(0, 0, 0, alpha)

			for _, ent in ipairs(ents.GetAll()) do
				if REDACT_DATA.CanCensorRedactedEntity(ent) then
					if not GetConVar("ttt2_redact_error"):GetBool() then
						render.SetColorMaterial()
					end
					render.DrawBox(ent:GetPos(), ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), color_redact)
				end
			end
		end)
	elseif REDACT_DATA.MODE == REDACT_MODE.DUMB_2D then
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
			local left_most_point = ScrW()
			local up_most_point = ScrH()
			local right_most_point = 0
			local down_most_point = 0
			local is_on_screen = false

			--According to the wiki, ToScreen requires a 3D rendering context to work correctly.
			--https://wiki.facepunch.com/gmod/Vector:ToScreen
			cam.Start3D()
				--Edge case: The player is right in front of the redacted entity, such that the vertices of the OBB are all off screen.
                is_on_screen = is_on_screen or not util.IsOffScreen((ent:GetPos() + ent:OBBCenter()):ToScreen())

				for i = 1, 8 do
					local screen_pos = cube_vertex_obbs_world[i]:ToScreen()
					is_on_screen = is_on_screen or not util.IsOffScreen(screen_pos)

					left_most_point = math.min(screen_pos.x, left_most_point)
					up_most_point = math.min(screen_pos.y, up_most_point)
					right_most_point = math.max(screen_pos.x, right_most_point)
					down_most_point = math.max(screen_pos.y, down_most_point)
				end
			cam.End3D()

			--Note: This method is flawed. To truly check this, we would need to test a lot of points in the projected rectangle to see if they're on or off the screen.
			if not is_on_screen then
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

		hook.Add("HUDPaint", "HUDPaintRedactedDumb2D", function()
			local client = LocalPlayer()
			local alpha = 255
			if client:GetSubRole() == ROLE_REDACTED then
				alpha = 190
			end

			for _, ent in ipairs(ents.GetAll()) do
				if REDACT_DATA.CanCensorRedactedEntity(ent) then

					--REDACT_DEBUG
					--cam.Start3D()
					--	render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), COLOR_RED)
					--cam.End3D()
					--REDACT_DEBUG

					DrawBlackBoxAroundEntity(ent, alpha)
				end
			end
		end)
	end --DUMB_2D
end