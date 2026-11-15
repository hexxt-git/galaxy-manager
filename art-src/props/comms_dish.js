// A big comms dish facing up at the sky on a short mount: bright rim, pale bowl, feed horn held over the centre on struts.
const COMMS = {
  rim: '#f6f3e8', shell: '#bcd0cd', shellDark: '#86a1a2', base: '#a9bcc4', baseDark: '#6b818c', leg: '#555a68',
  horn: '#e8833a', led: '#7ed957',
  c: [0, -56], R: 43, Ry: 23, thick: 11, rimW: 4.5, hornH: 13, plate: [30, 6, 18],
};

function commsEll([cx, cy], rx, ry, n = 48) {
  const out = [];
  for (let i = 0; i < n; i++) { const t = 2 * Math.PI * i / n; out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); }
  return out;
}

function commsBox(x0, x1, yb, front, depth, lit, dark, r) {
  const yf = yb - front, yt = yf - depth;
  const sil = shape(rounded(rect(x0, yt, x1, yb), r), lit, 0, AMP);
  clipTo(sil, () => { blob(rect(x0 - 4, yf, x1 + 4, yb + 4), dark); pen([[x0, yf], [x1, yf]], DETAIL, INK, AMP); });
  path(sil, true); stroke(LINE);
  return { sil, yf, yt };
}

function commsDish() {
  const D = COMMS, [a, front, depth] = D.plate, [cx, cy] = D.c, P = Math.PI;
  seed = 1341;
  blob(rounded(rect(-a - 4, -depth - 10, a + 6, 4), 8), GROUND);
  const pl = commsBox(-a, a, 0, front, depth, D.base, D.baseDark, 4);
  const led = commsEll([a - 7, pl.yf + 3], 2.4, 1.6, 12);
  blob(led, D.led); path(led, true); stroke(DETAIL);

  const foot = pl.yf - depth / 2;
  const yoke = rounded(rect(-9, cy + 14, 9, foot + 2), 3);
  const ys = shape(yoke, D.leg, 0, AMP);
  clipTo(ys, () => blob(rect(1, cy, 14, foot + 6), INK));
  path(ys, true); stroke(LINE);

  const rim = commsEll(D.c, D.R, D.Ry);
  const back = commsEll([cx, cy + D.thick], D.R * 0.92, D.Ry * 0.95);
  const sil = shape([...rim.filter((_, k) => k >= 24), ...back.filter((_, k) => k <= 24)], D.shellDark, 0, AMP);
  blob(rim, D.rim);
  const bowl = commsEll(D.c, D.R - D.rimW, D.Ry - D.rimW * 0.75);
  clipTo(bowl, () => {
    blob(bowl, D.shellDark);
    blob(commsEll([cx, cy + 9], D.R - D.rimW, D.Ry - D.rimW * 0.75), D.shell);
  });
  path(wobble(bowl, AMP, 4, true), true); stroke(DETAIL);
  path(sil, true); stroke(LINE);
  path(wobble(rim, AMP, 4, true), true); stroke(LINE);

  const f = [cx, cy - D.hornH];
  for (const t of [P * 0.5, P * 1.17, P * 1.83]) {
    const p = [cx + (D.R - D.rimW) * Math.cos(t), cy + (D.Ry - D.rimW) * Math.sin(t)];
    pen([p, f], 3.8, INK, AMP); pen([p, f], 1.4, D.leg, 0);
  }
  const hb = rounded(rect(cx - 4.5, f[1] - 4, cx + 4.5, f[1] + 4), 2);
  const h = shape(hb, D.horn, 0, AMP);
  clipTo(h, () => blob(rect(cx - 6, f[1] + 0.5, cx + 6, f[1] + 6), '#a8532a'));
  path(h, true); stroke(DETAIL);
  const cap = commsEll([cx, f[1] - 4], 4.5, 1.8, 14);
  blob(cap, INK);
}

registerProp('comms_dish', {
  w: 96, h: 107, ox: 48, oy: 101, draw: commsDish,
  pal: () => [INK, COMMS.rim, COMMS.shell, COMMS.shellDark, COMMS.base, COMMS.baseDark, COMMS.leg, COMMS.horn, '#a8532a', COMMS.led, GROUND],
});
