extends CharacterBody2D

var health = 3
@export var speed: float = 70.0
var player: CharacterBody2D = null

@onready var sprite = $AnimatedSprite2D

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
		elif velocity.x > 0:
			sprite.flip_h = false


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
	queue_free() # This un-instances the node safely
