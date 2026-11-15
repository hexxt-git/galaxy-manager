// Tutorial speech box: a flat hand-drawn panel in the menu button style, plus the blinking "more" arrow.
// Text is set in-engine. Origin is the top-left corner.
const DLG = { w: 340, h: 96, r: 12, amp: 3, face: '#f4f1ea' };

function dialogBox() {
  seed = 2101;
  const e = LINE / 2 + 0.5;
  const sil = shape(rounded(rect(e, e, DLG.w - e, DLG.h - e), DLG.r), DLG.face, 0, DLG.amp);
  path(sil, true); stroke(LINE);
}

function dialogNext() {
  seed = 2111;
  const sil = shape(rounded([[2.5, 2.5], [17.5, 2.5], [10, 12.5]], 2.5), '#f2c230', 0, 0);
  path(sil, true); stroke(2.4);
}

registerProp('dialog_box', { w: DLG.w, h: DLG.h, ox: 0, oy: 0, draw: dialogBox, pal: () => [INK, DLG.face] });
registerProp('dialog_next', { w: 20, h: 15, ox: 0, oy: 0, draw: dialogNext, pal: () => [INK, '#f2c230'] });
