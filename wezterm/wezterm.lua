local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font 'JetBrains Mono'
config.default_prog = { 'wsl.exe', '~' }

-- Устанавливаем выбранную тему
config.color_scheme = 'Adventure'

config.window_background_opacity = 0.9
config.use_fancy_tab_bar = false

return config
