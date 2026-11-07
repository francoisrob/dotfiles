local c = require("gruvbox")

hl.monitor({
	output = "",
	mode = "highrr",
	position = "auto",
	scale = 1,
})

hl.monitor({
	output = "desc:Dell Inc. DELL U2724DE BR2DDP3",
	mode = "2560x1440@120",
	position = "0x0",
	scale = 1,
	bitdepth = 10,
	vrr = 1,
})

hl.monitor({
	output = "desc:Dell Inc. DELL U2724D JCJK9P3",
	mode = "2560x1440@120",
	position = "2560x0",
	scale = 1,
	bitdepth = 10,
	vrr = 1,
})

hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm finalize")
end)

hl.config({
	general = {
		border_size = 1,
		gaps_in = 2,
		gaps_out = 4,
		gaps_workspaces = 10,

		col = {
			inactive_border = c.bg2,
			active_border = c.aqua,
			nogroup_border = c.red,
			nogroup_border_active = c.red,
		},

		layout = "dwindle",
		no_focus_fallback = false,
		resize_on_border = true,
		extend_border_grab_area = 15,
		hover_icon_on_border = true,
		allow_tearing = false,
		resize_corner = 0,

		snap = {
			enabled = true,
			window_gap = 15,
			monitor_gap = 15,
			border_overlap = false,
		},
	},

	decoration = {
		rounding = 5,
		rounding_power = 2.0,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.1,
		dim_special = 0.5,
		dim_around = 0.5,

		blur = {
			enabled = true,
			size = 5,
			passes = 2,
			ignore_opacity = true,
			new_optimizations = true,
			xray = false,
			noise = 0.0117,
			contrast = 0.8916,
			brightness = 0.8172,
			vibrancy = 0.1696,
			vibrancy_darkness = 0.0,
			special = true,
			popups = true,
			popups_ignorealpha = 0.2,
			input_methods = false,
			input_methods_ignorealpha = 0.2,
		},

		shadow = {
			enabled = true,
			range = 40,
			render_power = 4,
			color = "rgba(000000dd)",
			color_inactive = "rgba(00000077)",
			offset = { 0, 8 },
			scale = 0.97,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.curve("fluent_decel", { type = "bezier", points = { { 0, 0.2 }, { 0.4, 1 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.55 }, { 0.45, 1 } } })
hl.curve("easeOutCubic", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
hl.curve("easeinoutsine", { type = "bezier", points = { { 0.37, 0 }, { 0.63, 1 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.3, bezier = "easeOutCubic", style = "gnomed" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "fluent_decel", style = "gnomed" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1.5, bezier = "easeOutCirc", style = "slide" })

hl.animation({ leaf = "fadeIn", enabled = true, speed = 0.1, bezier = "easeOutCubic" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.7, bezier = "easeOutCubic" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 10, bezier = "easeOutCirc" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "fluent_decel" })
hl.animation({ leaf = "border", enabled = true, speed = 2.7, bezier = "easeOutCirc" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.3, bezier = "easeOutCubic", style = "slidefadevert" })

hl.config({
	input = {
		kb_layout = "us",
		kb_options = "caps:swapescape",

		kb_rules = "",
		numlock_by_default = true,
		repeat_rate = 30,
		repeat_delay = 250,
		scroll_method = "2fg",

		touchpad = {
			natural_scroll = true,
			drag_lock = false,
			tap_and_drag = true,
		},
	},

	dwindle = {
		smart_split = true,
		preserve_split = true,
		smart_resizing = true,
	},

	group = {
		col = {
			border_inactive = c.red,
			border_active = { colors = { c.yellow, c.aqua, c.aqua, c.yellow }, angle = 135 },
		},

		groupbar = {
			enabled = true,
			font_size = 12,
			font_family = "Ubuntu",
			text_color = c.fg1,
			height = 13,
			indicator_gap = 4,
			indicator_height = 3,
			gradients = false,
			text_offset = -1,
			gaps_in = 0,
			gaps_out = 2,
			render_titles = true,

			col = {
				active = c.green,
				inactive = c.bg1,
			},
		},
	},

	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		disable_autoreload = false,
		vrr = 2,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		enable_swallow = true,
		focus_on_activate = true,
		animate_manual_resizes = true,
		animate_mouse_windowdragging = true,
	},

	xwayland = {
		use_nearest_neighbor = true,
	},

	render = {
		direct_scanout = 0,
	},

	cursor = {
		inactive_timeout = 5,
		no_hardware_cursors = 1,
	},

	ecosystem = {
		no_donation_nag = true,
	},

	debug = {
		overlay = false,
		disable_logs = false,
		enable_stdout_logs = false,
	},
})

local mainMod = "SUPER"

hl.bind(
	mainMod .. " + Q",
	hl.dsp.exec_cmd(
		[[uwsm-app -- sh -c 'kitten @ --to unix:/tmp/kitty launch --type=os-window --cwd=current 2>/dev/null || kitty --single-instance --listen-on unix:/tmp/kitty']]
	)
)
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("uwsm stop"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("uwsm-app -- chromium"))
hl.bind(mainMod .. " + V", hl.dsp.window.float())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session $XDG_SESSION_ID"))

hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("uwsm-app -- fuzzel"))
hl.bind(
	mainMod .. " + A",
	hl.dsp.exec_cmd([[uwsm-app -- sh -c 'cliphist list | fuzzel --dmenu | cliphist decode | wl-copy']])
)

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }))

hl.bind(mainMod .. " + P", hl.dsp.window.pin())
hl.bind(mainMod .. " + O", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + T", hl.dsp.group.toggle())

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + Tab", hl.dsp.group.next())

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + space", hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + Y", hl.dsp.window.move({ workspace = "special" }))

hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grimblast --notify copy area"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("grimblast --notify copy output"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("uwsm-app -- gnome-calculator"))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/vol-step.sh up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/vol-step.sh down"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })

hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("~/.config/wayle/scripts/brightness.sh up"),
	{ repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("~/.config/wayle/scripts/brightness.sh down"),
	{ repeating = true }
)

hl.bind("ALT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
	hl.bind("l", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("h", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("k", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
	hl.bind("j", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
	hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.window_rule({
	match = { class = "(org.gnome.Calculator)", title = "(Calculator)" },
	float = true,
	size = { 400, 630 },
	center = true,
})

hl.window_rule({ match = { class = "(com.wayle.settings)" }, float = true, size = { 1300, 800 }, center = true })

hl.window_rule({
	match = { class = "(mpv)" },
	float = true,
	size = { 1280, 720 },
	center = true,
})

hl.window_rule({
	match = { class = "(org.pulseaudio.pavucontrol)", title = "(Volume Control)" },
	float = true,
	size = { 1050, 500 },
	center = true,
})

hl.window_rule({
	match = { initial_class = "chrome-nngceckbapebfimnlniiiahkandclblb-Default" },
	float = true,
	size = { 500, 600 },
	center = true,
})

hl.window_rule({
	match = { initial_class = "xdg-desktop-portal-gtk" },
	float = true,
	size = { 700, 600 },
	center = true,
})

hl.window_rule({
	match = { initial_class = "chromium-browser", initial_title = "^Sign in.*" },
	float = true,
	size = { 500, 700 },
})

hl.window_rule({
	match = { initial_class = "(Slack)", initial_title = "(Slack – Huddle)" },
	float = true,
	size = { 800, 600 },
})

hl.window_rule({ match = { workspace = "w[t1]" }, border_size = 0 })

hl.window_rule({ match = { title = "(Picture in picture)" }, float = true })

hl.window_rule({ match = { pin = true }, opacity = "1 0.7", border_size = 0 })

hl.window_rule({ match = { class = "(kitty)", title = "(Scratchpad)" }, workspace = "special" })

hl.window_rule({ match = { float = false }, no_shadow = true })

hl.window_rule({ match = { class = "(mpv)" }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { initial_class = "chromium-browser" }, idle_inhibit = "fullscreen" })

hl.window_rule({ match = { class = "(org.gnome.Calculator)" }, dim_around = true })

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.layer_rule({ match = { namespace = "wayle-bar-.*" }, blur = true })
hl.layer_rule({ match = { namespace = "wayle-bar-.*" }, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "wayle-notification-popup" }, blur = true })
hl.layer_rule({ match = { namespace = "wayle-notification-popup" }, ignore_alpha = 0.5 })

hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("hyprsunset -t 4500"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("pkill hyprsunset"))

if hl.plugin.hyprexpo ~= nil then
	hl.config({
		plugin = {
			hyprexpo = {
				columns = 3,
				gap_size = 5,
				bg_col = "rgb(1d2021)",
				workspace_method = "center current",
			},
		},
	})
end

if hl.plugin["dynamic-cursors"] ~= nil then
	hl.config({
		plugin = {
			["dynamic-cursors"] = {
				enabled = true,
				mode = "tilt",
				threshold = 2,
				shake = {
					enabled = true,
					threshold = 6.0,
					factor = 2.0,
				},
			},
		},
	})
end
