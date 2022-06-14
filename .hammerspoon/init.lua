require('modules.inputsource_aurora')
require('modules.window_manager')

hs.hotkey.bind({"ctrl", "alt"}, "space", function()
  hs.application.launchOrFocus("Finder")
end)

