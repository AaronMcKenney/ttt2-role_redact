local L = LANG.GetLanguageTableReference("en")

--GENERAL ROLE LANGUAGE STRINGS
L[REDACTED.name] = "Redacted"
L["info_popup_" .. REDACTED.name] = "[REDACTED]"
L["body_found_" .. REDACTED.abbr] = "They were [REDACTED]"
L["search_role_" .. REDACTED.abbr] = "This person was a [REDACTED]"
L["target_" .. REDACTED.name] = "[REDACTED]"
L["ttt2_desc_" .. REDACTED.name] = "[REDACTED]"

--REDACTED TEAM
L[TEAM_REDACTED] = "[REDACTED]"
L["hilite_win_" .. TEAM_REDACTED] = "[REDACTED]"
L["win_" .. TEAM_REDACTED] = "[REDACTED]"
L["ev_win_" .. TEAM_REDACTED] = "[REDACTED]"
L[TEAM_REDACTED_SETUP] = "[REDACTED]"
L["hilite_win_" .. TEAM_REDACTED_SETUP] = "[REDACTED]"
L["win_" .. TEAM_REDACTED_SETUP] = "[REDACTED]"
L["ev_win_" .. TEAM_REDACTED_SETUP] = "[REDACTED]"

--OTHER ROLE LANGUAGE STRINGS
--BMF--L["redacted_" .. REDACTED.name] = "[REDACTED]"
L["voice_prevented_" .. REDACTED.name] = "[REDACTED] can't speak!"

--REDACT DEAGLE
L["DEAGLE_NAME_" .. REDACTED.name] = "Redact Deagle"
L["DEAGLE_DESC_" .. REDACTED.name] = "Redact an entity or a part of the world."

--EVENT STRINGS

--CONVAR STRINGS
L["label_redact_weight_innocent"] = "Prob. of joining Innocents"
L["label_redact_weight_traitor"] = "Prob. of joining Traitors"
L["label_redact_weight_redacted"] = "Prob. of being on own team"
L["label_redact_weight_other"] = "Prob. of joining a different evil team"
L["label_redact_can_commune"] = "Redacted can use text/voice chat"
L["label_redact_mode"] = "Redacted Mode"
L["label_redact_mode_0"] = "0: Smart 2D - Rectangle with depth"
L["label_redact_mode_1"] = "1: 3D - Black box"
L["label_redact_mode_2"] = "2: Dumb 2D - Rectangle without depth"
L["label_redact_error"] = "ERROR"
L["label_redact_deagle_enable"] = "Redacted spawns with Redact Deagle"
L["label_redact_deagle_starting_ammo"] = "Redact Deagle starting ammo"
L["label_redact_deagle_capacity"] = "Redact Deagle magazine"
L["label_redact_deagle_refill_time"] = "Redact Deagle refill time"
L["label_redact_duration"] = "Duration of redaction for players"
L["label_redact_speed_multi"] = "Speed mult. for Redacted Status"
