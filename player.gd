extends CharacterBody2D

signal health_changed(new_health: int)
signal player_died

const SPEED = 100.0

var health: int = 5
var can_attack: bool = true
var attack_duration: float = 0.3
var attack_cooldown: float = 0.2
var facing_right: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
var swing_pivot: Node2D

func _ready() -> void:
	add_to_group("Player")
	attack_shape.disabled = true
	_create_swing_visual()

func _create_swing_visual() -> void:
	swing_pivot = Node2D.new()
	swing_pivot.position = Vector2(0, -2)
	add_child(swing_pivot)

	var handle = Line2D.new()
	handle.points = PackedVector2Array([Vector2(2, 0), Vector2(10, 0)])
	handle.width = 1.5
	handle.default_color = Color(0.6, 0.4, 0.2)
	swing_pivot.add_child(handle)

	var head = Line2D.new()
	head.points = PackedVector2Array([Vector2(9, 3), Vector2(11, -3)])
	head.width = 2.0
	head.default_color = Color(0.65, 0.65, 0.7)
	swing_pivot.add_child(head)

	swing_pivot.visible = false

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		if direction.x < 0:
			sprite.flip_h = true
			attack_area.position.x = -13
			facing_right = false
		elif direction.x > 0:
			sprite.flip_h = false
			attack_area.position.x = 13
			facing_right = true
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and can_attack:
		perform_attack()

func perform_attack() -> void:
	can_attack = false
	attack_shape.set_deferred("disabled", false)

	_play_swing()

	modulate = Color.YELLOW
	sprite.scale = Vector2(1.3, 1.3)

	await get_tree().physics_frame

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage(1)

	await get_tree().create_timer(attack_duration).timeout
	attack_shape.set_deferred("disabled", true)

	modulate = Color.WHITE
	sprite.scale = Vector2(1.0, 1.03125)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _play_swing() -> void:
	swing_pivot.visible = true
	if facing_right:
		swing_pivot.scale.x = 1
		swing_pivot.rotation = deg_to_rad(-60)
		var tween = create_tween()
		tween.tween_property(swing_pivot, "rotation", deg_to_rad(60), attack_duration)
		tween.tween_callback(func(): swing_pivot.visible = false)
	else:
		swing_pivot.scale.x = -1
		swing_pivot.rotation = deg_to_rad(60)
		var tween = create_tween()
		tween.tween_property(swing_pivot, "rotation", deg_to_rad(-60), attack_duration)
		tween.tween_callback(func(): swing_pivot.visible = false)

func take_damage(amount: int) -> void:
	health -= amount
	health_changed.emit(health)
	modulate = Color.RED

	if health <= 0:
		player_died.emit()
	else:
		await get_tree().create_timer(0.1).timeout
		modulate = Color.WHITE
