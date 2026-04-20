extends CharacterBody2D

signal died

var health: int = 3
@export var speed: float = 70.0
@export var damage: int = 1
@export var attack_cooldown: float = 1.0
var player: CharacterBody2D = null
var can_attack: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("Enemy")
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		print("Enemy: Player not found")
	sprite.play("walk")

func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	var direction: Vector2 = position.direction_to(player.position)
	velocity = direction * speed
	move_and_slide()

	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

	# Damage player on contact
	if can_attack and global_position.distance_to(player.global_position) < 12.0:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			can_attack = false
			await get_tree().create_timer(attack_cooldown).timeout
			can_attack = true

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "AttackArea":
		take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color.RED
	if health <= 0:
		die()
	else:
		await get_tree().create_timer(0.1).timeout
		modulate = Color.WHITE

func die() -> void:
	died.emit()
	queue_free()
