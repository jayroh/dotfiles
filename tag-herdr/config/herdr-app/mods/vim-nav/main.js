// vim-nav: Ctrl+h/j/k/l that is Vim-aware, like vim-tmux-navigator.
// keys.json binds ctrl-h/j/k/l to "vim-nav.left" etc. If the focused pane runs
// Vim/Neovim, the key is forwarded to it (Vim moves between its own splits and
// crosses back via editor/nvim.lua at an edge). Otherwise Herdr moves pane focus.
// Hosted invisibly by a layout block (see layouts/main-nav.json).
import { View, div } from "gpui-kit";
import { panes, run, hc, nextCommand } from "herdr";

const KEYS = { left: "ctrl+h", down: "ctrl+j", up: "ctrl+k", right: "ctrl+l" };
// Same matcher as vim-tmux-navigator: vi, vim, nvim, view, gvim, *diff ...
const VIM = /^g?(view|l?n?vim?x?)(diff)?$/;

function isVim(p) {
  const prog = p.program || {};
  return [prog.key, prog.name, p.app]
    .filter(Boolean)
    .some((s) => VIM.test(String(s).toLowerCase()));
}

export default class VimNav extends View {
  init(_props, cx) {
    cx.spawn(async (cx) => {
      for (;;) {
        const dir = await nextCommand();
        if (!KEYS[dir]) continue;
        const p = panes().find((x) => x.focused);
        if (p && p.terminal && isVim(p)) {
          try {
            await hc(["keys", p.terminal, KEYS[dir]]);
          } catch (e) {
            console.log("vim-nav: hc keys failed", String(e));
          }
        } else {
          run("pane.go", { direction: dir });
        }
      }
    });
  }

  // Draws nothing: the mod only listens for key commands.
  render(_cx) {
    return div();
  }
}
