// Lab minigame scanner: a moon rock on a sample tray under an overhead scanner head. The beam (lens bottom at
// art px 100,22 down to the rock top ~33) and the goal lamps (on the front band, y 64..82) are drawn in-engine.
const MG_SCAN = {
  lit: '#bcd0cd', dark: '#86a1a2', metal: '#8a909c', metalDark: '#555a68', frame: '#3d4250',
  tray: '#dfe7e4', rock: '#a9adb2', rockDark: '#7c818b', lens: '#6fd0d8',
  lampOff: '#8a909c', lampOffDark: '#555a68', lampOn: '#7ed957', lampOnLit: '#c8f5a0',
};

function mgScanEll(cx, cy, rx, ry, n = 24) {
  const out = [];
  for (let i = 0; i < n; i++) { const t = i / n * 2 * Math.PI; out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); }
  return out;
}

function mgScanPart(pts, fill, w = DETAIL, shade, shadeFill) {
  const p = shape(pts, fill, 0, AMP);
  if (shade) clipTo(p, () => blob(shade, shadeFill));
  path(p, true); stroke(w);
  return p;
}

function mgLabScanner() {
  const S = MG_SCAN;
  seed = 2201;
  // base slab: lit top, dark front band for the lamps
  const sil = shape(rounded(rect(8, 54, 162, 82), 6), S.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(0, 64, 170, 86), S.dark);
    pen([[8, 64], [162, 64]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
  // post and arm
  mgScanPart(rounded(rect(22, 8, 34, 62), 3), S.metal, LINE, rect(29, 0, 40, 64), S.metalDark);
  mgScanPart(rounded(rect(22, 6, 96, 15), 3), S.metal, LINE, rect(20, 12, 100, 20), S.metalDark);
  // scanner head with lens
  mgScanPart(rounded(rect(84, 2, 116, 19), 4), S.frame, LINE);
  mgScanPart(rounded(rect(93, 16, 107, 23), 2), S.lens);
  pen([[89, 8], [96, 8]], DETAIL, S.lens, 0);
  // sample tray and rock
  mgScanPart(mgScanEll(100, 57, 32, 7), S.tray, LINE, rect(60, 58, 140, 70), S.dark);
  mgScanPart(rounded([[83, 53], [80, 45], [87, 37], [100, 33], [114, 36], [121, 45], [116, 53], [97, 55]], 4),
    S.rock, LINE, [[76, 47], [124, 45], [124, 60], [76, 60]], S.rockDark);
  mgScanPart(mgScanEll(108, 40, 3.4, 2, 14), S.rockDark);
}

function mgLabLamp(on) {
  const S = MG_SCAN;
  return () => {
    seed = on ? 2301 : 2302;
    const p = shape(mgScanEll(8, 8, 6, 6, 24), on ? S.lampOn : S.lampOff, 0, 0);
    clipTo(p, () => blob(on ? mgScanEll(6.5, 6, 2.6, 2, 12) : rect(0, 9, 16, 16), on ? S.lampOnLit : S.lampOffDark));
    path(p, true); stroke(LINE);
  };
}

registerProp('mg_lab_scanner', {
  w: 170, h: 86, ox: 0, oy: 0, draw: mgLabScanner,
  pal: () => [INK, MG_SCAN.lit, MG_SCAN.dark, MG_SCAN.metal, MG_SCAN.metalDark, MG_SCAN.frame, MG_SCAN.tray,
    MG_SCAN.rock, MG_SCAN.rockDark, MG_SCAN.lens],
});
registerProp('mg_lab_lamp_off', { w: 16, h: 16, ox: 0, oy: 0, draw: mgLabLamp(false), pal: () => [INK, MG_SCAN.lampOff, MG_SCAN.lampOffDark] });
registerProp('mg_lab_lamp_on', { w: 16, h: 16, ox: 0, oy: 0, draw: mgLabLamp(true), pal: () => [INK, MG_SCAN.lampOn, MG_SCAN.lampOnLit] });
