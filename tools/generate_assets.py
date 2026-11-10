"""Generate the prototype's original pixel art and sound. Requires Pillow.

The committed PNG/WAV assets are enough to play; this is an optional source tool.
No external game sprites, music or character likeness assets are used.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "art"
ROOT.mkdir(exist_ok=True)
rng = random.Random(41)


def character(name, zombie=False):
    sheet = Image.new("RGBA", (128, 128))
    for direction in range(4):  # south, east, north, west
        for frame in range(4):
            im = Image.new("RGBA", (32, 32))
            d = ImageDraw.Draw(im)
            step = [0, 1, 0, -1][frame]
            bob = 1 if frame in (1, 3) else 0
            skin = "#8b9b75" if zombie else "#d6ae82"
            shade = "#596c56" if zombie else "#a47757"
            coat = "#576c65" if zombie else "#74503b"
            light = "#738477" if zombie else "#a1784e"
            pants = "#354a49" if zombie else "#34444b"
            hair = "#3e5143" if zombie else "#b49155"
            # Feet and separated legs remain visible at every facing.
            d.rectangle((11, 21, 14, 27 + step), fill=pants)
            d.rectangle((17, 21, 20, 27 - step), fill=pants)
            d.rectangle((10, 27 + step, 14, 29 + step), fill="#1d2a2d")
            d.rectangle((17, 27 - step, 21, 29 - step), fill="#1d2a2d")
            d.rectangle((9, 13 + bob, 22, 22 + bob), fill="#263a35")
            d.rectangle((10, 13 + bob, 21, 21 + bob), fill=coat)
            d.rectangle((10, 14 + bob, 12, 20 + bob), fill=light)
            d.rectangle((8, 15 + bob, 10, 23 + bob), fill=coat)
            d.rectangle((22, 15 + bob, 24, 23 + bob), fill=coat)
            d.rectangle((8, 22 + bob, 10, 24 + bob), fill=skin)
            d.rectangle((22, 22 + bob, 24, 24 + bob), fill=skin)
            d.rectangle((13, 10 + bob, 19, 14 + bob), fill=shade)
            if direction != 2:
                d.rectangle((11, 5 + bob, 21, 11 + bob), fill=skin)
                d.rectangle((11, 6 + bob, 12, 10 + bob), fill=shade)
            d.rectangle((11, 3 + bob, 21, 6 + bob), fill=hair)
            d.rectangle((13, 2 + bob, 19, 3 + bob), fill=hair)
            d.rectangle((10, 5 + bob, 12, 8 + bob), fill=hair)
            if direction == 2:
                d.rectangle((11, 6 + bob, 21, 11 + bob), fill=hair)
                d.rectangle((13, 12 + bob, 19, 14 + bob), fill=light)
            elif direction in (1, 3):
                d.rectangle((19, 7 + bob, 22, 9 + bob), fill=skin)
                d.point((20, 7 + bob), fill="#223632")
                d.rectangle((12, 4 + bob, 16, 9 + bob), fill=hair)
            else:
                d.point((14, 8 + bob), fill="#223632")
                d.point((19, 8 + bob), fill="#223632")
                d.rectangle((13, 5 + bob, 17, 6 + bob), fill="#c4a367" if not zombie else hair)
                d.line((13, 13 + bob, 15, 15 + bob), fill="#ceb98c" if not zombie else light)
                d.line((19, 13 + bob, 17, 15 + bob), fill="#ceb98c" if not zombie else light)
                d.line((16, 16 + bob, 16, 20 + bob), fill="#4b3e33")
            if zombie:
                d.rectangle((19, 17 + bob, 21, 20 + bob), fill="#824b43")
                d.rectangle((12, 22, 14, 23), fill="#6a6450")
                d.point((19, 9 + bob), fill="#b77751")
            if direction == 3:
                im = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            sheet.alpha_composite(im, (frame * 32, direction * 32))
    sheet.save(ROOT / f"{name}.png")


character("player")
character("zombie", True)
# A distinct survivor jacket and hair, using the same original base sprite.
npc = Image.open(ROOT / "player.png").convert("RGBA")
replace = {(116, 80, 59): (77, 105, 116), (161, 120, 78): (112, 145, 146),
           (180, 145, 85): (60, 59, 49), (196, 163, 103): (92, 88, 67)}
npc.putdata([(*replace.get(p[:3], p[:3]), p[3]) for p in npc.getdata()])
npc.save(ROOT / "survivor.png")

# Deterministic ground atlas: grass, asphalt, paving, floor, dirt, dark grass.
atlas = Image.new("RGB", (192, 32))
d = ImageDraw.Draw(atlas)
palettes = [("#3c5341", "#49604a", "#344c3c"),
            ("#424f4e", "#485553", "#3b4746"),
            ("#7a8172", "#858b7c", "#646e63"),
            ("#836b50", "#93795a", "#6b5b47"),
            ("#78694d", "#857456", "#665e46"),
            ("#2e4437", "#364d3b", "#263e32")]
for tile, colors in enumerate(palettes):
    x = tile * 32
    d.rectangle((x, 0, x + 31, 31), fill=colors[0])
    for _ in range(95):
        px, py = rng.randrange(32), rng.randrange(32)
        d.rectangle((x + px, py, x + min(px + rng.randrange(1, 3), 31), py), fill=rng.choice(colors[1:]))
    if tile == 2:
        d.line((x, 0, x + 31, 0), fill=colors[1])
        d.line((x, 31, x + 31, 31), fill=colors[2])
        d.line((x, 0, x, 31), fill=colors[2])
    if tile == 3:
        for py in range(0, 32, 8):
            d.line((x, py, x + 31, py), fill=colors[2])
        d.line((x + 15, 0, x + 15, 7), fill=colors[2])
        d.line((x + 25, 8, x + 25, 15), fill=colors[2])
        d.line((x + 8, 16, x + 8, 23), fill=colors[2])
atlas.save(ROOT / "ground.png")

# Tree, drawn as overlapping pixel clusters with a bottom-center pivot.
im = Image.new("RGBA", (80, 96))
d = ImageDraw.Draw(im)
d.rectangle((35, 50, 43, 90), fill="#4d4936")
d.rectangle((38, 53, 42, 88), fill="#756244")
for cx, cy, r, c in [(24, 48, 21, "#233e32"), (53, 44, 23, "#233e32"),
                      (39, 25, 26, "#2c4938"), (25, 30, 20, "#35563e"),
                      (46, 27, 22, "#3c5d43"), (37, 14, 16, "#47664a")]:
    d.rectangle((cx-r, cy-r//2, cx+r, cy+r//2), fill=c)
    d.rectangle((cx-r//2, cy-r, cx+r//2, cy+r), fill=c)
for _ in range(130):
    px, py = rng.randrange(8, 70), rng.randrange(3, 64)
    if im.getpixel((px, py))[3]:
        d.rectangle((px, py, px+2, py+1), fill=rng.choice(["#47634a", "#527052", "#304d39"]))
im.save(ROOT / "tree.png")


def sound(name, seconds, sample):
    rate = 22050
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        frames = []
        for i in range(int(rate * seconds)):
            t = i / rate
            v = max(-1, min(1, sample(t, i)))
            frames.append(struct.pack("<h", int(v * 24000)))
        f.writeframes(b"".join(frames))


sound("shot", .19, lambda t, i: (rng.uniform(-1, 1) * .8 + math.sin(2*math.pi*(95*t-100*t*t))*.5)*math.exp(-t*36))
sound("impact", .12, lambda t, i: rng.uniform(-.7, .7)*math.exp(-t*42))
sound("door", .25, lambda t, i: (math.sin(2*math.pi*130*t)*.23 + rng.uniform(-.17,.17))*math.exp(-t*15))
sound("step", .075, lambda t, i: rng.uniform(-.2,.2)*math.exp(-t*48))
sound("hurt", .24, lambda t, i: (math.sin(2*math.pi*(100*t-60*t*t))*.3+rng.uniform(-.08,.08))*math.exp(-t*11))
filtered = 0.0


def wind(t, i):
    global filtered
    filtered = filtered * .97 + rng.uniform(-1, 1) * .03
    return filtered * (.21 + .08*math.sin(t*.9)) * min(t, 1) * min(8-t, 1)


sound("wind", 8, wind)
print("Original art and audio generated in", ROOT)
