extends CharacterBody2D

const SPEED = 100.0
@onready var attack_area = $FlipRoot/PlayerAttackArea
@onready var attack_shape = $FlipRoot/PlayerAttackArea/CollisionShape2D
@onready var debug_rect = $FlipRoot/PlayerAttackArea/ColorRect
@onready var flip_root = $FlipRoot
@onready var anim_player = $FlipRoot/AnimationPlayer

var can_attack = true
var attack_duration = 0.3
var attack_cooldown = 0.2 # Seconds

var health = 3

func _physics_process(_delta: float) -> void:
	# Movement code
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED if direction != Vector2.ZERO else velocity.move_toward(Vector2.ZERO, SPEED)
	move_and_slide()
	
	# Turn
	var directionAX := Input.get_axis("ui_left", "ui_right")
	if directionAX > 0:
		flip_root.scale.x = 1
	elif directionAX < 0:
		flip_root.scale.x = -1

	# Attack Input
	if Input.is_action_just_pressed("ui_accept") and can_attack:
		if not anim_player.is_playing():
			anim_player.play("Swing")
		
		perform_attack()

func perform_attack():
	can_attack = false
	
	# Enable Physics
	attack_shape.set_deferred("disabled", false)
	
	# Enable Visuals (The ColorRect)
	#debug_rect.show() 
	
	# Increase this to 0.3s just to CONFIRM you can see it
	await get_tree().create_timer(attack_duration).timeout
	
	# Disable everything
	#debug_rect.hide()
	attack_shape.set_deferred("disabled", true)
	
	# Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	
	print("ATTACKED")

func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Check if the thing hitting us is an attack
	if area.name == "AttackArea":
		take_damage(1)

func take_damage(amount):
	health -= amount
	print("Ouch! Health left: ", health)
	
	# Visual Feedback (Turn red)
	modulate = Color.RED
	
	if health <= 0:
		die()
	else:
		# Reset color after 0.1s
		await get_tree().create_timer(0.1).timeout
		modulate = Color.WHITE

func die():
	queue_free()
