// A double-hump border rock with a squat wedge in front, teal mineral seams exposed on the dark faces, loose chunks at the base.
const OUTCROP = {
  fleck: '#4fd6d0',
  rocks: [  // back to front
    {
      sil: [[-44, 0], [-46, -26], [-41, -47], [-29, -58], [-18, -55], [-13, -42], [-6, -46], [7, -46], [17, -36], [21, -18], [20, 0]],
      edge: [[-50, -27], [-33, -33], [-16, -27], [-11, -24], [5, -29], [26, -22]],
      crack: [[-13, -42], [-14, -32]],
      veins: [
        [[-41, -21], [-33, -19], [-27, -11], [-31, -8], [-35, -13], [-42, -15]],
        [[-22, -22], [-15, -23], [-12, -16], [-17, -13], [-21, -16]],
      ],
      r: 6,
    },
    {
      sil: [[4, 0], [2, -16], [-1, -38], [3, -49], [11, -50], [26, -37], [39, -23], [45, -10], [44, 0]],
      edge: [[-6, -28], [7, -32], [23, -22], [36, -12], [48, -5]],
      veins: [[[4, -23], [13, -19], [20, -10], [15, -6], [11, -12], [3, -16]]],
      r: 5,
    },
  ],
  chunks: [[-19, 2, 11, false], [-8, 2, 9, true], [34, 2, 10, false]],
};

function outcropRock(R) {
  const sil = shape(rounded(R.sil, R.r), ROCK.lit, 0, AMP);
  clipTo(sil, () => {
    blob([...R.edge, [R.edge[R.edge.length - 1][0], 10], [R.edge[0][0], 10]], ROCK.dark);
    for (const v of R.veins) { const p = shape(rounded(v, 0.5), OUTCROP.fleck, 0, AMP); path(p, true); stroke(DETAIL); }
    pen(R.edge, LINE, INK, AMP);
    if (R.crack) pen(R.crack, DETAIL, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

function rockOutcrop() {
  seed = 847;
  blob(rounded(rect(-47, -5, 47, 5), 4), GROUND);
  OUTCROP.rocks.forEach(outcropRock);
  for (const [x, y, w, teal] of OUTCROP.chunks) {
    const h = w * 0.8, a = w / 2;
    const p = shape(rounded([[x - a, y], [x - a + 1, y - h * 0.7], [x - 1, y - h], [x + a, y - h * 0.55], [x + a, y]], 1), teal ? OUTCROP.fleck : ROCK.lit, 0, AMP);
    if (!teal) clipTo(p, () => blob(rect(x - a - 2, y - h * 0.4, x + a + 2, y + 2), ROCK.dark));
    path(p, true); stroke(DETAIL);
  }
}

registerProp('rock_outcrop', {
  w: 100, h: 74, ox: 50, oy: 66, draw: rockOutcrop,
  pal: () => [INK, ROCK.lit, ROCK.dark, OUTCROP.fleck, GROUND],
});
