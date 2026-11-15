#!/bin/sh
# Exports only the named props: export_props.sh solar_panel ice_drill  ->  assets/art/props/<name>.png
set -e
S=$(cd "$(dirname "$0")" && pwd)
P="$S/../../assets/art/props"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
NAMES=$(echo "$@" | tr ' ' ',')
DOM=$(mktemp)
"$CHROME" --headless --disable-gpu --virtual-time-budget=8000 --dump-dom "file://$S/../props/view.html?$NAMES&export" 2>/dev/null > "$DOM"
"$S/../.venv/bin/python" -I - "$DOM" "$P" <<'PY'
import sys, re, base64, io, pathlib
from PIL import Image
dom = pathlib.Path(sys.argv[1]).read_text()
for name, u in re.findall(r'(\w+) data:image/png;base64,([A-Za-z0-9+/=]+)', dom):
    Image.open(io.BytesIO(base64.b64decode(u))).save(pathlib.Path(sys.argv[2]) / f'{name}.png')
for line in re.findall(r'\w+ size \d+ \d+ origin \d+ \d+', dom):
    print(line)
PY
rm "$DOM"
