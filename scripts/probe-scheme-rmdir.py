#!/usr/bin/env python3
"""Sonda R-F19: co naprawdę robi `rmdir /scheme/<nazwa>` na żywym E-OS.

Nie zgaduje i nie asertuje z góry — wykonuje zestaw poleceń i **wypisuje surowy
transkrypt**, żeby wniosek dało się wyprowadzić z tego, co system faktycznie powiedział.
Trzy z tych poleceń to kontrole instrumentu (§4.2): jeśli wszystkie zwrócą ten sam błąd,
sonda niczego nie rozróżnia i jej wynik trzeba odrzucić.

Console i login pochodzą z install-smoke-drive.py — ta sama, sprawdzona obsługa
konsoli szeregowej, w tym expect() liczone od znacznika (bez tego expect dopasowywał
zachętę sprzed instalacji; patrz U-166).
"""
import importlib.util
import pathlib
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("drive", HERE / "install-smoke-drive.py")
drive = importlib.util.module_from_spec(spec)
spec.loader.exec_module(drive)

# Kolejnosc ma znaczenie: kontrole PRZED wlasciwym pomiarem, zeby nie dalo sie
# dopasowac wyniku do oczekiwania po fakcie.
PROBES = [
    ("ls /scheme/",                      "jakie schematy w ogole istnieja"),
    ("rmdir /scheme/probe_nie_istnieje", "KONTROLA: schemat, ktorego nie ma"),
    ("rmdir /scheme/file/nie-ma-tego",   "KONTROLA: zwykla sciezka wewnatrz schematu"),
    ("rmdir /scheme/file",               "POMIAR: korzen schematu redoxfs"),
    ("ls /scheme/ | wc -l",              "czy schemat file nadal istnieje po probie"),
]


def main():
    serial, budget = sys.argv[1], int(sys.argv[2])
    # Ta sama obsluga konsoli przydaje sie do KAZDEGO pytania o zywy system, wiec zestaw
    # polecen da sie nadpisac: EOS_PROBE_CMDS="cmd1\ncmd2". Bez tego uruchamia sie
    # oryginalny zestaw R-F19 opisany wyzej.
    import os
    import tempfile
    override = os.environ.get("EOS_PROBE_CMDS")
    probes = ([(c, "") for c in override.splitlines() if c.strip()]
              if override else PROBES)
    # The serial log path used to be hardcoded under /tmp/eosfix, which macOS clears on
    # reboot: after one restart every probe died with FileNotFoundError before reaching the
    # guest, and the failure looked like a boot problem rather than a missing directory.
    # Default beside the run and let the caller redirect it.
    log_path = os.environ.get("EOS_PROBE_LOG") or os.path.join(
        tempfile.gettempdir(), "eos-probe-serial.log")
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    print("probe: dziennik szeregowy -> %s" % log_path)
    con = drive.Console(serial, budget, log_path)
    con.dismiss_boot_menu(serial.replace("ser.sock", "mon.sock"))

    if not drive.login(con):
        print("probe: FAIL — nie udalo sie zalogowac")
        return 1

    print("\n" + "=" * 72)
    for cmd, why in probes:
        con.mark()
        marker = f"---PROBE {cmd}---"
        con.send(f"echo '{marker}'")
        con.send(cmd)
        con.pump(4)
        tail = con.buf[con.marker:]
        print(f"\n$ {cmd}\n  ({why})")
        for line in tail.splitlines():
            line = line.strip()
            if line and marker not in line and not line.startswith("echo "):
                print(f"  | {line[:110]}")
        time.sleep(0.5)
    print("=" * 72)
    print("\nWniosek wyprowadz z POWYZSZEGO, nie z oczekiwan. Jesli wszystkie trzy")
    print("polecenia rmdir zwrocily ten sam blad, sonda nic nie rozroznia — odrzuc wynik.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
