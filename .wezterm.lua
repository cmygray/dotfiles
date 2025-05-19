local wezterm = require("wezterm")
local act = wezterm.action

local keys = {
	{ key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
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
}

for i = 1, 9 do
	table.insert(keys, {
		key = tostring(i),
		mods = "LEADER",
		action = wezterm.action.MoveTab(i - 1),
	})
end

return {
	default_cwd = wezterm.home_dir .. "/Workspace",
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
