// Outcrop minigame (scripts/colony/minigames/outcrop.gd): a close-up of the grey outcrop rock. A rock hammer strikes
// the sample chunk; cracks spread round it tap by tap until it breaks free. Rock-sprite coordinates, top-left origin;
// the skin mirrors MGO.strike and the chunk box (MGO.box).
const MGO = {
  fleck: '#4fd6d0', fleckDark: '#2a9a98', hollow: '#4c505a',
  steel: '#8a909c', steelDark: '#555a68', grip: '#e8803a', gripDark: '#a8532a',
  btn: '#e1e8ef', btnDark: '#a9b6c7', btnLip: '#66768c',
  w: 240, h: 142,
  strike: [126, 50],
  box: [100, 40, 52, 52],  // x, y, w, h of the chunk / socket sprites inside the rock sprite
  chunk: [[105, 56], [118, 45], [138, 46], [149, 58], [145, 80], [130, 87], [112, 85], [104, 70]],
  fold: [[96, 70], [110, 68], [126, 67], [142, 69], [156, 71]],
};

function mgoCircle(cx, cy, r, n = 48) {
  const out = [];
  for (let i = 0; i < n; i++) out.push([cx + r * Math.cos(i / n * 2 * Math.PI), cy + r * Math.sin(i / n * 2 * Math.PI)]);
  return out;
}

function mgoRockPart(R) {
  const sil = shape(rounded(R.sil, R.r), ROCK.lit, 0, AMP);
  clipTo(sil, () => {
    blob([...R.edge, [R.edge[R.edge.length - 1][0], 200], [R.edge[0][0], 200]], ROCK.dark);
    for (const v of R.veins || []) { const p = shape(rounded(v, 0.8), MGO.fleck, 0, AMP); path(p, true); stroke(DETAIL); }
    pen(R.edge, LINE, INK, AMP);
    for (const c of R.cracks || []) pen(c, DETAIL, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

function mgoRock() {
  seed = 4101;
  blob(rounded(rect(6, 128, 234, 140), 5), GROUND);
  mgoRockPart({
    sil: [[16, 134], [10, 96], [16, 60], [36, 34], [64, 24], [92, 28], [108, 20], [150, 18], [182, 28], [206, 46], [226, 74], [232, 106], [224, 134]],
    edge: [[0, 80], [28, 86], [58, 80], [84, 72], ...MGO.fold.slice(1, 4), [172, 76], [200, 84], [244, 92]],
    veins: [
      [[22, 98], [38, 94], [50, 104], [42, 112], [28, 108]],
      [[160, 92], [176, 88], [188, 102], [178, 110], [166, 104]],
      [[204, 98], [216, 94], [222, 110], [210, 114]],
      [[62, 112], [74, 108], [80, 120], [68, 122]],
    ],
    cracks: [[[64, 24], [68, 40], [62, 52]], [[190, 34], [184, 50]]],
    r: 10,
  });
  mgoRockPart({
    sil: [[4, 136], [2, 116], [12, 102], [30, 100], [48, 108], [54, 124], [50, 136]],
    edge: [[-4, 118], [20, 122], [58, 116]],
    veins: [[[28, 124], [38, 122], [42, 130], [32, 132]]],
    r: 6,
  });
  mgoRockPart({
    sil: [[190, 136], [192, 120], [204, 112], [222, 114], [234, 124], [234, 136]],
    edge: [[186, 124], [210, 127], [240, 122]],
    r: 5,
  });
  mgoChunk();
}

// The sample chunk, in rock coordinates: an inked lump set into the rock, and the sample sprite once broken free.
function mgoChunk() {
  seed = 4201;
  const sil = shape(rounded(MGO.chunk, 1.5), ROCK.lit, 0, AMP);
  clipTo(sil, () => {
    blob([...MGO.fold, [156, 100], [96, 100]], ROCK.dark);
    pen(MGO.fold, LINE, INK, AMP);
    const fl = shape(rounded([[122, 73], [134, 71], [137, 80], [126, 82]], 0.8), MGO.fleck, 0, AMP);
    path(fl, true); stroke(DETAIL);
  });
  path(sil, true); stroke(LINE);
}

// The hole the chunk leaves: deep shadow under the top lip, its lit floor below, a fresh teal glint.
function mgoSocket() {
  seed = 4301;
  const sil = shape(rounded(MGO.chunk, 1.5), MGO.hollow, 0, AMP);
  clipTo(sil, () => {
    blob(rounded(MGO.chunk.map(([x, y]) => [x, y + 12]), 3), ROCK.dark);
    const fl = shape(rounded([[118, 76], [128, 74], [130, 80], [121, 82]], 0.8), MGO.fleck, 0, AMP);
    path(fl, true); stroke(DETAIL);
  });
  path(sil, true); stroke(LINE);
}

// Jagged crack from a to b: split into three with a sideways kink.
function mgoJag(a, b) {
  const dx = b[0] - a[0], dy = b[1] - a[1], len = Math.hypot(dx, dy) || 1, nx = -dy / len, ny = dx / len;
  const k1 = rr(-1.8, 1.8), k2 = rr(-1.8, 1.8);
  return [a, [a[0] + dx / 3 + nx * k1, a[1] + dy / 3 + ny * k1], [a[0] + dx * 2 / 3 + nx * k2, a[1] + dy * 2 / 3 + ny * k2], b];
}

// Cracks added by each tap (taps 1..5; the 6th breaks the chunk out): a star on the chunk, then spreading out from its edge.
const MGO_CRACKS = [
  [[[126, 50], [121, 54]], [[126, 50], [131, 55]], [[126, 50], [126, 57]]],
  [[[116, 46], [110, 36]], [[136, 45], [142, 34]]],
  [[[106, 54], [94, 50]], [[148, 56], [162, 52]], [[121, 54], [116, 62]]],
  [[[104, 72], [90, 80]], [[146, 78], [160, 86]], [[110, 36], [104, 28]], [[142, 34], [150, 28]]],
  [[[132, 88], [134, 102]], [[114, 86], [108, 100]], [[94, 50], [84, 46]], [[162, 52], [172, 56]], [[131, 55], [138, 62]]],
];

function mgoCrack(stage) {
  return () => {
    seed = 4401;
    for (let s = 0; s < stage; s++) for (const [a, b] of MGO_CRACKS[s]) pen(mgoJag(a, b), DETAIL, INK, 0);
  };
}

// Geologist's hammer, (0, 0) = where the striking face meets the rock. Hit pose: handle reaching right, head upright.
// Raised pose: the same hammer swung back about the hand.
function mgoHammer(raise) {
  return () => {
    seed = 4501;
    const hand = [58, -30], a = raise * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
    const rot = pts => pts.map(([x, y]) => {
      const dx = x - hand[0], dy = y - hand[1];
      return [hand[0] + dx * c - dy * s, hand[1] + dx * s + dy * c];
    });
    const part = (pts, fill, w, shade, shadeFill, r = 2) => {
      const p = shape(rounded(rot(pts), r), fill, 0, AMP);
      if (shade) clipTo(p, () => blob(rot(shade), shadeFill));
      path(p, true); stroke(w);
    };
    // handle shaft then grip, from the head to the hand
    part([[2, -18], [46, -30], [47, -24], [3, -12]], MGO.steel, DETAIL, [[0, -14], [50, -27], [50, -20], [0, -8]], MGO.steelDark, 1.5);
    part([[40, -30], [66, -37], [69, -27], [42, -22]], MGO.grip, LINE, [[38, -25], [72, -33], [72, -20], [38, -18]], MGO.gripDark, 3);
    // head: square striking face at the bottom, tapering pick at the top
    part([[-6, -1], [-6, -20], [-2, -36], [1, -40], [3, -36], [6, -20], [6, -1]], MGO.steel, LINE,
      [[1, -42], [10, -42], [10, 2], [1, 2]], MGO.steelDark, 2);
    pen(rot([[-6, -6], [6, -6]]), DETAIL, INK, 0);
  };
}

function mgoChip(teal) {
  return () => {
    seed = teal ? 4601 : 4602;
    const p = shape(rounded([[1.5, 6.5], [1, 3], [4, 1], [8, 2], [8.5, 6], [5, 8]], 1), teal ? MGO.fleck : ROCK.lit, 0, AMP);
    clipTo(p, () => blob(rect(0, 5, 10, 10), teal ? MGO.fleckDark : ROCK.dark));
    path(p, true); stroke(DETAIL);
  };
}

function mgoBurst() {
  const c = 9, star = [];
  for (let i = 0; i < 16; i++) {
    const a = i / 16 * 2 * Math.PI - Math.PI / 2, r = i % 2 ? 2.4 : (i % 4 ? 6 : 8.2);
    star.push([c + Math.cos(a) * r, c + Math.sin(a) * r]);
  }
  path(star, true); ctx.fillStyle = '#ffffff'; ctx.fill(); stroke(1.4);
}

// The big round minigame button (as mg_solar_button) with a rock hammer as its icon.
function mgoButton(pressed) {
  return () => {
    const S = MGO, k = 1.5, cx = 38 * k, cy = 36 * k, R = 34 * k, dy = pressed ? 4 * k : 0;
    seed = 611;
    const lip = shape(mgoCircle(cx, cy + 6 * k, R, 64), S.btnLip, 0, AMP);
    path(lip, true); stroke(LINE);
    const face = shape(mgoCircle(cx, cy + dy, R, 64), S.btn, 0, AMP);
    clipTo(face, () => blob([...smooth([[cx + 40 * k, cy + dy - 6 * k], [cx + 18 * k, cy + dy + 22 * k], [cx - 12 * k, cy + dy + 30 * k],
      [cx - 40 * k, cy + dy + 22 * k]], false, 3), [cx - 40 * k, cy + 60 * k], [cx + 40 * k, cy + 60 * k]], S.btnDark));
    path(face, true); stroke(LINE);
    ctx.save();
    ctx.translate(cx - 36, cy + dy + 23);
    ctx.scale(1.15, 1.15);
    mgoHammer(0)();
    ctx.restore();
  };
}

const mgoRockPal = () => [INK, ROCK.lit, ROCK.dark, MGO.fleck, MGO.hollow, GROUND];
const mgoHammerPal = () => [INK, MGO.steel, MGO.steelDark, MGO.grip, MGO.gripDark];
const [BX, BY, BW, BH] = MGO.box;
registerProp('mg_outcrop_rock', { w: MGO.w, h: MGO.h, ox: 0, oy: 0, draw: mgoRock, pal: mgoRockPal });
registerProp('mg_outcrop_sample', { w: BW, h: BH, ox: -BX, oy: -BY, draw: mgoChunk, pal: mgoRockPal });
registerProp('mg_outcrop_socket', { w: BW, h: BH, ox: -BX, oy: -BY, draw: mgoSocket, pal: mgoRockPal });
for (let i = 1; i <= 5; i++) registerProp('mg_outcrop_crack_' + i, { w: MGO.w, h: MGO.h, ox: 0, oy: 0, draw: mgoCrack(i), pal: () => [INK] });
registerProp('mg_outcrop_hammer', { w: 165, h: 165, ox: 45, oy: 150, scale: [1.5, 1.5], draw: mgoHammer(0), pal: mgoHammerPal });
registerProp('mg_outcrop_hammer_up', { w: 165, h: 165, ox: 45, oy: 150, scale: [1.5, 1.5], draw: mgoHammer(30), pal: mgoHammerPal });
registerProp('mg_outcrop_chip_a', { w: 10, h: 10, ox: 0, oy: 0, draw: mgoChip(false), pal: () => [INK, ROCK.lit, ROCK.dark] });
registerProp('mg_outcrop_chip_b', { w: 10, h: 10, ox: 0, oy: 0, draw: mgoChip(true), pal: () => [INK, MGO.fleck, MGO.fleckDark] });
registerProp('mg_outcrop_burst', { w: 19, h: 19, ox: 0, oy: 0, draw: mgoBurst, pal: () => [INK, '#ffffff'] });
const mgoBtnPal = () => [INK, MGO.btn, MGO.btnDark, MGO.btnLip, ...mgoHammerPal().slice(1)];
registerProp('mg_outcrop_button', { w: 114, h: 120, ox: 0, oy: 0, draw: mgoButton(false), pal: mgoBtnPal });
registerProp('mg_outcrop_button_pressed', { w: 114, h: 120, ox: 0, oy: 0, draw: mgoButton(true), pal: mgoBtnPal });
