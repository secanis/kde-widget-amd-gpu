#!/usr/bin/env bash
# Toggles the panel popup of the installed widget from the command line, so the
# open/close/reopen cycle can be exercised without touching the mouse (works on
# Wayland). It assigns a temporary global shortcut to the first panel instance,
# invokes it via kglobalaccel, and removes the shortcut again.
#
# Usage: tools/toggle-popup.sh [count] [delay-seconds]
set -euo pipefail
ID=${PLUGIN_ID:-$(python3 -c "import json;print(json.load(open('$(dirname "$0")/../package/metadata.json'))['KPlugin']['Id'])")}
COUNT=${1:-4}
DELAY=${2:-2}
KEY="Meta+Ctrl+Alt+F12"

plasma_js() {
  busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$1" | sed -e 's/^s "//' -e 's/"$//'
}

WIDGET=$(plasma_js "for (const p of panels()) { for (const id of p.widgetIds) { const w=p.widgetById(id); if (w.type=='$ID') { w.globalShortcut='$KEY'; print(id); break } } }")
if [ -z "$WIDGET" ]; then
  echo "no panel instance of $ID found" >&2
  exit 1
fi
cleanup() { plasma_js "for (const p of panels()) { for (const id of p.widgetIds) { if (id==$WIDGET) p.widgetById(id).globalShortcut='' } }" >/dev/null; }
trap cleanup EXIT
sleep 1

echo "widget $WIDGET: toggling popup $COUNT times, ${DELAY}s apart (watch the panel)"
for i in $(seq 1 "$COUNT"); do
  busctl --user call org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component invokeShortcut s "activate widget $WIDGET"
  echo "  toggle $i"
  sleep "$DELAY"
done
