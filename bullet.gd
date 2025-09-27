extends Area2D

@export var speed: float = 600.0
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _ready():
	# Connect collision signal
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):   # make sure your player is in the "player" group
		print("Bullet hit player!")
		body.take_damage(1)  # (example function on player)
		queue_free()
	elif body.is_in_group("scientist"):
		return
	else:
		queue_free()  # bullet disappears on anything else too
