extends CharacterBody2D

const SPEED = 300.0

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("p2_left", "p2_right", "p2_up", "p2_down")
	if direction:
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	move_and_slide()
