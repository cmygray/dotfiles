local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local WORKSPACE = os.getenv("WORKSPACE") or (wezterm.home_dir .. "/Workspace")
local CLAUDE = wezterm.home_dir .. "/.local/bin/claude"

-- Action: Select project → enter task name → spawn Claude worktree session
local claude_tab = wezterm.action_callback(function(window, pane)
	local choices = {}
	local handle = io.popen('ls -1 "' .. WORKSPACE .. '"')
	if handle then
		for dir in handle:lines() do
			table.insert(choices, { id = dir, label = dir })
		end
		handle:close()
	end

	if #choices == 0 then return end

	window:perform_action(act.InputSelector({
		title = "Select project",
		fuzzy = true,
		choices = choices,
		action = wezterm.action_callback(function(win, p, id, label)
			if not id then return end
			win:perform_action(act.PromptInputLine({
				description = "Task name (e.g. fix-login-bug):",
				action = wezterm.action_callback(function(win2, p2, line)
					if not line or line == "" then return end
					local project_dir = WORKSPACE .. "/" .. id
					local cmd = "cd " .. wezterm.shell_quote_arg(project_dir)
						.. " && " .. wezterm.shell_quote_arg(CLAUDE)
						.. " --dangerously-skip-permissions --worktree " .. wezterm.shell_quote_arg(line)
					local tab, _, _ = win2:mux_window():spawn_tab({
						cwd = project_dir,
						args = { "zsh", "-lic", cmd },
					})
					tab:set_title(line)
				end),
			}), p)
		end),
	}), pane)
end)

-- Action: Resume existing Claude worktree session
local resume_worktree = wezterm.action_callback(function(window, pane)
	local handle = io.popen(
		'find "' .. WORKSPACE .. '" -path "*/.claude/worktrees/*" -type d -maxdepth 4 -mindepth 4 2>/dev/null'
	)
	if not handle then return end

	local choices = {}
	for line in handle:lines() do
		-- line: /path/to/Workspace/project/.claude/worktrees/wt-name
		local project = line:match(WORKSPACE .. "/([^/]+)/")
		local wt_name = line:match("/worktrees/([^/]+)$")
		if project and wt_name then
			table.insert(choices, {
				id = project .. "\t" .. wt_name,
				label = project .. "/" .. wt_name,
			})
		end
	end
	handle:close()

	if #choices == 0 then
		window:toast_notification("worktree", "No worktrees found", nil, 3000)
		return
	end

	window:perform_action(act.InputSelector({
		title = "Resume worktree",
		fuzzy = true,
		choices = choices,
		action = wezterm.action_callback(function(win, p, id, label)
			if not id then return end
			local project, wt_name = id:match("^(.+)\t(.+)$")
			if not project or not wt_name then return end
			local project_dir = WORKSPACE .. "/" .. project
			local cmd = "cd " .. wezterm.shell_quote_arg(project_dir)
				.. " && " .. wezterm.shell_quote_arg(CLAUDE)
				.. " --dangerously-skip-permissions --worktree " .. wezterm.shell_quote_arg(wt_name)
			local tab, _, _ = win:mux_window():spawn_tab({
				cwd = project_dir,
				args = { "zsh", "-lic", cmd },
			})
			tab:set_title(wt_name)
		end),
	}), pane)
end)

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

-- Event: Strip close button from fancy tab bar
wezterm.on("format-tab-title", function(tab)
	local title = tab.tab_title
	if #title == 0 then
		title = tab.active_pane.title
	end
	return " " .. title .. " "
end)

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
	{ key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
	-- New window from home directory (CMD + n)
	{ key = "n", mods = "SUPER", action = act.SpawnCommandInNewWindow({ cwd = wezterm.home_dir }) },
	-- New tab with name prompt (LEADER + c or CMD + t)
	{ key = "t", mods = "SUPER|SHIFT", action = prompt_and_spawn_tab },
	{ key = "t", mods = "SUPER", action = claude_tab },
	-- Resume existing worktree (CMD + SHIFT + r)
	{ key = "r", mods = "SUPER|SHIFT", action = resume_worktree },
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
	{ key = "r", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "T", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "t", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "h", mods = "SUPER|ALT", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "l", mods = "SUPER|ALT", action = wezterm.action.ActivateTabRelative(1) },
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
		key = "x",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "R",
		mods = "LEADER|SHIFT",
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
	automatically_reload_config = true,
	enable_kitty_keyboard = true,
	window_decorations = "RESIZE",
	default_cwd = wezterm.home_dir,
	color_scheme = "nord",
	send_composed_key_when_right_alt_is_pressed = false,
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = true,
	show_new_tab_button_in_tab_bar = false,
	tab_bar_at_bottom = true,
	show_tab_index_in_tab_bar = false,
	show_close_tab_button_in_tabs = false,
	enable_scroll_bar = false,
	window_padding = { left = 0, right = 0, top = 0, bottom = 0 },

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

	ssh_domains = {
		{
			name = "SSHMUX:home",
			remote_address = "home",
			username = "won",
			remote_wezterm_path = "/opt/homebrew/bin/wezterm",
		},
	},

	quick_select_patterns = {
		"[a-zA-Z0-9]{27}",
		"[a-zA-Z0-9]{21}",
		"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
	},
}
