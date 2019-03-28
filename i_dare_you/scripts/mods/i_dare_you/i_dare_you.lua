local mod = get_mod("i_dare_you")
--[[
	I dare you!

	Lets you and your friends dare each other with insidious concequences.
--]]

-- ##### ██████╗  █████╗ ████████╗ █████╗  ############################################################################
-- ##### ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗ ############################################################################
-- ##### ██║  ██║███████║   ██║   ███████║ ############################################################################
-- ##### ██║  ██║██╔══██║   ██║   ██╔══██║ ############################################################################
-- ##### ██████╔╝██║  ██║   ██║   ██║  ██║ ############################################################################
-- ##### ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ############################################################################

-- Scale
local UIResolutionScale = UIResolutionScale or function()
	return RESOLUTION_LOOKUP.scale
end

-- Debugging
local debug = mod:get("debug")
--local test_dare = "dont_use_item"

-- Load dares
mod.dares = mod:dofile("scripts/mods/i_dare_you/i_dare_you_dares")

-- Persistent Data
mod:persistent_table("data", {
	-- Peer IDs
	selector_peer_id = nil,
	victim_peer_id = nil,
	-- Dare choices
	dares = {},
	is_selecting = false,
	selection = false,
	-- Selected dare
	selected_dare = nil,
	active_dare = nil,
	-- Settings
	active = nil,
	mode = 1,
	allow_inn = false,
	activate_dare_1 = nil,
	activate_dare_2 = nil,
	activate_dare_3 = nil,
	-- Users
	mod_users = {},
})
mod.data = mod:persistent_table("data")
mod.data.mod_users = {}
if debug then
	mod.data.active_dare = nil
end

-- ##### ██╗███╗   ██╗██████╗ ██╗   ██╗████████╗ ######################################################################
-- ##### ██║████╗  ██║██╔══██╗██║   ██║╚══██╔══╝ ######################################################################
-- ##### ██║██╔██╗ ██║██████╔╝██║   ██║   ██║    ######################################################################
-- ##### ██║██║╚██╗██║██╔═══╝ ██║   ██║   ██║    ######################################################################
-- ##### ██║██║ ╚████║██║     ╚██████╔╝   ██║    ######################################################################
-- ##### ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝    ╚═╝    ######################################################################
--[[
	Input functions used by chat commands and hotkeys
--]]
mod.activate_dare_1 = function(automatic)
	mod:activate_dare(1, automatic)
end
mod.activate_dare_2 = function(automatic)
	mod:activate_dare(2, automatic)
end
mod.activate_dare_3 = function(automatic)
	mod:activate_dare(3, automatic)
end
--[[
	Evaluating input functions
--]]
mod.activate_dare = function(self, id, automatic)
	if self.data.is_selecting or automatic then
		self.data.selected_dare = self.data.dares[id].id
		self.data.is_selecting = false
		local server_peer_id = self:server_peer_id()
		self:network_send("dare_selected_server", server_peer_id, self.data.selected_dare)
	end
end
--[[
	Start server
--]]
mod.start_server = function()
	if mod:is_server() then
		mod.server:start()
	end
end
mod.stop_server = function()
	if mod:is_server() then
		mod.server:stop()
	end
end
--[[
	Chat commands
--]]
mod:command("start_server", "Start I dare You! server.", mod.start_server)
mod:command("stop_server", "Stop I dare You! server.", mod.stop_server)
mod:command("dare1", "Choose dare 1.", mod.activate_dare_1)
mod:command("dare2", "Choose dare 2.", mod.activate_dare_2)
mod:command("dare3", "Choose dare 3.", mod.activate_dare_3)

-- ##### ██████╗ ██████╗  ██████╗  ██████╗ █████╗ ██╗     ██╗     ███████╗ ############################################
-- ##### ██╔══██╗██╔══██╗██╔════╝ ██╔════╝██╔══██╗██║     ██║     ██╔════╝ ############################################
-- ##### ██████╔╝██████╔╝██║█████╗██║     ███████║██║     ██║     ███████╗ ############################################
-- ##### ██╔══██╗██╔═══╝ ██║╚════╝██║     ██╔══██║██║     ██║     ╚════██║ ############################################
-- ##### ██║  ██║██║     ╚██████╗ ╚██████╗██║  ██║███████╗███████╗███████║ ############################################
-- ##### ╚═╝  ╚═╝╚═╝      ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝ ############################################
--[[
	Handshake to see if mod is active
	Clients receive this from server
--]]
mod:network_register("handshake_client", function(sender)
	-- "sender" is server
	mod:network_send("handshake_server", sender, mod.data.active)
end)
--[[
	Handshake reply
	Server receives this from clients
--]]
mod:network_register("handshake_server", function(sender, active)
	if debug then
		if active then mod:echo("Joined user '"..tostring(sender).."' has mod active!")
		else mod:echo("Joined user '"..tostring(sender).."' has mod NOT active!") end
	end
	if active then
		mod.server:add_mod_user(sender)
	end
end)
--[[
	Reset UI
	Everyone receives this from server
--]]
mod:network_register("reset_ui_client", function(sender, state_name)
	state_name = state_name or "idle"
	mod.ui:set_state(state_name)
end)
--[[
	Start dare selection
	Everyone receives this from server
--]]
mod:network_register("start_dare_selection_client", function(sender, selector_peer_id, victim_peer_id, dares)
	if debug then
		mod:echo("Selector:'"..tostring(selector_peer_id).."'")
		mod:echo("Victim:'"..tostring(victim_peer_id).."'")
		local dare_list = ""
		for i, dare in pairs(dares) do
			dare_list = dare_list..dare
			if i < 3 then dare_list = dare_list..", " end
		end
		mod:echo("Dares:'"..dare_list.."'")
	end
	mod.data.selector_peer_id = selector_peer_id
	mod.data.victim_peer_id = victim_peer_id
	local active_dares = {}
	for _, dare in pairs(dares) do
		active_dares[#active_dares+1] = mod:get_dare(dare)
	end
	mod.data.dares = active_dares
	mod.ui:start_selection()
end)
--[[
	Dare was selected by selector
	Server receives this from clients
--]]
mod:network_register("dare_selected_server", function(sender, dare_name)
	local check_dare = mod:get_dare(dare_name)
	if check_dare then
		if debug then
			mod:echo("Dare '"..dare_name.."' valid!")
		end
		mod:network_send("dare_selected_client", "all", mod.data.selector_peer_id, mod.data.victim_peer_id, dare_name)
		mod.server:set_state("countdown")
	else
		if debug then
			mod:echo("Dare '"..dare_name.."' invalid!")
		end
	end
end)
--[[
	Dare was selected
	Clients receive this from server
--]]
mod:network_register("dare_selected_client", function(sender, selector_peer_id, victim_peer_id, dare_name)
	if debug then
		mod:echo("Selector:'"..tostring(selector_peer_id).."'")
		mod:echo("Victim:'"..tostring(victim_peer_id).."'")
		mod:echo("Selected dare:'"..dare_name.."'")
	end
	mod.data.selector_peer_id = selector_peer_id
	mod.data.victim_peer_id = victim_peer_id
	mod.data.is_selecting = false
	mod.data.selection = false
	mod.data.selected_dare = dare_name
	mod.ui:set_state("show_selection")
end)
--[[
	Start dare on client
	Clients receive this from server
--]]
mod:network_register("start_dare_client", function(sender, dare_name)
	if mod:is_victim() then
		if debug then
			mod:echo("Dare '"..dare_name.."' started.")
		end
		mod:set_dare(dare_name)
	end
end)
--[[
	Dare finished
	Server receives this from clients
--]]
mod:network_register("dare_finished_server", function(sender, reason)
	if debug then
		mod:echo("Dare finished! Reason:'"..reason.."'")
	end
	mod:network_send("dare_finished_client", "all", reason)
	mod.server:set_state("selection")
end)
--[[
	Dare finished
	Clients receive this from server
--]]
mod:network_register("dare_finished_client", function(sender, reason)
	if debug then
		mod:echo("Dare finished! Reason:'"..reason.."'")
	end
	mod:finish_dare()
end)
--[[
	Abort all dares
	Clients receive this from server
--]]
mod:network_register("abort_all_dares_client", function(sender)
	if mod:is_victim() and mod.data.active_dare then
		mod:abort_dare("server_shutdown")
	end
	mod.data.active_dare = nil
end)
--[[
	Request punishment
	Server receives this from clients
--]]
mod:network_register("request_punishment_server", function(sender, value)
	if debug then
		mod:echo("Player '"..sender.."' requested punishment of '"..tostring(value).."'!")
	end
	local unit = mod:player_unit_from_peer_id(sender)
	DamageUtils.add_damage_network(unit, unit, value, "full", "forced", nil, Vector3(0, 0, 1), "debug")
	--DamageUtils.add_damage_network(target_unit, attacker_unit, damage, "torso", action.damage_type, nil, damage_direction, damage_source, nil, nil, nil, action.hit_react_type)
end)
--[[
	User deactivated mod
--]]
mod:network_register("user_deactivated_mod", function(sender)
	if mod:is_server() then
		mod.server:remove_mod_user(sender)
	end
end)
--[[
	User activates mod
--]]
mod:network_register("user_activated_mod", function(sender)
	if mod:is_server() then
		mod.server:add_mod_user(sender)
	end
end)

-- #####  █████╗  ██████╗████████╗██╗██╗   ██╗███████╗    ██████╗  █████╗ ██████╗ ███████╗ ############################
-- ##### ██╔══██╗██╔════╝╚══██╔══╝██║██║   ██║██╔════╝    ██╔══██╗██╔══██╗██╔══██╗██╔════╝ ############################
-- ##### ███████║██║        ██║   ██║██║   ██║█████╗      ██║  ██║███████║██████╔╝█████╗   ############################
-- ##### ██╔══██║██║        ██║   ██║╚██╗ ██╔╝██╔══╝      ██║  ██║██╔══██║██╔══██╗██╔══╝   ############################
-- ##### ██║  ██║╚██████╗   ██║   ██║ ╚████╔╝ ███████╗    ██████╔╝██║  ██║██║  ██║███████╗ ############################
-- ##### ╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ############################
--[[
	Get dare from table by name
--]]
mod.get_dare = function(self, dare_name)
	for _, dare in pairs(mod.dares) do
		if dare.id == dare_name then
			return dare
		end
	end
	return nil
end
--[[
	Set active dare and start it
--]]
mod.set_dare = function(self, dare_name)
	mod.data.active_dare = mod:get_dare(dare_name)
	mod:start_dare()
end
--[[
	Start active dare
--]]
mod.start_dare = function(self)
	if mod.data.active_dare then
		if mod.data.active_dare.start then mod.data.active_dare:start() end
	end
end
--[[
	Update active dare
--]]
mod.update_dare = function(self, dt)
	if mod.data.active_dare then
		if mod.data.active_dare.update then mod.data.active_dare:update(dt) end
	end
end
--[[
	Abort active dare with a reason
--]]
mod.abort_dare = function(self, reason)
	mod:network_send("dare_finished_server", self:server_peer_id(), reason)
end
--[[
	Finish active dare
--]]
mod.finish_dare = function(self)
	if self.data.active_dare then
		if self.data.active_dare.finish then self.data.active_dare:finish() end
		self.data.active_dare = nil
	end
end

mod.remind_dare = function(self)
	self.ui:remind()
end

mod.add_damage = function(self, value)
	mod:network_send("request_punishment_server", mod:server_peer_id(), value)
end

-- ##### ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗  ############################################################
-- ##### ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗ ############################################################
-- ##### ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝ ############################################################
-- ##### ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗ ############################################################
-- ##### ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║ ############################################################
-- ##### ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝ ############################################################
--[[
	Server mechanics
--]]
mod.server = {
	state = nil,
	timer = 0,
	--mod_users = {},
	--[[
		Start server system
	--]]
	start = function(self)
		mod:network_send("reset_ui_client", "all")
		if mod:has_enough_players() and not mod:is_in_inn() then
			self:set_state("init")
		else
			self:stop()
		end
	end,
	--[[
		Stop server
	--]]
	stop = function(self)
		mod:network_send("reset_ui_client", "all")
		mod:network_send("abort_all_dares_client", "all")
		if not mod:has_enough_players() then
			mod:echo(mod:localize("error_not_enough_players"))
		end
		if mod:is_in_inn() then
			mod:echo(mod:localize("error_in_inn"))
		end
		self:set_state("idle")
	end,
	--[[
		Check if server needs to be stopped
	--]]
	check = function(self)
		if not mod:has_enough_players() then
			self:stop()
		end
	end,
	--[[
		Add mod user
	--]]
	add_mod_user = function(self, peer_id)
		--mod.data.mod_users[#mod.data.mod_users+1] = peer_id
		if not self:get_user_index(peer_id) then
			table.insert(mod.data.mod_users, peer_id)
		end
		if debug then
			mod:dump(mod.data.mod_users, "mod.data.mod_users", 2)
		end
		self:start()
	end,
	--[[
		Get user index
	--]]
	get_user_index = function(self, peer_id)
		for i, user_peer_id in pairs(mod.data.mod_users) do
			if user_peer_id == peer_id then
				return i
			end
		end
		return nil
	end,
	--[[
		Remove mod user
	--]]
	remove_mod_user = function(self, peer_id)
		local index = self:get_user_index(peer_id)
		if index then
			--mod.data.mod_users[peer_id] = nil
			table.remove(mod.data.mod_users, index)
			if debug then
				mod:dump(mod.data.mod_users, "mod.data.mod_users", 2)
			end
			self:check()
		end
	end,
	--[[
		Server states
	--]]
	states = {
		idle = {
			id = 0,
			time = 0,
			start = function(self)
			end,
			finish = function(self)
			end,
		},
		init = {
			id = 1,
			time = 20,
			start = function(self)
			end,
			finish = function(self)
				mod.server:set_state("selection")
			end,
		},
		waiting = {
			id = 2,
			time = 30,
			timer_sent = false,
			start = function(self)
				self.timer_sent = false
			end,
			finish = function(self)
				mod:network_send("dare_finished_client", "all", "time")
				mod.server:set_state("selection")
			end,
		},
		selection = {
			id = 3,
			time = 11,
			start = function(self)
				local selector_peer_id = mod:random_player()
				local victim_peer_id = mod:random_player()
				if mod.data.mode < 3 or #mod.data.mod_users > 1 then
					victim_peer_id = mod:random_player(selector_peer_id)
				end
				if selector_peer_id and victim_peer_id then
					local dares = mod.server:get_random_dares(selector_peer_id, victim_peer_id)
					mod:network_send("start_dare_selection_client", "all", selector_peer_id, victim_peer_id, dares)
				else
					mod.server:stop()
				end
			end,
			finish = function(self)
				mod:echo("automatic selection!")
				local rnd = math.random(1, 3)
				mod["activate_dare_"..tostring(rnd)](true)
				mod.server:set_state("countdown")
			end,
		},
		countdown = {
			id = 4,
			time = 4,
			start = function(self)
			end,
			finish = function(self)
				mod:network_send("start_dare_client", mod.data.victim_peer_id, mod.data.selected_dare)
				mod.server:set_state("waiting")
			end,
		},
	},
	get_available_dares = function(self, selector_peer_id, victim_peer_id)
		local available_dares = {}
		for _, dare in pairs(mod.dares) do
			if not dare.check_condition or dare:check_condition(selector_peer_id, victim_peer_id) then
				available_dares[#available_dares+1] = dare.id
			end
		end
		return available_dares
	end,
	--[[
		Get set of random dares
	--]]
	get_random_dares = function(self, selector_peer_id, victim_peer_id)
		--local available_dares = table.clone(mod.dares)
		local available_dares = self:get_available_dares(selector_peer_id, victim_peer_id)
		local dares = {}
		for i = 1, 3 do
			local rnd = math.random(1, #available_dares)
			--dares[#dares+1] = available_dares[rnd].id --table.clone(available_dares[rnd])
			dares[#dares+1] = available_dares[rnd]
			table.remove(available_dares, rnd)
		end
		--mod:dump(dares, "dares", 1)
		if debug and test_dare then
			local found = false
			for _, dare in pairs(dares) do
				if dare == test_dare then
					found = true
					break
				end
			end
			if found == false then
				local dare = mod:get_dare(test_dare)
				if not dare.check_condition or dare:check_condition(selector_peer_id, victim_peer_id) then
					mod:echo("Added test dare!")
					local rnd = math.random(1, 3)
					dares[rnd] = test_dare
				end
			end
		end
		return dares
	end,
	--[[
		Set server state
	--]]
	set_state = function(self, state_name)
		local state = self.states[state_name]
		if state then
			if debug then mod:echo("State '"..state_name.."' started!") end
			self.state = state
			self.timer = 0
			self.state:start()
		else
			mod:echo("Unknown State '"..state_name.."'!")
		end
	end,
	--[[
		Update server mechanics
	--]]
	update = function(self, dt)
		-- If state is nil return
		if not self.state then
			return
		end
		-- Evaluate state
		if self.state == self.states.idle then
			return
		else
			self.timer = self.timer + dt
			if self.timer >= self.state.time then
				self.state:finish()
			end
		end
	end,
}

-- ##### ██╗   ██╗██╗     ██████╗ ██████╗ ██████╗ ███████╗ ############################################################
-- ##### ██║   ██║██║    ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ############################################################
-- ##### ██║   ██║██║    ██║     ██║   ██║██║  ██║█████╗   ############################################################
-- ##### ██║   ██║██║    ██║     ██║   ██║██║  ██║██╔══╝   ############################################################
-- ##### ╚██████╔╝██║    ╚██████╗╚██████╔╝██████╔╝███████╗ ############################################################
-- #####  ╚═════╝ ╚═╝     ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝ ############################################################
--[[
	UI mechanics
--]]
mod.ui = {
	state = nil,
	timer = 0,
	widgets = {},
	countdown = 0,
	--[[
		UI states
	--]]
	states = {
		idle = {
			render = {},
			name = "idle",
			time = 0,
			start = function(self)
			end,
			finish = function(self)
			end,
		},
		waiting = {
			render = { "dare_1", "dare_2", "dare_3", "victim_name" },
			name = "waiting",
			victim_name = {
				start_offset = {800, -40, 0},
				start_size = 24,
			},
			dare_1 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_2 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_3 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			time = 0,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
			end,
		},
		reminder_grow = {
			render = { "dare_1", "dare_2", "dare_3", "victim_name", "reminder" },
			name = "reminder_grow",
			victim_name = {
				start_offset = {800, -40, 0},
				start_size = 24,
			},
			dare_1 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_2 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_3 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			reminder = {
				start_size = 0,
				finish_size = 120,
				update_size = true,
				start_offset = {0, 0, 0},
				fade_in = true,
				fade_in_time = 0.5,
				text = "reminder",
			},
			time = 0.5,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				mod.ui:set_state("reminder_pop")
			end,
		},
		reminder_pop = {
			render = { "dare_1", "dare_2", "dare_3", "victim_name", "reminder" },
			name = "reminder_pop",
			victim_name = {
				start_offset = {800, -40, 0},
				start_size = 24,
			},
			dare_1 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_2 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_3 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			reminder = {
				start_size = 120,
				finish_size = 80,
				update_size = true,
				start_offset = {0, 0, 0},
			},
			time = 0.5,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				mod.ui:set_state("reminder_fade")
			end,
		},
		reminder_fade = {
			render = { "dare_1", "dare_2", "dare_3", "victim_name", "reminder" },
			name = "reminder_fade",
			victim_name = {
				start_offset = {800, -40, 0},
				start_size = 24,
			},
			dare_1 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_2 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_3 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			reminder = {
				start_size = 80,
				start_offset = {0, 0, 0},
				fade_out = true,
				fade_out_time = 2,
			},
			time = 2,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				mod.ui:set_state("waiting")
			end,
		},
		waiting_fade = {
			render = { "dare_1", "dare_2", "dare_3", "victim_name" },
			name = "waiting_fade",
			victim_name = {
				start_offset = {800, -40, 0},
				start_size = 24,
				fade_out = true,
				fade_out_time = 0.5,
			},
			dare_1 = {
				start_offset = {800, 0, 0},
				start_size = 30,
				fade_out = true,
				fade_out_time = 0.5,
			},
			dare_2 = {
				start_offset = {800, 0, 0},
				start_size = 30,
				fade_out = true,
				fade_out_time = 0.5,
			},
			dare_3 = {
				start_offset = {800, 0, 0},
				start_size = 30,
				fade_out = true,
				fade_out_time = 0.5,
			},
			time = 0.5,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				mod.ui:set_state("selection_grow")
			end,
		},
		selection_grow = {
			render = { "title_incoming_dare", "title_choose_dare" },
			name = "selection_grow",
			title_incoming_dare = {
				start_size = 0,
				finish_size = 120,
				update_size = true,
				start_offset = {0, 0, 0},
				fade_in = true,
				fade_in_time = 0.5,
			},
			title_choose_dare = {
				start_size = 0,
				finish_size = 120,
				update_size = true,
				start_offset = {0, 0, 0},
				fade_in = true,
				fade_in_time = 0.5,
			},
			time = 0.5,
			start = function(self)
				mod.data.selection = true
				mod.ui:init_state()
			end,
			-- update = function(self)
			-- 	mod.ui:update_state()
			-- end,
			finish = function(self)
				mod.ui:set_state("selection_pop")
			end,
		},
		selection_pop = {
			render = { "title_incoming_dare", "title_choose_dare" },
			name = "selection_pop",
			title_incoming_dare = {
				start_size = 120,
				finish_size = 80,
				update_size = true,
				start_offset = {0, 0, 0},
			},
			title_choose_dare = {
				start_size = 120,
				finish_size = 80,
				update_size = true,
				start_offset = {0, 0, 0},
			},
			time = 0.25,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				mod.ui:set_state("selection_move_up")
			end,
		},
		selection_move_up = {
			render = { "title_incoming_dare", "title_choose_dare" },
			name = "selection_move_up",
			title_incoming_dare = {
				start_offset = {0, 0, 0},
				finish_offset = {0, 400, 0},
				update_offset = true,
				start_size = 80,
			},
			title_choose_dare = {
				start_offset = {0, 0, 0},
				finish_offset = {0, 400, 0},
				update_offset = true,
				start_size = 80,
			},
			time = 0.25,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				mod.ui:set_state("waiting_for_input")
			end,
		},
		waiting_for_input = {
			render = { "title_incoming_dare", "title_choose_dare", "victim_name", "dare_1", "dare_2", "dare_3", "counter" },
			name = "waiting_for_input",
			title_incoming_dare = {
				start_offset = {0, 400, 0},
				start_size = 80,
			},
			title_choose_dare = {
				start_offset = {0, 400, 0},
				start_size = 80,
			},
			victim_name = {
				start_offset = {0, 350, 0},
				start_size = 40,
				text = "victim_name",
				fade_in = true,
				fade_in_time = 0.5,
			},
			dare_1 = {
				start_offset = {0, -320, 0},
				start_size = 30,
				text = "dare_1",
				fade_in = true,
				fade_in_time = 0.5,
			},
			dare_2 = {
				start_offset = {0, -360, 0},
				start_size = 30,
				text = "dare_2",
				fade_in = true,
				fade_in_time = 0.5,
			},
			dare_3 = {
				start_offset = {0, -400, 0},
				start_size = 30,
				text = "dare_3",
				fade_in = true,
				fade_in_time = 0.5,
			},
			counter = {
				start_offset = {0, -280, 0},
				start_size = 30,
				text = "time",
				update_text = true,
				fade_in = true,
				fade_in_time = 0.5,
			},
			time = 10,
			start = function(self)
				if mod:is_selector() then
					mod.data.is_selecting = true
				end
				mod.ui:init_state()
			end,
			finish = function(self)
				-- if mod:is_selector() then
				-- 	if mod.data.is_selecting then
				-- 		-- Time's up -> random choice
				-- 		local rnd = math.random(1, 3)
				-- 		mod["activate_dare_"..tostring(rnd)]()
				-- 		--mod.data.is_selecting = false
				-- 	end
				-- end
				-- mod.ui:set_state("show_selection")
			end,
		},
		show_selection = {
			render = { "title_incoming_dare", "title_choose_dare", "victim_name", "dare_1", "dare_2", "dare_3" },
			name = "show_selection",
			title_incoming_dare = {
				start_offset = {0, 400, 0},
				start_size = 80,
				fade_out = true,
				fade_out_time = 0.5,
			},
			title_choose_dare = {
				start_offset = {0, 400, 0},
				start_size = 80,
				fade_out = true,
				fade_out_time = 0.5,
			},
			victim_name = {
				start_offset = {0, 350, 0},
				finish_offset = {0, -40, 0},
				update_offset = true,
				start_size = 40,
				finish_size = 40,
				update_size = true,
			},
			dare_1 = {
				start_offset = {0, -320, 0},
				finish_offset = {0, 0, 0},
				update_offset = true,
				start_size = 30,
				finish_size = 60,
				update_size = true,
				fade_out = true,
				fade_out_time = 0.5,
			},
			dare_2 = {
				start_offset = {0, -360, 0},
				finish_offset = {0, 0, 0},
				update_offset = true,
				start_size = 30,
				finish_size = 60,
				update_size = true,
				fade_out = true,
				fade_out_time = 0.5,
			},
			dare_3 = {
				start_offset = {0, -400, 0},
				finish_offset = {0, 0, 0},
				update_offset = true,
				start_size = 30,
				finish_size = 60,
				update_size = true,
				fade_out = true,
				fade_out_time = 0.5,
			},
			time = 0.5,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				mod.ui:set_state("move_selection")
			end,
		},
		move_selection = {
			render = { "dare_1", "dare_2", "dare_3", "victim_name" },
			name = "move_selection",
			victim_name = {
				start_offset = {0, -40, 0},
				finish_offset = {800, -40, 0},
				update_offset = true,
				start_size = 40,
				finish_size = 24,
				update_size = true,
			},
			dare_1 = {
				start_offset = {0, 0, 0},
				finish_offset = {800, 0, 0},
				update_offset = true,
				start_size = 60,
				finish_size = 30,
				update_size = true,
			},
			dare_2 = {
				start_offset = {0, 0, 0},
				finish_offset = {800, 0, 0},
				update_offset = true,
				start_size = 60,
				finish_size = 30,
				update_size = true,
			},
			dare_3 = {
				start_offset = {0, 0, 0},
				finish_offset = {800, 0, 0},
				update_offset = true,
				start_size = 60,
				finish_size = 30,
				update_size = true,
			},
			time = 0.5,
			start = function(self)
			end,
			finish = function(self)
				--mod.ui:set_state("countdown_1")
				mod.ui:start_countdown(3)
			end,
		},
		countdown_1 = {
			render = { "dare_1", "dare_2", "dare_3", "victim_name", "countdown" },
			name = "countdown_1",
			victim_name = {
				start_offset = {800, -40, 0},
				start_size = 24,
			},
			dare_1 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_2 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_3 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			countdown = {
				start_offset = {0, 0, 0},
				start_size = 0,
				finish_size = 180,
				update_size = true,
				fade_in = true,
				fade_in_time = 0.75,
				text = "countdown",
			},
			time = 0.75,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				mod.ui:set_state("countdown_1_pop")
			end,
		},
		countdown_1_pop = {
			render = { "dare_1", "dare_2", "dare_3", "victim_name", "countdown" },
			name = "countdown_1_pop",
			victim_name = {
				start_offset = {800, -40, 0},
				start_size = 24,
			},
			dare_1 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_2 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			dare_3 = {
				start_offset = {800, 0, 0},
				start_size = 30,
			},
			countdown = {
				start_offset = {0, 0, 0},
				start_size = 180,
				finish_size = 120,
				update_size = true,
				fade_out = true,
				fade_out_time = 0.25,
			},
			time = 0.25,
			start = function(self)
				mod.ui:init_state()
			end,
			finish = function(self)
				if mod.ui.countdown > 0 then
					mod.ui.countdown = mod.ui.countdown - 1
					mod.ui:set_state("countdown_1")
				else
					mod.ui:set_state("waiting")
				end
			end,
		},
	},
	--[[
		Start dare selection
	--]]
	start_selection = function(self)
		self:set_state("waiting_fade")
	end,
	--[[
		Start dare countdown
	--]]
	start_countdown = function(self, count)
		self.countdown = count
		self:set_state("countdown_1")
	end,
	--[[
		Show dare reminder
	--]]
	is_reminding = function(self)
		return self.state.name == "reminder_grow"
			or self.state.name == "reminder_pop"
			or self.state.name == "reminder_fade"
	end,
	remind = function(self)
		if not self:is_reminding() then
			self:set_state("reminder_grow")
		end
	end,
	--[[
		Create widgets for UI
	--]]
	create_widgets = function(self)
		self.widgets = {}
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("title_incoming_dare", "Incoming Dare!", nil, nil, mod.is_not_selector)
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("title_choose_dare", "Choose Dare!", nil, nil, mod.is_selector)
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("reminder", "N/A")
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("countdown", "N/A")
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("victim_name", "N/A", 60, {0, 350, 0})
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("counter", "N/A", 30, {0, -280, 0})
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("dare_1", "N/A", 30, {0, -320, 0}, mod.is_selecting_or_selected)
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("dare_2", "N/A", 30, {0, -360, 0}, mod.is_selecting_or_selected)
		self.widgets[#self.widgets+1] = mod:create_simple_text_widget("dare_3", "N/A", 30, {0, -400, 0}, mod.is_selecting_or_selected)
	end,
	--[[
		Init state with defined start values
	--]]
	init_state = function(self)
		for _, widget in pairs(self.widgets) do
			local animation = self.state[widget.content.id]
			if animation then
				widget.style.text.font_size = animation.start_size
				widget.style.text_shadow.font_size = animation.start_size
				widget.offset = self:apply_scale_to_offset(animation.start_offset)
				if animation.text then
					if animation.text == "victim_name" then
						local name = "yourself"
						if not mod:is_victim() then
							name = mod:player_name_from_peer_id(mod.data.victim_peer_id)
						end
						widget.content.text = string.format("for %s!", name)
					elseif animation.text == "dare_1" then
						widget.content.text = string.format("%s: %s", mod.data.activate_dare_1, mod.data.dares[1].text)
						widget.style.text.text_color = mod.data.dares[1].text_color
						widget.content.dare_id = mod.data.dares[1].id
					elseif animation.text == "dare_2" then
						widget.content.text = string.format("%s: %s", mod.data.activate_dare_2, mod.data.dares[2].text)
						widget.style.text.text_color = mod.data.dares[2].text_color
						widget.content.dare_id = mod.data.dares[2].id
					elseif animation.text == "dare_3" then
						widget.content.text = string.format("%s: %s", mod.data.activate_dare_3, mod.data.dares[3].text)
						widget.style.text.text_color = mod.data.dares[3].text_color
						widget.content.dare_id = mod.data.dares[3].id
					elseif animation.text == "time" then
						widget.content.text = self.state.time
					elseif animation.text == "reminder" then
						widget.content.text = mod.data.active_dare.reminder or "N/A"
					elseif animation.text == "countdown" then
						if self.countdown > 0 then
							widget.content.text = self.countdown
						elseif self.countdown == 0 then
							widget.content.text = "Go!"
						end
					else
						widget.content.text = animation.text
					end
				end
				if animation.fade_in then
					if UIWidget.has_animation(widget) then UIWidget.stop_animations(widget) end
					local color = widget.style.text.text_color
					UIWidget.animate(widget, UIAnimation.init(UIAnimation.function_by_time, color, 1, 0, 255, animation.fade_in_time, math.easeInCubic))
					local color = widget.style.text_shadow.text_color
					UIWidget.animate(widget, UIAnimation.init(UIAnimation.function_by_time, color, 1, 0, 255, animation.fade_in_time, math.easeInCubic))
				end
				if animation.fade_out then
					if not widget.content.dare_id or widget.content.dare_id ~= mod.data.selected_dare then
						if UIWidget.has_animation(widget) then UIWidget.stop_animations(widget) end
						local color = widget.style.text.text_color
						UIWidget.animate(widget, UIAnimation.init(UIAnimation.function_by_time, color, 1, 255, 0, animation.fade_out_time, math.easeInCubic))
						local color = widget.style.text_shadow.text_color
						UIWidget.animate(widget, UIAnimation.init(UIAnimation.function_by_time, color, 1, 255, 0, animation.fade_out_time, math.easeInCubic))
					end
				end
			end
		end
	end,
	--[[
		Update UI
	--]]
	update = function(self, dt)
		if self.state then
			self.timer = self.timer + dt
			if self.timer >= self.state.time then
				self.state:finish()
			else
				-- Function
				if self.state.update then
					self.state:update()
				end
				-- Animation
				for _, widget in pairs(self.widgets) do
					local animation = self.state[widget.content.id]
					if animation then
						if not widget.content.dare_id or widget.content.dare_id == mod.data.selected_dare then
							if animation.update_size then
								local time = self.timer / self.state.time
								local size = math.lerp(animation.start_size, animation.finish_size, time)
								widget.style.text.font_size = size
								widget.style.text_shadow.font_size = size
							end
							if animation.update_offset then
								local time = self.timer / self.state.time
								local x_pos = math.lerp(animation.start_offset[1], animation.finish_offset[1], time)
								local y_pos = math.lerp(animation.start_offset[2], animation.finish_offset[2], time)
								local z_pos = math.lerp(animation.start_offset[3], animation.finish_offset[3], time)
								--widget.offset = {x_pos, y_pos, z_pos}
								widget.offset = self:apply_scale_to_offset({x_pos, y_pos, z_pos})
							end
						end
						if animation.update_text then
							if animation.text == "time" then
								widget.content.text = string.format ("%i", self.state.time - self.timer + 1)
							end
						end
					end
				end
			end
		end
	end,
	--[[
		Apply hud scaling
	--]]
	apply_scale_to_offset = function(self, offset)
		local new_offset = offset
		if UISettings.use_custom_hud_scale then
			local mult = 2 - (UISettings.hud_scale * 0.01)
			new_offset = {offset[1] * mult, offset[2] * mult, offset[3]}
		end
		return new_offset
	end,
	--[[
		Set a state
	--]]
	set_state = function(self, state_name)
		local state = self.states[state_name]
		if state then
			if debug then mod:echo("UIState '"..state_name.."' started!") end
			self.state = state
			self.timer = 0
			self.state:start()
		else
			mod:echo("Unknown UIState '"..state_name.."'!")
		end
	end,
}

-- ##### ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗ ###################################
-- ##### ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝ ###################################
-- ##### █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗ ###################################
-- ##### ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║ ###################################
-- ##### ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║ ###################################
-- ##### ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝ ###################################
--[[
	Create a simple text widget
--]]
mod.create_simple_text_widget = function(self, id, text, size, offset, content_check, scenegraph_id)
	local scenegraph_id = scenegraph_id or "i_dare_you"
	local offset = offset or {0, 0, 0}
	local size = size or 80
	local widget = {
		element = {
			passes = {
				{
					style_id = "text",
					pass_type = "text",
					text_id = "text",
					content_check_function = content_check or function(content)
						return true
					end,
				},
				{
					style_id = "text_shadow",
					pass_type = "text",
					text_id = "text",
					content_check_function = content_check or function(content)
						return true
					end,
				},
			},
		},
		content = {
			text = text,
			id = id,
		},
		style = {
			text = {
				font_size = size,
				--word_wrap = true,
				pixel_perfect = true,
				horizontal_alignment = "center",
				vertical_alignment = "center",
				dynamic_font = true,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("white", 255),
				offset = {0, 0, 2},
			},
			text_shadow = {
				font_size = size,
				--word_wrap = true,
				pixel_perfect = true,
				horizontal_alignment = "center",
				vertical_alignment = "center",
				dynamic_font = true,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("black", 255),
				offset = {2, -2, 1},
			},
		},
		scenegraph_id = scenegraph_id,
		offset = offset,
	}
	return UIWidget.init(widget)
end
--[[
	Get a random player
--]]
mod.random_player = function(self, except_peer_id)
	if Managers and Managers.state and Managers.state.network then
		-- Compile list of possible players
		local possible_peer_ids = {}
		-- local players = Managers.player:players()
		-- for _, player in pairs(players) do
		-- 	if not except_peer_id or player.peer_id ~= except_peer_id then
		-- 		possible_peer_ids[#possible_peer_ids+1] = player.peer_id
		-- 	end
		-- end
		for _, peer_id in pairs(mod.data.mod_users) do
			-- Make sure peer_id is usable
			if not except_peer_id or peer_id ~= except_peer_id then
				-- Make sure player is alive
				if mod:is_peer_id_alive(peer_id) then
					possible_peer_ids[#possible_peer_ids+1] = peer_id
				end
			end
		end
		-- Choose random player
		local rnd_peer_id = math.random(1, #possible_peer_ids)
		return possible_peer_ids[rnd_peer_id]
	end
	return nil
end
--[[
	Check if in inn / keep
--]]
mod.is_in_inn = function(self)
	return LevelHelper:current_level_settings().level_id == "inn_level" --and not debug --or mod.data.allow_inn
end
--[[
	Check if server
--]]
mod.is_server = function(self)
	if Managers and Managers.state and Managers.state.network then
		return Managers.state.network.is_server
	end
	return false
end
--[[
	Check if victim
--]]
mod.is_victim = function(self)
	return mod.data.victim_peer_id == mod:my_peer_id()
end
--[[
	Check if selector
--]]
mod.is_selector = function(self)
	return mod.data.selector_peer_id == mod:my_peer_id()
end
--[[
	Check if not selector
--]]
mod.is_not_selector = function(self)
	return mod.data.selector_peer_id ~= mod:my_peer_id()
end
--[[
	Get player name from peer_id
--]]
mod.player_name_from_peer_id = function(self, peer_id)
	local player = Managers.player:player_from_peer_id(peer_id)
	return player:name()
end
--[[
	Get player unit from peer_id
--]]
mod.player_unit_from_peer_id = function(self, peer_id)
	local player = Managers.player:player_from_peer_id(peer_id)
	return player.player_unit
end
--[[
	Check if peer_id is alive
--]]
mod.is_peer_id_alive = function(self, peer_id)
	local unit = mod:player_unit_from_peer_id(peer_id)
	if unit then
		local health_extension = ScriptUnit.extension(unit, "health_system")
		if health_extension and health_extension:is_alive() then
			return true
		end
	end
	return false
end
--[[
	Get local peer_id
--]]
mod.my_peer_id = function(self)
	local local_player = Managers.player:local_player()
	return local_player.peer_id
end
--[[
	Get server peer_id
--]]
mod.server_peer_id = function(self)
	if self:is_server() then return self:my_peer_id() end
	return Managers.state.network.network_transmit.server_peer_id
end
--[[
	Check if selecting or selected dare_id
--]]
mod.is_selecting_or_selected = function(content)
	if mod.data.selection or content.dare_id == mod.data.selected_dare then
		return true
	end
	return false
end
--[[
	Check if there are enough mod users to play
--]]
mod.has_enough_players = function(self)
	local player_count = #Managers.player:players()
	local users = mod.data.mod_users
	local party = #mod.data.mod_users == player_count and #mod.data.mod_users > 1
	local minimum = #mod.data.mod_users >= 2
	local alone = #mod.data.mod_users >= 1
	return (mod.data.mode == 1 and party) or (mod.data.mode == 2 and minimum) or (mod.data.mode == 3 and alone)
end
--[[
	Get hotkey string representation
--]]
mod.hotkey_string = function(self, hotkey_table)
	local hotkey_string = ""
	for i=#hotkey_table, 1, -1 do
		hotkey_string = hotkey_string..string.upper(hotkey_table[i])
		if i > 1 then hotkey_string = hotkey_string.." + " end
	end
	return hotkey_string
end

-- ##### ██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗███████╗ ###################################################################
-- ##### ██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██╔════╝ ###################################################################
-- ##### ███████║██║   ██║██║   ██║█████╔╝ ███████╗ ###################################################################
-- ##### ██╔══██║██║   ██║██║   ██║██╔═██╗ ╚════██║ ###################################################################
-- ##### ██║  ██║╚██████╔╝╚██████╔╝██║  ██╗███████║ ###################################################################
-- ##### ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝ ###################################################################

mod:hook_safe(CutsceneUI, "set_player_input_enabled", function(self, enabled)
	if enabled and mod:is_server() then
		mod:echo("START!")
		mod.server:start()
	end
end)

--[[
	Inject scenegraph element
--]]
mod:hook(UISceneGraph, "init_scenegraph", function(func, scenegraph, ...)
	scenegraph.i_dare_you = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		scale = "hud_scale_fit",
		parent = "root",
		size = { 1920, 1080 },
        position = { 0, 0, 0 },
	}

	return func(scenegraph, ...)
end)
mod:hook_disable(UISceneGraph, "init_scenegraph")
--[[
	Inject scenegraph into buff_ui and observer_ui
--]]
local create_ui_elements = function(func, self, ...)
	mod:hook_enable(UISceneGraph, "init_scenegraph")
	local result = func(self, ...)
	--mod.ui:create_widgets()
	mod:hook_disable(UISceneGraph, "init_scenegraph")
	return result
end
mod:hook(BuffUI, "_create_ui_elements", create_ui_elements)
--mod:hook(ObserverUI, "create_ui_elements", create_ui_elements)
--[[
	Update widgets
--]]
local update_widgets = function(self, dt)
	mod.ui:update(dt)
end
mod:hook_safe(BuffUI, "update", update_widgets)
--mod:hook_safe(ObserverUI, "update", update_widgets)
--[[
	Draw widgets
--]]
local draw_widgets = function(self, dt)
	if mod.ui.state then
		local ui_renderer = self.ui_renderer
		local ui_scenegraph = self.ui_scenegraph
		local input_service = self.input_manager:get_service("ingame_menu")
		
		-- Draw widgets
		UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, self.render_settings)
		for _, widget in pairs(mod.ui.widgets) do
			if table.contains(mod.ui.state.render, widget.content.id) then
				UIRenderer.draw_widget(ui_renderer, widget)
			end
		end
		UIRenderer.end_pass(ui_renderer)
	end
end
mod:hook_safe(BuffUI, "draw", draw_widgets)
--mod:hook_safe(ObserverUI, "draw", draw_widgets)

-- ##### ███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗ #########################################################
-- ##### ██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝ #########################################################
-- ##### █████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗ #########################################################
-- ##### ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║ #########################################################
-- ##### ███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║ #########################################################
-- ##### ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ #########################################################
--[[
	Player joined the game
--]]
mod.on_user_joined = function(player)
	if mod:is_server() then
		if debug then
			mod:echo("User joined game!")
			mod:echo("Asking joined user if mod is active...")
			mod:echo("PeerID:'"..tostring(player.peer_id).."'")
		end
		mod:network_send("handshake_client", player.peer_id)
	end
end
--[[
	Player left the game
--]]
mod.on_user_left = function(player)
	if mod:is_server() then
		if debug then
			mod:echo("User left game!")
			mod:echo("PeerID:'"..tostring(player.peer_id).."'")
		end
		mod.server:remove_mod_user(player.peer_id)
	end
end
--[[
	Update cycle
--]]
mod.update = function(dt)
	if mod:is_server() then
		mod.server:update(dt)
	end
	mod:update_dare(dt)
end
--[[
	Mod unload
--]]
mod.on_unload = function(exit_game)
end
--[[
	Gamestate change
--]]
mod.on_game_state_changed = function(status, state)
	if mod.data.active and mod:is_server() then
		-- Add self to mod users
		mod.server:add_mod_user(mod:my_peer_id())
		if state == "StateIngame" and status == "enter" then
			-- if not mod:is_in_inn() or debug then
			-- 	--mod.server:set_state("init")
			-- 	mod.server:start()
			-- else
			-- 	--mod.server:set_state("idle")
			-- 	mod.server:stop()
			-- end
		elseif state == "StateIngame" and status == "exit" then
			--mod.server:set_state("idle")
			mod.server:stop()
		end
	end
end
--[[
	Setting change
--]]
mod.on_setting_changed = function(setting_name)
	if setting_name == "active" then
		-- Save setting to variable
		mod.data.active = mod:get("active")
		-- Check if allowed to change setting
		if mod:is_in_inn() then
			-- We're in the inn, so it's allowed
			if not mod.data.active then
				if debug then mod:echo("Deactivate!") end
				mod:network_send("user_deactivated_mod", mod:server_peer_id())
			else
				if debug then mod:echo("Activate!") end
				mod:network_send("user_activated_mod", mod:server_peer_id())
			end
		else
			-- We're in a mission, so it's punishment time
			if mod.data.active then
				if debug then mod:echo("Die!") end
				mod:set("active", true)
			end
		end
	-- elseif setting_name == "allow_inn" then
	-- 	-- Save setting to variable
	-- 	mod.data.allow_inn = mod:get("allow_inn")
	-- 	-- Restart server
	-- 	if mod:is_server() then mod.server:start() end

	elseif setting_name == "mode" then
		-- Save setting to variable
		mod.data.mode = mod:get("mode")
		-- Restart server
		if mod:is_server() then mod.server:start() end

	elseif setting_name == "activate_dare_1" then
		-- Save setting to variable
		mod.data.activate_dare_1 = mod:hotkey_string(mod:get("activate_dare_1"))

	elseif setting_name == "activate_dare_2" then
		-- Save setting to variable
		mod.data.activate_dare_2 = mod:hotkey_string(mod:get("activate_dare_2"))

	elseif setting_name == "activate_dare_3" then
		-- Save setting to variable
		mod.data.activate_dare_3 = mod:hotkey_string(mod:get("activate_dare_3"))
	
	elseif setting_name == "debug" then
		debug = mod:get("debug")
	end
end
--[[
	Mod disable
--]]
mod.on_disabled = function(is_first_call)
end
--[[
	Mod enable
--]]
mod.on_enabled = function(is_first_call)
end
--[[
	When all mods are loaded
--]]
mod.on_all_mods_loaded = function()
	-- Widgets
	mod.ui:create_widgets()
	-- Set settings
	mod.data.active = mod:get("active")
	mod.data.mode = mod:get("mode")
	--mod.data.allow_inn = mod:get("allow_inn")
	--mod:dump(mod:get("activate_dare_1"), "activate_dare_1", 2)
	mod.data.activate_dare_1 = mod:hotkey_string(mod:get("activate_dare_1"))
	mod.data.activate_dare_2 = mod:hotkey_string(mod:get("activate_dare_2"))
	mod.data.activate_dare_3 = mod:hotkey_string(mod:get("activate_dare_3"))
	-- Add local player to list
	if mod:is_server() then
		mod.server:add_mod_user(mod:my_peer_id())
	end
end
