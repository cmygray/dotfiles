-- 세로 모니터 두 대를 각각 위 1/3, 아래 2/3로 나눈 칸 네 개를 합쳐 만드는 레이아웃.
-- 포커스된 창을 영역으로 옮기면, 레이아웃을 채우던 나머지 창이 따라 재배치된다.
--
-- 영역: TOP(위 걸침), BOT(아래 걸침), LT/LB(왼쪽 모니터 위/아래), RT/RB(오른쪽 모니터 위/아래)
-- 상태는 따로 저장하지 않고 창 위치로 판단한다.
--   - 멤버: 영역과 위치가 맞고, 앞쪽 창에 가려지지 않은 창
--   - 예비: 영역과 위치가 맞지만 앞쪽 멤버에 가려진 창 (빈 칸을 채울 때 끌어온다)
--   - 어느 영역에도 맞지 않는 창은 건드리지 않는다

local M = {}

local TOP_RATIO = 1 / 3
local TOLERANCE = 20

-- 앞에 둔 레이아웃이 동점일 때 우선한다
local LAYOUTS = {
	{ "TOP", "BOT" },
	{ "TOP", "LB", "RB" },
	{ "LT", "RT", "BOT" },
	{ "LT", "RT", "LB", "RB" },
}

local COLS = {
	TOP = { L = true, R = true },
	BOT = { L = true, R = true },
	LT = { L = true },
	LB = { L = true },
	RT = { R = true },
	RB = { R = true },
}

local ROW = { TOP = "top", LT = "top", RT = "top", BOT = "bottom", LB = "bottom", RB = "bottom" }

local function contains(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

local function share_col(a, b)
	for col in pairs(COLS[a]) do
		if COLS[b][col] then
			return true
		end
	end
	return false
end

local function overlaps(a, b)
	return ROW[a] == ROW[b] and share_col(a, b)
end

-- 창이 원래 영역에서 새 영역으로 갈 때의 비용: 좌우 쪽이 바뀌면 2, 위아래가 바뀌면 1
local function move_cost(from, to)
	local cost = 0
	if not share_col(from, to) then
		cost = cost + 2
	end
	if ROW[from] ~= ROW[to] then
		cost = cost + 1
	end
	return cost
end

local function build_regions()
	local screens = hs.screen.allScreens()
	if #screens ~= 2 then
		return nil
	end
	table.sort(screens, function(a, b)
		return a:frame().x < b:frame().x
	end)
	local l, r = screens[1]:frame(), screens[2]:frame()
	-- 메뉴바·Dock은 한 모니터에만 있어 두 모니터의 사용 가능 높이가 다르다.
	-- 걸침 창과 칸 경계를 맞추려고 두 모니터가 공통으로 쓸 수 있는 세로 구간만 쓴다.
	local y = math.max(l.y, r.y)
	local h = math.min(l.y + l.h, r.y + r.h) - y
	local top_h = h * TOP_RATIO
	local bot_h = h - top_h
	return {
		TOP = hs.geometry.rect(l.x, y, l.w + r.w, top_h),
		BOT = hs.geometry.rect(l.x, y + top_h, l.w + r.w, bot_h),
		LT = hs.geometry.rect(l.x, y, l.w, top_h),
		LB = hs.geometry.rect(l.x, y + top_h, l.w, bot_h),
		RT = hs.geometry.rect(r.x, y, r.w, top_h),
		RB = hs.geometry.rect(r.x, y + top_h, r.w, bot_h),
	}
end

local function region_of(win, regions)
	local f = win:frame()
	for name, r in pairs(regions) do
		if
			math.abs(f.x - r.x) <= TOLERANCE
			and math.abs(f.y - r.y) <= TOLERANCE
			and math.abs(f.w - r.w) <= TOLERANCE
			and math.abs(f.h - r.h) <= TOLERANCE
		then
			return name
		end
	end
	return nil
end

-- 화면에 있는 일반 창을 앞에서 뒤 순서로 돌려준다.
-- hs.window.orderedWindows()는 창이 없는 프로세스까지 접근성 API로 조회해서
-- 응답 없는 프로세스(예: CursorUIViewService) 하나에 1.5초씩 묶인다.
-- CGWindowList(hs.window.list)로 순서와 소유 pid를 먼저 얻고, 그 앱만 조회한다.
local function ordered_windows()
	local entries = hs.window.list()
	local by_id, seen_pid = {}, {}
	for _, e in ipairs(entries) do
		local pid = e.kCGWindowOwnerPID
		if e.kCGWindowLayer == 0 and pid and not seen_pid[pid] then
			seen_pid[pid] = true
			local app = hs.application.applicationForPID(pid)
			if app then
				for _, win in ipairs(app:allWindows()) do
					by_id[win:id()] = win
				end
			end
		end
	end
	local result = {}
	for _, e in ipairs(entries) do
		local win = by_id[e.kCGWindowNumber]
		if win then
			table.insert(result, win)
			by_id[e.kCGWindowNumber] = nil
		end
	end
	return result
end

-- 앞에서 뒤 순서(최근 사용 순)로 창을 훑어 멤버와 예비로 나눈다
local function snapshot(focused, regions)
	local focused_id = focused:id()
	local focused_region = region_of(focused, regions)
	local claimed = {}
	if focused_region then
		table.insert(claimed, focused_region)
	end

	local members, spares = {}, {}
	for _, win in ipairs(ordered_windows()) do
		if win:id() ~= focused_id and win:isStandard() then
			local name = region_of(win, regions)
			if name then
				local hidden = false
				for _, c in ipairs(claimed) do
					if overlaps(c, name) then
						hidden = true
						break
					end
				end
				if hidden then
					table.insert(spares, { win = win, region = name })
				else
					table.insert(claimed, name)
					table.insert(members, { win = win, region = name })
				end
			end
		end
	end
	return members, spares
end

-- target을 포함하는 레이아웃 중, 제자리에 남는 멤버가 가장 많고 창 수가 지금과 가장 가까운 것
local function choose_layout(target, members)
	local n = #members + 1
	local best, best_score
	for _, layout in ipairs(LAYOUTS) do
		if contains(layout, target) then
			local kept = 0
			for _, m in ipairs(members) do
				if m.region ~= target and contains(layout, m.region) then
					kept = kept + 1
				end
			end
			local score = kept * 10 - math.abs(#layout - n)
			if not best_score or score > best_score then
				best, best_score = layout, score
			end
		end
	end
	return best
end

local function move_single_screen(win, target)
	local f = hs.screen.mainScreen():frame()
	local top_h = f.h * TOP_RATIO
	if ROW[target] == "top" then
		win:setFrame(hs.geometry.rect(f.x, f.y, f.w, top_h))
	else
		win:setFrame(hs.geometry.rect(f.x, f.y + top_h, f.w, f.h - top_h))
	end
end

function M.move(target)
	local focused = target_window()
	if not focused then
		return
	end

	local regions = build_regions()
	if not regions then
		move_single_screen(focused, target)
		return
	end

	local members, spares = snapshot(focused, regions)
	local layout = choose_layout(target, members)

	-- 레이아웃에 남는 멤버는 제자리, 나머지는 다시 배치할 후보가 된다
	local occupied = { [target] = true }
	local candidates = {}
	for _, m in ipairs(members) do
		if m.region ~= target and contains(layout, m.region) then
			occupied[m.region] = true
		else
			table.insert(candidates, m)
		end
	end
	-- 밀려난 멤버를 최근 사용 순으로 먼저, 그다음 예비 창
	for _, s in ipairs(spares) do
		table.insert(candidates, s)
	end

	local free = {}
	for _, name in ipairs(layout) do
		if not occupied[name] then
			table.insert(free, name)
		end
	end

	focused:setFrame(regions[target])

	-- 빈 칸 수보다 많은 후보는 제자리에 둔다 (앞 창에 가려진다)
	for _, c in ipairs(candidates) do
		if #free == 0 then
			break
		end
		local best_i, best_cost
		for i, name in ipairs(free) do
			local cost = move_cost(c.region, name)
			if not best_cost or cost < best_cost then
				best_i, best_cost = i, cost
			end
		end
		c.win:setFrame(regions[free[best_i]])
		table.remove(free, best_i)
	end
end

return M
