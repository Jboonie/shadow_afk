# Shadow AFK

**Keep your Shadow.Tech remote session alive without moving your real cursor.**

A lightweight Windows utility that sends periodic mouse-move messages directly to a chosen window. It prevents Shadow.Tech (and similar remote/cloud PC) sessions from timing out when you're away, while leaving your actual mouse position unchanged—so you can keep working on your local machine without triggering the remote idle timeout.

---

## Features

- **Cursor stays put** — Injects `WM_MOUSEMOVE` into the target window's message queue; your system cursor never moves.
- **Pick any window** — Lists visible windows by title; choose by index or search by partial title.
- **Configurable interval** — Movement interval in seconds (default 60s, minimum 10s) with ±15% jitter to avoid fixed patterns.
- **Low footprint** — Single executable, no GUI; runs in a console. Stop with **Ctrl+C**.
- **Robust** — Exits cleanly if the target window is closed; sleeps in small chunks for responsive interrupt handling.

---

## Requirements

- **Windows** (the app uses the Win32 API; your real machine can be any OS for development).
- **Nim** ≥ 2.2.2 ([install Nim](https://nim-lang.org/install.html)).
- **Nimble** (included with Nim) for dependency management.

---

## Installation & Dependencies

1. **Install Nim** (if needed):

   - **Windows:** [Download the installer](https://nim-lang.org/install.html) or use [choosenim](https://github.com/dom96/choosenim).
   - **macOS/Linux:** e.g. `curl https://nim-lang.org/choosenim/init.sh -sSf | sh` then `choosenim stable`.

2. **Clone the repository:**

   ```bash
   git clone https://github.com/YOUR_USERNAME/shadow_afk.git
   cd shadow_afk
   ```

3. **Install dependencies** (one-time):

   ```bash
   nimble install
   ```

   This installs [winim](https://github.com/khchen/winim) (Win32 bindings for Nim) as specified in `shadow_afk.nimble`.

---

## Building & Deployment

Build and run from the project root (Nimble will use `srcDir` from `shadow_afk.nimble`).

### Development build (quick iteration)

```bash
nimble build
```

Runs a debug build; output is in the project directory.

### Release build (for deployment)

Optimized, stripped binary for distribution or running on the Shadow PC:

```bash
nim c -d:release -d:strip --opt:speed -d:mingw -p:src src/shadow_afk.nim
```

Or using the Nimble package name (from repo root):

```bash
nim c -d:release -d:strip --opt:speed -d:mingw shadow_afk
```

Binary will be named `shadow_afk.exe` (or `shadow_afk` on some setups). Copy this single executable to the Windows machine (e.g. your Shadow.Tech session); no runtime dependencies beyond Windows.

### Cross-compile from Linux to Windows

To build the Windows executable from a Linux host (e.g. for CI or a single binary to copy):

```bash
nim c -d:release -d:strip --opt:speed --cpu:amd64 --os:windows \
  --gcc.exe:x86_64-w64-mingw32-gcc \
  --gcc.linkerexe:x86_64-w64-mingw32-gcc \
  -p:src src/shadow_afk.nim
```

Requires a MinGW cross-compiler, e.g.:

- **Debian/Ubuntu:** `sudo apt install mingw-w64`
- **Fedora:** `sudo dnf install mingw64-gcc`

---

## Usage

1. **Start the executable** on the Windows session you want to keep alive (e.g. inside your Shadow.Tech desktop):

   ```bash
   ./shadow_afk.exe
   ```

2. **Choose a window** from the numbered list (e.g. the Shadow client window, or a game/app you leave open). You can enter:
   - A number (e.g. `0`, `1`) to select by index, or  
   - Part of the window title to filter; if exactly one match is found, it is selected.

3. **Set the movement interval** when prompted (in seconds). Default is 60; minimum is 10. Press Enter to accept the default.

4. The program will post a mouse-move message to the target window at roughly that interval (with slight random jitter). **Your real cursor does not move.** To stop, press **Ctrl+C**.

Example:

```
================================================================
  Shadow Jiggler — keep your remote session alive
  (your real cursor stays put the entire time)
================================================================

────────────────────────────────────────────────────────────────
  [  0]  Shadow - Windows
  [  1]  Notepad
────────────────────────────────────────────────────────────────

Enter window number (or part of title to filter): shadow
  ✓  Matched: Shadow - Windows

Movement interval in seconds [default: 60, min: 10]: 45

  Target  : Shadow - Windows  (hwnd=...)
  Interval: ~45s  (±15% jitter)

  Running — press Ctrl+C to stop.

  [14:32:01]  move #   1  →  client (512, 384)  [window: 1024×768]
  ...
```

---

## How it works

The program uses the Windows API to:

1. **Enumerate** visible top-level windows (`EnumWindows`).
2. **Post** `WM_MOUSEMOVE` messages to the selected window’s message queue (`PostMessageW`), with coordinates inside the window’s client area (center ± a small random offset).

Because it uses `PostMessage` (not `SendInput` or moving the system cursor), only the target window “sees” the movement. The rest of the system—and your physical cursor—are unchanged. Many remote/idle-detection systems treat such activity as user input, so the session stays active.

---

## License

MIT. See the project’s license file for details.

---

## Author

**Jay Walker**

If you find this useful for Shadow.Tech or similar setups, consider starring the repo or opening an issue for suggestions.
