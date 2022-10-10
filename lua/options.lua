function MenuQuickplaySettingsInitiator:modify_node(node)
	local quick = Global.crimenet and Global.crimenet.quickplay
	local function add_call(option, value)
		local default = value or "any"
		node:item("quickplay_"..option):set_value(quick and quick[option] or default)
	end
	
	node:item("quickplay_settings_level_min"):set_max(100)
	node:item("quickplay_settings_level_min"):set_value(quick and quick.level_diff_min or 0)
	
	add_call("gamemode", "standard")
	add_call("servers", "random")
	add_call("distance", 3)
	add_call("state")
	add_call("hide_banned", "off")
	add_call("instant_join", "off")
	
	add_call("job_plan")
	add_call("mods")
	add_call("one_down", "off")
	add_call("mutators", "off")
	add_call("difficulty", 1)
	add_call("difficulty_range", "equal")
	add_call("blacklisted_mods")

	return node
end