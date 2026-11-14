#!/bin/sh
# Exports the workstation prop and its UI pieces from workstation.html into the Godot project.
set -e
S=$(cd "$(dirname "$0")" && pwd)
P="$S/../../assets/art"
mkdir -p "$P/props" "$P/ui"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --allow-file-access-from-files --virtual-time-budget=8000 --dump-dom "file://$S/../workstation.html" 2>/dev/null > "$S/workstation.dom"
"$S/../.venv/bin/python" -I - "$S/workstation.dom" "$P" <<'PY'
import sys, re, base64, io, pathlib
from PIL import Image
dom = pathlib.Path(sys.argv[1]).read_text()
if 'data:image/png' not in dom:
    sys.exit('workstation.html produced no sprites (script error?)')
for name, u in re.findall(r'([\w/]+) data:image/png;base64,([A-Za-z0-9+/=]+)', dom):
    im = Image.open(io.BytesIO(base64.b64decode(u)))
    im.save(pathlib.Path(sys.argv[2]) / f'{name}.png')
    print(name, im.size)
for line in re.findall(r'(?:origin|ninepatch) [\w/]+ [\d. ]+', dom):
    print(line.strip())
PY
rm "$S/workstation.dom"
