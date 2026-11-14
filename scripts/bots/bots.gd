extends Node2D

## Spawns wandering bots on the map's walkable floor, once its collisions are in the physics space.

const BOT := preload("res://scenes/bot.tscn")
const Bot := preload("res://scripts/bots/bot.gd")
const NavGrid := preload("res://scripts/bots/nav_grid.gd")
const Crewmate := preload("res://scripts/crewmate.gd")

signal spawned

@export var map: Node2D
@export var count := 6

var nav: NavGrid
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	y_sort_enabled = true
	rng.randomize()
	# shapes added this frame only reach the physics space's queries after a physics step
	await get_tree().physics_frame
	await get_tree().physics_frame
	var bots: Array[Bot] = []
	for i in count:
		bots.append(BOT.instantiate())
	var players := get_tree().get_nodes_in_group("player")
	var exclude: Array[RID] = []
	for p in players:
		exclude.append(p.get_rid())
	nav = NavGrid.new()
	nav.build(get_world_2d().direct_space_state, bots[0].get_node("Feet"), map.floor_rects, exclude)

	var colours: Array = Crewmate.COLOURS.keys()
	for p in players:
		colours.erase(p.colour)
	colours.shuffle()
	for i in count:
		var bot := bots[i]
		bot.colour = colours[i % colours.size()]
		bot.nav = nav
		bot.rng.seed = rng.randi()
		bot.position = nav.random_point(rng)
		for p in players:
			bot.add_collision_exception_with(p)
		add_child(bot)
	spawned.emit()
