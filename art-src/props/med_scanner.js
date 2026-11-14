// A round scanner platform: a short drum with a glowing pad, and an arch standing across its middle.
const MEDSCAN = {
  lit: '#bcd0cd', dark: '#86a1a2', pad: '#6fd0d8', padDark: '#3e93a8', arch: '#a9bcc4', archDark: '#6b818c',
  R: 30, height: 7, fore: 0.55, padR: 20,
  archX: 24, archH: 48, archW: 9, cut: 6,
};

function medscanEllipse(cx, cy, rx, ry, t0, t1, n) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]);
  }
  return out;
}

function medScanner() {
  const M = MEDSCAN, f = M.fore, R = M.R, yb = -f * R, yt = yb - M.height, P = Math.PI;
  seed = 811;
  blob(medscanEllipse(2, yb + 2.5, R + 2, f * (R + 2), 0, 2 * P, 40), GROUND);
  const sil = shape([...medscanEllipse(0, yb, R, f * R, 0, P, 24), ...medscanEllipse(0, yt, R, f * R, P, 2 * P, 24)], M.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-R - 4, yt, R + 4, 4), M.dark);
    blob(medscanEllipse(0, yt, R, f * R, 0, 2 * P, 40), M.lit);
    pen(medscanEllipse(0, yt, R, f * R, -0.1, P + 0.1, 28), LINE, INK, AMP);
    const pad = medscanEllipse(0, yt, M.padR, f * M.padR, 0, 2 * P, 36);
    blob(pad, M.pad);
    const core = medscanEllipse(0, yt, M.padR * 0.45, f * M.padR * 0.45, 0, 2 * P, 20);
    blob(core, M.padDark);
    path(wobble(pad, AMP, 4, true), true); stroke(DETAIL);
    path(wobble(core, AMP, 4, true), true); stroke(DETAIL * 0.8);
  });
  path(sil, true); stroke(LINE);

  const x = M.archX, w = M.archW, h = M.archH;
  const band = [...medscanEllipse(0, yt, x + w / 2, h, P, 2 * P, 28), ...medscanEllipse(0, yt, x - w / 2, h - w, 2 * P, P, 28)];
  const arch = shape(band, M.arch, 0, AMP);
  clipTo(arch, () => {
    blob(smooth([[M.cut, yt - h - 10], [x + w + 4, yt - h - 10], [x + w + 4, yt + 4], [x - w / 2 - 2, yt + 4], [M.cut + 12, yt - h * 0.55]], true, 2), M.archDark);
    
  });
  path(arch, true); stroke(LINE);
}

registerProp('med_scanner', {
  w: 96, h: 111, ox: 46, oy: 102, scale: [1.35, 1.35], draw: medScanner,
  pal: () => [INK, MEDSCAN.lit, MEDSCAN.dark, MEDSCAN.pad, MEDSCAN.padDark, MEDSCAN.arch, MEDSCAN.archDark, GROUND],
});
