extends CharacterBody2D

var health = 3
@export var speed: float = 70.0
var player: CharacterBody2D = null

@onready var sprite = $AnimatedSprite2D
@onready var flip_root = $AnimatedSprite2D/FlipRoot
@onready var attack_trigger = $AnimatedSprite2D/FlipRoot/AttackTrigger
@onready var attack_shape = $AnimatedSprite2D/FlipRoot/AttackArea/CollisionShape2D
@onready var anim_player = $AnimatedSprite2D/FlipRoot/AnimationPlayer

var can_attack = true
var attack_duration = 0.3
var attack_cooldown = 0.2 # Seconds

func _ready(): 
		player = get_tree().get_first_node_in_group("Player")
		if player == null: 
			print("Error Player node not found.")

func _physics_process(delta): 
	if player != null: 
		var direction: Vector2 = position.direction_to(player.position)
		
		velocity = direction * speed
		
		move_and_slide()
		if velocity.x < 0:
			# Assuming the sprite is a child, adjust node path if necessary
			sprite.flip_h = true
			flip_root.scale.x = -1
		elif velocity.x > 0:
			sprite.flip_h = false
			flip_root.scale.x = 1


func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Check if the thing hitting us is an attack
	if area.name == "PlayerAttackArea":
		take_damage(1)

func _on_attack_trigger_entered(area: Area2D) -> void:
	if area.name == "PlayerHurtbox":
		if not anim_player.is_playing():
			anim_player.play("Swing")
		perform_attack()
	
	

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


func die():
	queue_free() # This un-instances the node safely


func _on_attack_trigger_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
