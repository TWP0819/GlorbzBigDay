extends CharacterBody2D

var hurt = false
var dead = false
var HP = 20
var motion = Vector2()
var can_atk = true
var is_attacking = false
var damage_per_tick := 1  # how much damage per tick

func _ready():
	$TickTimer.stop()
	pass

func _physics_process(delta: float) -> void:
	var player = get_tree().get_root().find_child("glorb", true, false)

	if not dead and not hurt and not is_attacking:
		# Move toward player
		var direction = (player.position - position).normalized()
		velocity = direction * 100.0  # CharacterBody2D has built-in velocity

		# Face the player
		rotation = lerp_angle(rotation, direction.angle(),delta * 4)
		# Play walk animation
		$hazmat_sprite.play("walk")
	else:
		# No movement if dead or hurt
		velocity = Vector2.ZERO
		var direction = (player.position - position).normalized()
		rotation = lerp_angle(rotation, direction.angle(), delta * 0.8)

	# Apply sliding movement
	move_and_slide()

	# Fire bullets if able #####!!!!
	if can_atk and not dead:
		var dir = position.distance_to(player.position)
		if dir <= 210:
			attack()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("pipe") and dead == false:
		var player = get_tree().get_root().find_child("glorb", true, false)
		HP -= player.attack_power
		hurt = true
		$hazmat_sprite.play("hurt")
		$thwack.play()
		print(HP)

		if HP <= 0:
			dead = true
			$hazmat_sprite.play("die")

func _on_hazmat_sprite_animation_finished() -> void:
	if $hazmat_sprite.animation == "die":
		queue_free()

	if $hazmat_sprite.animation == "hurt":
		hurt = false
		$fire.stop()
		if is_attacking:
			$hazmat_sprite.play("attack")
		else:
			$hazmat_sprite.animation = "idle"
		
	if $hazmat_sprite.animation == "attack":
		$attack_area/hitbox.disabled = true
		$attack_area/AnimatedSprite2D.visible = false
		get_tree().create_timer(2).timeout.connect(func(): can_atk = true)
		is_attacking = false;
		
	if $hazmat_sprite.animation == "charge":
		$attack_area/hitbox.disabled = false
		$hazmat_sprite.play("attack")
		$attack_area/AnimatedSprite2D.visible = true
		$attack_area/AnimatedSprite2D.play("fire")

func attack():
	$hazmat_sprite.play("charge")
	$fire.play()
	is_attacking = true
	can_atk = false

func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):  # player entered
		$TickTimer.start()
		print("Player inside hazmat attack area")

func _on_attack_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		$TickTimer.stop()
		print("Player left hazmat attack area")

func _on_tick_timer_timeout() -> void:
	var player = get_tree().get_root().find_child("glorb", true, false)
	player.take_damage(damage_per_tick)
	print("Player takes", damage_per_tick, "damage from Hazmat")
