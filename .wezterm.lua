local wezterm = require 'wezterm'
local act = wezterm.action

local keys = {
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = '%', mods = 'LEADER', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '"', mods = 'LEADER', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'p', mods = 'LEADER', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'n', mods = 'LEADER', action = wezterm.action.ActivateTabRelative(1) },
  { key = '<', mods = 'LEADER', action = act.MoveTabRelative(-1) },
  { key = '>', mods = 'LEADER', action = act.MoveTabRelative(1) },

  { key = 'Enter', mods = 'ALT', action = 'DisableDefaultAssignment' },
  { key = 'Enter', mods = 'ALT|SHIFT', action = 'ToggleFullScreen' },


  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false, replace_current = true } },
  { key = 'Escape', action = 'PopKeyTable' },
}

for i = 1, 9 do
  table.insert(keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = wezterm.action.MoveTab(i - 1),
  })
end

return {
  color_scheme = 'nord',
  font = wezterm.font 'JetBrains Mono',

  leader = {
    key = 'a',
    mods = 'CTRL',
  },

  keys = keys,

  key_tables = {
    resize_pane = {
      { key = 'h', action = act.AdjustPaneSize { 'Left', 1 } },
      { key = 'j', action = act.AdjustPaneSize { 'Down', 1 } },
      { key = 'k', action = act.AdjustPaneSize { 'Up', 1 } },
      { key = 'l', action = act.AdjustPaneSize { 'Right', 1 } },
    },
  }
}

