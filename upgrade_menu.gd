extends Control

signal stat_chosen(stat_name: String)

# List of stats
var stats := ["ATTACK", "BLOCK", "ROLL"]
var selected_index := 0

@onready var stat_labels := $HBoxContainer.get_children()
@onready var info_label := $Label

func _ready():
	_update_selection()

func _process(_delta):
	if not visible:
		return

	if Input.is_action_just_pressed("ui_right"):
		selected_index = (selected_index + 1) % stats.size()
		_update_selection()
	elif Input.is_action_just_pressed("ui_left"):
		selected_index = (selected_index - 1 + stats.size()) % stats.size()
		_update_selection()
	elif Input.is_action_just_pressed("ui_accept"):  # Z key mapped to ui_accept
		emit_signal("stat_chosen", stats[selected_index])
		visible = false

func _update_selection():
	for i in range(stat_labels.size()):
		if i == selected_index:
			stat_labels[i].self_modulate = Color(1, 1, 0) # yellow
		else:
			stat_labels[i].self_modulate = Color(1, 1, 1) # white
	info_label.text = "Choose a Stat to Upgrade"
