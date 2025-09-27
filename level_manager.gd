extends Node2D

# --- Level Scenes ---
var level_scenes := [
	preload("res://Level1.tscn"),
	preload("res://Level2.tscn"),
	preload("res://Level3.tscn"),
	preload("res://Level4.tscn")
]

# --- Enemy Scenes ---
var enemy_scenes := [
	preload("res://scientist.tscn"),
	preload("res://hazmat.tscn")
]

# --- Player & UI ---
@onready var start_menu := $"../UI/StartMenu"
@onready var player := $"../glorb"
@onready var upgrade_menu := $"../UI/UpgradeMenu"

# --- Music ---
@onready var menu_ost: AudioStreamPlayer = $MenuOST
@onready var game_ost: AudioStreamPlayer = $GameOST

# --- Level Management ---
var current_level: Node = null
var last_index := -1
var level_number := 0        # tracks completed levels
var base_enemy_count := 3    # starting number of enemies

# --- Game State ---
var game_started := false
var current_enemies: Array = []

func _ready():
	randomize()
	start_menu.visible = true
	player.visible = false

	# Start menu music
	if game_ost.playing:
		game_ost.stop()
	if not menu_ost.playing:
		menu_ost.play()

func _input(event):
	if event.is_action_pressed("start_game") and start_menu.visible:
		start_menu.visible = false
		game_started = true

		# Stop menu music and start game music
		if menu_ost.playing:
			menu_ost.stop()
		if not game_ost.playing:
			game_ost.play()

		load_random_level()

# --- Load a random level ---
func load_random_level():
	# Remove previous level
	if current_level:
		current_level.queue_free()
	current_enemies.clear()

	# Resume GameOST if it was paused
	if not game_ost.playing:
		game_ost.play()

	# Pick a random level (avoid immediate repeat)
	var index := randi() % level_scenes.size()
	while index == last_index and level_scenes.size() > 1:
		index = randi() % level_scenes.size()
	last_index = index

	# Instantiate and add level
	current_level = level_scenes[index].instantiate()
	add_child(current_level)

	# Move and show player at spawn
	var spawn_point = current_level.get_node("PlayerSpawn")
	if spawn_point:
		player.global_position = spawn_point.global_position
	player.visible = true

	# Spawn enemies
	spawn_enemies()

# --- Spawn enemies with increasing count ---
func spawn_enemies():
	var enemy_spawns = current_level.get_node("EnemySpawns")
	if not enemy_spawns:
		return

	var spawn_points = enemy_spawns.get_children()
	var num_enemies = base_enemy_count + level_number
	num_enemies = min(num_enemies, spawn_points.size())
	spawn_points.shuffle()

	for i in range(num_enemies):
		var spawn = spawn_points[i]
		var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn.global_position

		# Assign player reference if enemy has 'player' property
		if "player" in enemy:
			enemy.player = player

		add_child(enemy)
		current_enemies.append(enemy)

		# Track when enemy is removed
		enemy.connect("tree_exited", Callable(self, "_on_enemy_removed").bind(enemy))

# --- Enemy removal ---
func _on_enemy_removed(enemy):
	if enemy in current_enemies:
		current_enemies.erase(enemy)
	check_level_complete()

# --- Check if level is complete ---
func check_level_complete():
	if current_enemies.is_empty():
		show_upgrade_menu()

# --- Show upgrade menu ---
func show_upgrade_menu():
	# Pause current level
	if current_level:
		current_level.visible = false

	# Pause player
	player.set_process(false)
	player.visible = false

	# Pause GameOST and start Intermission
	if game_ost.playing:
		game_ost.stop()

	# Show upgrade menu
	upgrade_menu.visible = true
	upgrade_menu.focus_mode = Control.FOCUS_ALL
	upgrade_menu.set_focus_behavior_recursive(true)
	upgrade_menu.grab_focus()
	upgrade_menu.selected_index = 0
	upgrade_menu._update_selection()

	# Connect stat chosen signal
	upgrade_menu.connect("stat_chosen", Callable(self, "_on_stat_chosen"))

# --- Handle stat choice ---
func _on_stat_chosen(stat: String):
	match stat:
		"ATTACK":
			if "attack_power" in player:
				player.attack_power += 1
		"BLOCK":
			if "block_power" in player:
				player.block_power += 0.1
				player.block_cooldown -= 0.15
		"ROLL":
			if "roll_distance" in player:
				player.roll_distance += 150
				player.dash_cooldown -= 0.1

	upgrade_menu.visible = false
	player.visible = true
	player.set_process(true)
	level_number += 1
	load_random_level()
