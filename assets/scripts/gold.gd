extends Area2D

signal collected(points: int)

const GOLD_POINTS := 50

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("Gold")
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# El AttackArea del jugador es un Area2D hijo directo del CharacterBody2D del Player
	var parent = area.get_parent()
	if parent != null and parent.is_in_group("Player"):
		_collect()

func _collect() -> void:
	# Desactivar monitoreo para que no dispare la señal más de una vez
	set_deferred("monitoring", false)
	collected.emit(GOLD_POINTS)

	# Animación: escala y desvanece antes de destruirse
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.12)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 0.2, 0.0), 0.18)
	tween.chain().tween_callback(queue_free)
