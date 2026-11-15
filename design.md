# Moon Crew: art design

Rules worked out from the art in `assets/art/` and its sources in `art-src/`. New art should follow them unless there's a deliberate reason to break one.

## Vibe

A friendly, lived-in space station drawn like a cartoon: chunky, rounded, ink-outlined shapes in flat colours, rendered as crisp pixel art. It should read like a toy model of a workplace, not a gritty sci-fi set. Rooms feel used, with scuffs, stains, cables and hazard tape, but nothing looks broken or scary. The station is mostly cool greys and steel blues, with a few warm, saturated objects that catch the eye: a red chair, a brass generator, green plants, a glowing tank.

Keywords: **chunky, rounded, flat, inked, cozy-industrial, readable at a glance.**

## Rendering pipeline

- Everything is drawn as **vector paths with a round brush**, then pixelated at native size with a **fixed per-sprite palette** (`art-src/pixel/pixelate.js`). Each art pixel is supersampled 8×8 and takes the most common palette colour. Blends never produce new colours, so there is **no anti-aliasing** in the exports.
- Floors and decals are drawn straight at pixel size in Python with the same wobbly-brush look.
- **Game density:** the character is about 70 art px tall (`DENSITY 0.75`). The game shows art at **2× with nearest-neighbour filtering** (`StationMap.SCALE = 2`, texture filter nearest). Never scale art by non-integer amounts.
- **Global contrast 0.9:** every exported fill is pulled 10% toward mid grey (`CONTRAST` in `pixelate.js` and `contrast.py`). Author colours at full strength and let the pipeline soften them. Ink and key colours are exempt.
- Previews are judged only on the exported PNGs, upscaled with nearest-neighbour and shown next to the character for scale. The smooth vector render is not the art.

## Line

- **One ink colour:** `#0d0d12` (near-black, slightly blue). Every outline and dark detail uses it. Don't use coloured lines.
- **Outer silhouette:** `LINE = 5 × 0.93 × 0.75 ≈ 3.5 art px`. Every prop, the character and the UI have a closed, bold outline.
- **Interior detail lines:** `DETAIL = LINE × 0.68 ≈ 2.4 px`. Door seams, panel insets, shelf edges and the horizon between top and front all use this weight. The one exception is the horizon line on simple boxes such as the crate and locker, which uses full LINE.
- **Round caps and joins** everywhere. Corners are cut back (`rounded()`) and then Chaikin-smoothed, so boxes read as softly rounded slabs. Long edges stay straight and only corners curve.
- **Pen wobble:** strokes have a small hand-drawn waver (`WOBBLE 0.35`, two sine harmonics). Each prop pins a `seed`, so its wobble is deterministic. Lines should look confidently hand-inked: never ruler-perfect, never sketchy.

## Shading: two flat tones

- Each material gets exactly **two tones: `lit` and `dark`**. The dark tone is a second flat paint layer, not a gradient, and it is darker and slightly cooler or more saturated than the lit tone.
- **Light comes from straight above.** Top faces are lit and front-facing vertical faces are dark. Most props are a lit top slab over a dark front band, split by an ink line.
- There are no gradients, dithering, specular highlights or rim lights in sprites. The only "highlight" is a separate lit-coloured shape, such as a visor glint or a screen.
- Per-sprite palettes stay tiny: **3–6 colours for simple props** (ink + lit + dark + ground key) and **around 11 at most** for busy multi-material ones.

## Perspective and footprint

- Use a **top-down 3/4 view**: you see the top face and the front face of everything, and no side faces. Shapes are frontal, not isometric.
- Round things are **squashed ellipses** (tables, the reactor base, planters, the dish). Their front rim shows as a dark band.
- **The origin is the bottom-centre of the ground contact**, on the centreline of the bottom outline, the same way the character's feet sit on its origin. Sprites y-sort from that point.
- Props that tile in a row (lockers, the electrical panel, walls) have **straight vertical sides** so neighbours butt together cleanly.

## Ground shadows

- Every standing object has a **soft-cornered, slightly wobbly oval or rounded-rect shadow** under its footprint, offset a little to the right.
- In the source it's drawn in the key colour `#ff00ff` and exported as **exactly RGBA (24, 24, 40, 56)**. The `room_light` shader detects alpha 56/255 and redraws it as a neutral shadow that responds to room light. Don't use alpha 56 for anything else.
- The character's shadow is a separate texture (`character/shadow.png`, 19×5 radii) with the same colour and alpha.

## Colour

### Materials (lit / dark)

| Material | Lit | Dark | Used on |
|---|---|---|---|
| Pale steel | `#bcd0cd` | `#86a1a2` | lockers, electrical panel, reactor shell |
| Cool steel | `#a9bcc4` | `#6b818c` | bases, plinths |
| Gunmetal | `#8a909c` | `#555a68` | pipes, legs, chair bases, caps |
| Dark machinery | `#4b505e` / `#3d4250` | `#2c2f3a` / `#2a2d38` | grilles, cables, slats |
| Station blue | `#4a92c9` | `#2b5c91` | tables, benches (the "furniture" colour) |
| Crate green | `#5f9c80` | `#336355` | crates, storage boxes |
| Brass | `#c9a548` | `#8a6733` | generator, flanges, collars |
| Accent red | `#c8453f` | `#8a2b33` | chair, valve wheels, labels |
| Planter purple | `#b07cc6` | `#7a4f96` | hydro planter |
| Terracotta | `#d0703f` | — | plant pots |

### Accents (small areas only)

- Plant leaves `#5fbf45` / `#b5dc4f`. Bio-fluid `#8fcf63`.
- Screens and glow `#6fd0d8`, `#5fc9b8`. Status LED green `#7ed957`, LED red `#c8453f`.
- Hazard yellow `#f2c230` (warning signs) and floor stripe yellow `(206, 176, 84)`.
- Cloth, paper and glass `#dfe7e4` / `#c4d8d4`. Burlap `#b08a5a`, rope `#e3cf8e`.

### Rules

- **Mid-value, slightly desaturated bases with one saturated hero colour per prop.** For example, the generator is brass with one green LED, and the panel is pale steel with one yellow warning sign.
- Neutrals lean **cool (blue-green grey)**. Warm colours are kept for objects people care about: food, plants, power, seating.
- Bright, high-saturation colour belongs to the **crewmates**. Props shouldn't compete with them.

### Crewmates

The body uses two key colours in `character.png`: pure red `#ff0000` for lit and pure blue `#0000ff` for shadow. These are recoloured at runtime (`character_recolor.gdshader`, `COLOURS` in `scripts/crewmate.gd`). There are ten saturated player colours (red, blue, green, pink, orange, yellow, black, white, purple, cyan), each a lit tone plus a darker, cooler shadow. The visor is `#95cadc` / `#4f7d93` with a white glint. Pure red and pure blue are reserved for keys and must not appear in other art.

## Character

- A chunky, big-bodied bean with a short pair of legs, a backpack on the back and a wide visor. It faces right. The idle pose is the only exported frame.
- Motion is done in code, not frames: a hop (`HOP 6`), lean and sway at about 5.6 steps per second.
- The character is the scale reference for everything else: the 34×49 sprite, stored at 2× (68×98) and drawn at scale 1.2. A crate is roughly one character wide, a locker about 1.3× as tall, and a table seats several.

## Floors

- Each room has its own seamless tile, drawn with the same **round-brush wobble lines** (brush radius 1.6 px, amplitude 1.4). Grout and seams are slightly wavy and never ruled.
- **Floors are low-contrast and mid-to-light value** so props and crewmates pop. Adjacent tiles differ by only about 10–20 RGB.
  - Cafeteria: cream diamond checker `(220,220,210)` / `(199,199,187)`.
  - Storage: blue-grey square tiles `(150,160,170)` with yellow guide stripes.
  - Control: dark olive metal plates `(120,116,96)` with rivets and vent slots, graded darker (`ROOM_GRADE` exponent 2.0, light 0.765).
- **Decals** add wear: cracks, stains, scuffs, oil, scorch marks, drains, hatches and hazard squares. They use only the floor's own palette (a step lighter or darker), carry **no ink outline**, and are scattered sparsely (about one per 14k–45k art px²). Grid-shaped decals snap to the tile period.

## Walls

- Walls are slate blue-grey slabs drawn in front view. The flat top band is lighter, the face below is darker and divided by evenly spaced vertical seams, and an ink line runs along the floor edge. Each wall is 115 px tall and tiles every 64 px.
- Side walls are thin vertical strips. Doors are rounded-top openings cut into the wall face.
- Outside the station is near-black navy. The outer hull is a lighter grey rim with rounded corners.

## Lighting and atmosphere (in engine)

- **Room light** is per room: a brightness multiplier and a contrast exponent applied to every sprite in the room (`room_light.gdshaderinc`). Crewmates fade between room values as they walk through doors.
- **Floor AO** darkens floor corners in two **hard-stepped bands** with wobbly edges, snapped to a 4 px grid. Dim rooms get deeper corners.
- **Line of sight** dims what the player can't see to `(0.7, 0.7, 0.74)`. Changes **dissolve with an 8×8 Bayer dither** on a world-locked 4 px grid.
- All lighting effects are **stepped or dithered, never smooth gradients**, so they stay consistent with the pixel art.
- Selection is shown as a solid, pixel-crisp **yellow outline** `(1, 0.86, 0.2)`, 2 px around the sprite silhouette.

## UI

- UI uses the same language as the props: ink-outlined, rounded, two-tone, pixelated at the same density.
- The main action is a big round **USE** button: pale grey face, dark rim below, pointing-hand icon and bold black caps. It has a pressed state and a faded grey disabled state.
- Panels are slate with a lighter header band. The close button is a red square with a white X. Screen icons are green terminal screens.
- The font is **Fredoka** (rounded, friendly) in ink `#0d0d12`.

## Checklist for new art

1. Draw in `art-src` with the shared helpers (`shape`, `pen`, `rounded`, `clipTo`, `LINE`, `DETAIL`). Pin a `seed`.
2. Use a lit top and dark front, with two flat tones per material taken from the table above.
3. Give it a closed ink silhouette, interior lines at DETAIL weight, and round corners.
4. Give it a ground shadow in `#ff00ff`, with the origin at the bottom-centre of the footprint.
5. Keep at most one saturated hero accent, and keep the palette small.
6. Size it against the character and check it at 2× nearest on the floor tiles before it ships.
