// Flat ground rings under the focused target: a hazard-yellow band (or cool grey when it can't be used) between two
// thin ink edges, with a pale highlight along the inside. Centred on (0, 0); no ground shadow. Registers both rings.
const MARK_RING = { rx: 30.5, ry: 11.5, band: 7, ink: 1.4 };

function groundRing(lit, light) {
  const R = MARK_RING;
  const oval = (dx, dy, fill) => {
    ctx.beginPath();
    ctx.ellipse(0, 0, R.rx - dx, R.ry - dy, 0, 0, Math.PI * 2);
    ctx.fillStyle = fill;
    ctx.fill();
  };
  const k = R.ry / R.rx;
  const b = R.band, i = R.ink;
  oval(0, 0, INK);
  oval(i, i, lit);
  oval(b - i - 2, (b - i - 2) * k + 0.6, light);
  oval(b - i, (b - i) * k + 0.9, lit);
  oval(b, b * k + 1.2, INK);
  ctx.globalCompositeOperation = 'destination-out';
  oval(b + i, (b + i) * k + 1.4, '#000');
  ctx.globalCompositeOperation = 'source-over';
}

const RING_TONES = { lit: '#f2c230', light: '#fbe58a', grey: '#a3a9b4', greyLight: '#d3d7de' };
registerProp('mark_ring', {
  w: 64, h: 26, ox: 32, oy: 13, draw: () => groundRing(RING_TONES.lit, RING_TONES.light),
  pal: () => [INK, RING_TONES.lit, RING_TONES.light],
});
registerProp('mark_ring_blocked', {
  w: 64, h: 26, ox: 32, oy: 13, draw: () => groundRing(RING_TONES.grey, RING_TONES.greyLight),
  pal: () => [INK, RING_TONES.grey, RING_TONES.greyLight],
});
