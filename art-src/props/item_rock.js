// A moon rock sample: lumpy warm-grey stone with a glinting teal mineral fleck.
const ROCK = { lit: '#aaa197', dark: '#6f665d', fleck: '#4fd6d0' };

function itemRock() {
  const R = ROCK;
  seed = 1311;
  blob(rounded(rect(-8, -2, 10, 2.5), 2), GROUND);
  const sil = shape(rounded([[-7, 0], [-9.5, -4], [-8, -10], [-2, -13], [5, -12], [9.5, -7], [9, -2], [5, 0]], 3), R.lit, 0, AMP);
  clipTo(sil, () => {
    const horizon = smooth([[-11, -5], [-4, -3.5], [3, -5], [11, -4]], false, 2);
    blob([...horizon, [11, 3], [-11, 3]], R.dark);
    pen(horizon, 1.4, INK, AMP);
    const fl = rounded([[1, -11.5], [5, -9.5], [3, -6.5], [-0.5, -8.5]], 0.6);
    blob(fl, R.fleck);
    path(fl, true); stroke(1.4);
  });
  path(sil, true); stroke(LINE);
}

registerProp('item_rock', { w: 42, h: 35, ox: 21, oy: 28, scale: [1.73, 1.73], draw: itemRock, pal: () => [INK, ROCK.lit, ROCK.dark, ROCK.fleck, GROUND] });
