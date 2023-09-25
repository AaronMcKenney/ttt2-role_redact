--ConVar syncing
CreateConVar("ttt2_redact_weight_innocent", "65", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_weight_traitor", "20", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_weight_redacted", "5", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_weight_other", "10", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_can_commune", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_mode", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_deagle_enable", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_deagle_starting_ammo", "3", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_deagle_capacity", "9", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_deagle_refill_time", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicRedactedCVars", function(tbl)
	tbl[ROLE_REDACTED] = tbl[ROLE_REDACTED] or {}

	--# What is the weight of the possibiilty for the Redacted to be forced onto the Innocent Team immediately after spawning?
	--  ttt2_redact_weight_innocent [0..n] (default: 65)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_weight_innocent",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_redact_weight_innocent (Def: 65)"
	})

	--# What is the weight of the possibiilty for the Redacted to be forced onto the Traitor Team immediately after spawning?
	--  ttt2_redact_weight_traitor [0..n] (default: 20)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_weight_traitor",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_redact_weight_traitor (Def: 20)"
	})

	--# What is the weight of the possibiilty for the Redacted to be forced onto the Redacted Team immediately after spawning?
	--  ttt2_redact_weight_redacted [0..n] (default: 5)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_weight_redacted",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_redact_weight_redacted (Def: 5)"
	})

	--# What is the weight of the possibiilty for the Redacted to be forced onto an evil team currently in play immediately after spawning?
	--  Example: If the teams present at the beginning of the round are: Innocent, Traitor, and Infected, then the Redacted will be given the Infected role here.
	--  Note: If there are no other teams present, then the Redacted will instead be put onto the Redacted Team.
	--  ttt2_redact_weight_other [0..n] (default: 10)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_weight_other",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_redact_weight_other (Def: 10)"
	})

	--# Can the Redacted commune with others through text or voice chat?
	--  Even if this is set, the Redacted still won't be able to communicate in team voice/chat (ex. they can't talk to their fellow traitors)
	--  ttt2_redact_can_commune [0/1] (default: 1)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_can_commune",
		checkbox = true,
		desc = "ttt2_redact_can_commune (Def: 1)"
	})

	--# What does it mean for an entity to be "redacted"?
	--  ttt2_redact_mode [0..2] (default: 0)
	--  # 0: Smart 2D - 2D black rectangle with depth. Always "in front" of the entity.
	--  # 1: 3D - 3D black box. Technically the simplest.
	--  # 2: Dumb 2D - 2D black rectangle without depth. Visible through walls. Mostly used for debugging.
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_mode",
		combobox = true,
		desc = "ttt2_redact_mode (Def: 0)",
		choices = {
			"0 - Smart 2D",
			"1 - 3D",
			"2 - Dumb 2D"
		},
		numStart = 0
	})

	--# Does the Redacted spawn with a Redact Deagle?
	--  ttt2_redact_deagle_enable [0/1] (default: 1)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_deagle_enable",
		checkbox = true,
		desc = "ttt2_redact_deagle_enable (Def: 1)"
	})

	--# How much ammo does the Redact Deagle start with?
	--  ttt2_redact_deagle_starting_ammo [0..n] (default: 3)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_deagle_starting_ammo",
		slider = true,
		min = 0,
		max = 12,
		decimal = 0,
		desc = "ttt2_redact_deagle_starting_ammo (Def: 3)"
	})

	--# How much ammo is the Redact Deagle capable of holding?
	--  ttt2_redact_deagle_capacity [0..n] (default: 9)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_deagle_capacity",
		slider = true,
		min = 1,
		max = 12,
		decimal = 0,
		desc = "ttt2_redact_deagle_capacity (Def: 9)"
	})

	--# How many seconds until the Redact Deagle refills one bullet (0 to prevent refilling)?
	--  ttt2_redact_deagle_refill_time [0..n] (default: 30)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_deagle_refill_time",
		slider = true,
		min = 0,
		max = 120,
		decimal = 0,
		desc = "ttt2_redact_deagle_refill_time (Def: 30)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddRedactedGlobals", function()
	SetGlobalInt("ttt2_redact_weight_innocent", GetConVar("ttt2_redact_weight_innocent"):GetInt())
	SetGlobalInt("ttt2_redact_weight_traitor", GetConVar("ttt2_redact_weight_traitor"):GetInt())
	SetGlobalInt("ttt2_redact_weight_redacted", GetConVar("ttt2_redact_weight_redacted"):GetInt())
	SetGlobalInt("ttt2_redact_weight_other", GetConVar("ttt2_redact_weight_other"):GetInt())
	SetGlobalBool("ttt2_redact_can_commune", GetConVar("ttt2_redact_can_commune"):GetBool())
	SetGlobalInt("ttt2_redact_mode", GetConVar("ttt2_redact_mode"):GetInt())
	SetGlobalBool("ttt2_redact_deagle_enable", GetConVar("ttt2_redact_deagle_enable"):GetBool())
	SetGlobalInt("ttt2_redact_deagle_starting_ammo", GetConVar("ttt2_redact_deagle_starting_ammo"):GetInt())
	SetGlobalInt("ttt2_redact_deagle_capacity", GetConVar("ttt2_redact_deagle_capacity"):GetInt())
	SetGlobalInt("ttt2_redact_deagle_refill_time", GetConVar("ttt2_redact_deagle_refill_time"):GetInt())
end)

cvars.AddChangeCallback("ttt2_redact_weight_innocent", function(name, old, new)
	SetGlobalInt("ttt2_redact_weight_innocent", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_redact_weight_traitor", function(name, old, new)
	SetGlobalInt("ttt2_redact_weight_traitor", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_redact_weight_redacted", function(name, old, new)
	SetGlobalInt("ttt2_redact_weight_redacted", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_redact_weight_other", function(name, old, new)
	SetGlobalInt("ttt2_redact_weight_other", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_redact_can_commune", function(name, old, new)
	SetGlobalBool("ttt2_redact_can_commune", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_redact_mode", function(name, old, new)
	SetGlobalInt("ttt2_redact_mode", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_redact_deagle_enable", function(name, old, new)
	SetGlobalBool("ttt2_redact_deagle_enable", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_redact_deagle_starting_ammo", function(name, old, new)
	SetGlobalInt("ttt2_redact_deagle_starting_ammo", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_redact_deagle_capacity", function(name, old, new)
	SetGlobalInt("ttt2_redact_deagle_capacity", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_redact_deagle_refill_time", function(name, old, new)
	SetGlobalInt("ttt2_redact_deagle_refill_time", tonumber(new))
end)
