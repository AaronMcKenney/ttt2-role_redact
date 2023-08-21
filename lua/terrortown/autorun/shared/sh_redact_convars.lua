--ConVar syncing
CreateConVar("ttt2_redact_weight_innocent", "65", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_weight_traitor", "20", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_weight_redacted", "5", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_weight_other", "10", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_redact_can_commune", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

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
	--  ttt2_redact_can_commune [0/1] (default: 0)
	table.insert(tbl[ROLE_REDACTED], {
		cvar = "ttt2_redact_can_commune",
		checkbox = true,
		desc = "ttt2_redact_can_commune (Def: 0)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddRedactedGlobals", function()
	SetGlobalInt("ttt2_redact_weight_innocent", GetConVar("ttt2_redact_weight_innocent"):GetInt())
	SetGlobalInt("ttt2_redact_weight_traitor", GetConVar("ttt2_redact_weight_traitor"):GetInt())
	SetGlobalInt("ttt2_redact_weight_redacted", GetConVar("ttt2_redact_weight_redacted"):GetInt())
	SetGlobalInt("ttt2_redact_weight_other", GetConVar("ttt2_redact_weight_other"):GetInt())
	SetGlobalBool("ttt2_redact_can_commune", GetConVar("ttt2_redact_can_commune"):GetBool())
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
