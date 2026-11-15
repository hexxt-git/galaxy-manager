// Ice drill minigame: an ice chunk riding up the auger into the hopper, and a puff of vapour from ice the bit boiled off.
const MGD_ICE = { ice: '#c6ecf4', iceDark: '#7cbcd8', puff: '#e4e9f0', puffDark: '#a9b4c2' };

function mgdChunk() {
  seed = 919;
  const pts = Array.from({ length: 6 }, (_, i) => {
    const t = 2 * Math.PI * (i + 0.3) / 6, k = rr(0.85, 1.05);
    return [7 + 5 * k * Math.cos(t), 6 + 4.4 * k * Math.sin(t)];
  });
  const c = shape(rounded(pts, 1.2), MGD_ICE.ice, 0, 0);
  clipTo(c, () => blob(c.map(([x, y]) => [x + 2.6, y + 3]), MGD_ICE.iceDark));
  path(c, true); stroke(DETAIL);
}

function mgdPuff() {
  seed = 923;
  const lobes = [[7, 11, 5], [13, 8, 6], [19, 11.5, 4.8]];
  const all = lobes.map(([x, y, r]) => Array.from({ length: 14 }, (_, i) => [x + r * Math.cos(i / 14 * 6.283), y + r * Math.sin(i / 14 * 6.283)]));
  for (const p of all) { path(p, true); stroke(DETAIL * 2); }
  for (const p of all) blob(p, MGD_ICE.puff);
  for (const [x, y, r] of lobes) blob(Array.from({ length: 14 }, (_, i) => [x + 1 + r * 0.8 * Math.cos(i / 14 * 6.283), y + 1.4 + r * 0.7 * Math.sin(i / 14 * 6.283)]), MGD_ICE.puffDark);
  for (const [x, y, r] of lobes) blob(Array.from({ length: 14 }, (_, i) => [x - 0.4 + r * 0.75 * Math.cos(i / 14 * 6.283), y - 0.6 + r * 0.7 * Math.sin(i / 14 * 6.283)]), MGD_ICE.puff);
}

registerProp('mg_drill_chunk', { w: 14, h: 13, ox: 0, oy: 0, draw: mgdChunk, pal: () => [INK, MGD_ICE.ice, MGD_ICE.iceDark] });
registerProp('mg_drill_puff', { w: 26, h: 19, ox: 0, oy: 0, draw: mgdPuff, pal: () => [INK, MGD_ICE.puff, MGD_ICE.puffDark] });
