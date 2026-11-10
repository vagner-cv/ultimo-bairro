"""Import, validate, export and package the Windows/Linux prototype with Godot 4.6.3."""
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "builds"
LOGS = BUILD / "logs"
VERSION = "0.1.0"


def run(name, arguments):
    log_path = LOGS / f"{name}.log"
    with log_path.open("w") as output:
        result = subprocess.run(["godot", "--headless", "--path", str(ROOT), *arguments],
                                cwd=ROOT, stdout=output, stderr=subprocess.STDOUT)
    log = log_path.read_text()
    if result.returncode or "SCRIPT ERROR:" in log or "\nERROR:" in log:
        raise RuntimeError(f"{name} failed; see {log_path}\n{log[-3000:]}")
    print(f"PASS {name}", flush=True)


def main():
    LOGS.mkdir(parents=True, exist_ok=True)
    run("import", ["--editor", "--import", "--quit"])
    run("tests", ["--fixed-fps", "60", "--script", "res://tests/run_tests.gd"])
    for platform, preset, executable in [
        ("Windows", "Windows Desktop", "UltimoBairro.exe"),
        ("Linux", "Linux", "UltimoBairro.x86_64"),
    ]:
        folder = BUILD / platform.lower()
        folder.mkdir(exist_ok=True)
        run(f"export-{platform.lower()}", ["--export-release", preset, str(folder / executable)])
        for notice in ["FONT-LICENSE.txt", "GODOT-LICENSE.txt"]:
            shutil.copy(ROOT / "art" / notice, folder / notice)
        (folder / "LEIA-ME.txt").write_text(
            "ÚLTIMO BAIRRO — PROTÓTIPO 0.1\n\n"
            "Extraia todos os arquivos antes de jogar.\n"
            f"Abra {executable}. Não precisa instalar Godot.\n\n"
            "WASD ou setas: caminhar\nMouse: mirar\nBotão esquerdo: atirar (segure para repetir)\n"
            "E: portas e conversa\nEsc: pausa / encerrar diálogo\nM: áudio\nF11: tela cheia\n\n"
            "Você começa na casa 07. Use E perto da porta para sair.\n"
            "Mara está no jardim à direita. Há 18 infectados no bairro.\n"
            "Munição infinita, sem recarga. Sem coleta ou salvamento nesta versão.\n\n"
            "Arte provisória original. Motor Godot; fontes DejaVu.\n"
            "As licenças dessas dependências acompanham este pacote.\n",
            encoding="utf-8")
        package = BUILD / f"UltimoBairro-{VERSION}-{platform}.zip"
        with zipfile.ZipFile(package, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for file in sorted(folder.iterdir()):
                archive.write(file, file.name)
        with zipfile.ZipFile(package) as archive:
            assert archive.testzip() is None
        print(f"Created {package.name}: {package.stat().st_size / 1024**2:.1f} MiB", flush=True)


if __name__ == "__main__":
    main()
