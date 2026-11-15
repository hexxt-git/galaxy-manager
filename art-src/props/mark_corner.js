// One L-shaped corner bracket, the top-left one: origin on the corner point, arms running right and down.
// The game rotates/mirrors four copies around a station footprint.
function markCorner() {
  const L = [[9, 0], [0, 0], [0, 9]];
  pen(L, 5.4, INK, 0);
  pen(L, 2.6, '#f2c230', 0);
}

registerProp('mark_corner', { w: 15, h: 15, ox: 3, oy: 3, draw: markCorner, pal: () => [INK, '#f2c230'] });
