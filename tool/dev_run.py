"""Run the app against a backend with hot reload on every save, on one or more devices.

    python tool/dev_run.py                          # emulator-5554, live Ohio API
    python tool/dev_run.py --device all             # every connected Android device
    python tool/dev_run.py --device emulator-5554,5843524835493498
    python tool/dev_run.py --device chrome --api http://localhost:8000

Each device gets its own `flutter run`, started one after another: the next build only
begins once the previous device is running, because builds in this folder share one
output and would otherwise overwrite each other (an emulator-only app ends up on a
phone). `flutter run -d all` is not used because it also launches the desktop app.

Saving any .dart file under lib/ hot-reloads every device. Type a key and press Enter to
send it to all devices: r = hot reload, R = hot restart (resets app state), q = quit.
A pubspec.yaml change needs a full re-run (q, then start again).
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
READY_MARKER = "Flutter run key commands"


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


def android_devices():
    adb = shutil.which("adb") or os.path.join(os.environ.get("LOCALAPPDATA", ""), "Android", "Sdk",
                                              "platform-tools", "adb.exe")
    out = subprocess.run([adb, "devices"], capture_output=True, text=True).stdout.splitlines()[1:]
    return [line.split()[0] for line in out if line.strip().endswith("device")]


class DeviceRun:
    def __init__(self, flutter, device, api):
        self.device = device
        self.ready = threading.Event()
        cmd = [flutter, "run", "-d", device, f"--dart-define=API_BASE_URL={api}"]
        if os.name == "nt" and flutter.lower().endswith(".bat"):
            cmd = ["cmd", "/c", *cmd]
        self.proc = subprocess.Popen(cmd, cwd=MOBILE_DIR, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, text=True, bufsize=1, errors="replace")
        self.lock = threading.Lock()
        threading.Thread(target=self._pump, daemon=True).start()

    def _pump(self):
        tag = f"[{self.device}] "
        for line in self.proc.stdout:
            if READY_MARKER in line:
                self.ready.set()
            sys.stdout.write(tag + line)
            sys.stdout.flush()
        self.ready.set()  # process ended: never block the next device

    def send(self, key):
        with self.lock:
            if self.proc.poll() is None:
                try:
                    self.proc.stdin.write(key)  # one character: Flutter reads keystrokes
                    self.proc.stdin.flush()
                except OSError:
                    pass


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--device", default="emulator-5554",
                        help="device id, comma-separated ids, or 'all' (connected Android devices)")
    parser.add_argument("--api", default=DEFAULT_API, help="backend origin passed as API_BASE_URL")
    args = parser.parse_args()

    devices = android_devices() if args.device == "all" else [d.strip() for d in args.device.split(",") if d.strip()]
    if not devices:
        sys.exit("[dev_run] no devices found")
    flutter = shutil.which("flutter.bat") or shutil.which("flutter") or "flutter"
    print(f"[dev_run] {', '.join(devices)} -> {args.api}")
    print("[dev_run] auto hot reload on save; type r / R / q + Enter for reload / restart / quit")

    runs = []

    def start_all():
        for device in devices:
            run = DeviceRun(flutter, device, args.api)
            runs.append(run)
            run.ready.wait()  # next build only after this device is running

    def send_all(key):
        for run in list(runs):
            if run.ready.is_set():
                run.send(key)

    def forward_keys():
        for line in sys.stdin:
            key = line.strip()[:1]
            if key:
                send_all(key)

    def watch_sources():
        lib = os.path.join(MOBILE_DIR, "lib")
        pubspec = os.path.join(MOBILE_DIR, "pubspec.yaml")
        last, pub = dart_snapshot(lib), os.stat(pubspec).st_mtime_ns
        while True:
            time.sleep(0.7)
            now = dart_snapshot(lib)
            if now != last:
                time.sleep(0.3)  # let editors finish writing
                last = dart_snapshot(lib)
                print("[dev_run] change detected -> hot reload")
                send_all("r")
            try:
                current = os.stat(pubspec).st_mtime_ns
            except OSError:
                current = pub
            if current != pub:
                pub = current
                print("[dev_run] pubspec.yaml changed: quit (q) and start again to pick up packages")

    threading.Thread(target=forward_keys, daemon=True).start()
    threading.Thread(target=watch_sources, daemon=True).start()
    starter = threading.Thread(target=start_all, daemon=True)
    starter.start()
    try:
        starter.join()
        while any(run.proc.poll() is None for run in runs):
            time.sleep(0.5)
    except KeyboardInterrupt:
        send_all("q")
    return 0


if __name__ == "__main__":
    sys.exit(main())
