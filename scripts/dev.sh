#!/usr/bin/env bash
# Developer launcher.
#
# The mobile app (mobile/) is fully offline — it stores everything in a local
# SQLite file on the device, so it does NOT need the Next.js web backend to
# run. By default this script just runs the Flutter app.
#
# Usage:
#   ./scripts/dev.sh                # flutter run on mobile/
#   ./scripts/dev.sh -d "iPhone 15" # extra args go straight to flutter run
#   ./scripts/dev.sh --web          # also boot the Next.js web app on :3000
#   ./scripts/dev.sh --web-only     # just the Next.js web app

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-3000}"
WEB_LOG="${WEB_LOG:-$REPO_ROOT/.web-dev.log}"
WEB_PID=""
RUN_WEB=0
RUN_FLUTTER=1

color() { printf "\033[%sm%s\033[0m" "$1" "$2"; }
info()  { echo "$(color "1;34" "[dev]") $*"; }
err()   { echo "$(color "1;31" "[dev]") $*" >&2; }

cleanup() {
  local code=$?
  if [[ -n "$WEB_PID" ]] && kill -0 "$WEB_PID" 2>/dev/null; then
    info "Stopping web backend (pid $WEB_PID)…"
    kill -- "-$WEB_PID" 2>/dev/null || kill "$WEB_PID" 2>/dev/null || true
    wait "$WEB_PID" 2>/dev/null || true
  fi
  exit "$code"
}
trap cleanup EXIT INT TERM

# Pull our flags out of the arg list before forwarding the rest to flutter.
FLUTTER_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --web)      RUN_WEB=1 ;;
    --web-only) RUN_WEB=1; RUN_FLUTTER=0 ;;
    *)          FLUTTER_ARGS+=("$arg") ;;
  esac
done

start_web() {
  command -v pnpm >/dev/null 2>&1 || { err "pnpm not found (needed for --web)."; exit 1; }
  if curl -fsS "http://localhost:$PORT" >/dev/null 2>&1; then
    info "Reusing existing web server on http://localhost:$PORT."
    return
  fi
  info "Installing web deps + generating Prisma client…"
  (cd "$REPO_ROOT/web" && pnpm install --silent && pnpm prisma generate >/dev/null)

  info "Starting Next.js on http://localhost:$PORT (logs → $WEB_LOG)…"
  : > "$WEB_LOG"
  ( cd "$REPO_ROOT/web" && PORT="$PORT" setsid pnpm dev >>"$WEB_LOG" 2>&1 ) &
  WEB_PID=$!

  info "Waiting for the backend to come up…"
  local tries=60
  while (( tries-- > 0 )); do
    if curl -fsS "http://localhost:$PORT" >/dev/null 2>&1; then
      info "Web backend ready ✅"
      return
    fi
    if ! kill -0 "$WEB_PID" 2>/dev/null; then
      err "Backend exited early. Tail of log:"; tail -n 20 "$WEB_LOG" >&2 || true; exit 1
    fi
    sleep 1
  done
  err "Backend did not respond on port $PORT in time. See $WEB_LOG."; exit 1
}

start_flutter() {
  command -v flutter >/dev/null 2>&1 || { err "flutter not found in PATH."; exit 1; }
  info "Launching Flutter app${FLUTTER_ARGS[*]:+ (args: ${FLUTTER_ARGS[*]})}…"
  cd "$REPO_ROOT/mobile"
  exec flutter run "${FLUTTER_ARGS[@]}"
}

(( RUN_WEB == 1 ))     && start_web
(( RUN_FLUTTER == 1 )) && start_flutter

# --web-only: stay in the foreground until the user kills us so the trap fires.
if [[ -n "$WEB_PID" ]]; then
  info "Web server is the only process. Press Ctrl+C to stop."
  wait "$WEB_PID"
fi
