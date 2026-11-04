-- nview: 에이전트가 nvim 팬에 코드를 "보여 주는" 명령 모음.
-- scripts/nview 가 `nvim --server ... --remote-expr` 로 run(cmd, argfile) 을 부른다.
-- 이 파일은 매 호출마다 dofile 로 다시 읽히므로 상태는 탭 변수(t:nview)와 네임스페이스에만 둔다.
local M = {}

local ns = vim.api.nvim_create_namespace("nview")
vim.api.nvim_set_hl(0, "NviewFocus", { default = true, link = "Visual" })
vim.api.nvim_set_hl(0, "NviewNote", { default = true, link = "DiagnosticInfo" })

-- "path[:from[-to]]" → { file, from, to }
local function parse_spec(spec)
	local file, from, to = spec:match("^(.-):(%d+)%-(%d+)$")
	if not file then
		file, from = spec:match("^(.-):(%d+)$")
		to = from
	end
	if not file then
		file = spec
	end
	return { file = file, from = tonumber(from), to = tonumber(to) }
end

-- 에이전트 전용 새 탭. 상대 경로는 호출한 쪽 cwd 기준으로 풀리도록 tcd 한다.
local function new_tab(cwd, title)
	vim.cmd("tabnew")
	vim.cmd.tcd(vim.fn.fnameescape(cwd))
	vim.t.nview = title
end

local function open_file(file)
	if vim.fn.filereadable(file) == 0 then
		error("파일 없음: " .. file, 0)
	end
	vim.cmd.edit(vim.fn.fnameescape(file))
	vim.bo.readonly = true
	return vim.api.nvim_get_current_buf()
end

local function mark(buf, from, to, note)
	if not from then
		return
	end
	local last = vim.api.nvim_buf_line_count(buf)
	from = math.min(from, last)
	to = math.min(to or from, last)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	vim.api.nvim_buf_set_extmark(buf, ns, from - 1, 0, {
		end_row = to - 1,
		line_hl_group = "NviewFocus",
		virt_lines = note and { { { "▶ " .. note, "NviewNote" } } } or nil,
		virt_lines_above = true,
	})
	vim.api.nvim_win_set_cursor(0, { from, 0 })
	vim.cmd("normal! zz")
end

-- 스크래치 버퍼(git 의 특정 리비전 내용 등). 수정 불가.
local function scratch(name, lines, ft)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	pcall(vim.api.nvim_buf_set_name, buf, name)
	vim.bo[buf].modifiable = false
	-- bufhidden=wipe 는 쓰지 않는다: 현재 diff 탭을 닫을 때 nvim 0.12 가 segfault 했다. clear 가 지운다.
	vim.bo[buf].bufhidden = "hide"
	vim.b[buf].nview_scratch = true
	if ft and ft ~= "" then
		vim.bo[buf].filetype = ft
	end
	return buf
end

-- diff: 파일 둘, 또는 git 리비전(기본 HEAD) 대비 작업 트리. 파일마다 탭 하나.
function M.diff(a)
	if a.files and #a.files == 2 then
		new_tab(a.cwd, "diff")
		open_file(a.files[1])
		vim.cmd("vert diffsplit " .. vim.fn.fnameescape(a.files[2]))
		vim.bo.readonly = true
		return "diff 1쌍"
	end
	local rev = a.rev or "HEAD"
	local root = vim.fn.systemlist({ "git", "-C", a.cwd, "rev-parse", "--show-toplevel" })[1]
	if vim.v.shell_error ~= 0 then
		error("git 저장소가 아님: " .. a.cwd, 0)
	end
	local names = vim.fn.systemlist({ "git", "-C", root, "diff", "--name-only", rev, "--" })
	if vim.v.shell_error ~= 0 then
		error("git diff 실패: " .. rev, 0)
	end
	if #names == 0 then
		return "변경 없음 (" .. rev .. ")"
	end
	local max = a.max or 8
	for i, rel in ipairs(names) do
		if i > max then
			break
		end
		new_tab(root, "diff " .. rel)
		local ft = vim.filetype.match({ filename = rel }) or ""
		local old = vim.fn.systemlist({ "git", "-C", root, "show", rev .. ":" .. rel })
		if vim.v.shell_error ~= 0 then
			old = {} -- 새 파일
		end
		if vim.fn.filereadable(root .. "/" .. rel) == 1 then
			open_file(rel)
		else
			vim.api.nvim_win_set_buf(0, scratch("nview://deleted/" .. rel, {}, ft))
		end
		vim.cmd("diffthis")
		vim.cmd("leftabove vnew")
		vim.api.nvim_win_set_buf(0, scratch("nview://" .. rev .. "/" .. rel, old, ft))
		vim.cmd("diffthis")
		vim.cmd("wincmd l")
	end
	local more = #names > max and string.format(" (+%d개 생략, 위치는 list 로)", #names - max) or ""
	return string.format("diff %d개 파일 vs %s%s", math.min(#names, max), rev, more)
end

-- show: 한 곳을 열고 범위 하이라이트 + 설명.
function M.show(a)
	local s = parse_spec(a.spec)
	new_tab(a.cwd, "show " .. s.file)
	local buf = open_file(s.file)
	mark(buf, s.from, s.to, a.note)
	return "show " .. a.spec
end

-- side: 2~3곳을 세로 분할로 나란히.
function M.side(a)
	if #a.specs < 2 or #a.specs > 3 then
		error("side 는 2~3곳만 받습니다 (그 이상은 list)", 0)
	end
	new_tab(a.cwd, "side")
	for i, spec in ipairs(a.specs) do
		if i > 1 then
			vim.cmd("rightbelow vsplit")
		end
		local s = parse_spec(spec)
		local buf = open_file(s.file)
		mark(buf, s.from, s.to, nil)
	end
	vim.cmd("wincmd =")
	vim.cmd("1wincmd w")
	return "side " .. #a.specs .. "곳"
end

-- list: grep 형식(file:line[:col]:text) 줄들을 quickfix 로.
function M.list(a)
	new_tab(a.cwd, "list")
	vim.fn.setqflist({}, " ", {
		title = a.title or "nview",
		lines = a.lines,
		efm = "%f:%l:%c:%m,%f:%l:%m,%f:%l",
	})
	local n = #vim.fn.getqflist()
	if n == 0 then
		error("위치를 하나도 읽지 못했습니다 (file:line:text 형식인지 확인)", 0)
	end
	vim.cmd("copen")
	vim.cmd("cfirst")
	return "list " .. n .. "곳"
end

-- clear: nview 가 연 탭과 표시를 모두 정리.
function M.clear()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	end
	local function is_nview(tab)
		local ok, v = pcall(vim.api.nvim_tabpage_get_var, tab, "nview")
		return ok and v
	end
	-- 1) 현재 탭을 닫지 않도록 nview 가 아닌 탭으로 먼저 옮긴다 (없으면 만든다)
	local keep
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		if not is_nview(tab) then
			keep = tab
			break
		end
	end
	if not keep then
		vim.cmd("0tabnew")
		keep = vim.api.nvim_get_current_tabpage()
	end
	vim.api.nvim_set_current_tabpage(keep)
	-- 2) nview 탭 닫기
	local closed = 0
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		if is_nview(tab) then
			vim.cmd("tabclose! " .. vim.api.nvim_tabpage_get_number(tab))
			closed = closed + 1
		end
	end
	vim.cmd("diffoff!")
	-- 3) 화면에서 내려간 스크래치 버퍼 정리
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.b[buf].nview_scratch and vim.fn.bufwinid(buf) == -1 then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
	end
	return "clear 탭 " .. closed .. "개"
end

-- 진입점. 성공은 "ok ...", 실패는 "ERR ..." 문자열로 돌려준다(셸이 접두어로 판별).
function M.run(cmd, argfile)
	local f = assert(io.open(argfile))
	local args = vim.json.decode(f:read("*a"))
	f:close()
	local fn = M[cmd]
	if not fn then
		return "ERR 알 수 없는 명령: " .. cmd
	end
	local before = vim.api.nvim_get_current_tabpage()
	local ok, res = pcall(fn, args)
	if not ok then
		-- 실패한 명령이 연 빈 탭은 남기지 않는다
		if vim.api.nvim_get_current_tabpage() ~= before and vim.t.nview then
			pcall(vim.cmd, "tabclose!")
		end
		return "ERR " .. tostring(res)
	end
	vim.cmd("redraw")
	return "ok " .. tostring(res)
end

return M
