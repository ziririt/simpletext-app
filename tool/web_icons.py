#!/usr/bin/env python3
# 웹 아이콘 생성기 (Skyblue Note)
#
# 왜 손으로 만드나. flutter_launcher_icons 는 web 생성 시 manifest.json 을
# 제가 다시 쓴다 — id·scope·display_override·categories·description 같이
# 우리가 손으로 채운 값이 날아간다. 그래서 웹만 이 스크립트로 만든다.
# 원본은 assets/icon/ 세 장뿐이고, 플랫폼 폴더의 PNG 는 손대지 않는다.
#
#   python3 tool/web_icons.py        (Pillow 필요: pip install pillow)
#
# 마스커블(maskable)은 안드로이드·PWA 런처가 아이콘을 원·물방울 따위로
# 오려내는 규격이다. 가운데 지름 80% 원 안에 그림이 다 들어와야 잘리지
# 않는다. 그래서 배경은 가장자리까지 채우고, 그림만 80% 로 줄여 얹는다.
import os
from PIL import Image

SRC = os.environ.get('ICON_SRC', 'assets/icon')
OUT = os.environ.get('ICON_OUT', 'web')
SAFE = 0.80

base = Image.open(f'{SRC}/app_icon.png').convert('RGBA')
bg   = Image.open(f'{SRC}/app_icon_bg.png').convert('RGBA')
fg   = Image.open(f'{SRC}/app_icon_fg.png').convert('RGBA')

def plain(n, path):
    base.resize((n, n), Image.LANCZOS).save(path, optimize=True)
    print('  ', path, f'{n}x{n}')

def maskable(n, path):
    canvas = bg.resize((n, n), Image.LANCZOS)
    m = int(round(n * SAFE))
    art = fg.resize((m, m), Image.LANCZOS)
    off = (n - m) // 2
    canvas.alpha_composite(art, (off, off))
    canvas.save(path, optimize=True)
    print('  ', path, f'{n}x{n} (안전영역 {int(SAFE*100)}%)')

os.makedirs(f'{OUT}/icons', exist_ok=True)
print('웹 아이콘 생성')
plain(32,  f'{OUT}/favicon.png')
plain(192, f'{OUT}/icons/Icon-192.png')
plain(512, f'{OUT}/icons/Icon-512.png')
maskable(192, f'{OUT}/icons/Icon-maskable-192.png')
maskable(512, f'{OUT}/icons/Icon-maskable-512.png')
print('끝.')
