"""Regenerate prototype audio. Artwork is prepared by prepare_assets.py."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "art"
rng = random.Random(41)

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
print("Audio generated in", ROOT)
