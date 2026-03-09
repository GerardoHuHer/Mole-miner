extends CharacterBody2D

const SPEED = 100.0
@onready var attack_area = $AttackArea
@onready var attack_shape = $AttackArea/CollisionShape2D
@onready var debug_rect = $AttackArea/ColorRect # Make sure the name matches exactly!

var can_attack = true
var attack_cooldown = 0.5 # Seconds

func _physics_process(_delta: float) -> void:
	# Movement code
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED if direction != Vector2.ZERO else velocity.move_toward(Vector2.ZERO, SPEED)
	move_and_slide()

	# Attack Input
	if Input.is_action_just_pressed("ui_accept") and can_attack:
		perform_attack()

func perform_attack():
	can_attack = false
	
	# Enable Physics
	attack_shape.set_deferred("disabled", false)
	
	# Enable Visuals (The ColorRect)
	debug_rect.show() 
	
	# Increase this to 0.3s just to CONFIRM you can see it
	await get_tree().create_timer(0.3).timeout
	
	# Disable everything
	debug_rect.hide()
	attack_shape.set_deferred("disabled", true)
	
	# Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	
	print("ATTACKED")
