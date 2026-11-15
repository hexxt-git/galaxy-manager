// Chunky arrow head pointing right, centred on (0, 0), for the way-finding pointer (the game rotates it).
function markArrow() {
  const head = rounded([[8, 0], [-7.5, -7.5], [-4.5, 0], [-7.5, 7.5]], 1.4);
  path(head, true);
  ctx.fillStyle = '#f2c230';
  ctx.fill();
  stroke(2.2);
}

registerProp('mark_arrow', { w: 20, h: 18, ox: 10, oy: 9, draw: markArrow, pal: () => [INK, '#f2c230'] });
