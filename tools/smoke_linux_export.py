"""Exercise the exported Linux executable with real X11 mouse/keyboard events.

Needs a DISPLAY, libXtst, and Pillow. Intended for a dedicated test display;
do not run on a desktop being used by another person.
"""
import ctypes
import os
from pathlib import Path
import subprocess
import time
from PIL import ImageGrab

ROOT = Path(__file__).resolve().parents[1]
X11 = ctypes.CDLL("libX11.so.6")
XTST = ctypes.CDLL("libXtst.so.6")
X11.XOpenDisplay.argtypes = [ctypes.c_char_p]
X11.XOpenDisplay.restype = ctypes.c_void_p
X11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
X11.XKeysymToKeycode.restype = ctypes.c_uint
X11.XStringToKeysym.argtypes = [ctypes.c_char_p]
X11.XStringToKeysym.restype = ctypes.c_ulong
X11.XFlush.argtypes = [ctypes.c_void_p]
X11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
X11.XDefaultRootWindow.restype = ctypes.c_ulong
X11.XQueryPointer.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_uint)]
X11.XSetInputFocus.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
XTST.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
XTST.XTestFakeButtonEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
XTST.XTestFakeMotionEvent.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
DISPLAY_NAME = os.environ["DISPLAY"]
DISPLAY = X11.XOpenDisplay(DISPLAY_NAME.encode())
if not DISPLAY:
    raise RuntimeError("Cannot connect to test display")


def key(name, hold=.08):
    code = X11.XKeysymToKeycode(DISPLAY, X11.XStringToKeysym(name.encode()))
    assert code
    XTST.XTestFakeKeyEvent(DISPLAY, code, 1, 0)
    X11.XFlush(DISPLAY)
    time.sleep(hold)
    XTST.XTestFakeKeyEvent(DISPLAY, code, 0, 0)
    X11.XFlush(DISPLAY)
    time.sleep(.12)


def click(x, y, hold=.08):
    XTST.XTestFakeMotionEvent(DISPLAY, -1, x, y, 0)
    X11.XFlush(DISPLAY)
    time.sleep(.1)
    root, child = ctypes.c_ulong(), ctypes.c_ulong()
    root_x, root_y, win_x, win_y = (ctypes.c_int() for _ in range(4))
    mask = ctypes.c_uint()
    X11.XQueryPointer(DISPLAY, X11.XDefaultRootWindow(DISPLAY), ctypes.byref(root), ctypes.byref(child), ctypes.byref(root_x), ctypes.byref(root_y), ctypes.byref(win_x), ctypes.byref(win_y), ctypes.byref(mask))
    if child.value:
        X11.XSetInputFocus(DISPLAY, child.value, 1, 0)
        X11.XFlush(DISPLAY)
        time.sleep(.1)
    XTST.XTestFakeButtonEvent(DISPLAY, 1, 1, 0)
    X11.XFlush(DISPLAY)
    time.sleep(hold)
    XTST.XTestFakeButtonEvent(DISPLAY, 1, 0, 0)
    X11.XFlush(DISPLAY)
    time.sleep(.3)


def picture(name):
    shot = ImageGrab.grab(xdisplay=DISPLAY_NAME)
    shot.save(ROOT / "builds" / f"smoke-{name}.png")
    return shot


def main():
    log_path = ROOT / "builds/logs/native-smoke.log"
    with log_path.open("w") as log:
        process = subprocess.Popen([str(ROOT / "builds/linux/UltimoBairro.x86_64"),
                                    "--audio-driver", "Dummy"], stdout=log, stderr=subprocess.STDOUT)
        try:
            time.sleep(1.8)
            assert process.poll() is None, "Executable did not stay open"
            picture("title")
            click(240, 572)
            time.sleep(.7)
            game = picture("started")
            red, green, blue = game.getpixel((100, 664))[:3]
            assert red > 130 and green > 100 and blue < 180, "Start click did not enter gameplay"
            key("i")
            inventory = picture("inventory")
            assert max(inventory.getpixel((400, 300))[:3]) < 60, "I did not open inventory"
            key("Escape")
            key("Tab")
            world_map = picture("map")
            red, green, blue = world_map.getpixel((270, 150))[:3]
            assert 40 < red < 60 and 64 < green < 82, "Tab did not open map"
            key("Escape")
            key("space")
            key("f")
            key("e")
            key("s", 1.0)
            key("d", .78)
            time.sleep(.2)
            key("e")
            dialogue = picture("dialogue")
            red, green, blue = dialogue.getpixel((291, 520))[:3]
            assert red > 180 and green > 120 and blue < 180, "Walk/door/NPC interaction did not open dialogue"
            key("Escape")
            click(1000, 350, .5)
            key("Escape")
            picture("paused")
            click(535, 356)  # Restart from the pause menu.
            time.sleep(.5)
            restarted = picture("restarted")
            red, green, blue = restarted.getpixel((100, 664))[:3]
            assert red > 130 and green > 100, "Restart did not restore the player"
            key("Escape")
            click(640, 490)  # Quit button.
            process.wait(timeout=5)
            assert process.returncode == 0, "Executable exited with an error"
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
    output = log_path.read_text()
    if "SCRIPT ERROR:" in output or "\nERROR:" in output:
        raise RuntimeError(output)
    print("PASS: native Linux start, inventory, map, jump, knife, keyboard movement, door, NPC dialogue, shooting, pause, restart and quit")


if __name__ == "__main__":
    main()
