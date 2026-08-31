#!/usr/bin/env bash
# ============================================================
#  Time Recorder - HTML 同步脚本（bash / Git Bash）
#  以 Time Recorder.html 为唯一权威源，覆盖同步到四处副本：
#    dist/index.html
#    windows/Time Recorder.html
#    harmony-app/entry/src/main/resources/rawfile/index.html
#    C:/TimeRecorderHarmony/entry/src/main/resources/rawfile/index.html
#      (DevEco 鸿蒙开发目录，无空格路径，见 README)
#  用法：bash sync-html.sh
# ============================================================
set -e
cd "$(dirname "$0")"

SRC="Time Recorder.html"
DEST1="dist/index.html"
DEST2="windows/Time Recorder.html"
DEST3="harmony-app/entry/src/main/resources/rawfile/index.html"
DEST4="C:/TimeRecorderHarmony/entry/src/main/resources/rawfile/index.html"

[ -f "$SRC" ] || { echo "❌ 找不到权威源 $SRC"; exit 1; }

cp -f "$SRC" "$DEST1" && echo "  [OK] $DEST1"
cp -f "$SRC" "$DEST2" && echo "  [OK] $DEST2"
cp -f "$SRC" "$DEST3" && echo "  [OK] $DEST3"
if [ -f "$DEST4" ]; then
  cp -f "$SRC" "$DEST4" && echo "  [OK] $DEST4 (DevEco dev dir)"
else
  echo "  [SKIP] $DEST4 (not found; skip if you do not use the no-space DevEco copy)"
fi

echo ""
echo "同步完成。四处副本（网页 / Windows / 鸿蒙 / DevEco 开发目录）已使用同一份 HTML。"
