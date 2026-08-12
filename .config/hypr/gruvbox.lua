-- Gruvbox Dark, medium contrast (background bg0 = #282828)
-- Palette: https://github.com/morhetz/gruvbox
--
-- Lua port of gruvbox.conf. Returns a plain table; `require` it and index it:
--   local c = require("gruvbox")
--   c.aqua  --> "rgb(8ec07c)"
--
-- The `*_alpha` entries are the bare hex digits (no rgb() wrapper), kept for
-- parity with the old $fooAlpha variables.

return {
    -- Backgrounds (dark0_hard .. dark4)
    bg0_h       = "rgb(1d2021)",
    bg0_h_alpha = "1d2021",

    bg0         = "rgb(282828)",
    bg0_alpha   = "282828",

    bg0_s       = "rgb(32302f)",
    bg0_s_alpha = "32302f",

    bg1         = "rgb(3c3836)",
    bg1_alpha   = "3c3836",

    bg2         = "rgb(504945)",
    bg2_alpha   = "504945",

    bg3         = "rgb(665c54)",
    bg3_alpha   = "665c54",

    bg4         = "rgb(7c6f64)",
    bg4_alpha   = "7c6f64",

    -- Gray
    gray        = "rgb(928374)",
    gray_alpha  = "928374",

    -- Foregrounds (light0 .. light4)
    fg0         = "rgb(fbf1c7)",
    fg0_alpha   = "fbf1c7",

    fg1         = "rgb(ebdbb2)",
    fg1_alpha   = "ebdbb2",

    fg2         = "rgb(d5c4a1)",
    fg2_alpha   = "d5c4a1",

    fg3         = "rgb(bdae93)",
    fg3_alpha   = "bdae93",

    fg4         = "rgb(a89984)",
    fg4_alpha   = "a89984",

    -- Bright accents
    red         = "rgb(fb4934)",
    red_alpha   = "fb4934",

    green       = "rgb(b8bb26)",
    green_alpha = "b8bb26",

    yellow       = "rgb(fabd2f)",
    yellow_alpha = "fabd2f",

    blue        = "rgb(83a598)",
    blue_alpha  = "83a598",

    purple       = "rgb(d3869b)",
    purple_alpha = "d3869b",

    aqua        = "rgb(8ec07c)",
    aqua_alpha  = "8ec07c",

    orange       = "rgb(fe8019)",
    orange_alpha = "fe8019",

    -- Neutral accents
    neutral_red          = "rgb(cc241d)",
    neutral_red_alpha    = "cc241d",

    neutral_green        = "rgb(98971a)",
    neutral_green_alpha  = "98971a",

    neutral_yellow       = "rgb(d79921)",
    neutral_yellow_alpha = "d79921",

    neutral_blue         = "rgb(458588)",
    neutral_blue_alpha   = "458588",

    neutral_purple       = "rgb(b16286)",
    neutral_purple_alpha = "b16286",

    neutral_aqua         = "rgb(689d6a)",
    neutral_aqua_alpha   = "689d6a",

    neutral_orange       = "rgb(d65d0e)",
    neutral_orange_alpha = "d65d0e",
}
