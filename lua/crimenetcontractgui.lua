local function find_accurate(v, e)
	local table_to_string = string.upper(table.concat(v, "  "))
	local function precise(text)
		return text:gsub("%p", "").."  "
	end
	if string.match(precise(table_to_string), precise(e)) == precise(e) then
		return true
	elseif string.match(precise(table_to_string), precise(e)) ~= precise(e) then
		return false
	end
end

local data = CrimeNetContractGui.init
function CrimeNetContractGui:init(ws, fullscreen_ws, node)
	data(self, ws, fullscreen_ws, node)
	if node:parameters().name == "quickplay_contract_join" then
		local _, _, w, _ = self._contact_text_header:text_rect()
		while w > 500 do
			self._contact_text_header:set_font_size(self._contact_text_header:font_size() * 0.99)
			_, _, w, _ = self._contact_text_header:text_rect()
		end
		
		self._legends_panel = self._panel:panel({
			name = "legends_panel",
			w = self._panel:w() * 0.45,
			layer = 50,
			h = tweak_data.menu.pd2_medium_font_size
		})
		self._legends = {}
		self._legends_panel:set_righttop(self._panel:w(), 0)

		local function create_legend(button, texture_rect)
			local panel = self._legends_panel:panel({
				name = "select"
			})
			local icon = panel:bitmap({
				texture = "guis/textures/pd2/mouse_buttons",
				name = "icon",
				h = 23,
				blend_mode = "add",
				w = 17,
				texture_rect = texture_rect
			})
			local text = panel:text({
				blend_mode = "add",
				aligh = "center",
				text = managers.localization:to_upper_text("menu_quickplay_mouse_"..button),
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = tweak_data.screen_colors.text
			})
			
			local _, _, w, _ = text:text_rect()
			while w > (self._legends_panel:w() / 3) - 25 do
				text:set_font_size(text:font_size() * 0.99)
				_, _, w, _ = text:text_rect()
			end
			
			self:make_fine_text(text)
			text:set_left(icon:right() + 2)
			text:set_center_y(icon:center_y())
			panel:set_w(text:right())
			self._legends[button] = panel
		end
		
		create_legend("left", {1, 1, 17, 23})
		create_legend("middle", {35, 1, 17, 23})
		create_legend("right", {18, 1, 17, 23})
		
		local x = self._legends_panel:w()
		local padding = 10
	
		self._legends.right:set_right(x)
		x = self._legends.right:left() - padding or x
		
		self._legends.middle:set_right(x)
		x = self._legends.middle:left() - padding or x
		
		self._legends.left:set_right(x)
		x = self._legends.left:left() - padding or x
		
		local mods_presence = node:parameters().menu_component_data.mods
		self._legends.left:set_visible(mods_presence and mods_presence ~= "" and mods_presence ~= "1")
	end
end

local data = CrimeNetContractGui.mouse_moved
function CrimeNetContractGui:mouse_moved(o, x, y)
	data(self, o, x, y)
	
	if self._node:parameters().name == "quickplay_contract_join" then
		if self._mod_items and self._mods_tab and self._mods_tab:is_active() then
			for _, item in ipairs(self._mod_items) do	
				local mods_blacklist = Global.crimenet.mods_blacklist or {}
				local mod_name = item[1]:text()
				local name_match = find_accurate(mods_blacklist, mod_name)
				local base = mod_name == "SUPERBLT" or mod_name == "BEARDLIB"
				
				if mod_name then
					if base then
						item[1]:set_color(Color("505050"))
						item[2]:set_color(Color("505050"))
					elseif not name_match then
						item[1]:set_color(Color(0.8, 0.8, 0.8))
						item[2]:set_color(tweak_data.screen_colors.button_stage_2)
					elseif name_match then
						item[1]:set_color(tweak_data.screen_colors.pro_color)
						item[2]:set_color(tweak_data.screen_colors.infamy_color)
					end
				end
			end
		end
	end
end

local data = CrimeNetContractGui.mouse_pressed
function CrimeNetContractGui:mouse_pressed(o, button, x, y)
	if self._node:parameters().name == "quickplay_contract_join" then
	
		if alive(self._briefing_len_panel) and self._briefing_len_panel:visible() and self._step > 2 and self._briefing_len_panel:child("button_text"):inside(x, y) then
			self:toggle_post_event()
		end

		if alive(self._potential_rewards_title) and self._potential_rewards_title:visible() and self._potential_rewards_title:inside(x, y) then
			self:_toggle_potential_rewards()
		end

		if self._active_page and button == Idstring("0") then
			for k, tab_item in pairs(self._tabs) do
				if not tab_item:is_active() and tab_item:inside(x, y) then
					self:set_active_page(tab_item:index())
				end
			end
		end
		
		local mods_blacklist = Global.crimenet.mods_blacklist or {}
		if self._mod_items and self._mods_tab and self._mods_tab:is_active() then
			if button == Idstring("0") then
				for _, item in ipairs(self._mod_items) do
					if item[1]:inside(x, y) then
						local mod_name = item[1]:text()
						local name_match = find_accurate(mods_blacklist, mod_name)
						local base = mod_name == "SUPERBLT" or mod_name == "BEARDLIB"
						if mod_name then
							if not name_match and not base then
								table.insert(mods_blacklist, mod_name)
							elseif name_match then
								table.delete(mods_blacklist, mod_name)
							end
						end

						break
					end
				end
			end
		end

		local job = self._node:parameters().menu_component_data
		if button == Idstring("1") then
			local banned = managers.ban_list:banned(job.host_id)
			local dialog_data = {
				title = managers.localization:text(banned and "dialog_sure_to_unban_title" or "dialog_sure_to_ban_title"),
				text = managers.localization:text(banned and "dialog_sure_to_unban_body" or "dialog_sure_to_kick_ban_body", {
					USER = job.host_name
				})
			}
			local yes_button = {
				text = managers.localization:text("dialog_yes"),
				callback_func = function()
					if managers.ban_list:banned(job.host_id) then
						managers.ban_list:unban(job.host_id)
					else
						managers.ban_list:ban(job.host_id, job.host_name)
					end
				end
			}
			local no_button = {
				text = managers.localization:text("dialog_no"),
				cancel_button = true
			}
			dialog_data.button_list = {
				yes_button,
				no_button
			}

			managers.system_menu:show(dialog_data)
		end
		
		if button == Idstring("2") then
			Steam:overlay_activate("url", "https://steamcommunity.com/profiles/" .. job.host_id)
		end
	else
		data(self, o, button, x, y)
	end
end