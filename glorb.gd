extends CharacterBody2D

# --- Movement ---
const SPEED = 500
var is_attacking = false
var g_hp = Global.g_hp
var can_attack = true
var attacks = 0

# --- Stats ---
var attack_power: int = 5       # Increases damage dealt
var block_power: float = 0.8     # How long block lasts
var roll_distance: float = 1150.0  # Distance or speed of roll/dodge

# --- Dash ---
var dash_duration: float = 0.2
var dash_cooldown: float = 1.5
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# --- Block ---
var is_blocking: bool = false
var block_timer: float = 0.0
var block_cooldown: float = 2.0        # Cooldown before block can be used again
var block_cooldown_timer: float = 0.0

# --- Physics ---
func _physics_process(delta: float) -> void:
	# --- Handle block timers ---
	if is_blocking:
		block_timer -= delta
		velocity = Vector2.ZERO  # freeze movement
		if block_timer <= 0:
			is_blocking = false
			if %glorb_sprite.animation == "block":
				%glorb_sprite.play("idle")
	elif block_cooldown_timer > 0:
		block_cooldown_timer -= delta

	# --- Block input ---
	if Input.is_action_just_pressed("block") and not is_blocking and block_cooldown_timer <= 0 and not is_attacking:
		start_block()

	# --- Handle dashing ---
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * roll_distance

		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
			if %glorb_sprite.animation != "idle":
				%glorb_sprite.play("idle")
	elif dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# --- Movement (only if not blocking or dashing) ---
	if not is_dashing and not is_blocking:
		var direction = Input.get_vector("left", "right", "up", "down")
		velocity = direction * SPEED

		if not direction.is_zero_approx():
			rotation = lerp_angle(rotation, direction.angle(), delta * 14)

		if direction:
			if %glorb_sprite.animation != "walking" and not is_attacking:
				%glorb_sprite.play("walking")
		else:
			if %glorb_sprite.animation != "idle" and not is_attacking:
				%glorb_sprite.play("idle")

		# Attack
		if Input.is_action_just_pressed("attack") and can_attack and attacks <= 2:
			%glorb_sprite.play("attack1")
			$swing.play()
			is_attacking = true
			can_attack = false
			$attack_area/glorb_hitbox.disabled = false

		# Dash input
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not is_attacking:
			var dash_input = Input.get_vector("left", "right", "up", "down")
			if not dash_input.is_zero_approx():
				start_dash(dash_input)

	move_and_slide()

# --- Dash Function ---
func start_dash(direction: Vector2) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_direction = direction.normalized()

	if %glorb_sprite.animation != "dash":
		%glorb_sprite.play("dash")
		$swing.play()

# --- Block Function ---
func start_block():
	is_blocking = true
	block_timer = block_power
	block_cooldown_timer = block_cooldown
	velocity = Vector2.ZERO
	%glorb_sprite.play("block")
	$block.play()

# --- Animation Finished Handler ---
func _on_glorb_sprite_animation_finished() -> void:
	attacks += 1
	if attacks >= 3:
		get_tree().create_timer(0.7).timeout.connect(func(): attacks = 0)

	if %glorb_sprite.animation == "attack1":
		$attack_area/glorb_hitbox.disabled = true
		get_tree().create_timer(0.1).timeout.connect(func(): can_attack = true)
		is_attacking = false

	if %glorb_sprite.animation == "hurt":
		%glorb_sprite.animation = "idle"

# --- Kill / Damage ---
func kill():
	get_tree().reload_current_scene()

func take_damage(amount: int) -> void:
	if is_blocking:
		print("Blocked attack! No damage taken.")
		return  # absorb all damage while blocking

	g_hp -= amount
	print("Player HP:", g_hp)
	if g_hp <= 0:
		kill()
