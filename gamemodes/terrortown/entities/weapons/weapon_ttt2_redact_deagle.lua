--Shamelessly taken from the Sidekick Deagle

SWEP.Base = "weapon_tttbase"

SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.AdminSpawnable = true

SWEP.HoldType = "pistol"

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/icon_redact_deagle.vmt")
end

if CLIENT then
	SWEP.PrintName = "Redact Deagle"
	SWEP.Author = "BlackMagicFine"

	SWEP.ViewModelFOV = 54
	SWEP.ViewModelFlip = false

	SWEP.Category = "Deagle"
	SWEP.Icon = "vgui/ttt/icon_redact_deagle.vtf"
	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "DEAGLE_NAME_" .. REDACTED.name,
		desc = "DEAGLE_DESC_" .. REDACTED.name
	}
end

--Gun stats
SWEP.Primary.Delay = 1
SWEP.Primary.Recoil = 6
SWEP.Primary.Automatic = false
SWEP.Primary.NumShots = 1
SWEP.Primary.Damage = 0
SWEP.Primary.Cone = 0.00001
SWEP.Primary.Ammo = ""
SWEP.Primary.ClipSize = GetConVar("ttt2_redact_deagle_capacity"):GetInt()
SWEP.Primary.ClipMax = GetConVar("ttt2_redact_deagle_capacity"):GetInt()
SWEP.Primary.DefaultClip = GetConVar("ttt2_redact_deagle_starting_ammo"):GetInt()

--Misc.
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = false
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.UseHands = true
SWEP.Kind = WEAPON_EXTRA
SWEP.CanBuy = {}
SWEP.LimitedStock = true
SWEP.globalLimited = true
SWEP.NoRandom = true
SWEP.notBuyable = true

--Model
SWEP.ViewModel = "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"
SWEP.Weight = 5
SWEP.Primary.Sound = Sound("Weapon_Deagle.Single")

--Iron sights
SWEP.IronSightsPos = Vector(-6.361, -3.701, 2.15)
SWEP.IronSightsAng = Vector(0, 0, 0)

function SWEP:Initialize()
	if CLIENT then
		return
	end

	self.refill_in_progress = false

	self:BeginRefilling()
end

local function CanRefill(wep)
	if not IsValid(wep) then
		return false
	end

	return (GetConVar("ttt2_redact_deagle_refill_time"):GetInt() > 0 and wep:Clip1() < wep:GetMaxClip1())
end

local function Refill(wep)
	if not IsValid(wep) or not CanRefill(wep) then
		return
	end

	wep:SetClip1(wep:Clip1() + 1)

	if not CanRefill(wep) then
		wep.refill_in_progress = false
	else
		wep:BeginRefilling()
	end
end

function SWEP:BeginRefilling()
	if not CanRefill(self) then
		return
	end

	self.refill_in_progress = true

	local refill_time = GetConVar("ttt2_redact_deagle_refill_time"):GetInt()
	timer.Simple(refill_time, function()
		Refill(self)
	end)
end

local function RedactDeagleCallback(attacker, tr, dmg)
	if CLIENT or not IsValid(attacker) or not attacker:IsPlayer() then
		return
	end

	local target = tr.Entity
	if IsValid(target) then
		target:SetNWBool("TTT2IsRedacted", true)
	end

	local wep = attacker:GetWeapon("weapon_ttt2_redact_deagle")
	if IsValid(wep) and not wep.refill_in_progress then
		wep:BeginRefilling()
	end

	return true
end

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:ShootBullet(dmg, recoil, numbul, cone)
	cone = cone or 0.01

	local bullet = {}
	bullet.Num = 1
	bullet.Src = self:GetOwner():GetShootPos()
	bullet.Dir = self:GetOwner():GetAimVector()
	bullet.Spread = Vector(cone, cone, 0)
	bullet.Tracer = 0
	bullet.TracerName = self.Tracer or "Tracer"
	bullet.Force = 10
	bullet.Damage = 0
	bullet.Callback = RedactDeagleCallback

	self:GetOwner():FireBullets(bullet)
	self.BaseClass.ShootBullet(self, dmg, recoil, numbul, cone)
end

function SWEP:OnRemove()
	if CLIENT then
		STATUS:RemoveStatus("ttt2_redact_deagle_refilling")
	end
end
