#!/usr/bin/env bash
# ============================================================
#  Time Recorder - HTML 同步脚本（bash / Git Bash）
#  以 Time Recorder.html 为唯一权威源，覆盖同步到三处副本：
#    dist/index.html
#    windows/Time Recorder.html
#    harmony-app/entry/src/main/resources/rawfile/index.html
#  用法：bash sync-html.sh
# ============================================================
set -e
cd "$(dirname "$0")"

SRC="Time Recorder.html"
DEST1="dist/index.html"
DEST2="windows/Time Recorder.html"
DEST3="harmony-app/entry/src/main/resources/rawfile/index.html"

[ -f "$SRC" ] || { echo "❌ 找不到权威源 $SRC"; exit 1; }

cp -f "$SRC" "$DEST1" && echo "  [OK] $DEST1"
cp -f "$SRC" "$DEST2" && echo "  [OK] $DEST2"
cp -f "$SRC" "$DEST3" && echo "  [OK] $DEST3"

echo ""
echo "同步完成。三端（网页 / Windows / 鸿蒙）已使用同一份 HTML。"
