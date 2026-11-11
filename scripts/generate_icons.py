#!/usr/bin/env python3
"""Render original Dream Reader artwork. Requires Pillow; no remote artwork is used."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
image = Image.new('RGB', (1536, 1536), '#0B1418')
canvas = ImageDraw.Draw(image)
canvas.ellipse((330, 260, 1120, 1250), fill='#ACEBD5')
canvas.ellipse((550, 200, 1300, 1100), fill='#0B1418')
canvas.polygon([(760, 820), (1010, 770), (1180, 810), (1180, 1120), (960, 1090), (760, 1180)], fill='#ACEBD5')
canvas.polygon([(760, 820), (550, 780), (430, 810), (430, 1110), (600, 1100), (760, 1180)], fill='#74BBA6')
canvas.line((760, 820, 760, 1170), fill='#0B1418', width=15)
canvas.polygon([(1020, 380), (1050, 490), (1160, 520), (1050, 550), (1020, 660), (990, 550), (880, 520), (990, 490)], fill='#FFF0D9')
for size in [192, 512]:
    icon = image.resize((size, size), Image.Resampling.LANCZOS)
    icon.save(root / f'web/icons/Icon-{size}.png')
    icon.save(root / f'web/icons/Icon-maskable-{size}.png')
image.resize((32, 32), Image.Resampling.LANCZOS).save(root / 'web/favicon.png')
for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    image.resize((size, size), Image.Resampling.LANCZOS).save(root / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
