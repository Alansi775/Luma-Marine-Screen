#!/bin/bash
# External liveness watchdog for flutter-pi.service.
#
# Why this exists as a separate process rather than a check inside the
# app itself: a confirmed native GStreamer/VAAPI deadlock (2026-07-05,
# see frontend/lib/core/platform/platform_thread_watchdog.dart) can
# wedge flutter-pi's platform thread AND the Dart UI isolate together —
# a first attempt at an in-app heartbeat over a MethodChannel hung
# right alongside everything else, because sending that heartbeat
# needed the exact same contended native lock. Nothing running inside
# the wedged process can be trusted to notice its own death, so this
# script runs as its own independent systemd service and never touches
# flutter-pi's own machinery — it only reads a heartbeat file the app
# writes via plain `dart:io` file I/O, and shells out to systemctl.
set -euo pipefail

HEARTBEAT_FILE="/run/flutter-pi/pano-heartbeat"
MAX_AGE_SECONDS=30
CHECK_INTERVAL=10

while true; do
  sleep "$CHECK_INTERVAL"

  if [ ! -f "$HEARTBEAT_FILE" ]; then
    # Not up yet, or just (re)started — give it a chance to write its
    # first heartbeat rather than treating absence as a wedge.
    continue
  fi

  now=$(date +%s)
  mtime=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo "$now")
  age=$((now - mtime))

  if [ "$age" -gt "$MAX_AGE_SECONDS" ]; then
    echo "$(date -Iseconds) pano-watchdog: heartbeat is ${age}s stale — flutter-pi appears wedged, restarting"
    systemctl restart flutter-pi.service
  fi
done
