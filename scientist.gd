extends CharacterBody2D

var hurt = false
var dead = false
var HP = 10
var motion = Vector2()
var bullet_speed = 2000
var can_atk = true

var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var fire_offset: Vector2 = Vector2(20, 0) # spawn in front of character

func _ready():
	pass

func _physics_process(_delta: float) -> void:
	var player = get_tree().get_root().find_child("glorb", true, false)

	if not dead and not hurt:
		# Move toward player
		var direction = (player.position - position).normalized()
		velocity = direction * 150.0  # CharacterBody2D has built-in velocity

		# Face the player
		look_at(player.position)

		# Play walk animation
		$scientist_sprite.play("walk")
	else:
		# No movement if dead or hurt
		velocity = Vector2.ZERO

	# Apply sliding movement
	move_and_slide()

	# Fire bullets if able
	if can_atk and not dead and not hurt:
		fire()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("pipe") and dead == false:
		var player = get_tree().get_root().find_child("glorb", true, false)
		HP -= player.attack_power
		hurt = true
		$scientist_sprite.play("hurt")
		$thwack.play()
		print(HP)

		if HP <= 0:
			dead = true
			$scientist_sprite.play("die")

func _on_scientist_sprite_animation_finished() -> void:
	if $scientist_sprite.animation == "die":
		queue_free()

	if $scientist_sprite.animation == "hurt":
		hurt = false
		$scientist_sprite.animation = "idle"

func fire():
	var bullet = bullet_scene.instantiate()
	$gunshot.play()

	# Place the bullet at the player's position + offset rotated to face direction
	bullet.global_position = global_position + fire_offset.rotated(rotation)

	# Send bullet in the direction the player is facing
	bullet.direction = Vector2.RIGHT.rotated(rotation)

	get_parent().add_child(bullet)

	can_atk = false
	get_tree().create_timer(1.5).timeout.connect(func(): can_atk = true)
	
