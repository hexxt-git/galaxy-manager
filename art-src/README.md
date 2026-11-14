# art-src

Sources for the pixel art in `assets/art/`. Shapes are drawn as round-brush canvas paths, then rendered at native pixel size with a fixed palette (`pixel/pixelate.js`). Floors are drawn directly in Python.

- `character.html` — character geometry; `pixel/build.py` copies it into `pixel/character.js`. Only the idle frame is exported; the game animates it with a hop.
- `props/<name>.js` — one prop each (some register several, e.g. wall pieces), sharing `props/prop.js`. Preview with `props/view.html?crate,bench`. Every prop file is exported automatically.
- `workstation.html` — the workstation sprite, exported by `pixel/export_workstation.sh`.
- `pixel/floor.py`, `pixel/room_floors.py`, `pixel/floor_decals.py` — the cafeteria floor tile, the other room floors, and the scattered floor details.
- `pixel/export_godot.sh` — regenerates the character, the floors, the props and the workstation into `assets/art/`.
- `map_preview.py` — renders the layout in `scripts/map/station_map.gd` to a PNG without running the game.

Setup: `python3 -m venv .venv && .venv/bin/pip install pillow numpy`. Run the Python scripts with `.venv/bin/python -I`.
