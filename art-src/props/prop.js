// Shared prop helpers. Each prop lives in its own <name>.js and calls registerProp().
// Props are authored straight in game art pixels (character DENSITY 0.75), with (0, 0) at the bottom-centre of
// the ground contact, on the centreline of the bottom outline, the same way the character's feet sit on its origin.

const LINE = 5 * 0.93 * 0.75;     // the character's outline width at game density
const DETAIL = LINE * 0.68;       // interior lines, same ratio the character uses
const GROUND = '#ff00ff';          // ground-shadow key; exported as a translucent darkening of the floor
const GROUND_RGBA = [24, 24, 40, 56];

// Cuts every corner back by up to r before Chaikin, so corners round off like a round brush while long edges stay straight.
function rounded(pts, r) {
  const out = [];
  const n = pts.length;
  for (let i = 0; i < n; i++) {
    const p = pts[(i + n - 1) % n], c = pts[i], q = pts[(i + 1) % n];
    const lp = Math.hypot(p[0] - c[0], p[1] - c[1]), lq = Math.hypot(q[0] - c[0], q[1] - c[1]);
    const a = Math.min(r, lp * 0.45) / lp, b = Math.min(r, lq * 0.45) / lq;
    out.push([c[0] + (p[0] - c[0]) * a, c[1] + (p[1] - c[1]) * a]);
    out.push([c[0] + (q[0] - c[0]) * b, c[1] + (q[1] - c[1]) * b]);
  }
  return smooth(out, true, 3);
}

function rect(x0, y0, x1, y1) { return [[x0, y0], [x1, y0], [x1, y1], [x0, y1]]; }

// name -> { w, h, ox, oy, draw, pal: () => [colours], scale?: [sx, sy] }. The origin is the art pixel boundary under (0, 0).
// `scale` sizes the geometry only: strokes go through the unscaled transform, so LINE and DETAIL stay put.
const PROPS = {};
function registerProp(name, spec) { PROPS[name] = spec; }

let lineBase = null;
function stroke(w, color = INK) {
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.lineWidth = w;
  ctx.strokeStyle = color;
  if (!lineBase) return ctx.stroke();
  ctx.save();
  ctx.setTransform(lineBase);
  ctx.stroke();
  ctx.restore();
}

function drawProp(P) {
  const [sx, sy] = P.scale || [1, 1];
  lineBase = ctx.getTransform();
  ctx.save();
  ctx.scale(sx, sy);
  P.draw();
  ctx.restore();
  lineBase = null;
}

function sprite(name) {
  const P = PROPS[name];
  const cv = pixelate(P.w, P.h, P.pal(), g => { ctx = g; ctx.translate(P.ox, P.oy); drawProp(P); });
  const g = cv.getContext('2d');
  const img = g.getImageData(0, 0, P.w, P.h);
  const key = hexRgb(GROUND);
  for (let i = 0; i < img.data.length; i += 4) {
    if (img.data[i + 3] && img.data[i] === key[0] && img.data[i + 1] === key[1] && img.data[i + 2] === key[2]) {
      img.data.set(GROUND_RGBA, i);
    }
  }
  g.putImageData(img, 0, 0);
  return cv;
}

const CHAR = { w: 75, h: 80, ox: 37.65, oy: 77.0625 };
function characterSprite(colour) {
  return pixelate(CHAR.w, CHAR.h, [INK, ...PAL[colour], '#95cadc', '#4f7d93', '#ffffff'], g => {
    ctx = g; character(CHAR.ox, CHAR.oy, colour, 0.93 * 0.75, false, 'idle');
  });
}

// Export dump (for export_godot.sh) or a preview: each prop in vector at 5x, then at game density on the
// floor beside a character, at 1x, 2x (in game) and 3x.
function propPage(names) {
  if (location.search.includes('export')) {
    const lines = [];
    for (const name of names) {
      const P = PROPS[name];
      lines.push(name + ' ' + sprite(name).toDataURL('image/png'));
      lines.push(name + ' size ' + P.w + ' ' + P.h + ' origin ' + P.ox + ' ' + P.oy);
    }
    document.getElementById('dump').textContent = lines.join('\n');
    return;
  }
  const VS = 5, PAD = 30;
  const vecW = names.map(n => PROPS[n].w * VS);
  const vecH = Math.max(...names.map(n => PROPS[n].h)) * VS;
  const sceneW = names.reduce((a, n) => a + PROPS[n].w + 12, 0) + 2 * (CHAR.w + 12) + 20;
  const sceneH = Math.max(110, ...names.map(n => PROPS[n].h + 40));
  const cv = document.getElementById('out');
  cv.width = Math.max(1200, vecW.reduce((a, b) => a + b + PAD, PAD), sceneW * 3 + 2 * PAD);
  cv.height = 60 + vecH + 60 + sceneH * 2 + 60 + sceneH * 3 + 40;
  const out = cv.getContext('2d');
  out.fillStyle = '#9fd6e6';
  out.fillRect(0, 0, cv.width, cv.height);
  const label = (t, x, y) => {
    out.font = 'bold 15px sans-serif'; out.fillStyle = '#123'; out.textAlign = 'left'; out.fillText(t, x, y);
  };

  label('vector (5x)', PAD, 26);
  out.fillStyle = '#d6d6cb';
  out.fillRect(PAD, 40, cv.width - 2 * PAD, vecH + 20);
  ctx = out;
  let x = PAD;
  names.forEach((n, i) => {
    const P = PROPS[n];
    out.save(); out.translate(x + P.ox * VS, 50 + P.oy * VS); out.scale(VS, VS); drawProp(P); out.restore();
    x += vecW[i] + PAD;
  });

  const floor = new Image();
  floor.onload = () => {
    const scene = document.createElement('canvas');
    scene.width = sceneW; scene.height = sceneH;
    const s = scene.getContext('2d');
    s.fillStyle = s.createPattern(floor, 'repeat');
    s.fillRect(0, 0, sceneW, sceneH);
    const ground = sceneH - 12;
    const put = (spr, ox, oy, px) => s.drawImage(spr, Math.round(px - ox), Math.round(ground - oy));
    let px = 10;
    put(characterSprite('red'), CHAR.ox, CHAR.oy, px + CHAR.ox); px += CHAR.w + 12;
    for (const n of names) { const P = PROPS[n]; put(sprite(n), P.ox, P.oy, px + P.ox); px += P.w + 12; }
    put(characterSprite('cyan'), CHAR.ox, CHAR.oy, px + CHAR.ox);
    const y0 = 60 + vecH + 60;
    label('game density (1x)', PAD, y0 - 10);
    blit(out, scene, PAD, y0, 1);
    label('in game (2x, nearest)', PAD + sceneW + PAD, y0 - 10);
    blit(out, scene, PAD + sceneW + PAD, y0, 2);
    const y1 = y0 + sceneH * 2 + 60;
    label('zoom (3x)', PAD, y1 - 10);
    blit(out, scene, PAD, y1, 3);
  };
  floor.src = '../../assets/art/floor_tile.png';
}
