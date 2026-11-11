"""Pack authored pixel atlases for Godot (crop/nearest resize only, no art synthesis).

Usage: python3 tools/import_pixel_atlases.py /path/to/sources.json
The manifest maps hero_pistol/shotgun/rifle/knife, flora, buildings, props,
storage, items, actors and ground to original atlas PNG paths.
Runtime PNGs are committed; this optional packaging step is not needed to play.
"""
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "art/pixel"
NEAREST = Image.Resampling.NEAREST


def cells(path, columns, rows, adaptive=False):
    image = Image.open(path).convert("RGBA")
    def seams(part, count, horizontal):
        length = part.height if horizontal else part.width
        step = length / count
        mask = part.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
        boundaries = [0]
        for index in range(1, count):
            center = round(index * step)
            if not adaptive:
                boundaries.append(center)
                continue
            def score(at):
                band = mask.crop((0, at - 1, part.width, at + 2) if horizontal else
                                 (at - 1, 0, at + 2, part.height))
                return (band.histogram()[255], abs(at - center))
            # Generated object sheets may use uneven gutters. Split through
            # transparent gaps rather than copying a neighbor into the cell.
            boundaries.append(min(range(round(center - step * .22), round(center + step * .22)), key=score))
        return boundaries + [length]
    ys = seams(image, rows, True)
    result = []
    for y in range(rows):
        strip = image.crop((0, ys[y], image.width, ys[y + 1]))
        xs = seams(strip, columns, False)
        result.extend(strip.crop((xs[x], 0, xs[x + 1], strip.height)) for x in range(columns))
    return result


def visible_box(image):
    return image.getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()


def trimmed(image, maximum):
    image = image.crop(visible_box(image))
    factor = min(maximum[0] / image.width, maximum[1] / image.height)
    return image.resize((max(1, round(image.width * factor)), max(1, round(image.height * factor))), NEAREST)


def save_objects(source, columns, rows, names, maximum=(128, 128)):
    for name, image in zip(names, cells(source, columns, rows, adaptive=True)):
        trimmed(image, maximum).save(OUT / (name + ".png"))


def actor_frame(image, height=64, cell=(96, 80), baseline=74):
    box = visible_box(image)
    cut = image.crop(box)
    scale = height / cut.height
    resized = cut.resize((round(cut.width * scale), height), NEAREST)
    # Keep the atlas' body axis fixed across the gait. Centering the lowest shoe
    # would move the torso sideways when the left/right foot takes a step.
    body_x = image.width / 2 - box[0]
    frame = Image.new("RGBA", cell)
    frame.paste(resized, (round(cell[0] / 2 - body_x * scale), baseline - height))
    return frame


def main(manifest):
    OUT.mkdir(parents=True, exist_ok=True)
    for weapon in ["pistol", "shotgun", "rifle", "knife"]:
        atlas = Image.new("RGBA", (384, 640))
        for i, image in enumerate(cells(manifest["hero_" + weapon], 4, 8)):
            frame = actor_frame(image)
            atlas.paste(frame, (i % 4 * 96, i // 4 * 80))
        atlas.save(OUT / ("hero_" + weapon + ".png"))
    save_objects(manifest["flora"], 4, 4,
        ["oak", "pine", "birch", "palm", "willow", "maple", "dead_tree", "fruit_tree",
         "bush", "flower_bush", "fern", "tall_grass", "wildflowers", "weeds", "lavender", "plant"], (160, 192))
    save_objects(manifest["buildings"], 4, 2,
        ["house_plaster", "house_blue", "house_brick", "house_timber", "store", "clinic", "warehouse", "house_stucco"], (384, 384))
    save_objects(manifest["props"], 6, 4,
        ["wood_fence", "fence", "bench", "barricade", "barrel", "lamp", "woodpile", "car",
         "leaves", "drain", "rubble", "bicycle", "sofa", "table", "bed", "bookcase",
         "hospital_bed", "workbench", "fridge", "armchair", "desk", "ivy", "well", "hedge"])
    save_objects(manifest["storage"], 6, 3,
        ["locker", "locker_open", "wood", "cardboard", "drawer", "drawer_open", "dumpster", "dumpster_open",
         "loot", "wall_plaster", "wall_brick", "wall_wood", "door_wood", "door_wood_open",
         "door_blue", "door_blue_open", "door_steel", "door_steel_open"])
    save_objects(manifest["items"], 4, 2,
        ["herb", "pistol", "shotgun", "rifle", "knife", "ammo_9mm", "ammo_shell", "ammo_rifle"], (96, 64))
    actors = cells(manifest["actors"], 4, 4)
    for name, indices in [("mara_idle", [0, 1, 0, 1]), ("zombie_walk", [4, 5, 6, 7]),
                          ("zombie_idle", [8, 9, 8, 9]), ("zombie_attack", [10, 11, 10, 11])]:
        strip = Image.new("RGBA", (384, 80))
        for col, index in enumerate(indices):
            strip.paste(actor_frame(actors[index]), (col * 96, 0))
        strip.save(OUT / (name + ".png"))
    trimmed(actors[15], (72, 32)).save(OUT / "zombie_corpse.png")
    for name, image in zip(["grass", "asphalt", "paving", "wood_floor"], cells(manifest["ground"], 2, 2)):
        image.convert("RGB").resize((256, 256), NEAREST).save(OUT / (name + ".png"))
    print(f"Packed {len(list(OUT.glob('*.png')))} runtime textures into {OUT}")


if __name__ == "__main__":
    main(json.loads(Path(sys.argv[1]).read_text()))
