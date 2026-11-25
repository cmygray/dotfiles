-- 일부 앱(Yab 등 CEF 기반)은 hs.window.focusedWindow()가 nil을 돌려주므로
-- 앞에 있는 앱의 focused/main 창으로 대체한다
function target_window()
	local window = hs.window.focusedWindow()
	if window then
		return window
	end
	local app = hs.application.frontmostApplication()
	if not app then
		return nil
	end
	return app:focusedWindow() or app:mainWindow()
end

function get_frame()
	if #hs.screen.allScreens() == 1 then
		return hs.screen.mainScreen():frame()
	else
		local frame = {
			x = 0,
			y = 0,
			w = 0,
			h = 0,
			left_w = 0,
			left_h = 0,
			right_w = 0,
			right_h = 0,
		}

		local screens = hs.screen.allScreens()
		table.sort(screens, function(a, b)
			return a:frame().x < b:frame().x
		end)
		local left_frame = screens[1]:frame()
		local right_frame = screens[2]:frame()

		frame.x = left_frame.x
		frame.y = left_frame.y
		frame.w = left_frame.w + right_frame.w
		frame.h = left_frame.h
		frame.left_w = left_frame.w
		frame.left_h = left_frame.h
		frame.right_w = right_frame.w
		frame.right_h = right_frame.h

		return frame
	end
end

hs.hotkey.bind({ "ctrl", "shift", "alt" }, "return", function()
	local frame = get_frame()

	local window = target_window()
	if not window then
		return
	end
	local window_frame = window:frame()

	window_frame.x = frame.x
	window_frame.y = frame.y
	window_frame.w = frame.w
	window_frame.h = frame.h

	window:setFrame(window_frame)
end)

--hs.hotkey.bind({"ctrl", "shift", "alt"}, "left", function()
--  local frame = get_frame()
--
--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()
--
--  window_frame.x = frame.x
--  window_frame.y = frame.y
--  window_frame.w = frame.left_w
--  window_frame.h = frame.left_h
--
--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "shift", "alt"}, "right", function()
--  local frame = get_frame()
--
--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()
--
--  window_frame.x = frame.left_w
--  window_frame.y = frame.y
--  window_frame.w = frame.right_w
--  window_frame.h = frame.right_h
--
--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "e", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.x
--  window_frame.y = frame.y
--  window_frame.w = frame.w / 3 * 2
--  window_frame.h = frame.h

--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "t", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.w / 3
--  window_frame.y = frame.y
--  window_frame.w = frame.w / 3 * 2
--  window_frame.h = frame.h

--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "d", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.x
--  window_frame.y = frame.y
--  window_frame.w = frame.w / 3
--  window_frame.h = frame.h

--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "f", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.w / 3
--  window_frame.y = frame.y
--  window_frame.w = frame.w / 3
--  window_frame.h = frame.h

--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "g", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.w / 3 * 2
--  window_frame.y = frame.y
--  window_frame.w = frame.w / 3
--  window_frame.h = frame.h

--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "u", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.x
--  window_frame.y = frame.y
--  window_frame.w = frame.w / 2
--  window_frame.h = frame.h / 2

--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "j", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.x
--  window_frame.y = frame.y + frame.h / 2
--  window_frame.w = frame.w / 2
--  window_frame.h = frame.h / 2

--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "i", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.w / 2
--  window_frame.y = frame.y
--  window_frame.w = frame.w / 2
--  window_frame.h = frame.h / 2

--  window:setFrame(window_frame)
--end)

--hs.hotkey.bind({"ctrl", "alt"}, "k", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = frame.w / 2
--  window_frame.y = frame.y + frame.h / 2
--  window_frame.w = frame.w / 2
--  window_frame.h = frame.h / 2

--  window:setFrame(window_frame)
--end)

-- 위 1/3, 아래 2/3 타일링: 포커스된 창을 옮기면 레이아웃의 나머지 창이 따라 움직인다 (modules/tiling.lua)
local tiling = require("modules.tiling")
local TILING_KEYS = {
	up = "TOP", -- 두 모니터에 걸친 위 1/3
	down = "BOT", -- 두 모니터에 걸친 아래 2/3
	u = "LT", -- 왼쪽 모니터 위
	i = "RT", -- 오른쪽 모니터 위
	j = "LB", -- 왼쪽 모니터 아래
	k = "RB", -- 오른쪽 모니터 아래
}
for key, region in pairs(TILING_KEYS) do
	hs.hotkey.bind({ "ctrl", "shift", "alt" }, key, function()
		tiling.move(region)
	end)
end

--hs.hotkey.bind({"ctrl", "alt"}, "c", function()
--  local frame = get_frame()

--  local window = hs.window.focusedWindow()
--  local window_frame = window:frame()

--  window_frame.x = (frame.w - window_frame.w) / 2
--  window_frame.y = (frame.h - window_frame.h) / 2

--  window:setFrame(window_frame)
--end)
