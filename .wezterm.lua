local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

-- Action: Prompt for tab name, then spawn tab with that name
local prompt_and_spawn_tab = act.PromptInputLine({
	description = "Enter tab name:",
	action = wezterm.action_callback(function(window, pane, line)
		if line and line ~= "" then
			local tab, _, _ = window:mux_window():spawn_tab({ cwd = wezterm.home_dir })
			tab:set_title(line)
		end
	end),
})

-- Event: When clicking the + button in tab bar
wezterm.on("new-tab-button-click", function(window, pane, button, default_action)
	if button == "Left" then
		window:perform_action(prompt_and_spawn_tab, pane)
		return false -- prevent default action (avoid duplicate tab)
	end
end)

-- Event: When GUI first starts, prompt for initial tab name
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	-- Use a slight delay to ensure window is ready
	wezterm.time.call_after(0.1, function()
		window:gui_window():perform_action(
			act.PromptInputLine({
				description = "Enter tab name:",
				action = wezterm.action_callback(function(win, p, line)
					if line and line ~= "" then
						win:active_tab():set_title(line)
					end
				end),
			}),
			pane
		)
	end)
end)

local keys = {
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b\r" }) },
	{ key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
	-- New window from home directory (CMD + n)
	{ key = "n", mods = "SUPER", action = act.SpawnCommandInNewWindow({ cwd = wezterm.home_dir }) },
	-- New tab with name prompt (LEADER + c or CMD + t)
	{ key = "c", mods = "LEADER", action = prompt_and_spawn_tab },
	{ key = "t", mods = "SUPER", action = prompt_and_spawn_tab },
	-- Rename current tab (LEADER + ,)
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename tab:",
			action = wezterm.action_callback(function(window, pane, line)
				if line and line ~= "" then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	{ key = "v", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "s", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "T", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "t", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "<", mods = "LEADER", action = act.MoveTabRelative(-1) },
	{ key = ">", mods = "LEADER", action = act.MoveTabRelative(1) },
	{
		key = "!",
		mods = "LEADER",
		action = wezterm.action_callback(function(_, pane)
			pane:move_to_new_window()
		end),
	},
	{
		key = "d",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "r",
		mods = "LEADER",
		action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false, replace_current = true }),
	},
	{ key = "Escape", mods = "LEADER", action = "PopKeyTable" },
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b\r" }) },
}

for i = 1, 9 do
	table.insert(keys, {
		key = tostring(i),
		mods = "LEADER",
		action = wezterm.action.MoveTab(i - 1),
	})
end

return {
	automatically_reload_config = true,
	window_decorations = "RESIZE",
	default_cwd = wezterm.home_dir,
	color_scheme = "nord",

	font = wezterm.font_with_fallback({
		"JetBrainsMono NF",
		"JetBrains Mono",
	}),

	inactive_pane_hsb = {
		saturation = 0.7,
		brightness = 0.6,
	},

	leader = {
		key = "'",
		mods = "CTRL",
	},

	keys = keys,

	key_tables = {
		resize_pane = {
			{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
		},
	},

	quick_select_patterns = {
		"[a-zA-Z0-9]{27}",
		"[a-zA-Z0-9]{21}",
	},
}
