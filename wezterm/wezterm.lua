-- ~/code/my-shell-my-rules/wezterm/wezterm.lua
-- Mirror of kitty/kitty.conf for WezTerm on Windows + WSL2
-- Docs: https://wezfurlong.org/wezterm/config/files.html

local wezterm = require 'wezterm'
local act     = wezterm.action
local config  = wezterm.config_builder()

-----------------------------------------------------------------------------
--                              WSL
-----------------------------------------------------------------------------

config.default_domain = 'WSL:Ubuntu-24.04'

-----------------------------------------------------------------------------
--                              Font
-----------------------------------------------------------------------------

-- MonoLisa Variable (paid) with all stylistic sets enabled
-- Falls back to Symbols Nerd Font Mono for icons (eza, starship, fzf-tab)
config.font = wezterm.font_with_fallback {
  {
    family = 'MonoLisa Variable',
    harfbuzz_features = {
      'zero', 'ss01', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08',
      'ss09', 'ss10', 'ss11', 'ss12', 'ss13', 'ss14', 'ss15', 'ss16',
      'ss17', 'ss18',
    },
  },
  { family = 'Symbols Nerd Font Mono' },
}
config.font_size = 15

-----------------------------------------------------------------------------
--                           Eldritch colorscheme
-----------------------------------------------------------------------------

config.colors = {
  foreground = '#ebfafa',
  background = '#0D1116',

  cursor_bg  = '#f94dff',
  cursor_fg  = '#0D1116',

  selection_fg = '#ebfafa',
  selection_bg = '#e9b3fd',

  ansi = {
    '#0D1116', -- black
    '#f16c75', -- red
    '#37f499', -- green
    '#9ad900', -- yellow
    '#987afb', -- blue
    '#fca6ff', -- magenta
    '#04d1f9', -- cyan
    '#ebfafa', -- white
  },
  brights = {
    '#e58f2a', -- bright black (orange)
    '#f16c75', -- bright red
    '#37f499', -- bright green
    '#9ad900', -- bright yellow
    '#987afb', -- bright blue
    '#fca6ff', -- bright magenta
    '#04d1f9', -- bright cyan
    '#ebfafa', -- bright white
  },

  -- Tab bar
  tab_bar = {
    background = '#0D1116',
    active_tab = {
      bg_color = '#37f499',
      fg_color = '#0D1116',
    },
    inactive_tab = {
      bg_color = '#0D1116',
      fg_color = '#04d1f9',
    },
    inactive_tab_hover = {
      bg_color = '#1a1f2b',
      fg_color = '#ebfafa',
    },
    new_tab = {
      bg_color = '#0D1116',
      fg_color = '#04d1f9',
    },
    new_tab_hover = {
      bg_color = '#37f499',
      fg_color = '#0D1116',
    },
  },

  -- Split borders
  split = '#987afb',
}

-----------------------------------------------------------------------------
--                              Cursor
-----------------------------------------------------------------------------

config.default_cursor_style = 'SteadyBar'
-- WezTerm uses width 1 by default for bar cursor; no sub-pixel thickness setting
config.cursor_blink_rate   = 0           -- no blinking (matches cursor_blink_interval 0)
config.force_reverse_video_cursor = false

-- TODO: cursor trail — not yet in WezTerm, tracked in PR #7737.
-- When merged, add:
--   config.cursor_trail_style = 'Torpedo'
--   config.cursor_trail_decay = { 0.01, 0.5 }

-----------------------------------------------------------------------------
--                              Window
-----------------------------------------------------------------------------

-- Hide titlebar, keep resize handles (closest to Kitty: hide_window_decorations titlebar-only)
config.window_decorations = 'RESIZE'

config.window_padding = {
  left   = '5px',
  right  = '2px',
  top    = '1px',
  bottom = '2px',
}

config.window_close_confirmation = 'NeverPrompt'   -- confirm_os_window_close 0

-- Transparency — WezTerm on Windows uses native composition
config.window_background_opacity = 0.85
-- Note: background_blur requires compositor support; on Windows this uses
-- the system acrylic/mica effect when available
config.win32_system_backdrop = 'Acrylic'

-----------------------------------------------------------------------------
--                              Scrollback
-----------------------------------------------------------------------------

config.scrollback_lines = 10000

-----------------------------------------------------------------------------
--                              Bell
-----------------------------------------------------------------------------

config.audible_bell = 'Disabled'

-----------------------------------------------------------------------------
--                              Tab bar
-----------------------------------------------------------------------------

config.enable_tab_bar       = true
config.tab_bar_at_bottom    = false
config.use_fancy_tab_bar    = false       -- retro/powerline style
config.show_tab_index_in_tab_bar = false
config.tab_max_width        = 32

-- Show last directory name in tab title (mirrors Kitty tab_title_template)
wezterm.on('format-tab-title', function(tab)
  local pane = tab.active_pane
  local cwd  = pane.current_working_dir
  if cwd then
    local path = cwd.file_path or tostring(cwd)
    local dir  = path:match('([^/\\]+)[/\\]?$') or path
    return ' ' .. dir .. ' '
  end
  return tab.active_pane.title
end)

-----------------------------------------------------------------------------
--                           Key bindings
-----------------------------------------------------------------------------
-- Kitty used Cmd on macOS; on Windows we use Ctrl+Shift as the modifier
-- and Alt for word-level navigation.

config.keys = {
  -- Reload config (Kitty: ctrl+cmd+,) — WezTerm hot-reloads automatically,
  -- but provide an explicit binding anyway
  { key = ',', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },

  -- New pane (Kitty: cmd+enter)
  { key = 'Enter', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },

  -- Navigate panes (Kitty: ctrl+shift+l/h)
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Next' },
  { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Prev' },

  -- Resize panes (Kitty: ctrl+cmd+option+hjkl)
  { key = 'h', mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Left',  3 } },
  { key = 'l', mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'k', mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Up',    3 } },
  { key = 'j', mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Down',  3 } },

  -- Close pane (Kitty: kitty_mod+w)
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = false } },

  -- New tab (Kitty: cmd+t)
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },

  -- Line navigation — send Ctrl-A / Ctrl-E for beginning/end of line
  -- (Kitty: cmd+left / cmd+right)
  { key = 'Home', mods = 'NONE', action = act.SendString '\x01' },
  { key = 'End',  mods = 'NONE', action = act.SendString '\x05' },

  -- Word navigation — send Meta-b / Meta-f (Kitty: opt+left / opt+right)
  { key = 'LeftArrow',  mods = 'ALT', action = act.SendString '\x1bb' },
  { key = 'RightArrow', mods = 'ALT', action = act.SendString '\x1bf' },

  -- Delete entire line — send Ctrl-U (Kitty: cmd+backspace)
  { key = 'Backspace', mods = 'CTRL', action = act.SendString '\x15' },

  -- Vertical split
  { key = 'v', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
}

return config
