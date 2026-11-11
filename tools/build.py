"""Import, validate, export and package the Windows/Linux prototype with Godot 4.6.3."""
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "builds"
LOGS = BUILD / "logs"
VERSION = "0.5.0"


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
    if not (ROOT / "art/pixel/house_plaster.png").exists():
        raise SystemExit("Missing project artwork: art/pixel/house_plaster.png")
    LOGS.mkdir(parents=True, exist_ok=True)
    (BUILD / ".gdignore").touch()
    run("import", ["--editor", "--import", "--quit"])
    run("tests", ["--fixed-fps", "60", "--script", "res://tests/run_tests.gd"])
    for platform, preset, executable in [
        ("Windows", "Windows Desktop", "UltimoBairro.exe"),
        ("Linux", "Linux", "UltimoBairro.x86_64"),
    ]:
        folder = BUILD / platform.lower()
        folder.mkdir(exist_ok=True)
        run(f"export-{platform.lower()}", ["--export-release", preset, str(folder / executable)])
        legacy_notice = folder / "CRAFTPIX-NOTICE.txt"
        if legacy_notice.exists():
            legacy_notice.unlink()
        for notice in ["FONT-LICENSE.txt", "GODOT-LICENSE.txt"]:
            shutil.copy(ROOT / "art" / notice, folder / notice)
        (folder / "LEIA-ME.txt").write_text(
            "ÚLTIMO BAIRRO — PROTÓTIPO 0.5.0\n\n"
            "Extraia todos os arquivos antes de jogar.\n"
            f"Abra {executable}. Não precisa instalar Godot.\n\n"
            "WASD ou setas: caminhar\nMouse: mirar\nBotão esquerdo: atirar (segure para repetir)\n"
            "Roda: zoom\nE: portas, recipientes e conversa\nI: inventário\nTab: mapa\n"
            "Espaço: pular\nF ou botão direito: faca\nH: erva\n1/2/3/4: armas\n"
            "Esc: fechar / pausar\nM: áudio\nF2: filtro de texturas\nF11: tela cheia\n\n"
            "Você começa na casa 07. Use E perto da porta para sair.\n"
            "Mara está no jardim à direita. A primeira onda tem 18 infectados.\n"
            "Cada onda seguinte traz mais 8 infectados, após 12 segundos de intervalo.\n"
            "Munição finita e própria para cada arma. A faca não usa munição.\n"
            "Mira livre: a bala segue a direção do mouse. Verde indica alvo na trajetória.\n"
            "O tiro acerta o corpo visível e respeita paredes, portas e dispersão.\n"
            "Abra armários, gavetas e lixeiras com E. Corte caixas com a faca.\n"
            "Organize os itens no inventário; sem limite de carregamento.\n"
            "O conteúdo dos recipientes persiste durante a partida. Não há salvamento.\n\n"
            "Pixel art gerada para o projeto.\nMotor Godot; fontes DejaVu.\n"
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
