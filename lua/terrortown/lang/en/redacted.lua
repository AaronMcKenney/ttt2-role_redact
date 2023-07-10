local L = LANG.GetLanguageTableReference("en")

--GENERAL ROLE LANGUAGE STRINGS
L[REDACTED.name] = "Redacted"
L["info_popup_" .. REDACTED.name] = "[REDACTED]"
L["body_found_" .. REDACTED.abbr] = "[REDACTED]"
L["search_role_" .. REDACTED.abbr] = "[REDACTED]"
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

-- OTHER ROLE LANGUAGE STRINGS
--L["redacted_" .. REDACTED.name] = "[REDACTED]"
L["voice_prevented_" .. REDACTED.name] = "The Redacted can't speak!"

--EVENT STRINGS
-- Need to be very specifically worded, due to how the system translates them.
--L["title_event_anon_force"] = "An Innocent player was forced to be Anonymous"
--L["desc_event_anon_force"] = "Innocent player {name} was forced to be Anonymous."
--L["title_event_anon_inform"] = "An anonymous player made a friend :)"
--L["desc_event_anon_inform"] = "Anonymous player {name1} knew that {name2} was also Anonymous."
