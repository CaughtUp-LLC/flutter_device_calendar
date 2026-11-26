#!/usr/bin/env python3
"""Verify the example app actually runs on the Android AVD.

Steps:
  1. Ensure emulator-5554 (Pixel_7_Pro_API_35) is booted; start it via
     the PCSetup AVD service when it is not (the sandbox cannot start
     emulators directly).
  2. Install the debug APK built by gradlew assembleDebug.
  3. Launch dev.flutter_device_calendar.example (cold start, LAUNCHER).
  4. PASS (exit 0, "AVD RUN OK") iff the app process is alive and its
     activity is the resumed one; FAIL (exit 1) otherwise.
  5. Save a screenshot to .avd-check/screenshot.png on success.

Stdlib only.
"""
import subprocess
import sys
import time
from pathlib import Path

ADB = r"C:\Users\steph_7kai5dh\AppData\Local\Android\Sdk\platform-tools\adb.exe"
SERIAL = "emulator-5554"
AVD_NAME = "Pixel_7_Pro_API_35"
AVD_SCRIPT = r"D:\Documents\GitHub\GitHub\PCSetup\scripts\android_avd.py"
PKG = "dev.flutter_device_calendar.example"

ROOT = Path(__file__).resolve().parent.parent
APK_CANDIDATES = [
    ROOT / "example" / "android" / "build" / "app" / "outputs" / "apk" / "debug" / "app-debug.apk",
    ROOT / "example" / "build" / "app" / "outputs" / "apk" / "debug" / "app-debug.apk",
    ROOT / "example" / "android" / "app" / "build" / "outputs" / "apk" / "debug" / "app-debug.apk",
]
SHOT_DIR = ROOT / ".avd-check"


def fail(msg, extra=""):
    print("AVD CHECK FAIL: %s" % msg)
    if extra:
        print(extra.strip()[-4000:])
    sys.exit(1)


def adb(*args, timeout=120, binary=False):
    cmd = [ADB, "-s", SERIAL] + list(args)
    r = subprocess.run(cmd, capture_output=True, timeout=timeout)
    if not binary:
        r.stdout = r.stdout.decode("utf-8", "replace")
        r.stderr = r.stderr.decode("utf-8", "replace")
    return r


def device_state():
    out = subprocess.run([ADB, "devices"], capture_output=True,
                         text=True, timeout=30).stdout
    for line in out.splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[0] == SERIAL:
            return parts[1]
    return None


def ensure_emulator():
    state = device_state()
    if state == "device":
        print("emulator already up: %s" % SERIAL)
        return
    print("emulator state=%r; starting %s via AVD service..." % (state, AVD_NAME))
    r = subprocess.run([sys.executable, AVD_SCRIPT, "start", AVD_NAME],
                       capture_output=True, text=True, timeout=300)
    if r.stdout:
        print(r.stdout[-2000:])
    if r.returncode != 0:
        fail("android_avd.py start exited %d" % r.returncode, r.stderr)
    deadline = time.time() + 120
    while time.time() < deadline:
        if device_state() == "device":
            print("emulator ready: %s" % SERIAL)
            return
        time.sleep(5)
    out = subprocess.run([ADB, "devices"], capture_output=True,
                         text=True, timeout=30).stdout
    fail("emulator did not reach 'device' state in 120 s; adb devices:\n" + out)


def wait_booted(deadline=180):
    end = time.time() + deadline
    while time.time() < end:
        r = adb("shell", "getprop", "sys.boot_completed", timeout=30)
        if r.stdout.strip() == "1":
            print("sys.boot_completed=1")
            return
        time.sleep(5)
    fail("sys.boot_completed never reached 1 within %d s" % deadline)


def find_apk():
    for p in APK_CANDIDATES:
        if p.exists():
            return p
    fail("APK not found; looked in:\n" + "\n".join(str(p) for p in APK_CANDIDATES) +
         "\n(run: example\\android\\gradlew.bat -p example\\android assembleDebug)")


def install(apk):
    r = adb("install", "-r", str(apk), timeout=600)
    if r.returncode != 0 or "Success" not in r.stdout:
        fail("adb install failed", r.stdout + r.stderr)
    print("install: %s" % r.stdout.strip())


def launch():
    adb("shell", "am", "force-stop", PKG, timeout=60)
    r = adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1",
            timeout=120)
    if "Events injected: 1" not in r.stdout:
        fail("monkey launch failed", r.stdout + r.stderr)
    print("launch: %s" % r.stdout.strip())


def crash_log():
    try:
        return adb("logcat", "-d", "-b", "crash", "-t", "200", timeout=60).stdout
    except Exception:
        return ""


def app_resumed():
    pid = adb("shell", "pidof", PKG, timeout=60).stdout.strip()
    if not pid:
        return False
    dump = adb("shell", "dumpsys", "activity", "activities", timeout=120).stdout
    pkg_l = PKG.lower()
    for line in dump.splitlines():
        low = line.lower()
        if pkg_l in low and "resumedactivity" in low:
            return True
    return False


def verify(deadline=90):
    end = time.time() + deadline
    while time.time() < end:
        if app_resumed():
            return
        time.sleep(3)
    fail("app process not resumed within %d s" % deadline, crash_log())


def screenshot():
    SHOT_DIR.mkdir(parents=True, exist_ok=True)
    r = adb("exec-out", "screencap", "-p", timeout=120, binary=True)
    if r.returncode != 0 or not r.stdout:
        fail("screencap failed", r.stderr)
    out = SHOT_DIR / "screenshot.png"
    out.write_bytes(r.stdout)
    print("screenshot: %s (%d bytes)" % (out, len(r.stdout)))


def main():
    t0 = time.time()
    ensure_emulator()
    wait_booted()
    apk = find_apk()
    install(apk)
    launch()
    verify()
    screenshot()
    print("AVD RUN OK (%.0f s)" % (time.time() - t0))


if __name__ == "__main__":
    main()

