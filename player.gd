extends CharacterBody2D

signal health_changed(new_health: int)
signal player_died

const SPEED = 100.0

var health: int = 5
var can_attack: bool = true
var attack_duration: float = 0.3
var attack_cooldown: float = 0.2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

func _ready() -> void:
	add_to_group("Player")
	attack_shape.disabled = true

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		# Flip sprite and attack area based on direction
		if direction.x < 0:
			sprite.flip_h = true
			attack_area.position.x = -13
		elif direction.x > 0:
			sprite.flip_h = false
			attack_area.position.x = 13
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and can_attack:
		perform_attack()

func perform_attack() -> void:
	can_attack = false
	attack_shape.set_deferred("disabled", false)

	# Visual feedback: flash yellow and scale up briefly
	modulate = Color.YELLOW
	sprite.scale = Vector2(1.3, 1.3)

	# Wait one physics frame so the collision shape registers overlaps
	await get_tree().physics_frame

	# Deal damage to all enemies in the attack area
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage(1)

	await get_tree().create_timer(attack_duration).timeout
	attack_shape.set_deferred("disabled", true)

	# Reset visual
	modulate = Color.WHITE
	sprite.scale = Vector2(1.0, 1.03125)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	health -= amount
	health_changed.emit(health)
	modulate = Color.RED

	if health <= 0:
		player_died.emit()
	else:
		await get_tree().create_timer(0.1).timeout
		modulate = Color.WHITE
