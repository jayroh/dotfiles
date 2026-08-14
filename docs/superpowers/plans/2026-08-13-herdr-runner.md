# Herdr Runner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the three tmux-only pane integrations in this Neovim config (vim-tmux-runner, vimux, and four raw `tmux` keymaps) with a single herdr-native runner driven by the `herdr` CLI.

**Architecture:** One backend module (`lua/herdr/runner.lua`) owns all herdr CLI interaction and the runner pane's identity. A thin wiring layer (`lua/config/herdr.lua`) binds keymaps and user commands to it. `vim-test` reaches the same module through a registered custom strategy. Nothing else talks to the CLI.

**Tech Stack:** Lua (Neovim 0.12), `vim.system()`, `vim.json`, herdr CLI 0.7.4+, rcm/rcup, bash.

## Global Constraints

- **herdr CLI >= 0.7.4.** Every CLI invocation returns JSON on stdout shaped `{"id": ..., "result": {...}}`.
- **Neovim >= 0.12** (repo pins 0.12.2 in `.tool-versions`). `vim.system()`, `vim.json`, and `vim.fn.getregion()` are all assumed present.
- **Binary resolution:** always `$HERDR_BIN_PATH` when set and non-empty, else `herdr`. Never hardcode a path.
- **Herdr detection:** always `$HERDR_PANE_ID` set and non-empty. Never `$TMUX`.
- **No throwing.** Outside herdr, or on any CLI failure, every entry point emits one `vim.notify(..., vim.log.levels.WARN)` and returns `nil`. Startup must never break.
- **`--source visible`** for every `herdr pane read`. `--source recent` returned empty in testing.
- **Empty stdout is success.** `pane run`, `pane send-text` and `pane send-keys` exit 0 and print nothing; only `pane split`, `pane list` and `pane close` emit JSON. `cli()` must return a truthy empty table for the former and reserve `nil` for genuine failure.
- **Runner pane is always split downward** from `$HERDR_PANE_ID`. `focus()` depends on this.
- **`pane send-keys` accepts only a named allowlist** on herdr 0.7.4: `Enter`, `C-c`, `Backspace`, `Escape`, `Tab`, arrows. There is no general `C-<letter>` and no raw-input path — `C-u` is rejected with `{"error":{"code":"invalid_key"}}`.
- **Tabs, not spaces**, in Lua files — matches every existing file in `tag-nvim/`.
- **`nvim -l` skips the user config.** Verified: `nvim --headless -l script.lua` leaves `vim.g.mapleader` as `nil`. Scripts needing only the runner module use `--cmd "set rtp+=$HOME/.config/nvim" -l script.lua`; scripts needing keymaps, commands, or plugins must use `-u ~/.config/nvim/init.lua -l script.lua`.
- **No test framework.** This repo has no test suite, linter, or CI by design. Verification scripts live in the scratchpad and are never committed.

**Scratchpad:** `/private/tmp/claude-501/-Users-joel--dotfiles/23bf64eb-b87f-4ab5-8cd1-1a8a288278de/scratchpad`

**Repo root:** `/Users/joel/.dotfiles`. All paths below are relative to it.

---

## File Structure

| File | Responsibility |
|---|---|
| `tag-nvim/config/nvim/lua/herdr/runner.lua` | **new** — every herdr CLI call; owns `runner_id` |
| `tag-nvim/config/nvim/lua/config/herdr.lua` | **new** — keymaps + `:Herdr*` commands; no CLI knowledge |
| `tag-nvim/config/nvim/lua/config/tmux.lua` | **deleted** |
| `tag-nvim/config/nvim/init.lua` | `require("config.tmux")` → `require("config.herdr")` |
| `tag-nvim/config/nvim/lua/plugins/tmux.lua` | vim-tmux-runner spec removed; navigator untouched |
| `tag-nvim/config/nvim/lua/plugins/testing.lua` | vimux dropped; herdr strategy registered |
| `setup.d/herdr` | **new** — clone + link `vim-herdr-navigation` |
| `setup.d/mise` | herdr plugin-clone block removed; `mise use -g herdr` kept |
| `setup` | `./setup.d/herdr` inserted after `./setup.d/tmux` |
| `tag-herdr/` | `git add` — currently untracked |

---

### Task 1: Runner module — CLI plumbing and pane lifecycle

**Files:**
- Create: `tag-nvim/config/nvim/lua/herdr/runner.lua`
- Verify: `<scratchpad>/t1_spec.lua`

**Interfaces:**
- Consumes: nothing.
- Produces: `require("herdr.runner")` exposing `available() -> boolean`, `open() -> string|nil`, `runner() -> string|nil`, `split(direction: "down"|"right", cwd: string) -> string|nil`, `run(cmd: string)`, `kill()`. Later tasks call these by exactly these names.

- [ ] **Step 1: Write the failing verification script**

Create `<scratchpad>/t1_spec.lua`:

```lua
local runner = require("herdr.runner")

assert(runner.available(), "expected to be running inside a herdr pane")

local id = runner.runner()
assert(id, "runner() returned nil")
assert(id:match("^w%d+:p"), "unexpected pane id: " .. tostring(id))

-- Second call must reuse, not re-split.
assert(runner.runner() == id, "runner() did not cache the pane id")

runner.run("echo T1-RUNNER-OK")
vim.wait(3000)

local read = vim.system({
	"herdr", "pane", "read", id, "--source", "visible", "--lines", "30",
}, { text = true }):wait()
assert(read.stdout:match("T1%-RUNNER%-OK"), "command never landed:\n" .. read.stdout)

runner.kill()
vim.wait(1000)
local list = vim.system({ "herdr", "pane", "list" }, { text = true }):wait()
assert(not list.stdout:match(id:gsub("%p", "%%%0")), "pane survived kill(): " .. id)

print("T1 PASS")
```

- [ ] **Step 2: Run it to verify it fails**

Run from `/Users/joel/.dotfiles`, inside a herdr pane:

```bash
nvim --headless --cmd "set rtp+=$HOME/.config/nvim" -l <scratchpad>/t1_spec.lua
```

Expected: FAIL with `module 'herdr.runner' not found`.

- [ ] **Step 3: Write the module**

Create `tag-nvim/config/nvim/lua/herdr/runner.lua`:

```lua
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

-- Run a herdr CLI command; return the decoded `result` table, or nil on any
-- failure. Never throws.
local function cli(args)
	local cmd = vim.list_extend({ bin() }, args)

	local spawned, proc = pcall(function()
		return vim.system(cmd, { text = true }):wait()
	end)
	if not spawned then
		warn("could not run '" .. bin() .. "' (not on PATH?)")
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

-- Split off $HERDR_PANE_ID and return the new pane id.
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
	vim.list_extend(args, extra or {})

	local result = cli(args)
	if result == nil or result.pane == nil or result.pane.pane_id == nil then
		return nil
	end
	return result.pane.pane_id
end

--- Create the runner pane unconditionally and cache it.
function M.open()
	if not M.available() then
		warn("not inside a herdr pane")
		return nil
	end

	local id = split_pane("down", vim.fn.getcwd(), { "--ratio", "0.25", "--no-focus" })
	if id == nil then
		return nil
	end

	runner_id = id
	return runner_id
end

--- Return a live runner pane id, creating or re-creating it as needed.
function M.runner()
	if not M.available() then
		warn("not inside a herdr pane")
		return nil
	end

	if runner_id ~= nil and pane_exists(runner_id) then
		return runner_id
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

--- Send a command plus Enter to the runner.
function M.run(cmd)
	local id = M.runner()
	if id == nil then
		return
	end
	cli({ "pane", "run", id, cmd })
end

--- Close the runner pane and forget it.
function M.kill()
	if runner_id == nil then
		return
	end
	cli({ "pane", "close", runner_id })
	runner_id = nil
end

return M
```

- [ ] **Step 4: Link it and re-run**

`lua/herdr/` is a new directory, so rcm must create it before the headless run can resolve the module:

```bash
rcup -x setup -t nvim
ls -l ~/.config/nvim/lua/herdr/runner.lua
nvim --headless --cmd "set rtp+=$HOME/.config/nvim" -l <scratchpad>/t1_spec.lua
```

Expected: the symlink resolves into `.dotfiles`, and the script prints `T1 PASS`.

- [ ] **Step 5: Verify the stale-pane path**

```bash
nvim --headless --cmd "set rtp+=$HOME/.config/nvim" -l - <<'LUA'
local runner = require("herdr.runner")
local first = runner.runner()
vim.system({ "herdr", "pane", "close", first }):wait()
vim.wait(1000)
local second = runner.runner()
assert(second and second ~= first, "expected a new pane after external close")
runner.kill()
print("T1 STALE PASS")
LUA
```

Expected: `T1 STALE PASS`. This proves `runner()` self-heals rather than erroring.

- [ ] **Step 6: Verify the outside-herdr path**

```bash
env -u HERDR_PANE_ID nvim --headless --cmd "set rtp+=$HOME/.config/nvim" -l - <<'LUA'
local runner = require("herdr.runner")
assert(runner.available() == false, "available() should be false without HERDR_PANE_ID")
assert(runner.runner() == nil, "runner() should return nil, not throw")
runner.run("echo should-not-run")
print("T1 FALLBACK PASS")
LUA
```

Expected: `T1 FALLBACK PASS`, preceded by warning text. Exit code 0 — no stack trace.

- [ ] **Step 7: Commit**

```bash
git add tag-nvim/config/nvim/lua/herdr/runner.lua
git commit -m "Add herdr runner module with pane lifecycle"
```

---

### Task 2: Runner module — send, focus, clear, and Claude agent targeting

**Files:**
- Modify: `tag-nvim/config/nvim/lua/herdr/runner.lua`
- Verify: `<scratchpad>/t2_spec.lua`

**Interfaces:**
- Consumes: `cli`, `M.runner`, `M.available`, `M.run` from Task 1.
- Produces: `send_text(text: string)`, `send_lines(text: string)`, `focus()`, `clear()`, `agent_send(text: string)`.

`send_text` sends **without** a trailing Enter — this is what lets `<leader>ab` leave a half-typed prompt in the Claude pane. `send_lines` sends the text then a separate `Enter` key.

- [ ] **Step 1: Write the failing verification script**

Create `<scratchpad>/t2_spec.lua`:

```lua
local runner = require("herdr.runner")

-- send_lines executes; send_text does not.
runner.send_lines("echo T2-LINES-OK")
vim.wait(3000)

local id = runner.runner()
local function visible()
	return vim.system({
		"herdr", "pane", "read", id, "--source", "visible", "--lines", "30",
	}, { text = true }):wait().stdout
end

assert(visible():match("T2%-LINES%-OK"), "send_lines did not execute:\n" .. visible())

runner.send_text("echo T2-TEXT-PENDING")
vim.wait(2000)
local after = visible()
assert(after:match("T2%-TEXT%-PENDING"), "send_text did not appear:\n" .. after)
-- It must still be sitting unexecuted on the prompt line.
local _, occurrences = after:gsub("T2%-TEXT%-PENDING", "")
assert(occurrences == 1, "send_text appears to have executed (" .. occurrences .. " occurrences)")

runner.clear()
vim.wait(2000)
assert(not visible():match("T2%-LINES%-OK"), "clear() did not clear the pane")

runner.kill()
print("T2 PASS")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
nvim --headless --cmd "set rtp+=$HOME/.config/nvim" -l <scratchpad>/t2_spec.lua
```

Expected: FAIL with `attempt to call field 'send_lines' (a nil value)`.

- [ ] **Step 3: Add the functions**

Insert into `tag-nvim/config/nvim/lua/herdr/runner.lua`, after `M.run` and before `M.kill`:

```lua
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
	local id = M.runner()
	if id == nil then
		return
	end
	if cli({ "pane", "send-text", id, text }) == nil then
		return
	end
	cli({ "pane", "send-keys", id, "Enter" })
end
```

And after `M.kill`:

```lua
--- Move focus into the runner. Exact because the runner is always split down.
function M.focus()
	if M.runner() == nil then
		return
	end
	cli({ "pane", "focus", "--direction", "down", "--pane", vim.env.HERDR_PANE_ID })
end

--- Clear the runner's screen.
---
--- Aborts any pending input line first. `pane run` appends to whatever is
--- already typed, so clearing a prompt that still holds unexecuted text would
--- execute the concatenation instead. Reachable in practice: agent_send falls
--- back to send_text against the runner when no Claude agent is running, so
--- <leader>ab followed by <leader>rc hits exactly this.
function M.clear()
	local id = M.runner()
	if id == nil then
		return
	end
	cli({ "pane", "send-keys", id, "C-c" })
	M.run("clear")
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
```

- [ ] **Step 4: Run it to verify it passes**

```bash
nvim --headless --cmd "set rtp+=$HOME/.config/nvim" -l <scratchpad>/t2_spec.lua
```

Expected: `T2 PASS`.

- [ ] **Step 5: Verify agent targeting resolves this Claude session**

```bash
nvim --headless --cmd "set rtp+=$HOME/.config/nvim" -l - <<'LUA'
local runner = require("herdr.runner")
local result = runner._cli({ "agent", "list" })
assert(result and result.agents and #result.agents > 0, "no agents detected")
local found = false
for _, a in ipairs(result.agents) do
	if a.agent == "claude" then found = true end
end
assert(found, "no claude agent found — agent_send would fall back to the runner")
print("T2 AGENT PASS")
LUA
```

Expected: `T2 AGENT PASS`. If it fails, `agent_send` still works via fallback — note it and continue.

- [ ] **Step 6: Commit**

```bash
git add tag-nvim/config/nvim/lua/herdr/runner.lua
git commit -m "Add send, focus, clear, and agent targeting to herdr runner"
```

---

### Task 3: Keymaps and user commands

**Files:**
- Create: `tag-nvim/config/nvim/lua/config/herdr.lua`
- Delete: `tag-nvim/config/nvim/lua/config/tmux.lua`
- Modify: `tag-nvim/config/nvim/init.lua` (final line, `require("config.tmux")`)

**Interfaces:**
- Consumes: everything from Tasks 1 and 2.
- Produces: keymaps `<leader>rs`, `<leader>rn`, `<leader>rk`, `<leader>rf`, `<leader>rc`, `<leader>ru`, `<leader>bo`, `<leader>ab`, `<leader>tj`, `<leader>tl`; commands `:HerdrRunnerOpen`, `:HerdrRunnerKill`, `:HerdrRunnerFocus`, `:HerdrRunnerClear`, `:HerdrRunnerSend`.

`<leader>tv` and `<leader>th` are **dropped**: herdr has no `select-layout` equivalent.

- [ ] **Step 1: Write the failing verification script**

Create `<scratchpad>/t3_spec.lua`:

```lua
-- maparg matches the STORED lhs, so <leader> must be expanded to its actual
-- value (","). Passing the literal string "<Leader>rs" silently matches nothing.
local leader = vim.g.mapleader
assert(leader and leader ~= "", "mapleader is unset")

local expected = {
	rs = { "n", "v" },
	rn = { "n" },
	rk = { "n" },
	rf = { "n" },
	rc = { "n" },
	ru = { "n" },
	bo = { "n" },
	ab = { "n" },
	tj = { "n" },
	tl = { "n" },
}

for suffix, modes in pairs(expected) do
	local lhs = leader .. suffix
	for _, mode in ipairs(modes) do
		local map = vim.fn.maparg(lhs, mode, false, true)
		assert(map and map.lhs, ("no %s mapping in mode %s"):format(lhs, mode))
	end
end

-- The dropped layout maps must be gone.
for _, suffix in ipairs({ "tv", "th" }) do
	local lhs = leader .. suffix
	local map = vim.fn.maparg(lhs, "n", false, true)
	assert(not (map and map.lhs), lhs .. " should have been removed")
end

for _, cmd in ipairs({
	"HerdrRunnerOpen", "HerdrRunnerKill", "HerdrRunnerFocus",
	"HerdrRunnerClear", "HerdrRunnerSend",
}) do
	assert(vim.fn.exists(":" .. cmd) == 2, "missing command :" .. cmd)
end

print("T3 PASS")
```

Note this runs against the **real** config (no `-u NONE`), so it needs the full startup path.

- [ ] **Step 2: Run it to verify it fails**

```bash
nvim --headless -l <scratchpad>/t3_spec.lua
```

Expected: FAIL on `<Leader>rs` (no such mapping).

- [ ] **Step 3: Write the wiring layer**

Create `tag-nvim/config/nvim/lua/config/herdr.lua`:

```lua
-- Keymaps and commands for the herdr runner pane.
--
-- Replaces lua/config/tmux.lua (raw `tmux` shell-outs) and the vim-tmux-runner
-- keymaps that used to live in lua/plugins/tmux.lua.

local runner = require("herdr.runner")

-- Visual selection, or the current line in normal mode.
local function selected_text()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		return table.concat(lines, "\n")
	end
	return vim.api.nvim_get_current_line()
end

-- Runner
vim.keymap.set({ "n", "v" }, "<leader>rs", function()
	runner.send_lines(selected_text())
end, { desc = "Send selection/line to herdr runner" })

vim.keymap.set("n", "<leader>rn", function()
	runner.open()
end, { desc = "Open herdr runner" })

vim.keymap.set("n", "<leader>rk", function()
	runner.kill()
end, { desc = "Kill herdr runner" })

vim.keymap.set("n", "<leader>rf", function()
	runner.focus()
end, { desc = "Focus herdr runner" })

vim.keymap.set("n", "<leader>rc", function()
	runner.clear()
end, { desc = "Clear herdr runner" })

-- Rubocop
vim.keymap.set("n", "<leader>ru", function()
	runner.run("rubocop -A")
end, { desc = "Run rubocop -A" })

vim.keymap.set("n", "<leader>bo", function()
	runner.run("rubocop -A " .. vim.fn.expand("%"))
end, { desc = "Run rubocop -A against this file" })

-- Claude Code: drop the @path in without executing, so you can finish the prompt.
vim.keymap.set("n", "<leader>ab", function()
	runner.agent_send("@./" .. vim.fn.expand("%") .. " ")
end, { desc = "Add full path, with @, to Claude Code" })

-- Ad-hoc scratch panes (not the runner)
vim.keymap.set("n", "<leader>tj", function()
	runner.split("down", vim.fn.expand("%:p:h"))
end, { desc = "Open herdr pane below in current directory" })

vim.keymap.set("n", "<leader>tl", function()
	runner.split("right", vim.fn.expand("%:p:h"))
end, { desc = "Open herdr pane to the right in current directory" })

-- Commands
vim.api.nvim_create_user_command("HerdrRunnerOpen", function()
	runner.open()
end, { desc = "Open the herdr runner pane" })

vim.api.nvim_create_user_command("HerdrRunnerKill", function()
	runner.kill()
end, { desc = "Close the herdr runner pane" })

vim.api.nvim_create_user_command("HerdrRunnerFocus", function()
	runner.focus()
end, { desc = "Focus the herdr runner pane" })

vim.api.nvim_create_user_command("HerdrRunnerClear", function()
	runner.clear()
end, { desc = "Clear the herdr runner pane" })

vim.api.nvim_create_user_command("HerdrRunnerSend", function(opts)
	runner.run(opts.args)
end, { nargs = "+", desc = "Send a command to the herdr runner pane" })
```

- [ ] **Step 4: Delete the tmux config and repoint init.lua**

```bash
git rm tag-nvim/config/nvim/lua/config/tmux.lua
```

In `tag-nvim/config/nvim/init.lua`, change the last line:

```lua
require("config.tmux")
```

to:

```lua
require("config.herdr")
```

- [ ] **Step 5: Relink and run the verification**

```bash
rcup -x setup -t nvim
nvim --headless -l <scratchpad>/t3_spec.lua
```

Expected: `T3 PASS`.

If it fails on `<Leader>tv`/`<Leader>th` still existing, the stale `~/.config/nvim/lua/config/tmux.lua` symlink is still being sourced — that is Task 6's prune step; note it and move on.

- [ ] **Step 6: Verify the send path end to end**

In a herdr pane, open a real file and check the runner receives a selection:

```bash
nvim --headless -c 'lua require("herdr.runner").send_lines("echo T3-SEND-OK")' -c 'sleep 3' -c qa
herdr pane list | jq -r '.result.panes[].pane_id'
```

Then read the newest pane and confirm `T3-SEND-OK` appears:

```bash
herdr pane read <newest-pane-id> --source visible --lines 20
herdr pane close <newest-pane-id>
```

- [ ] **Step 7: Commit**

```bash
git add tag-nvim/config/nvim/lua/config/herdr.lua tag-nvim/config/nvim/init.lua
git commit -m "Replace tmux keymaps with herdr runner keymaps and commands"
```

---

### Task 4: Cut vim-tmux-runner and point vim-test at herdr

**Files:**
- Modify: `tag-nvim/config/nvim/lua/plugins/tmux.lua` (remove the second spec, lines 20–44)
- Modify: `tag-nvim/config/nvim/lua/plugins/testing.lua`

**Interfaces:**
- Consumes: `require("herdr.runner").run` and `.available` from Tasks 1–2.
- Produces: global vimscript function `HerdrTestStrategy(cmd)`; `g:test#custom_strategies.herdr`; `g:test#strategy`.

`g:test#custom_strategies` must be a dict of **funcrefs**, so it is built in vimscript — a Lua table holding a funcref does not round-trip through `vim.g`. Extension point confirmed at `vim-test/autoload/test.vim:111`.

- [ ] **Step 1: Write the failing verification script**

Create `<scratchpad>/t4_spec.lua`:

```lua
assert(vim.fn.exists("*HerdrTestStrategy") == 1, "HerdrTestStrategy not defined")

local strategies = vim.g["test#custom_strategies"]
assert(type(strategies) == "table", "g:test#custom_strategies is not a dict")
assert(strategies.herdr ~= nil, "herdr strategy not registered")

local in_herdr = vim.env.HERDR_PANE_ID ~= nil and vim.env.HERDR_PANE_ID ~= ""
local want = in_herdr and "herdr" or "basic"
assert(vim.g["test#strategy"] == want,
	("test#strategy is %q, expected %q"):format(tostring(vim.g["test#strategy"]), want))

-- vim-tmux-runner must be gone; vim-tmux-navigator must remain.
local lazy = require("lazy.core.config").plugins
assert(lazy["vim-tmux-runner"] == nil, "vim-tmux-runner is still in the lazy spec")
assert(lazy["vimux"] == nil, "vimux is still in the lazy spec")
assert(lazy["vim-tmux-navigator"] ~= nil, "vim-tmux-navigator should have been kept")

print("T4 PASS")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
nvim --headless -u ~/.config/nvim/init.lua -l <scratchpad>/t4_spec.lua
```

Expected: FAIL with `HerdrTestStrategy not defined`.

- [ ] **Step 3: Remove the vim-tmux-runner spec**

In `tag-nvim/config/nvim/lua/plugins/tmux.lua`, delete the entire second table (the `"christoomey/vim-tmux-runner"` entry and its `keys` block), leaving the file as:

```lua
-- vim-herdr-navigation supersedes vim-tmux-navigator's mappings when present:
-- it handles herdr panes and falls back to tmux itself. Guarded so machines
-- without the herdr plugin keep vim-tmux-navigator's own mappings.
local herdr_nav = vim.fn.expand("~/.config/herdr/vim-herdr-navigation/editor/nvim.lua")
local has_herdr_nav = vim.uv.fs_stat(herdr_nav) ~= nil

return {
	{
		"christoomey/vim-tmux-navigator",
		lazy = false,
		init = function()
			vim.g.tmux_navigator_no_mappings = has_herdr_nav and 1 or nil
		end,
		config = function()
			if has_herdr_nav then
				dofile(herdr_nav)
			end
		end,
	},
}
```

- [ ] **Step 4: Rewrite the vim-test spec**

Replace `tag-nvim/config/nvim/lua/plugins/testing.lua` entirely:

```lua
return {
	"vim-test/vim-test",
	config = function()
		vim.keymap.set("n", "<leader>t", ":TestNearest<CR>", {})
		vim.keymap.set("n", "<leader>T", ":TestFile<CR>", {})
		vim.keymap.set("n", "<leader>a", ":TestSuite<CR>", {})
		vim.keymap.set("n", "<leader>l", ":TestLast<CR>", {})
		vim.keymap.set("n", "<leader>g", ":TestVisit<CR>", {})

		-- vim-test dispatches through g:test#custom_strategies, a dict of
		-- funcrefs — built in vimscript because a Lua table holding a funcref
		-- does not round-trip through vim.g.
		vim.cmd([[
			function! HerdrTestStrategy(cmd) abort
				call luaeval('require("herdr.runner").run(_A)', a:cmd)
			endfunction

			let g:test#custom_strategies = get(g:, 'test#custom_strategies', {})
			let g:test#custom_strategies['herdr'] = function('HerdrTestStrategy')
		]])

		-- Outside herdr fall back to vim-test's built-in strategy rather than
		-- silently sending tests nowhere.
		vim.g["test#strategy"] = require("herdr.runner").available() and "herdr" or "basic"
	end,
}
```

The `dependencies = { "preservim/vimux" }` block is gone — vimux was the tmux-only transport this replaces.

- [ ] **Step 5: Run the verification**

```bash
nvim --headless -u ~/.config/nvim/init.lua -l <scratchpad>/t4_spec.lua
```

Expected: `T4 PASS`.

- [ ] **Step 6: Verify a real test run reaches a herdr pane**

From a Ruby project directory inside a herdr pane (or any dir — the command text is what matters):

```bash
nvim --headless -c 'lua vim.fn["HerdrTestStrategy"]("echo T4-STRATEGY-OK")' -c 'sleep 3' -c qa
```

Then find the newest pane and confirm:

```bash
herdr pane list | jq -r '.result.panes[-1].pane_id'
herdr pane read <that-id> --source visible --lines 20   # expect T4-STRATEGY-OK
herdr pane close <that-id>
```

- [ ] **Step 7: Verify the non-herdr fallback**

```bash
env -u HERDR_PANE_ID nvim --headless -u ~/.config/nvim/init.lua -l <scratchpad>/t4_spec.lua
```

Expected: `T4 PASS` — with `test#strategy` resolving to `basic` this time.

- [ ] **Step 8: Commit**

```bash
git add tag-nvim/config/nvim/lua/plugins/tmux.lua tag-nvim/config/nvim/lua/plugins/testing.lua
git commit -m "Drop vim-tmux-runner and vimux, route vim-test through herdr"
```

---

### Task 5: Provision the nav plugin on every machine

**Files:**
- Create: `setup.d/herdr`
- Modify: `setup.d/mise` (remove the plugin-clone block; keep the `mise use -g herdr` pin)
- Modify: `setup` (insert `./setup.d/herdr` after `./setup.d/tmux`)
- Add: `tag-herdr/` (currently untracked)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `~/.config/herdr/vim-herdr-navigation` present and registered with herdr — the path `lua/plugins/tmux.lua` probes via `vim.uv.fs_stat`.

Fixes four defects in commit `caeaf1a`: the clone guard is inverted (`-d` where `! -d` was meant, so `git clone` targets a non-empty dir and aborts `./setup` under `set -e`); the clone sits inside `! command -v herdr`, which is already false on macOS because `setup.d/mac` brew-installs herdr earlier in the orchestrator; nothing calls `herdr plugin link`; and `setup.d/mise` exits early on asdf machines, so none of it runs there at all.

- [ ] **Step 1: Write the failing verification**

```bash
test -x setup.d/herdr && echo "EXISTS" || echo "T5 FAIL: setup.d/herdr missing"
```

Expected: `T5 FAIL: setup.d/herdr missing`.

- [ ] **Step 2: Write the script**

Create `setup.d/herdr`:

```bash
#!/bin/bash
# Install the vim-herdr-navigation plugin and register it with herdr.
#
# herdr itself is not this script's job: macOS gets it from the Brewfile, Linux
# from the `mise use -g herdr` pin in setup.d/mise. This script only provisions
# the plugin, so it no-ops when herdr is absent.
#
# Deliberately standalone rather than folded into setup.d/mise: that script
# exits early on asdf machines, which would leave them without the plugin.
set -e

PLUGIN_REPO="https://github.com/paulbkim-dev/vim-herdr-navigation.git"
PLUGIN_DIR="$HOME/.config/herdr/vim-herdr-navigation"

if ! command -v herdr &>/dev/null; then
  echo "⏭️  herdr not found on PATH — skipping vim-herdr-navigation."
  exit 0
fi

if [[ -d "$PLUGIN_DIR/.git" ]]; then
  echo "Updating vim-herdr-navigation ..."
  git -C "$PLUGIN_DIR" pull --ff-only || echo "   (local changes — skipping update)"
else
  echo "Cloning vim-herdr-navigation ..."
  mkdir -p "$(dirname "$PLUGIN_DIR")"
  git clone "$PLUGIN_REPO" "$PLUGIN_DIR"
fi

# Idempotent: repairs a clone that was never registered. Verified against herdr
# 0.7.4 — re-linking an already-linked plugin exits 0 with a plugin_linked
# payload, so there is nothing to tolerate here. Left unguarded deliberately: a
# genuine link failure (bad manifest, permissions) must abort ./setup under
# `set -e` rather than be swallowed and reported as success.
herdr plugin link "$PLUGIN_DIR"

echo "✅ vim-herdr-navigation linked."
```

Make it executable:

```bash
chmod +x setup.d/herdr
```

- [ ] **Step 3: Run it twice to prove idempotence**

```bash
./setup.d/herdr && ./setup.d/herdr
echo "exit=$?"
```

Expected: both runs exit 0. The second prints the "Updating" branch, not "Cloning". `exit=0`.

- [ ] **Step 4: Strip the broken block from setup.d/mise**

In `setup.d/mise`, replace:

```bash
if ! command -v herdr &>/dev/null; then
  mise use -g herdr

  if [[ -d "$HOME/.config/herdr/vim-herdr-navigation" ]]; then
    mkdir -p ~/.config/herdr
    git clone https://github.com/paulbkim-dev/vim-herdr-navigation.git ~/.config/herdr/vim-herdr-navigation
  fi
fi
```

with:

```bash
# The nav plugin is provisioned by setup.d/herdr, which also runs on asdf
# machines (this script does not).
if ! command -v herdr &>/dev/null; then
  mise use -g herdr
fi
```

- [ ] **Step 5: Add the step to the orchestrator**

In `setup`, insert after the `./setup.d/tmux` line:

```bash
./setup.d/herdr
```

Final order in that block:

```bash
./setup.d/neovim
./setup.d/tmux
./setup.d/herdr
./setup.d/omarchy
./setup.d/prune   # clear symlinks orphaned by deleted/renamed files, then relink
./setup.d/rcup
```

- [ ] **Step 6: Track tag-herdr**

```bash
git add tag-herdr/
git status --short tag-herdr/
```

Expected: `A  tag-herdr/config/herdr/config.toml`. `setup.d/rcup` already lists `-t herdr`, so no change is needed there.

- [ ] **Step 7: Verify the plugin is registered**

```bash
herdr plugin list
```

Expected: `vim-herdr-navigation (Vim Herdr Navigation) enabled [local:/Users/joel/.config/herdr/vim-herdr-navigation]`.

- [ ] **Step 8: Commit**

```bash
git add setup setup.d/herdr setup.d/mise tag-herdr/
git commit -m "Provision vim-herdr-navigation from its own setup step"
```

---

### Task 6: Prune stale symlinks and verify the whole config

**Files:**
- No source changes. Runs `setup.d/prune`, `rcup`, and a full-startup check.

**Interfaces:**
- Consumes: every prior task.
- Produces: a clean `~/.config/nvim` with no dangling links.

Deleting `lua/config/tmux.lua` in Task 3 strands `~/.config/nvim/lua/config/tmux.lua`. `lua/config/` is not directory-enumerated the way `lua/plugins/` is, so this is a dead symlink rather than a broken startup — but it must still be cleared, on this machine and every other one.

- [ ] **Step 1: Confirm the stale link exists**

```bash
ls -l ~/.config/nvim/lua/config/tmux.lua
```

Expected: a symlink into `.dotfiles` whose target no longer exists (`ls` shows it; `test -e` fails).

```bash
test -e ~/.config/nvim/lua/config/tmux.lua && echo "target exists" || echo "DANGLING (expected)"
```

- [ ] **Step 2: Preview the prune**

```bash
./setup.d/prune --dry-run
```

Expected: lists `~/.config/nvim/lua/config/tmux.lua` among the symlinks it would remove.

- [ ] **Step 3: Prune and relink**

```bash
./setup.d/prune
rcup -x setup -t nvim -t herdr
```

- [ ] **Step 4: Verify the link state**

```bash
test -e ~/.config/nvim/lua/config/tmux.lua && echo "T6 FAIL: still present" || echo "T6 pruned OK"
ls -l ~/.config/nvim/lua/herdr/runner.lua ~/.config/nvim/lua/config/herdr.lua
ls -l ~/.config/herdr/config.toml
```

Expected: `T6 pruned OK`, and all three symlinks resolve into `/Users/joel/.dotfiles`.

- [ ] **Step 5: Full startup check**

```bash
nvim --headless -c 'echo "startup ok"' -c qa
echo "exit=$?"
```

Expected: `exit=0`, no error output, no lazy.nvim import failure.

- [ ] **Step 6: Re-run every task's verification against the final config**

t1/t2 need only the runner module; t3/t4 need the full config, so they must be
launched with `-u` (`nvim -l` alone skips the user config entirely):

```bash
for t in t1 t2; do
  echo "--- $t ---"
  nvim --headless --cmd "set rtp+=$HOME/.config/nvim" -l <scratchpad>/${t}_spec.lua || echo "$t FAILED"
done
for t in t3 t4; do
  echo "--- $t ---"
  nvim --headless -u ~/.config/nvim/init.lua -l <scratchpad>/${t}_spec.lua || echo "$t FAILED"
done
```

Expected: `T1 PASS`, `T2 PASS`, `T3 PASS`, `T4 PASS`.

- [ ] **Step 7: Interactive smoke test**

Open nvim in a herdr pane by hand and confirm:

1. `<leader>rn` splits a pane below at roughly a quarter height, focus stays in nvim.
2. `<leader>rs` on a line sends and executes it.
3. Visual-select three lines, `<leader>rs` — all three arrive.
4. `<leader>rf` moves focus down; `Ctrl+k` returns to nvim (proves the nav plugin still works).
5. `<leader>rc` clears; `<leader>rk` closes.
6. `<leader>ab` puts `@./<path> ` in the Claude pane **without** submitting.
7. `<leader>t` in a spec file runs the nearest test in the runner.
8. `<leader>tj` / `<leader>tl` open scratch panes and do **not** disturb the runner.

- [ ] **Step 8: Commit any fixes and update CLAUDE.md**

`CLAUDE.md` documents the editor architecture and setup steps. Add `setup.d/herdr` to the setup-scripts table and note that the runner is herdr-native:

```markdown
| `setup.d/herdr` | Clone `vim-herdr-navigation` into `~/.config/herdr/` and `herdr plugin link` it. No-ops when `herdr` is absent. |
```

Then:

```bash
git add CLAUDE.md
git commit -m "Document the herdr setup step"
```

---

## Self-Review

**Spec coverage:** every section maps to a task — module (1, 2), keymaps (3), vim-test and VTR removal (4), provisioning/`setup.d/herdr`/package lists/`tag-herdr` (5), prune and verification (6). The spec's "Out of scope" items (`<leader>t` prefix delay, `<leader>ro`'s tmux nag, a keymap for `pane read`) are correctly absent.

**Placeholders:** none. Every code step carries complete source; every run step carries an exact command and expected output.

**Type consistency:** `runner()`, `open()`, `split(direction, cwd)`, `run(cmd)`, `send_text(text)`, `send_lines(text)`, `kill()`, `focus()`, `clear()`, `agent_send(text)`, `available()` are used identically in Tasks 3 and 4 to how Tasks 1 and 2 define them. `M._cli` is used only by Task 2's Step 5 check.

**Known risk:** `herdr plugin link` on an already-linked plugin is untested; Task 5 tolerates failure rather than aborting. Task 5 Step 3 confirms the real behaviour.
