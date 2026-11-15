extends Button

## Flat hand-drawn button from art-src/props/menu_button.js, drawn at whole-pixel scale so it stays crisp.

const ART := "res://assets/art/props/"
const K := 2  # screen px per art px
const INK := Color("0d0d12")


func _init(label := "", primary := false) -> void:
	var art := ColonyMap.texture(ART + "menu_label_" + label.to_lower().replace(" ", "_") + ".png")
	if art:
		var l := TextureRect.new()
		l.texture = art
		l.scale = Vector2(K, K)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.set_meta("art_size", art.get_size() * K)
		add_child(l)
		resized.connect(func() -> void: l.position = ((size - l.get_meta("art_size")) * 0.5 - Vector2(0, K)).round())
	else:
		text = label
	var base := "menu_primary" if primary else "menu_button"
	var normal := _face(base)
	for st in [["normal", normal], ["focus", normal], ["disabled", normal], ["hover", _face(base + "_hover")],
			["pressed", _face(base + "_pressed")]]:
		add_theme_stylebox_override(st[0], st[1])
	custom_minimum_size = normal.texture.get_size() * K if normal is StyleBoxTexture else Vector2(360, 88)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_font_size_override("font_size", 34)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(c, INK)


func _face(name: String) -> StyleBox:
	var t := ColonyMap.texture(ART + name + ".png")
	if t == null:
		return StyleBoxEmpty.new()
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.content_margin_bottom = 4
	return sb
