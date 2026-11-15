// Ice drill minigame backdrop: a cut-away of the dark Shackleton crater floor. The rig stands on the surface, the hopper
// waits for ice, and the gauges' empty slots sit at the sides; the shaft, bit, ice and gauge fills are drawn in game.
// Authored top-left; the skin relies on: surface y 70, shaft centre x 126, slots (13..19, 87..199) and (233..239, 87..186).
const MGD = {
  sky: '#161927', rim: '#2a2e40', rimLit: '#8d93a3', star: '#c9d3e0',
  dust: '#6b707d', dustDark: '#4c505d', ice: '#3d5468', iceDark: '#2e4052', vein: '#8fc7dc', veinLit: '#c6ecf4',
  bed: '#2a2c39', steel: '#a9bcc4', steelDark: '#6b818c', gun: '#8a909c', gunDark: '#555a68', slot: '#1b1e2b',
  hot: '#e0503c',
  w: 252, h: 220, surface: 70, cx: 126,
};

function mgdBar(a, b, w, fill) {
  pen([a, b], w + 2 * DETAIL, INK, AMP);
  pen([a, b], w, fill, 0);
}

function mgdGauge(x0, y0, x1, y1, bulb) {
  const plate = shape(rounded(rect(x0, y0, x1, y1), 4), MGD.steel, 0, AMP);
  clipTo(plate, () => blob(rect(x0 + (x1 - x0) * 0.62, y0 - 2, x1 + 2, y1 + 2), MGD.steelDark));
  path(plate, true); stroke(LINE);
}

function mgdScene() {
  const M = MGD, S = M.surface, W = M.w, H = M.h;
  seed = 907;
  const frame = rounded(rect(2, 2, W - 2, H - 2), 8);
  clipTo(frame, () => {
    blob(rect(0, 0, W, H), M.sky);
    for (let i = 0; i < 26; i++) {
      const x = rr(6, W - 6), y = rr(6, 40), r = rr(0.6, 1.1);
      blob(rect(x - r, y - r, x + r, y + r), M.star);
    }
    // the far crater wall, one peak catching the low sun
    const rimPts = [[0, 60], [0, 44], [30, 38], [52, 46], [80, 34], [104, 42], [150, 40], [176, 30], [196, 24], [214, 36], [240, 40], [W, 46], [W, 60]];
    shape(smooth(rimPts, true, 2), M.rim, 0, AMP);
    blob(smooth([[184, 28], [196, 23], [207, 30], [199, 29], [192, 31]], true, 2), M.rimLit);

    const top = wobble([[-4, S], [W + 4, S]], AMP, 6);
    const ground = [...top, [W + 4, H + 4], [-4, H + 4]];
    blob(ground, M.dust);
    const iceTop = wobble([[-4, 90], [60, 86], [130, 92], [200, 87], [W + 4, 91]], AMP * 2, 6);
    const iceBand = [...iceTop, [W + 4, H + 4], [-4, H + 4]];
    blob(iceBand, M.ice);
    const bedTop = wobble([[-4, 203], [80, 199], [170, 204], [W + 4, 200]], AMP * 2, 6);
    blob([...bedTop, [W + 4, H + 4], [-4, H + 4]], M.bed);
    clipTo(ground, () => {
      for (let i = 0; i < 18; i++) {
        const x = rr(4, W - 4), y = rr(S + 5, 86), r = rr(1.2, 2.4);
        blob(smooth(rect(x - r, y - r * 0.7, x + r, y + r * 0.7), true, 2), M.dustDark);
      }
      for (let i = 0; i < 34; i++) {
        const x = rr(4, W - 4), y = rr(98, 194), rx = rr(2.5, 6), ry = rr(1.5, 3);
        const vein = smooth(rect(x - rx, y - ry, x + rx, y + ry), true, 2);
        blob(vein, i % 3 ? M.vein : M.iceDark);
        if (i % 3) clipTo(vein, () => blob(rect(x - rx, y - ry, x + rx * 0.2, y), M.veinLit));
      }
      pen(iceTop, DETAIL, INK, 0);
      pen(bedTop, DETAIL, INK, 0);
    });
    pen(top, LINE, INK, 0);

    // rig: two skids beside the hole, an A-frame derrick, the motor, a hopper for the ice
    for (const [a, b] of [[90, 114], [138, 162]]) {
      const skid = shape(rounded(rect(a, S - 8, b, S + 1), 2.5), M.steel, 0, AMP);
      clipTo(skid, () => blob(rect(a - 2, S - 3, b + 2, S + 3), M.steelDark));
      path(skid, true); stroke(DETAIL);
    }
    mgdBar([96, 64], [152, 64], 2, M.steelDark);
    mgdBar([104, 42], [148, 42], 2, M.steelDark);
    mgdBar([98, S - 6], [M.cx, 8], 3, M.steel);
    mgdBar([154, S - 6], [M.cx, 8], 3, M.steelDark);
    const motor = shape(rounded(rect(M.cx - 13, 14, M.cx + 13, 36), 3), M.steel, 0, AMP);
    clipTo(motor, () => {
      blob(rect(M.cx - 16, 27, M.cx + 16, 40), M.steelDark);
      pen([[M.cx - 13, 27], [M.cx + 13, 27]], DETAIL, INK, AMP);
      for (const x of [M.cx - 6, M.cx, M.cx + 6]) pen([[x, 17], [x, 23]], DETAIL, INK, AMP);
    });
    path(motor, true); stroke(LINE);
    const lamp = shape(smooth(rect(M.cx + 7, 7, M.cx + 13, 13), true, 2), M.hot, 0, 0);
    path(lamp, true); stroke(DETAIL);

    const bin = shape(rounded([[172, 48], [212, 48], [209, S + 1], [175, S + 1]], 3), M.steel, 0, AMP);
    clipTo(bin, () => {
      blob(rect(168, 57, 216, S + 4), M.steelDark);
      pen([[172, 57], [212, 57]], DETAIL, INK, AMP);
    });
    path(bin, true); stroke(LINE);

    // gauges: ice collected on the left (fills down to the flag), bit heat on the right (red zone at the top)
    mgdGauge(6, 80, 26, 206);
    mgdGauge(226, 80, 246, 206);
    blob(smooth(rect(229, 186, 243, 202), true, 2), M.steel);
    for (const [x0, y0, x1, y1] of [[13, 87, 19, 199], [233, 87, 239, 186]]) {
      blob(rect(x0, y0, x1, y1), M.slot);
      path(rect(x0 - 0.5, y0 - 0.5, x1 + 0.5, y1 + 0.5), true); stroke(DETAIL * 0.8);
    }
    const bulb = smooth(rect(230, 187, 242, 201), true, 3);
    blob(bulb, M.slot);
    path(bulb, true); stroke(DETAIL);
    blob(rect(241, 87, 245, 112), M.hot);
    pen([[241, 112], [245, 112]], DETAIL * 0.7, INK, 0);
    const flag = [[20, 196], [26, 192.5], [20, 189]];
    shape(flag, M.veinLit, 0, 0);
    path(flag, true); stroke(DETAIL * 0.8);
  });
  path(frame, true); stroke(LINE);
}

registerProp('mg_drill_scene', {
  w: MGD.w, h: MGD.h, ox: 0, oy: 0, draw: mgdScene,
  pal: () => [INK, MGD.sky, MGD.rim, MGD.rimLit, MGD.star, MGD.dust, MGD.dustDark, MGD.ice, MGD.iceDark, MGD.vein,
    MGD.veinLit, MGD.bed, MGD.steel, MGD.steelDark, MGD.gun, MGD.gunDark, MGD.slot, MGD.hot],
});
