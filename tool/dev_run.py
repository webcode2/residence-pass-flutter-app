"""Run the app against a backend with hot reload on every save.

    python tool/dev_run.py                      # emulator-5554, live Ohio API
    python tool/dev_run.py --device emulator-5554 --device 5843524835493498   # both at once
    python tool/dev_run.py --device chrome --api http://localhost:8000

Run several devices from ONE session (repeat --device). Two separate sessions in this
folder share the same build output and overwrite each other's app (an x86_64-only APK
ends up on an ARM phone); one session builds per device and hot-reloads all of them.

Saving any .dart file under lib/ triggers a hot reload automatically. Type a key and
press Enter to send it to Flutter:  r = hot reload, R = hot restart (resets app state),
q = quit. A pubspec.yaml change needs a full re-run (q, then start again).
"""
import argparse
import os
import shutil
import subprocess
import sys
import threading
import time

MOBILE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_API = "https://residence-api-136222598323.us-east5.run.app"


def dart_snapshot(root):
    seen = {}
    for folder, _dirs, files in os.walk(root):
        for name in files:
            if name.endswith(".dart"):
                path = os.path.join(folder, name)
                try:
                    seen[path] = os.stat(path).st_mtime_ns
                except OSError:
                    pass
    return seen


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--device", action="append", help="repeat for several devices (default emulator-5554)")
    parser.add_argument("--api", default=DEFAULT_API, help="backend origin passed as API_BASE_URL")
    args = parser.parse_args()

    flutter = shutil.which("flutter.bat") or shutil.which("flutter") or "flutter"
    devices = args.device or ["emulator-5554"]
    cmd = [flutter, "run", *[part for d in devices for part in ("-d", d)], f"--dart-define=API_BASE_URL={args.api}"]
    if os.name == "nt" and flutter.lower().endswith(".bat"):
        cmd = ["cmd", "/c", *cmd]
    print(f"[dev_run] {', '.join(devices)} -> {args.api}")
    print("[dev_run] auto hot reload on save; type r / R / q + Enter for reload / restart / quit")
    proc = subprocess.Popen(cmd, cwd=MOBILE_DIR, stdin=subprocess.PIPE, text=True, bufsize=0)
    lock = threading.Lock()

    def send(key):
        with lock:
            if proc.poll() is None:
                try:
                    proc.stdin.write(key)  # single character, no newline: Flutter reads keystrokes
                    proc.stdin.flush()
                except OSError:
                    pass

    def forward_keys():
        for line in sys.stdin:
            key = line.strip()[:1]
            if key:
                send(key)

    def watch_sources():
        lib = os.path.join(MOBILE_DIR, "lib")
        pubspec = os.path.join(MOBILE_DIR, "pubspec.yaml")
        last, pub = dart_snapshot(lib), os.stat(pubspec).st_mtime_ns
        while proc.poll() is None:
            time.sleep(0.7)
            now = dart_snapshot(lib)
            if now != last:
                time.sleep(0.3)  # let editors finish writing
                last = dart_snapshot(lib)
                print("[dev_run] change detected -> hot reload")
                send("r")
            try:
                current = os.stat(pubspec).st_mtime_ns
            except OSError:
                current = pub
            if current != pub:
                pub = current
                print("[dev_run] pubspec.yaml changed: quit (q) and start again to pick up packages")

    threading.Thread(target=forward_keys, daemon=True).start()
    threading.Thread(target=watch_sources, daemon=True).start()
    try:
        return proc.wait()
    except KeyboardInterrupt:
        send("q")
        return proc.wait()


if __name__ == "__main__":
    sys.exit(main())
