function get_frame ()
  if #hs.screen.allScreens() == 1 then
    return hs.screen.mainScreen():frame()
  else
    local frame = {
      x = 0,
      y = 0,
      w = 0,
      h = 0,
    }

    local left_frame = hs.screen.allScreens()[1]:frame()
    local right_frame = hs.screen.allScreens()[2]:frame()

    frame.x = left_frame.x
    frame.y = left_frame.y
    frame.w = left_frame.w + right_frame.w
    frame.h = left_frame.h

    return frame
  end
end

hs.hotkey.bind({"ctrl", "alt"}, "return", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.x
  window_frame.y = frame.y
  window_frame.w = frame.w
  window_frame.h = frame.h

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "left", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.x
  window_frame.y = frame.y
  window_frame.w = frame.w / 2
  window_frame.h = frame.h

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "right", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.w / 2
  window_frame.y = frame.y
  window_frame.w = frame.w / 2
  window_frame.h = frame.h

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "e", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.x
  window_frame.y = frame.y
  window_frame.w = frame.w / 3 * 2
  window_frame.h = frame.h

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "t", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.w / 3
  window_frame.y = frame.y
  window_frame.w = frame.w / 3 * 2
  window_frame.h = frame.h

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "d", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.x
  window_frame.y = frame.y
  window_frame.w = frame.w / 3
  window_frame.h = frame.h

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "f", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.w / 3
  window_frame.y = frame.y
  window_frame.w = frame.w / 3
  window_frame.h = frame.h

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "g", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.w / 3 * 2
  window_frame.y = frame.y
  window_frame.w = frame.w / 3
  window_frame.h = frame.h

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "u", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.x
  window_frame.y = frame.y
  window_frame.w = frame.w / 2
  window_frame.h = frame.h / 2

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "j", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.x
  window_frame.y = frame.y + frame.h / 2
  window_frame.w = frame.w / 2
  window_frame.h = frame.h / 2

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "i", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.w / 2
  window_frame.y = frame.y
  window_frame.w = frame.w / 2
  window_frame.h = frame.h / 2

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "k", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.w / 2
  window_frame.y = frame.y + frame.h / 2
  window_frame.w = frame.w / 2
  window_frame.h = frame.h / 2

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "up", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.x
  window_frame.y = frame.y
  window_frame.w = frame.w
  window_frame.h = frame.h / 2

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "down", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = frame.x
  window_frame.y = frame.y + frame.h / 2
  window_frame.w = frame.w
  window_frame.h = frame.h / 2

  window:setFrame(window_frame)
end)

hs.hotkey.bind({"ctrl", "alt"}, "c", function()
  local frame = get_frame()

  local window = hs.window.focusedWindow()
  local window_frame = window:frame()

  window_frame.x = (frame.w - window_frame.w) / 2
  window_frame.y = (frame.h - window_frame.h) / 2

  window:setFrame(window_frame)
end)

