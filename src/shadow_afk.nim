# shadow_afk.nim
# ------------------
# Sends periodic mouse movements directly to a target window's message queue.
# Your real cursor never moves.
#
# Build:
#   nimble install winim   (one-time)
#   nim c -d:release -d:strip --opt:speed -d:mingw shadow_afk.nim
#
# Or cross-compile from Linux targeting Windows:
#   nim c -d:release -d:strip --opt:speed --cpu:amd64 --os:windows \
#         --gcc.exe:x86_64-w64-mingw32-gcc \
#         --gcc.linkerexe:x86_64-w64-mingw32-gcc shadow_jiggler.nim

import winim/lean
import std/[strutils, sequtils, random, times, os, strformat, algorithm]

# ── Window enumeration ────────────────────────────────────────────────────────

type WindowEntry = tuple[hwnd: HWND, title: string]

var gWindows: seq[WindowEntry]   # filled by the EnumWindows callback

proc enumCb(hwnd: HWND, lParam: LPARAM): WINBOOL {.stdcall.} =
  if IsWindowVisible(hwnd) == 0:
    return 1   # keep enumerating
  var buf: array[512, WCHAR]
  let len = GetWindowTextW(hwnd, cast[LPWSTR](addr buf[0]), buf.len.int32)
  if len > 0:
    let title = $cast[WideCString](addr buf[0])
    if title.strip().len > 0:
      gWindows.add((hwnd: hwnd, title: title.strip()))
  return 1     # keep enumerating

proc enumVisibleWindows(): seq[WindowEntry] =
  gWindows.setLen(0)
  discard EnumWindows(enumCb, 0)
  gWindows.sort(proc(a, b: WindowEntry): int = cmpIgnoreCase(a.title, b.title))
  return gWindows

# ── Win32 helpers ─────────────────────────────────────────────────────────────

proc getClientSize(hwnd: HWND): tuple[w, h: int] =
  var r: RECT
  discard GetClientRect(hwnd, addr r)
  return (w: r.right.int, h: r.bottom.int)

proc postMouseMove(hwnd: HWND, x, y: int) =
  ## Injects WM_MOUSEMOVE straight into the window's message queue.
  ## The real system cursor does NOT move.
  let lparam = MAKELPARAM(x.WORD, y.WORD)
  discard PostMessageW(hwnd, WM_MOUSEMOVE, 0, lparam)

# ── CLI helpers ───────────────────────────────────────────────────────────────

proc printSeparator() = echo "─".repeat(64)

proc pickWindow(windows: seq[WindowEntry]): WindowEntry =
  echo ""
  printSeparator()
  for idx, entry in windows:
    echo fmt"  [{idx:>3}]  {entry.title}"
  printSeparator()

  while true:
    stdout.write "\nEnter window number (or part of title to filter): "
    let raw = stdin.readLine().strip()
    if raw.len == 0: continue

    # Numeric pick
    if raw.allCharsInSet({'0'..'9'}):
      let n = raw.parseInt()
      if n >= 0 and n < windows.len:
        return windows[n]
      echo fmt"  ✗  Enter a number between 0 and {windows.len - 1}."
      continue

    # Title filter
    let matches = windows.filterIt(raw.toLowerAscii in it.title.toLowerAscii)
    case matches.len
    of 0:
      echo fmt"  ✗  No windows matching '{raw}'. Try again."
    of 1:
      echo fmt"  ✓  Matched: {matches[0].title}"
      return matches[0]
    else:
      echo "  Multiple matches — be more specific or use the number:"
      for entry in matches:
        let origIdx = windows.find(entry)
        echo fmt"      [{origIdx}]  {entry.title}"

proc getInterval(): float =
  stdout.write "\nMovement interval in seconds [default: 60, min: 10]: "
  let raw = stdin.readLine().strip()
  if raw.len == 0: return 60.0
  try:
    let v = raw.parseFloat()
    if v < 10.0:
      echo "  ! Clamped to minimum of 10 seconds."
      return 10.0
    return v
  except ValueError:
    echo "  ! Invalid — using default of 60 seconds."
    return 60.0

# ── Main ──────────────────────────────────────────────────────────────────────

proc main() =
  randomize()

  echo "=" .repeat(64)
  echo "  Shadow Jiggler — keep your remote session alive"
  echo "  (your real cursor stays put the entire time)"
  echo "=" .repeat(64)

  let windows = enumVisibleWindows()
  if windows.len == 0:
    echo "No visible windows found. Exiting."
    quit(1)

  let target   = pickWindow(windows)
  let interval = getInterval()
  const jitter = 0.15   # ±15 % timing variance

  echo ""
  echo fmt"  Target  : {target.title}  (hwnd={target.hwnd})"
  echo fmt"  Interval: ~{interval:.0f}s  (±{jitter*100:.0f}% jitter)"
  echo ""
  echo "  Running — press Ctrl+C to stop."
  echo ""

  var moveCount = 0

  while true:
    if IsWindow(target.hwnd) == 0:
      echo "  ✗  Target window has closed. Exiting."
      break

    let (w, h) = getClientSize(target.hwnd)
    if w == 0 or h == 0:
      let ts0 = now().format("HH:mm:ss")
      echo fmt"  [{ts0}]  ⚠  Window reports zero size — skipping."
    else:
      let cx    = w div 2
      let cy    = h div 2
      let drift = max(min(w, h) div 10, 20)
      let x     = cx + rand(-drift .. drift)
      let y     = cy + rand(-drift .. drift)

      postMouseMove(target.hwnd, x, y)
      inc moveCount
      let ts = now().format("HH:mm:ss")
      echo fmt"  [{ts}]  move #{moveCount:>4}  →  client ({x}, {y})  [window: {w}×{h}]"

    # Sleep interval ± jitter, split into small chunks for responsive Ctrl+C
    let sleepMs = int(interval * 1000.0 * rand(1.0 - jitter .. 1.0 + jitter))
    var elapsed = 0
    while elapsed < sleepMs:
      let chunk = min(200, sleepMs - elapsed)
      sleep(chunk)
      elapsed += chunk

when isMainModule:
  main()
