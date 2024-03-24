Hooks:Add("LocalizationManagerPostInit", "Quickplay_Enhanced_loc", function(...)
	LocalizationManager:add_localized_strings({
		menu_blacklisted_mods = "Mods Blacklist",
		menu_hide_blacklisted = "Hide lobbies with blacklisted mods",
		menu_remove_from_blacklist_text = "Do you wish to remove the mod from the blacklist?",
		menu_clean_blacklist_title = "Clean mods blacklist",
		menu_clean_blacklist_text = "Do you wish to clean all mods from the blacklist?",
		menu_quickplay_instant = "Fast join",
		menu_quickplay_mouse_left = "Add mod to blacklist",
		menu_quickplay_mouse_middle = "Steam Profile",
		menu_quickplay_mouse_right = "Ban player",
		menu_quickplay_server_state = "Server State",
		menu_quickplay_hide_banned = "Hide banned players",
		menu_quickplay_host_level = "Host level (Greater or Equal)",
		menu_cs_rank = "Rank: ",
		menu_equal = "Equal",
		menu_equalto_or_greater_than = "Greater or Equal",
		menu_equalto_less_than = "Less or Equal",
		menu_quickplay_search_type = "Search Type",
		menu_quickplay_main_menu_visible = "Hide Quickplay button in main menu (restart needed)",
	})

	if Idstring("russian"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			menu_blacklisted_mods = "Черный список модификаций",
			menu_hide_blacklisted = "Скрыть лобби c модиф. из черного списка",
			menu_remove_from_blacklist_text = "Вы уверены, что хотите убрать мод из черного списка?",
			menu_clean_blacklist_title = "Очистить черный список",
			menu_clean_blacklist_text = "Вы уверены, что хотите очистить черный список от модификаций?",
			menu_quickplay_instant = "Быстрое присоединение",
			menu_quickplay_mouse_left = "Добавить мод. в черный список",
			menu_quickplay_mouse_middle = "Профиль Steam",
			menu_quickplay_mouse_right = "Забанить игрока",
			menu_quickplay_server_state = "Статус сервера",
			menu_quickplay_hide_banned = "Скрыть забаненых игроков",
			menu_quickplay_host_level = "Уровень лидера лобби (Больше или равно)",
			menu_cs_rank = "Ранг: ",
			menu_equal = "Равно",
			menu_equalto_or_greater_than = "Больше или равно",
			menu_equalto_less_than = "Меньше или равно",
			menu_quickplay_search_type = "Тип поиска",
			menu_quickplay_main_menu_visible = "Скрыть кнопку Быстрой игры в меню (необходим перезапуск игры)",
		})
	end

	if Idstring("schinese"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			menu_blacklisted_mods = "模组黑名单",
			menu_hide_blacklisted = "隐藏安装了黑名单中的模组的大厅",
			menu_remove_from_blacklist_text = "你确定将此模组移出黑名单吗？",
			menu_clean_blacklist_title = "清空模组黑名单",
			menu_clean_blacklist_text = "你确定要清空模组黑名单吗？",
			menu_quickplay_instant = "快速加入",
			menu_quickplay_mouse_left = "将模组加入黑名单",
			menu_quickplay_mouse_middle = "Steam个人资料",
			menu_quickplay_mouse_right = "封禁玩家",
			menu_quickplay_server_state = "服务器状态",
			menu_quickplay_hide_banned = "隐藏被拉入黑名单的玩家",
			menu_quickplay_host_level = "主机等级 (不小于)",
			menu_cs_rank = "等级： ",
			menu_equal = "等于",
			menu_equalto_or_greater_than = "不小于",
			menu_equalto_less_than = "不大于",
			menu_quickplay_search_type = "搜索类型",
		})
	end
end)

local function unacceptable_mods_found(modded)
	local function precise(text)
		return text:gsub("%p", "").."  "
	end
	
	if modded then
		local mods = string.upper(modded):gsub("|", "  ")
		local mods_blacklist = Global.crimenet.mods_blacklist or {}
		for _, blacklisted_mod in pairs(mods_blacklist) do
			if string.find(precise(mods), precise(string.upper(blacklisted_mod))) then
				return true
			elseif string.find(precise(mods), precise(string.upper(blacklisted_mod))) then
				return false
			end
		end
	end
end

local function lobby_info(data)
	local room_list = data and data.room_list
	for i, room in ipairs(room_list) do
		if data and data.room_id == room.room_id or tostring(data.owner_name) == tostring(room.owner_name) then
			return i
		end
	end
end

local function search_quick_lobbies()
	local self = managers.network.matchmake
	local quick = Global.crimenet and Global.crimenet.quickplay
	
	if not self:_has_callback("search_quick_lobbies") then
		return
	end

	local function validated_value(lobby, key)
		local value = lobby:key_value(key)

		if value ~= "value_missing" and value ~= "value_pending" then
			return value
		end

		return nil
	end

	local function refresh_lobby()
		if not LobbyBrowser then
			return
		end

		local lobbies = LobbyBrowser:lobbies()
		local info = {
			room_list = {},
			attribute_list = {}
		}

		if lobbies then
			for _, lobby in ipairs(lobbies) do
			
				local skip_level = false

				local function skip_lobby(forbidden)
					if not skip_level and forbidden then
						skip_level = true
					end
				end
			
				local blacklisted_mods = quick.blacklisted_mods or "on"
				local hide_banned = quick.hide_banned or "off"
				skip_lobby(blacklisted_mods == "on" and unacceptable_mods_found(validated_value(lobby, "mods")))
				skip_lobby(blacklisted_mods == "on" and managers.ban_list:banned(lobby:key_value("owner_id")))
				skip_lobby(string.find(tostring(lobby:key_value("owner_name")), "P3DHack"))

				if not skip_level then
					table.insert(info.room_list, {
						owner_id = lobby:key_value("owner_id"),
						owner_name = lobby:key_value("owner_name"),
						room_id = lobby:id(),
						owner_level = lobby:key_value("owner_level")
					})

					local attributes_data = {
						numbers = self:_lobby_to_numbers(lobby),
						mutators = self:_get_mutators_from_lobby(lobby),
						crime_spree = tonumber(validated_value(lobby, "crime_spree")),
						crime_spree_mission = validated_value(lobby, "crime_spree_mission"),
						mods = validated_value(lobby, "mods"),
						one_down = tonumber(validated_value(lobby, "one_down")),
						skirmish = tonumber(validated_value(lobby, "skirmish")),
						skirmish_wave = tonumber(validated_value(lobby, "skirmish_wave")),
						skirmish_weekly_modifiers = validated_value(lobby, "skirmish_weekly_modifiers")
					}

					table.insert(info.attribute_list, attributes_data)
				end
			end
		end

		self:_call_callback("search_quick_lobbies", info)
	end

	LobbyBrowser:set_callbacks(refresh_lobby)
	local interest_keys = {
		"owner_id",
		"owner_name",
		"level",
		"difficulty",
		"permission",
		"state",
		"num_players",
		"drop_in",
		"min_level",
		"kick_option",
		"job_class_min",
		"job_class_max",
		"allow_mods",
		"mods"
	}
	
	if self._BUILD_SEARCH_INTEREST_KEY then
		table.insert(interest_keys, self._BUILD_SEARCH_INTEREST_KEY)
	end
	
	LobbyBrowser:set_interest_keys(interest_keys)
	LobbyBrowser:set_lobby_filter(self._BUILD_SEARCH_INTEREST_KEY, "true", "equal")
	LobbyBrowser:set_max_lobby_return_count(50)
	LobbyBrowser:set_distance_filter(quick.distance or 3)
	
	local gamemode = quick.gamemode or "standard"
	if gamemode == "crime_spree" then
		LobbyBrowser:set_lobby_filter("crime_spree", 1, "equalto_or_greater_than")
	elseif gamemode == "skirmish" then
		LobbyBrowser:set_lobby_filter("skirmish", 1, "equalto_or_greater_than")
	else
		LobbyBrowser:set_lobby_filter("crime_spree", -1, "equalto_less_than")
		LobbyBrowser:set_lobby_filter("skirmish", 0, "equalto_less_than")
		
		local job_plan = quick.job_plan or "any"
		LobbyBrowser:set_lobby_filter("job_plan", job_plan == "stealth" and 2 or job_plan == "loud" and 1 or -1, job_plan == "any" and "equalto_or_greater_than" or "equal")
		
		local one_down = quick.one_down or "off"
		LobbyBrowser:set_lobby_filter("one_down", 0, one_down == "off" and "equal" or one_down == "on" and "greater_than" or "equalto_or_greater_than")

		local mutators = quick.mutators or "off"
		LobbyBrowser:set_lobby_filter("mutators", 0, mutators == "off" and "equal" or mutators == "on" and "greater_than" or "equalto_or_greater_than")

		local difficulty = quick.difficulty or 1
		local difficulty_range = quick.difficulty_range or "equal"
		LobbyBrowser:set_lobby_filter("difficulty", difficulty, difficulty == 1 and "equalto_or_greater_than" or difficulty_range)
	end

	local state = quick.state or "any"
	LobbyBrowser:set_lobby_filter("state", 1, state == "in_lobby" and "equal" or state == "in_game" and "greater_than" or "equalto_or_greater_than")
	
	local mods = quick.mods or "any"
	LobbyBrowser:set_lobby_filter("mods", "1", mods == "off" and "equal" or mods == "on" and "greater_than" or "equalto_or_greater_than")
	
	local level_diff_min = quick.level_diff_min or 0
	LobbyBrowser:set_lobby_filter("owner_level", level_diff_min, "equalto_or_greater_than")
	
	if Global.game_settings.playing_lan then
		LobbyBrowser:refresh_lan()
	else
		LobbyBrowser:refresh()
	end
end

local function get_contract(info, owner_name)
	local room_list = info.room_list
	local attribute_list = info.attribute_list
	local i = lobby_info({
		room_list = room_list,
		owner_name = owner_name
	})
	local room = room_list[i]
	local attributes_numbers = attribute_list[i].numbers
	local level_id = tweak_data.levels:get_level_name_from_index(attributes_numbers[1] % 1000)
	local difficulty = tweak_data:index_to_difficulty(attributes_numbers[2])
	local job_id = tweak_data.narrative:get_job_name_from_index(math.floor(attributes_numbers[1] / 1000))
	local job_data = tweak_data.narrative:job_data(job_id)
	local data = {
		difficulty_id = attributes_numbers[2],
		difficulty = difficulty,
		one_down = attribute_list[i].one_down,
		job_id = job_id,
		level_id = level_id,
		id = room.room_id,
		room_id = room.room_id,
		server = true,
		num_plrs = attributes_numbers[5],
		state = attributes_numbers[4],
		host_name = tostring(room.owner_name),
		host_id = room.owner_id,
		contract_visuals = job_data and job_data.contract_visuals,
		info = room.info,
		mutators = attribute_list[i].mutators,
		is_crime_spree = attribute_list[i].crime_spree and attribute_list[i].crime_spree >= 0,
		crime_spree = attribute_list[i].crime_spree,
		crime_spree_mission = attribute_list[i].crime_spree_mission,
		server_data = {
			job_plan = attributes_numbers[10],
			kick_option = attributes_numbers[8],
			permission = attributes_numbers[3],
			min_level = attributes_numbers[7],
			drop_in = attributes_numbers[6]
		},
		mods = attribute_list[i].mods,
		is_skirmish = attribute_list[i].skirmish and attribute_list[i].skirmish > 0,
		skirmish = attribute_list[i].skirmish,
		skirmish_wave = attribute_list[i].skirmish_wave,
		skirmish_weekly_modifiers = attribute_list[i].skirmish_weekly_modifiers
	}
	
	local node = "quickplay_contract_join"
	if data.is_crime_spree then
		node = "crimenet_contract_crime_spree_join"
	elseif data.is_skirmish then
		node = "skirmish_contract_join"
	end

	managers.menu_component:post_event("menu_enter")
	managers.menu:open_node(node, {data})
end

MenuCallbackHandler.accept_quickplay_contract = function(self, item, node)
	local job_data = item:parameters().gui_node.node:parameters().menu_component_data

	if job_data.server then
		managers.crime_spree:join_server(job_data)
		managers.network.matchmake:join_server_with_check(job_data.room_id, false, job_data)
	elseif Global.game_settings.single_player then
		MenuCallbackHandler:start_single_player_job(job_data)
	else
		MenuCallbackHandler:start_job(job_data)
	end
end

MenuCallbackHandler.start_quickplay_game = function(self)
	local function f(info)
		managers.network.matchmake:search_lobby_done()
		
		local quick = Global.crimenet and Global.crimenet.quickplay
		local room_list = info.room_list
		local attribute_list = info.attribute_list
		
		local game_list = {}
		for i, room in ipairs(room_list) do
			game_list[room.room_id] = tostring(room.owner_name)
		end
		
		if not quick.previous_games then
			quick.previous_games = {}
		end
		
		managers.crimenet._previous_quick_play_games = quick.previous_games
		local selected_game = nil

		for room_id, _ in pairs(game_list) do
			if not table.contains(managers.crimenet._previous_quick_play_games, room_id) then
				selected_game = room_id

				table.insert(managers.crimenet._previous_quick_play_games, room_id)

				break
			end
		end

		if not selected_game then
			for _, room_id in ipairs(managers.crimenet._previous_quick_play_games) do
				if game_list[room_id] then
					selected_game = room_id

					table.insert(managers.crimenet._previous_quick_play_games, table.remove(managers.crimenet._previous_quick_play_games, 1))

					break
				else
					managers.crimenet._previous_quick_play_games[room_id] = nil
				end
			end
		end
		
		if table.empty(game_list) then
			local dialog_data = {
				title = managers.localization:text("menu_cn_quickplay_not_found_title"),
				text = managers.localization:text("menu_cn_quickplay_not_found_body")
			}
			local ok_button = {
				text = managers.localization:text("dialog_ok")
			}
			dialog_data.button_list = {
				ok_button
			}

			managers.system_menu:show(dialog_data)
		elseif quick.servers == "players_list" then
			local function get_server_info(i)
				local function text(id)
					return managers.localization:to_upper_text(id)
				end
				
				local diffs = {
					"menu_difficulty_normal",
					"menu_difficulty_hard",
					"menu_difficulty_very_hard",
					"menu_difficulty_overkill",
					"menu_difficulty_easy_wish",
					"menu_difficulty_apocalypse",
					"menu_difficulty_sm_wish"
				}
				local tactics = {
					"menu_plan_loud",
					"menu_plan_stealth",
					[-1.0] = "menu_any"
				}

				local mods = {}
				local mods_presence = attribute_list[i].mods
				if mods_presence and mods_presence ~= "1" then
					local splits = string.split(mods_presence, "|")
					for i = 1, #splits, 2 do
						table.insert(mods, splits[i])
					end
					
					table.delete(mods, "SuperBLT")
					table.delete(mods, "BeardLib")
				end

				local server_info = ""
				local function create_info(param)
					local set_info_stat = param[2] or ""
					local set_divider = param[4] or ":  "
					local set_info = param[3] and " " or param[1] .. set_divider .. set_info_stat .. "\n"
					server_info = server_info .. set_info
				end
				
				local attributes_numbers = attribute_list[i].numbers
				local job_id = tweak_data.narrative:get_job_name_from_index(math.floor(attributes_numbers[1] / 1000))
				local level_id = tweak_data.levels:get_level_name_from_index(attributes_numbers[1] % 1000)
				local narrative = tweak_data.narrative:job_data(job_id or "chill")
				local job_name = text(narrative and narrative.name_id)
				local level_name = text(tweak_data.levels[level_id or "chill"].name_id)
				
				local is_crime_spree = attribute_list[i].crime_spree and attribute_list[i].crime_spree >= 0
				local is_skirmish = attribute_list[i].skirmish and attribute_list[i].skirmish > 0
				local is_standard = not is_crime_spree and not is_skirmish

				local contract = not is_standard and text("menu_gamemode") or text("cn_menu_contract_header")
				local contract_name = job_name ~= level_name and #tweak_data.narrative:job_chain(job_id) > 1 and job_name.." ("..level_name..")" or job_name
				local current_job = is_crime_spree and text("menu_gamemode_spree") or is_skirmish and text("menu_skirmish") or contract_name
				local job_divider = not is_standard and ":  " or "  "
				create_info({contract, current_job, [4] = job_divider})

				local diff_text = text(diffs[attributes_numbers[2] - 1])
				local one_down_text = " ("..text("menu_toggle_one_down")..")"
				local difficulty = attribute_list[i].one_down == 1 and diff_text..one_down_text or diff_text
				local risk_title = is_crime_spree and "menu_cs_rank" or is_skirmish and "cn_menu_skirmish_contract_waves_header" or "menu_lobby_difficulty_title"
				local risk = is_crime_spree and "" .. attribute_list[i].crime_spree or is_skirmish and string.rep("", attribute_list[i].skirmish_wave or 0)..string.rep("", 9 - attribute_list[i].skirmish_wave or 9) or difficulty
				create_info({text(risk_title), risk, [4] = " "})
				
				local state_string_id = tweak_data:index_to_server_state(attributes_numbers[4])
				create_info({text("menu_quickplay_server_state"), state_string_id and text("menu_lobby_server_state_" .. state_string_id) or "UNKNOWN"})

				local players = string.rep("", attributes_numbers[5] or 1)..string.rep("", 4 - attributes_numbers[5] or 3)
				create_info({managers.localization:to_upper_text("menu_players_online", {COUNT = players}), [4] = ""})

				create_info({text("menu_preferred_plan"), text(tactics[attributes_numbers[10]])})
				
				create_info({text("menu_mods"), table.size(mods), table.empty(mods)})
				
				local mutators = attribute_list[i].mutators
				create_info({text("menu_cn_mutators_active"), mutators and table.size(mutators) or "", not attribute_list[i].mutators})
				
				return server_info
			end
			
			local dialog_data = {
				title = "",
				text = "",
				id = "server_list_dialog",
				font_size = 19
			}

			dialog_data.button_list = {}
			
			for id, name in pairs(game_list) do
				table.insert(dialog_data.button_list, {
					text = name,
					callback_func = function()
						if quick.instant_join == "on" then
							managers.network.matchmake:join_server(id, true, true)
						else
							get_contract(info, name)
						end
					end,
					focus_callback_func = function()
						local dlg = managers.system_menu:get_dialog(dialog_data.id)
						if dlg then
							local i = lobby_info({
								room_list = room_list,
								owner_name = name
							})
							dlg:set_text(get_server_info(i))
							dlg:set_title(name)
						end
					end
				})
			end

			if not dialog_data.button_list[1] then
				dialog_data.title = ""
				dialog_data.text = ""
			else
				local i = lobby_info({
					room_list = room_list,
					owner_name = dialog_data.button_list[1].text
				})
				
				dialog_data.text = get_server_info(i)
				dialog_data.title = tostring(room_list[i].owner_name)
				table.insert(dialog_data.button_list, {})
			end
			
			local cancel = {
				text = managers.localization:text("dialog_cancel"),
				cancel_button = true
			}

			table.insert(dialog_data.button_list, cancel)
			managers.system_menu:show_buttons(dialog_data)
		else
			if selected_game then
				if quick.instant_join == "on" then
					managers.network.matchmake:join_server(selected_game, true, true)
				else
					get_contract(info, game_list[selected_game])
				end
			end
		end
	end
	
	managers.network.matchmake:register_callback("search_quick_lobbies", f)
	search_quick_lobbies()
end

MenuCallbackHandler.check_blacklisted_mods = function(self)
	local mods_blacklist = Global.crimenet.mods_blacklist
	local dialog_data = {
		title = managers.localization:text("menu_blacklisted_mods"),
		text = "",
		id = "server_list_dialog",
		font_size = 19
	}

	dialog_data.button_list = {}
	
	if mods_blacklist then
		for id, name in pairs(mods_blacklist) do
			table.insert(dialog_data.button_list, {
				text = name,
				callback_func = function()
					local dialog_data = {
						title = managers.localization:text("menu_blacklisted_mods"),
						text = managers.localization:text("menu_remove_from_blacklist_text")
					}
					local yes = {
						text = managers.localization:text("dialog_yes"),
						callback_func = function()
							table.delete(mods_blacklist, name)
						end
					}
					local no = {
						text = managers.localization:text("dialog_no"),
						cancel_button = true
					}
					dialog_data.button_list = {
						yes,
						no
					}

					managers.system_menu:show(dialog_data)
				end
			})
		end

		if dialog_data.button_list[1] then
			table.insert(dialog_data.button_list, {})
			table.insert(dialog_data.button_list, {
				text = managers.localization:text("menu_clean_blacklist_title"),
				callback_func = function()
					local dialog_data = {
						title = managers.localization:text("menu_clean_blacklist_title"),
						text = managers.localization:text("menu_clean_blacklist_text")
					}
					local yes = {
						text = managers.localization:text("dialog_yes"),
						callback_func = function()
							Global.crimenet.mods_blacklist = {}
						end
					}
					local no = {
						text = managers.localization:text("dialog_no"),
						cancel_button = true
					}
					dialog_data.button_list = {
						yes,
						no
					}

					managers.system_menu:show(dialog_data)
				end
			})
		end
	end
	
	local cancel = {
		text = managers.localization:text("dialog_cancel"),
		cancel_button = true
	}

	table.insert(dialog_data.button_list, cancel)
	managers.system_menu:show_buttons(dialog_data)
end

local function add_call(option)
	MenuCallbackHandler["quickplay_toggle_"..option] = function(self, item)
		local quick = Global.crimenet and Global.crimenet.quickplay
		quick[option] = item:value()
	end
end

add_call("gamemode")
add_call("servers")
add_call("distance")
add_call("state")
add_call("hide_banned")
add_call("instant_join")
add_call("job_plan")
add_call("mods")
add_call("one_down")
add_call("mutators")
add_call("difficulty")
add_call("difficulty_range")
add_call("blacklisted_mods")
add_call("main_menu_visible")