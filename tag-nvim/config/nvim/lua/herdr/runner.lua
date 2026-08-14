-- herdr-native runner pane.
--
-- Owns every `herdr` CLI call in this config and the identity of the runner
-- pane. Callers (keymaps, vim-test) go through this module and never shell out
-- themselves.
--
-- Outside a herdr pane every entry point warns once and returns nil, so a tmux
-- or bare-terminal nvim still starts cleanly.

local M = {}

-- Pane id of the runner, scoped to this nvim instance. Revalidated on use.
local runner_id = nil

local function bin()
	local configured = vim.env.HERDR_BIN_PATH
	if configured == nil or configured == "" then
		return "herdr"
	end
	return configured
end

local function warn(msg)
	vim.notify("herdr runner: " .. msg, vim.log.levels.WARN)
end

--- True when nvim is running inside a herdr pane.
function M.available()
	return vim.env.HERDR_PANE_ID ~= nil and vim.env.HERDR_PANE_ID ~= ""
end

-- Wall-clock cap on any single herdr CLI call. Without this, a wedged or
-- unresponsive herdr server hangs nvim indefinitely with no Ctrl-C escape.
local CLI_TIMEOUT_MS = 2000

-- Run a herdr CLI command; return the decoded `result` table, or nil on any
-- failure. Never throws.
local function cli(args)
	local cmd = vim.list_extend({ bin() }, args)

	local spawned, proc = pcall(function()
		return vim.system(cmd, { text = true }):wait(CLI_TIMEOUT_MS)
	end)
	if not spawned then
		warn("could not run '" .. bin() .. "' (not on PATH?)")
		return nil
	end

	-- vim.system():wait(timeout) normally reports a timeout as code 124
	-- (verified against 0.12.2's vim/_core/system.lua) rather than throwing.
	-- But SIGKILL only reaches the direct child: if that child forked (a
	-- wrapper script, a mise shim, a daemonizing server), a surviving
	-- grandchild can keep stdout/stderr open, the internal uv_check that
	-- populates the result never fires, and `state.result` -- what :wait()
	-- returns -- stays nil. Reproduced live: a forking wrapper via
	-- HERDR_BIN_PATH left `proc` nil at 2x CLI_TIMEOUT_MS, and indexing
	-- `proc.code` next would throw out of cli() (and thus out of a keymap),
	-- contradicting the "Never throws" contract above. Must be checked before
	-- any `proc.*` access.
	if proc == nil then
		warn("'" .. bin() .. "' timed out after " .. CLI_TIMEOUT_MS .. "ms (no result -- possible orphaned child)")
		return nil
	end

	if proc.code == 124 then
		warn("'" .. bin() .. "' timed out after " .. CLI_TIMEOUT_MS .. "ms")
		return nil
	end

	if proc.code ~= 0 then
		warn(vim.trim(proc.stderr or "") ~= "" and vim.trim(proc.stderr) or ("exited " .. proc.code))
		return nil
	end

	-- `pane run`, `pane send-text` and `pane send-keys` succeed with no output
	-- at all; only split/list/close emit JSON. Exit 0 with empty stdout is
	-- success, so return an empty table — truthy, and distinct from the nil
	-- that signals real failure.
	if vim.trim(proc.stdout or "") == "" then
		return {}
	end

	local ok, decoded = pcall(vim.json.decode, proc.stdout)
	if not ok or type(decoded) ~= "table" or decoded.result == nil then
		warn("unexpected CLI output: " .. tostring(proc.stdout))
		return nil
	end

	return decoded.result
end

M._cli = cli -- exposed for later tasks in this module only

local function pane_exists(id)
	local result = cli({ "pane", "list" })
	if result == nil or type(result.panes) ~= "table" then
		return false
	end
	for _, pane in ipairs(result.panes) do
		if pane.pane_id == id then
			return true
		end
	end
	return false
end

-- `herdr pane read` returns plain text on stdout, not the `{"result":...}`
-- JSON every other subcommand emits -- cli() would reject it as unparseable
-- and return nil. Bypass cli() with a direct vim.system() call instead.
-- `--source recent` returns empty in testing; `--source visible` is the one
-- that works. Returns the visible pane content, or nil on any failure.
local function pane_output(id)
	local spawned, proc = pcall(function()
		return vim.system({ bin(), "pane", "read", id, "--source", "visible" }, { text = true }):wait(CLI_TIMEOUT_MS)
	end)
	if not spawned or proc == nil or proc.code ~= 0 then
		return nil
	end
	return proc.stdout
end

-- Poll a freshly split pane's visible output until it stops changing --
-- i.e. two consecutive, non-empty reads come back byte-identical, meaning
-- the shell has finished writing its startup output (direnv hook, nvm,
-- promptinit, ...) and is sitting idle at its prompt.
--
-- This is a DIFFERENT condition from pane_exists() in split_pane(): that
-- poll only confirms the pane is registered, not that the shell inside it
-- has finished sourcing ~/.zshrc. Sending input -- in particular
-- clean_prompt()'s C-c -- while sourcing is still in flight lands mid-init:
-- sometimes it kills the still-forming pane outright, sometimes zsh survives
-- having aborted partway through .zshrc, and because path.zsh resets PATH
-- wholesale early while zz-runtime.zsh restores the asdf/mise shims last (by
-- design, per its `zz-` naming), an interrupt landing between the two
-- strands the pane on the reset PATH -- system Ruby instead of the asdf
-- shim. Reproduced live, repeatedly, on the cold run()/send_lines() path.
--
-- Unlike registration, exhaustion here is NOT fatal: a slow or quiet shell
-- is probably still usable, so this warns and lets the caller proceed with
-- the pane id rather than failing the split outright.
local READINESS_TIMEOUT_MS = 5000
local READINESS_INTERVAL_MS = 100

local function wait_for_ready(id)
	local deadline = vim.uv.now() + READINESS_TIMEOUT_MS
	local previous = nil
	while true do
		local current = pane_output(id)
		if current ~= nil and current ~= "" and current == previous then
			return
		end
		previous = current
		if vim.uv.now() >= deadline then
			warn("pane '" .. id .. "' did not settle within " .. READINESS_TIMEOUT_MS .. "ms; proceeding anyway")
			return
		end
		vim.uv.sleep(READINESS_INTERVAL_MS)
	end
end

-- Runtime-manager environment variables to forward into a freshly split
-- pane, beyond PATH.
--
-- `herdr pane split` spawns its shell from the herdr *server*, not from
-- nvim -- unlike `tmux split-window`, which inherits the calling pane's
-- environment (what vim-tmux-runner relied on and why it never hit this).
-- Depending on the herdr session's own shell setup, a split pane's shell can
-- come up without nvim's environment at all: a bare, non-login prompt with
-- none of asdf's or mise's shims on PATH. Reproduced live in a session whose
-- split shells skip ~/.zshrc: `/usr/bin/bundle` (macOS system Ruby) instead
-- of the asdf-shimmed 4.0.14 the lockfile actually requires. PATH alone was
-- enough to fix that case -- it is the load-bearing entry -- but the rest of
-- this list is forwarded defensively for setups where a shim or tool
-- consults one of these directly rather than only walking PATH.
local ENV_FORWARD = {
	"ASDF_DIR",
	"ASDF_DATA_DIR",
	"ASDF_CONFIG_FILE",
	"MISE_SHELL",
	"MISE_DATA_DIR",
	"MISE_CONFIG_DIR",
	"GEM_HOME",
	"GEM_PATH",
	"BUNDLE_PATH",
	"BUNDLE_GEMFILE",
}

-- Build `--env KEY=VALUE` args for a fresh split. PATH is always forwarded,
-- verbatim: nvim's PATH can legitimately start with relative entries (e.g.
-- git-safe binstub directories), so it must not be normalised or
-- absolutised. Everything in ENV_FORWARD is forwarded only when actually set
-- and non-empty in nvim's own environment -- never emit `--env FOO=` for an
-- unset var.
local function env_args()
	local args = { "--env", "PATH=" .. (vim.env.PATH or "") }
	for _, name in ipairs(ENV_FORWARD) do
		local value = vim.env[name]
		if value ~= nil and value ~= "" then
			vim.list_extend(args, { "--env", name .. "=" .. value })
		end
	end
	return args
end

-- Split off $HERDR_PANE_ID and return the new pane id.
--
-- Two waits, for two different conditions -- do not delete either:
--
-- 1. Registration: `herdr pane split` returns a pane id before that pane is
--    actually addressable -- a send-keys/send-text fired immediately against
--    it fails with pane_not_found. Poll `pane list` until the id appears.
--    Never seeing it is a genuine failure; exhaustion returns nil.
--
-- 2. Readiness: see wait_for_ready() above for why registration alone isn't
--    enough and what goes wrong without it. Exhaustion there just warns.
--
-- Specs with any incidental delay before their first dispatch (a prior
-- assert, a prior cli() call) don't catch either race, which is why both
-- looked intermittent until tested on the genuine cold path.
local function split_pane(direction, cwd, extra)
	local args = {
		"pane",
		"split",
		vim.env.HERDR_PANE_ID,
		"--direction",
		direction,
		"--cwd",
		cwd,
	}
	vim.list_extend(args, env_args())
	vim.list_extend(args, extra or {})

	local result = cli(args)
	if result == nil or result.pane == nil or result.pane.pane_id == nil then
		return nil
	end
	local id = result.pane.pane_id

	local deadline = vim.uv.now() + 1000
	while not pane_exists(id) do
		if vim.uv.now() >= deadline then
			-- Never hand back an id we couldn't confirm is live -- a caller
			-- (M.open()) would cache it as runner_id and every subsequent call
			-- would fail against a pane that never existed as far as we know.
			warn("split pane '" .. id .. "' never became addressable")
			return nil
		end
		vim.uv.sleep(50)
	end

	wait_for_ready(id)

	return id
end

--- Return the live runner pane, splitting a new one only if none exists.
--- Second return value is true when THIS call created the pane -- a pane
--- that has never had anything sent to it cannot hold pending input, so
--- callers use this to skip clean_prompt()'s C-c on a fresh pane (see
--- clean_prompt()'s comment for why that C-c is actively destructive there).
---
--- Reuses rather than closes-and-resplits: `open()` is also what `runner()`
--- falls back to, and by the time it's called there is nothing left to close
--- (see runner()'s self-heal comment), so "reuse if live" is the only case
--- that needs handling here. It also keeps a second `:HerdrRunnerOpen` a
--- no-op instead of tearing down a pane the user may be mid-command in.
function M.open()
	if not M.available() then
		warn("not inside a herdr pane")
		return nil, false
	end

	if runner_id ~= nil and pane_exists(runner_id) then
		return runner_id, false
	end

	local id = split_pane("down", vim.fn.getcwd(), { "--ratio", "0.25", "--no-focus" })
	if id == nil then
		return nil, false
	end

	runner_id = id
	return runner_id, true
end

--- Return a live runner pane id, creating or re-creating it as needed.
--- Second return value: see M.open().
function M.runner()
	if not M.available() then
		warn("not inside a herdr pane")
		return nil, false
	end

	if runner_id ~= nil and pane_exists(runner_id) then
		return runner_id, false
	end

	-- Closed by hand since last use: drop the stale id and start over.
	runner_id = nil
	return M.open()
end

--- Ad-hoc scratch pane. Deliberately NOT cached as the runner.
function M.split(direction, cwd)
	if not M.available() then
		warn("not inside a herdr pane")
		return nil
	end
	return split_pane(direction, cwd or vim.fn.getcwd(), {})
end

--- Abort whatever is pending on a REUSED runner's prompt line before
--- dispatching a command there. Callers must only call this when M.runner()
--- reported `created == false` -- see the next paragraph for why.
---
--- `agent_send` falls back to `send_text()` against the runner whenever no
--- Claude agent is detected, parking unexecuted text on the prompt. Every
--- entry point that then dispatches a command to that same pane — `run()`
--- (`<leader>t`/`<leader>ru`/`<leader>bo`, the vim-test strategy),
--- `send_lines()` (`<leader>rs`) and `clear()` — would otherwise append to
--- that pending text and execute the concatenation instead of the intended
--- command. C-c before every dispatch to an EXISTING runner guarantees a
--- clean prompt.
---
--- A pane this same call just created cannot have pending input, so C-c
--- there is not merely unnecessary -- it is actively destructive: sent
--- before the shell has settled (see wait_for_ready()'s comment), it can
--- kill the still-forming pane outright or interrupt .zshrc mid-sourcing and
--- strand PATH on the pre-asdf/mise reset value. Reproduced live, repeatedly.
--- That's why `created` is threaded from `M.runner()` all the way to each
--- dispatch function below rather than checked in here: this function has no
--- way to tell fresh from reused on its own.
---
--- send_text() deliberately never calls this either: its entire purpose is
--- to park text on the prompt for the human to finish typing.
local function clean_prompt(id)
	cli({ "pane", "send-keys", id, "C-c" })
end

--- Send a command plus Enter to the runner.
function M.run(cmd)
	local id, created = M.runner()
	if id == nil then
		return
	end
	if not created then
		clean_prompt(id)
	end
	cli({ "pane", "run", id, cmd })
end

--- Send literal text with no trailing Enter.
function M.send_text(text)
	local id = M.runner()
	if id == nil then
		return
	end
	cli({ "pane", "send-text", id, text })
end

--- Send text and execute it.
function M.send_lines(text)
	local id, created = M.runner()
	if id == nil then
		return
	end
	if not created then
		clean_prompt(id)
	end
	if cli({ "pane", "send-text", id, text }) == nil then
		return
	end
	cli({ "pane", "send-keys", id, "Enter" })
end

--- Close the runner pane and forget it.
function M.kill()
	if not M.available() then
		warn("not inside a herdr pane")
		return
	end

	if runner_id == nil then
		return
	end
	cli({ "pane", "close", runner_id })
	runner_id = nil
end

--- Move focus into the runner. Exact because the runner is always split down.
function M.focus()
	if M.runner() == nil then
		return
	end
	cli({ "pane", "focus", "--direction", "down", "--pane", vim.env.HERDR_PANE_ID })
end

--- Clear the runner's screen.
---
--- Calls cli() directly with the already-resolved id rather than going
--- through run(), which would call M.runner() a second time for the same
--- pane.
function M.clear()
	local id, created = M.runner()
	if id == nil then
		return
	end
	if not created then
		clean_prompt(id)
	end
	cli({ "pane", "run", id, "clear" })
end

-- Pane id of a running Claude agent, or nil.
local function claude_pane()
	local result = cli({ "agent", "list" })
	if result == nil or type(result.agents) ~= "table" then
		return nil
	end
	for _, agent in ipairs(result.agents) do
		if agent.agent == "claude" then
			return agent.pane_id
		end
	end
	return nil
end

--- Send text to the detected Claude agent pane, falling back to the runner.
--- No trailing Enter: you finish typing the prompt yourself.
function M.agent_send(text)
	if not M.available() then
		warn("not inside a herdr pane")
		return
	end

	local pane = claude_pane()
	if pane == nil then
		M.send_text(text)
		return
	end

	cli({ "agent", "send", pane, text })
end

return M
