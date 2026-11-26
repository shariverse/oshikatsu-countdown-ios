#!/usr/bin/env python3
"""着せ替えのアプリアイコン（推し色の 12 色）のうち、代替アイコン 11 色の Icon Composer のファイルを作り直す。

今のアイコン（OshiCon/AppIcon.icon。ピンクの地に白いハート）を写し、地の色とダークの外観の色だけを替えて
OshiCon/AlternateAppIcons/AppIcon-<色>.icon に書く。図柄（Assets/heart.svg）・影・透け方は今のアイコンのまま。

色の正はアプリの `AppIconPalette`（OshiCon/Appearance/AppIcon.swift）。この表を変えたら、そちらも同じ値にする
（`AppIconTests` が、ここで作ったファイルとアプリの表の食い違いを見つける）。
ダークの外観は今のアイコンと同じ考え方で、暗い地に淡い推し色のハートにする。OKLCH で、
地は明るさ 0.19・彩度は推し色の 0.18 倍（0.035 まで）、ハートは明るさ 0.84・彩度は推し色の 0.8 倍（0.095 まで）、色相は推し色のまま。

使い方: リポジトリの最上位で `python3 scripts/make-alternate-app-icons.py`
"""

import json
import pathlib
import shutil

REPOSITORY = pathlib.Path(__file__).resolve().parent.parent
PRIMARY = REPOSITORY / "OshiCon" / "AppIcon.icon"
DESTINATION = REPOSITORY / "OshiCon" / "AlternateAppIcons"

# 代替アイコンの名前: (ライトの地 = 推し色, ダークの地, ダークのハート)
ICONS = {
    "AppIcon-Red": ("D0352B", "210D0B", "FFB5AA"),
    "AppIcon-Orange": ("B45A0E", "1D1109", "FDBA91"),
    "AppIcon-Yellow": ("8A6D00", "171309", "E1C986"),
    "AppIcon-Green": ("1A7A50", "0C1711", "99DCB6"),
    "AppIcon-Mint": ("0E7C86", "0B1617", "92D8E1"),
    "AppIcon-Blue": ("2F6FD6", "0B1422", "ACCCFF"),
    "AppIcon-Navy": ("3B4BB8", "0F1322", "B8C8FF"),
    "AppIcon-Purple": ("7A4BD0", "151022", "CEBFFF"),
    "AppIcon-Lavender": ("A23FB0", "1B0E1D", "E9B6EF"),
    "AppIcon-Brown": ("6B5B4B", "161311", "D6C8B9"),
    "AppIcon-Black": ("3A3842", "141315", "CBC9D3"),
}


def solid(hex_color: str) -> dict:
    """Icon Composer の単色（`srgb:r,g,b,a`。小数 5 桁）。"""
    channels = [int(hex_color[index:index + 2], 16) / 255 for index in (0, 2, 4)]
    return {"solid": "srgb:" + ",".join(f"{value:.5f}" for value in [*channels, 1.0])}


def make_icon(primary: dict, light: str, dark_ground: str, dark_heart: str) -> dict:
    icon = json.loads(json.dumps(primary))
    icon["fill-specializations"] = [
        {"value": solid(light)},
        {"appearance": "dark", "value": solid(dark_ground)},
    ]
    (heart,) = icon["groups"][0]["layers"]
    heart["fill-specializations"] = [{"appearance": "dark", "value": solid(dark_heart)}]
    return icon


def main() -> None:
    primary = json.loads((PRIMARY / "icon.json").read_text())
    if DESTINATION.exists():
        shutil.rmtree(DESTINATION)
    for name, (light, dark_ground, dark_heart) in ICONS.items():
        bundle = DESTINATION / f"{name}.icon"
        shutil.copytree(PRIMARY / "Assets", bundle / "Assets")
        # 図柄はそのまま。地の色の注記だけ、その色に合わせる
        svg = bundle / "Assets" / "heart.svg"
        svg.write_text(svg.read_text().replace("推し色のピンク #C8326A", f"推し色 #{light}"))
        text = json.dumps(make_icon(primary, light, dark_ground, dark_heart), indent=2, ensure_ascii=False, sort_keys=True)
        # Icon Composer と同じ書き方（`"key" : value`）にそろえる
        text = text.replace('": ', '" : ')
        (bundle / "icon.json").write_text(text + "\n")
    print(f"{len(ICONS)} 個の代替アイコンを {DESTINATION.relative_to(REPOSITORY)} に書きました")


if __name__ == "__main__":
    main()
