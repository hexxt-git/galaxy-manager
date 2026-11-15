// Flat menu buttons: one hand-drawn face and the ink outline, no lip. Every state shares the outline (same seed),
// so only the face colour changes. The label is set in-engine. Origin is the top-left corner.
const MENU_BTN = { w: 196, h: 44, r: 12, amp: 3 };
const MENU_FACES = {
  menu_button: '#e1e8ef', menu_button_hover: '#ffffff', menu_button_pressed: '#a9b6c7',
  menu_primary: '#f2c230', menu_primary_hover: '#ffd84d', menu_primary_pressed: '#c99a22',
};

function menuButton(face) {
  seed = 1901;
  const e = LINE / 2 + 0.5;
  const sil = shape(rounded(rect(e, e, MENU_BTN.w - e, MENU_BTN.h - e), MENU_BTN.r), face, 0, MENU_BTN.amp);
  path(sil, true); stroke(LINE);
}

for (const [name, face] of Object.entries(MENU_FACES)) {
  registerProp(name, { w: MENU_BTN.w, h: MENU_BTN.h, ox: 0, oy: 0, draw: () => menuButton(face), pal: () => [INK, face] });
}
