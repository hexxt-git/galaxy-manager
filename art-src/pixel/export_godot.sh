#!/bin/sh
# Re-exports the character strip, floor tile and props into the Godot project.
set -e
S=$(cd "$(dirname "$0")" && pwd)
P="$S/../../assets/art"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
python3 "$S/build.py"
"$CHROME" --headless --disable-gpu --virtual-time-budget=8000 --dump-dom "file://$S/stripexport.html" 2>/dev/null > "$S/strip.dom"
"$S/../.venv/bin/python" -I - "$S/strip.dom" "$P/character" <<'PY'
import sys, re, base64, io, pathlib
from PIL import Image
dom = pathlib.Path(sys.argv[1]).read_text()
for name, u in re.findall(r'(\w+) data:image/png;base64,([A-Za-z0-9+/=]+)', dom):
    im = Image.open(io.BytesIO(base64.b64decode(u)))
    im.save(pathlib.Path(sys.argv[2]) / f'{name}.png')
    print(name, im.size)
print(re.search(r'origin [\d.]+ [\d.]+', dom).group())
PY
rm "$S/strip.dom"
"$S/../.venv/bin/python" -I "$S/character_shadow.py" "$P/character/shadow.png"
"$S/../.venv/bin/python" -I "$S/floor.py" "$P/floor_tile.png"
"$S/../.venv/bin/python" -I "$S/room_floors.py" "$P/floors"
"$S/../.venv/bin/python" -I "$S/floor_decals.py" "$P/floors/decals"
# Props: the origin is the pixel corner under the bottom-centre of the ground contact,
# so in Godot use centered = false, offset = -origin.
mkdir -p "$P/props"
# every props/<name>.js except the shared prop.js
NAMES=$(cd "$S/../props" && ls *.js | grep -v "^prop.js$" | sed "s/\.js$//" | paste -sd, -)
"$CHROME" --headless --disable-gpu --virtual-time-budget=8000 --dump-dom "file://$S/../props/view.html?$NAMES&export" 2>/dev/null > "$S/props.dom"
"$S/../.venv/bin/python" -I - "$S/props.dom" "$P/props" <<'PY'
import sys, re, base64, io, pathlib
from PIL import Image
dom = pathlib.Path(sys.argv[1]).read_text()
for name, u in re.findall(r'(\w+) data:image/png;base64,([A-Za-z0-9+/=]+)', dom):
    Image.open(io.BytesIO(base64.b64decode(u))).save(pathlib.Path(sys.argv[2]) / f'{name}.png')
for line in re.findall(r'\w+ size \d+ \d+ origin \d+ \d+', dom):
    print(line)
PY
rm "$S/props.dom"
"$S/export_workstation.sh"
