#!/usr/bin/env python3
"""Generate Tempo app icon SVG/PNG assets from Instrument Serif Italic T."""

from __future__ import annotations

import sys
from pathlib import Path

from fontTools.misc.transform import Transform
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
FONT_CANDIDATES = [
    ROOT / "fonts" / "InstrumentSerif-Italic.ttf",
    Path("/tmp/InstrumentSerif-Italic.ttf"),
]
FONT_DOWNLOAD_URL = (
    "https://github.com/google/fonts/raw/main/ofl/instrumentserif/"
    "InstrumentSerif-Italic.ttf"
)
ICONS_DIR = ROOT / "assets" / "icons"
BRAND_DIR = ICONS_DIR / "brand"
SIYUAN_ICON = ROOT / "siyuan-plugin" / "icon.png"

CANVAS = 1024
# Editorial proportions: smaller mark, generous margins (Stripe-like restraint).
TARGET_HEIGHT_RATIO = 0.36
# Subtle inset panel — matches AppTheme bgSubtle / borderStrong.
PANEL_SIZE_RATIO = 0.74
PANEL_RADIUS = 168
PANEL_FILL = "#FAFAFA"
PANEL_STROKE = "#E4E4E7"
PANEL_STROKE_WIDTH = 2
FG_COLOR = "#0A0A0A"
BG_COLOR = "#FFFFFF"


def resolve_font() -> Path:
    for candidate in FONT_CANDIDATES:
        if not candidate.exists():
            continue
        try:
            TTFont(str(candidate))
            return candidate
        except Exception:
            continue

    cache = Path("/tmp/InstrumentSerif-Italic.ttf")
    if not cache.exists():
        import urllib.request

        print(f"Downloading Instrument Serif Italic to {cache} ...")
        urllib.request.urlretrieve(FONT_DOWNLOAD_URL, cache)

    TTFont(str(cache))
    return cache


def panel_rect() -> tuple[float, float, float, float]:
    size = CANVAS * PANEL_SIZE_RATIO
    origin = (CANVAS - size) / 2
    return origin, origin, size, size


def panel_svg(include_fill: bool) -> str:
    x, y, w, h = panel_rect()
    fill = f'fill="{PANEL_FILL}"' if include_fill else 'fill="none"'
    return (
        f'  <rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" '
        f'rx="{PANEL_RADIUS}" ry="{PANEL_RADIUS}" '
        f'{fill} stroke="{PANEL_STROKE}" stroke-width="{PANEL_STROKE_WIDTH}"/>\n'
    )


def transformed_bounds(
    glyph_set,
    glyph_name: str,
    transform: Transform,
) -> tuple[float, float, float, float]:
    bounds_pen = BoundsPen(glyph_set)
    glyph_set[glyph_name].draw(TransformPen(bounds_pen, transform))
    return bounds_pen.bounds


def glyph_to_path(font_path: Path, char: str = "T") -> tuple[str, tuple[float, float, float, float]]:
    font = TTFont(str(font_path))
    glyph_set = font.getGlyphSet()
    cmap = font.getBestCmap()
    code = ord(char)
    if code not in cmap:
        raise ValueError(f"Character {char!r} not found in font cmap")
    glyph_name = cmap[code]
    if isinstance(glyph_name, int):
        glyph_name = font.getGlyphName(glyph_name)

    bounds_pen = BoundsPen(glyph_set)
    glyph_set[glyph_name].draw(bounds_pen)
    x_min, y_min, x_max, y_max = bounds_pen.bounds

    target_height = CANVAS * TARGET_HEIGHT_RATIO
    scale = target_height / (y_max - y_min)
    cx = (x_min + x_max) / 2
    cy = (y_min + y_max) / 2

    scaled = Transform().scale(scale, -scale).translate(-cx, -cy)
    bx_min, by_min, bx_max, by_max = transformed_bounds(glyph_set, glyph_name, scaled)
    bcx = (bx_min + bx_max) / 2
    bcy = (by_min + by_max) / 2

    transform = Transform().translate(
        CANVAS / 2 - bcx,
        CANVAS / 2 - bcy,
    ).transform(scaled)
    transform = refine_transform_for_visual_center(
        glyph_set,
        glyph_name,
        transform,
        include_panel=False,
        panel_fill=False,
    )

    svg_pen = SVGPathPen(glyph_set)
    tpen = TransformPen(svg_pen, transform)
    glyph_set[glyph_name].draw(tpen)
    return svg_pen.getCommands(), (x_min, y_min, x_max, y_max)


def write_svg(
    path: Path,
    path_data: str,
    *,
    include_background: bool,
    include_panel: bool,
    panel_fill: bool,
) -> None:
    bg_rect = (
        f'  <rect width="{CANVAS}" height="{CANVAS}" fill="{BG_COLOR}"/>\n'
        if include_background
        else ""
    )
    panel = panel_svg(panel_fill) if include_panel else ""
    svg = (
        f'<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{CANVAS}" height="{CANVAS}" viewBox="0 0 {CANVAS} {CANVAS}">\n'
        f"{bg_rect}"
        f"{panel}"
        f'  <path fill="{FG_COLOR}" d="{path_data}"/>\n'
        f"</svg>\n"
    )
    path.write_text(svg, encoding="utf-8")


def write_monochrome_svg(path: Path, path_data: str) -> None:
    svg = (
        f'<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{CANVAS}" height="{CANVAS}" viewBox="0 0 {CANVAS} {CANVAS}">\n'
        f'  <path fill="#000000" d="{path_data}"/>\n'
        f"</svg>\n"
    )
    path.write_text(svg, encoding="utf-8")


def svg_to_png(svg_path: Path, png_path: Path, size: int) -> None:
    import cairosvg

    png_path.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        url=str(svg_path),
        write_to=str(png_path),
        output_width=size,
        output_height=size,
    )


def png_centroid(png_path: Path) -> tuple[float, float]:
    from PIL import Image

    img = Image.open(png_path).convert("L")
    pixels = img.load()
    width, height = img.size
    total = 0.0
    sum_x = 0.0
    sum_y = 0.0

    for y in range(height):
        for x in range(width):
            # Only the mark itself, not the inset panel fill.
            if pixels[x, y] > 128:
                continue
            weight = 255 - pixels[x, y]
            total += weight
            sum_x += x * weight
            sum_y += y * weight

    if total == 0:
        return width / 2, height / 2
    return sum_x / total, sum_y / total


def refine_transform_for_visual_center(
    glyph_set,
    glyph_name: str,
    transform: Transform,
    *,
    include_panel: bool,
    panel_fill: bool,
) -> Transform:
    import tempfile

    tmp_svg = Path(tempfile.gettempdir()) / "tempo_icon_centroid.svg"
    tmp_png = Path(tempfile.gettempdir()) / "tempo_icon_centroid.png"

    svg_pen = SVGPathPen(glyph_set)
    glyph_set[glyph_name].draw(TransformPen(svg_pen, transform))
    write_svg(
        tmp_svg,
        svg_pen.getCommands(),
        include_background=False,
        include_panel=include_panel,
        panel_fill=panel_fill,
    )
    svg_to_png(tmp_svg, tmp_png, CANVAS)
    cx, cy = png_centroid(tmp_png)

    return Transform().translate(CANVAS / 2 - cx, CANVAS / 2 - cy).transform(transform)


def main() -> int:
    try:
        import cairosvg  # noqa: F401
    except ImportError:
        print("Install cairosvg: pip install cairosvg", file=sys.stderr)
        return 1

    font_path = resolve_font()
    print(f"Using font: {font_path}")

    path_data, _bounds = glyph_to_path(font_path, "T")

    ICONS_DIR.mkdir(parents=True, exist_ok=True)
    BRAND_DIR.mkdir(parents=True, exist_ok=True)

    master_svg = ICONS_DIR / "app_icon.svg"
    foreground_svg = ICONS_DIR / "app_icon_foreground.svg"
    monochrome_svg = ICONS_DIR / "app_icon_monochrome.svg"

    write_svg(
        master_svg,
        path_data,
        include_background=True,
        include_panel=True,
        panel_fill=True,
    )
    write_svg(
        foreground_svg,
        path_data,
        include_background=False,
        include_panel=True,
        panel_fill=True,
    )
    write_monochrome_svg(monochrome_svg, path_data)
    print(f"Wrote {master_svg}")
    print(f"Wrote {foreground_svg}")
    print(f"Wrote {monochrome_svg}")

    exports: list[tuple[Path, Path, int]] = [
        (master_svg, ICONS_DIR / "app_icon_1024.png", 1024),
        (foreground_svg, ICONS_DIR / "app_icon_foreground.png", 1024),
        (monochrome_svg, ICONS_DIR / "app_icon_monochrome.png", 1024),
        (master_svg, SIYUAN_ICON, 160),
        (master_svg, BRAND_DIR / "favicon-32.png", 32),
        (master_svg, BRAND_DIR / "favicon-192.png", 192),
        (master_svg, BRAND_DIR / "macos_1024.png", 1024),
    ]

    for svg, png, size in exports:
        svg_to_png(svg, png, size)
        print(f"Wrote {png} ({size}x{size})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
