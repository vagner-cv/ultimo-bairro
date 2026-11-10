"""Extract generated artwork into engine textures and aligned animation frames.

Only atlas extraction, sizing and foot alignment are performed here. The
original artwork remains unchanged in art/source/.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "art"
NAMES = [
    "cottage_slate", "cottage_terracotta", "cottage_blue", "store", "cottage_timber", "oak",
    "tree", "bush", "car_rust", "car_blue", "fence", "lamp",
    "bed", "sofa", "table", "kitchen", "door_closed", "door_open",
    "barricade", "branches", "grass", "rubble", "sign", "pistol",
]


def bounds(frame):
    # This threshold only locates the object; all original alpha is preserved.
    return frame.getchannel("A").point(lambda x: 255 if x > 96 else 0).getbbox()


def pack_characters(source, columns, offset, name, frames=4):
    image = Image.open(ROOT / "source" / source).convert("RGBA")
    width, height = image.width // columns, image.height // 4
    extracted = []
    for row in range(4):
        for col in range(4):
            slot = offset + col % frames
            frame = image.crop((slot * width, row * height, (slot + 1) * width, (row + 1) * height))
            extracted.append(frame.crop(bounds(frame)))
    scale = 44 / max(frame.height for frame in extracted)
    sheet = Image.new("RGBA", (256, 256))
    for index, frame in enumerate(extracted):
        frame = frame.resize((max(1, round(frame.width * scale)), max(1, round(frame.height * scale))), Image.Resampling.LANCZOS)
        x = (index % 4) * 64 + (64 - frame.width) // 2
        y = (index // 4) * 64 + 61 - frame.height
        sheet.alpha_composite(frame, (x, y))
    sheet.save(ROOT / f"{name}.png")


def main():
    atlas = Image.open(ROOT / "source/environment.png").convert("RGBA")
    for index, name in enumerate(NAMES):
        x, y = index % 6 * 256, index // 6 * 256
        cell = atlas.crop((x, y, x + 256, y + 256))
        cell = cell.crop(bounds(cell))
        cell.save(ROOT / "world" / f"{name}.png")
    terrain = Image.open(ROOT / "source/terrain.png").convert("RGB")
    sheet = Image.new("RGB", (768, 128))
    for index in range(6):
        x, y = index % 3 * 512, index // 3 * 512
        tile = terrain.crop((x, y, x + 512, y + 512)).resize((128, 128), Image.Resampling.LANCZOS)
        sheet.paste(tile, (128 * index, 0))
    sheet.save(ROOT / "ground.png")
    pack_characters("player.png", 4, 0, "player")
    pack_characters("people.png", 6, 0, "zombie")
    pack_characters("people.png", 6, 4, "survivor", frames=2)
    print("Packed 24 environment sprites, six materials and 48 character frames.")


if __name__ == "__main__":
    main()
