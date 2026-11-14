// Renders vector drawing code into a hard-edged, fixed-palette pixel image.
// Each art pixel is supersampled SxS; the most common pure palette colour wins, so anti-aliased
// blends between two colours can never resolve to an unrelated third colour.
const SUPER = 8;
// Global contrast for all exported fills: palette colours move toward mid grey by this factor (1 = as authored).
// Written as authored: the outline ink, and key colours swapped out later (ground shadow, character recolour).
const CONTRAST = 0.9;
const AS_AUTHORED = ['#0d0d12', '#ff00ff', '#ff0000', '#0000ff'];

function soften(h) {
  const c = hexRgb(h);
  return AS_AUTHORED.includes(h.toLowerCase()) ? c : c.map(v => Math.round(128 + (v - 128) * CONTRAST));
}

function hexRgb(h) {
  const n = parseInt(h.slice(1), 16);
  return [n >> 16, (n >> 8) & 255, n & 255];
}

function pixelate(w, h, palette, draw) {
  const big = document.createElement('canvas');
  big.width = w * SUPER;
  big.height = h * SUPER;
  const bctx = big.getContext('2d');
  bctx.scale(SUPER, SUPER);
  draw(bctx);
  const src = bctx.getImageData(0, 0, big.width, big.height).data;

  const pal = palette.map(hexRgb);
  const outPal = palette.map(soften);
  const out = document.createElement('canvas');
  out.width = w;
  out.height = h;
  const octx = out.getContext('2d');
  const img = octx.createImageData(w, h);
  const votes = new Int32Array(pal.length + 1);

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      votes.fill(0);
      for (let sy = 0; sy < SUPER; sy++) {
        for (let sx = 0; sx < SUPER; sx++) {
          const i = ((y * SUPER + sy) * big.width + x * SUPER + sx) * 4;
          if (src[i + 3] < 128) { votes[pal.length]++; continue; }
          let best = -1, bd = 1e9;
          for (let p = 0; p < pal.length; p++) {
            const d = (src[i] - pal[p][0]) ** 2 + (src[i + 1] - pal[p][1]) ** 2 + (src[i + 2] - pal[p][2]) ** 2;
            if (d < bd) { bd = d; best = p; }
          }
          // blended subpixels sit far from every palette colour; they don't get a vote
          if (bd < 900) votes[best]++;
        }
      }
      let win = pal.length, wv = -1;
      for (let p = 0; p <= pal.length; p++) if (votes[p] > wv) { wv = votes[p]; win = p; }
      const o = (y * w + x) * 4;
      if (win < pal.length) {
        img.data[o] = outPal[win][0];
        img.data[o + 1] = outPal[win][1];
        img.data[o + 2] = outPal[win][2];
        img.data[o + 3] = 255;
      }
    }
  }
  octx.putImageData(img, 0, 0);
  return out;
}

function blit(dst, sprite, x, y, scale) {
  dst.imageSmoothingEnabled = false;
  dst.drawImage(sprite, Math.round(x), Math.round(y), sprite.width * scale, sprite.height * scale);
}
