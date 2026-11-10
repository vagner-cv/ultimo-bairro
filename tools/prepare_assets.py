"""Download the author's free kit and prepare only the images used by the game.

Use --archive PATH for an already downloaded ZIP. CraftPix artwork is kept out
of Git and source archives; builds embed the textures as part of the game.
"""
import argparse
import hashlib
import http.cookiejar
import io
import json
from pathlib import Path
import urllib.parse
import urllib.request
from html.parser import HTMLParser
import zipfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "art/vendor/craftpix"
BASE = "https://free-game-assets.itch.io/free-zombie-apocalypse-top-down-pixel-art-kit"
EXPECTED_SHA256 = "46c3597e153b6ca4f50b26cfc39ca58aa17b3f615388bbc8131ebea890cc4c3d"


class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.csrf = None
        self.upload = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "meta" and attrs.get("name") == "csrf_token":
            self.csrf = attrs.get("value") or attrs.get("content")
        if tag == "a" and "data-upload_id" in attrs and self.upload is None:
            self.upload = attrs["data-upload_id"]


def download_free():
    jar = http.cookiejar.CookieJar()
    client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))

    def fetch(url, data=None):
        request = urllib.request.Request(url, data=data, headers={
            "User-Agent": "Mozilla/5.0", "Referer": BASE + "/purchase",
            "Origin": "https://free-game-assets.itch.io"})
        with client.open(request, timeout=60) as response:
            return response.read()

    page = Page()
    page.feed(fetch(BASE + "/purchase").decode())
    if not page.csrf:
        raise RuntimeError("Download form changed. Download the free ZIP from the author and pass --archive.")
    data = urllib.parse.urlencode({"csrf_token": page.csrf}).encode()
    link = json.loads(fetch(BASE + "/download_url", data))
    page = Page()
    page.feed(fetch(link["url"]).decode())
    if not page.upload:
        raise RuntimeError("No free download was offered by the author.")
    data = urllib.parse.urlencode({"csrf_token": page.csrf}).encode()
    link = json.loads(fetch(BASE + "/file/" + page.upload, data))
    return fetch(link["url"])


def prepare(data):
    if hashlib.sha256(data).hexdigest() != EXPECTED_SHA256:
        raise RuntimeError("The author updated the ZIP. Review the new contents before updating its checksum.")
    DEST.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        selected = {"tiles.png": "City_Tileset/PSD/Tile.png", "ui.png": "UI/UI.png"}
        for action in ["Walk", "Idle", "Shot", "Dead", "Hart"]:
            selected[f"player_{action.lower()}.png"] = f"Characters/Character_3/{action}.png"
        selected["npc_idle.png"] = "Characters/Character_5/Idle.png"
        for action in ["Walk", "Idle", "Attack", "Dead", "Hart"]:
            selected[f"zombie_{action.lower()}.png"] = f"Enimies/Enimies_1/{action}.png"
        for target, source in selected.items():
            (DEST / target).write_bytes(archive.read(source))
    atlas = Image.open(DEST / "tiles.png").convert("RGBA")
    regions = {
        "tree": (18, 4, 3, 3), "bush": (14, 5, 2, 2),
        "bench": (15, 8, 2, 2), "dumpster": (12, 10, 3, 2),
        "fence": (15, 10, 3, 2), "barricade": (15, 12, 2, 1),
        "door_closed": (9, 6, 2, 2), "door_open": (12, 6, 2, 2),
        "crate": (11, 11, 1, 1), "barrel": (11, 12, 1, 1),
        "wall_light": (10, 8, 1, 2), "bottle": (9, 11, 1, 1),
        "paper": (19, 12, 1, 1), "stone": (20, 12, 1, 1),
    }
    for name, (x, y, width, height) in regions.items():
        atlas.crop((x * 16, y * 16, (x + width) * 16, (y + height) * 16)).save(DEST / f"{name}.png")
    ground = Image.new("RGBA", (768, 128))
    materials = [[249, 249, 271, 249], [72, 72, 334, 357], [244, 244, 266, 244],
                 [330, 352, 330, 330], [330, 331, 352, 330], [271, 249, 271, 271]]
    for kind, tiles in enumerate(materials):
        for y in range(4):
            for x in range(4):
                cell = tiles[(x * 3 + y * 5) % len(tiles)]
                tx, ty = cell % 22 * 16, cell // 22 * 16
                tile = atlas.crop((tx, ty, tx + 16, ty + 16)).resize((32, 32), Image.Resampling.NEAREST)
                ground.paste(tile, (kind * 128 + x * 32, y * 32))
    ground.save(DEST / "ground.png")
    # Extract the kit's native held pistol for the independent aiming layer.
    actor = Image.open(DEST / "player_idle.png").convert("RGBA")
    actor.crop((19, 24, 24, 29)).save(DEST / "pistol.png")
    print("Prepared the free CraftPix kit: terrain, props and native character animations.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path)
    args = parser.parse_args()
    cache = ROOT / "builds/cache/craftpix-zombie.zip"
    if args.archive:
        data = args.archive.read_bytes()
    elif cache.exists():
        data = cache.read_bytes()
    else:
        data = download_free()
    prepare(data)
    cache.parent.mkdir(parents=True, exist_ok=True)
    (ROOT / "builds/.gdignore").touch()
    if args.archive is None or args.archive.resolve() != cache.resolve():
        cache.write_bytes(data)


if __name__ == "__main__":
    main()
