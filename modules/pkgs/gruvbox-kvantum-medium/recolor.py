#!/usr/bin/env python3
"""Derive a Gruvbox-Dark-Medium Kvantum theme from gruvbox-kvantum's
Gruvbox-Dark-Brown, which is itself a partial re-color of KvAdapta.

Usage: recolor.py <src-theme-dir> <out-theme-dir>

Upstream is close to gruvbox but not the medium contrast + aqua accent this
system uses everywhere else, and it carries two real bugs (a double-hash typo,
and menubar items left in KvAdapta's blue-grey under light text). Every mapping
below was chosen by walking each color occurrence back to the element that owns
it, not by matching on the color alone.
"""

import re
import sys
from pathlib import Path

NAME = "Gruvbox-Dark-Medium"

# Gruvbox Dark, medium contrast (morhetz palette).
BG0_H = "#1d2021"
BG0 = "#282828"
BG0_S = "#32302f"
BG1 = "#3c3836"
BG2 = "#504945"
BG3 = "#665c54"
FG1 = "#ebdbb2"
AQUA = "#8ec07c"

# Surfaces drawn by the SVG. Only these four are retargeted:
#   #232323  titlebar/menubar/dock chrome        (off-palette grey)
#   #2e2e2e  button/lineedit/tooltip interiors   (off-palette grey)
#   #665c54  accent surfaces ONLY, never generic borders: itemview-pressed and
#            -toggled, button-toggled, combo-focused and -pressed, header-toggled,
#            menubaritem-pressed, tab-toggled, slider-toggled, progress-normal,
#            scrollbarslider-*, lineedit-focused, dial-handle
#   #cfd8dc  menubaritem-focused, a KvAdapta leftover that is not a gruvbox color
#
# #b74aff is deliberately untouched: Kvantum reads menu-shadow-hint-* as a shadow
# marker rather than a color to paint. The white fills on itemview-focused and
# header-focused are 5% hover tints, not surfaces, so they stay too.
SVG_COLORS = {
    "#232323": BG0,
    "#2e2e2e": BG1,
    "#665c54": AQUA,
    "#cfd8dc": AQUA,
}

# Qt palette roles, as a monotonic gruvbox ladder: dark < mid < button < midlight < light.
# Upstream shipped mid.color as "##202324" (a double-hash typo Kvantum cannot parse).
GENERAL_COLORS = {
    "window.color": BG0,
    "base.color": BG0,
    "alt.base.color": BG0,
    "dark.color": BG0_H,
    "mid.color": BG0_S,
    "button.color": BG1,
    "mid.light.color": BG2,
    "light.color": BG3,
    "highlight.color": AQUA + "cc",
    "inactive.highlight.color": AQUA + "bb",
    "highlight.text.color": BG0,
}

# Text painted on a surface that is now aqua. Upstream set these light because the
# accent used to be a dark brown; on light aqua they would be near-invisible.
ON_ACCENT_TEXT = {
    "PanelButtonCommand": ["text.toggle.color"],
    "ComboBox": ["text.focus.color", "text.press.color"],
    "HeaderSection": ["text.toggle.color"],
    "ItemView": ["text.press.color", "text.toggle.color"],
    "Tab": ["text.toggle.color"],
    "MenuBarItem": ["text.focus.color", "text.press.color"],
}

# Leftover KvAdapta color used as a text color rather than a surface.
OTHER_TEXT = {
    "Progressbar": {"text.toggle.color": FG1},
}

META = {
    "author": "sachnr, based on KvAdapta; recolored to gruvbox medium + aqua",
    "comment": "Gruvbox Dark, medium contrast (bg0 #282828) with aqua (#8ec07c) accents",
}


def recolor_svg(text):
    for old, new in SVG_COLORS.items():
        text = re.sub(re.escape(old), new, text, flags=re.IGNORECASE)
    return text


def edit_kvconfig(text):
    """Rewrite the ini section-aware: the same key means different things per section."""
    section = None
    out = []
    seen = set()

    def pending(sec):
        """Keys this section needs but did not already have."""
        want = {}
        if sec in ON_ACCENT_TEXT:
            want.update({k: BG0 for k in ON_ACCENT_TEXT[sec]})
        if sec in OTHER_TEXT:
            want.update(OTHER_TEXT[sec])
        return {k: v for k, v in want.items() if (sec, k) not in seen}

    for line in text.splitlines():
        header = re.match(r"\[(.+)\]\s*$", line)
        if header:
            # Flush any key the previous section was missing before leaving it.
            if section is not None:
                for k, v in pending(section).items():
                    out.append(f"{k}={v}")
            section = header.group(1)
            out.append(line)
            continue

        kv = re.match(r"([^=\s]+)\s*=", line)
        if kv and section is not None:
            key = kv.group(1)
            seen.add((section, key))
            new = None
            if section == "%General" and key in META:
                new = META[key]
            elif section == "GeneralColors" and key in GENERAL_COLORS:
                new = GENERAL_COLORS[key]
            elif key in ON_ACCENT_TEXT.get(section, []):
                new = BG0
            elif key in OTHER_TEXT.get(section, {}):
                new = OTHER_TEXT[section][key]
            if new is not None:
                out.append(f"{key}={new}")
                continue
        out.append(line)

    if section is not None:
        for k, v in pending(section).items():
            out.append(f"{k}={v}")
    return "\n".join(out) + "\n"


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)

    svg = next(src.glob("*.svg"))
    cfg = next(src.glob("*.kvconfig"))

    (out / f"{NAME}.svg").write_text(recolor_svg(svg.read_text()))
    (out / f"{NAME}.kvconfig").write_text(edit_kvconfig(cfg.read_text()))

    # Fail the build rather than ship a theme that silently lost its accent.
    written = (out / f"{NAME}.svg").read_text()
    for dead in SVG_COLORS:
        if re.search(re.escape(dead), written, re.IGNORECASE):
            sys.exit(f"recolor.py: {dead} survived in the SVG")
    if AQUA not in written:
        sys.exit("recolor.py: no aqua in the recolored SVG")


if __name__ == "__main__":
    main()
