extends Area2D

signal collected(points: int)

const GOLD_POINTS := 50

var _float_tween: Tween
var _glow_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("Gold")
	area_entered.connect(_on_area_entered)
	_start_animation()

func _start_animation() -> void:
	# Flotación suave ±3px (ciclo 1.5s)
	var base_y := position.y
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(self, "position:y", base_y - 3.0, 0.75) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(self, "position:y", base_y + 3.0, 0.75) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Pulso de brillo dorado (ciclo 1.1s) — usa valores HDR (>1.0) del renderer Forward+
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(self, "modulate", Color(1.5, 1.3, 0.4, 1.0), 0.55) \
		.set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55) \
		.set_ease(Tween.EASE_IN_OUT)

func _on_area_entered(area: Area2D) -> void:
	# El AttackArea del jugador es un Area2D hijo directo del CharacterBody2D del Player
	var parent = area.get_parent()
	if parent != null and parent.is_in_group("Player"):
		_collect()

func _collect() -> void:
	# Detener animaciones de idle para que no interfieran con la de recogida
	if _float_tween:
		_float_tween.kill()
	if _glow_tween:
		_glow_tween.kill()

	# Desactivar monitoreo para que no dispare la señal más de una vez
	set_deferred("monitoring", false)
	collected.emit(GOLD_POINTS)

	# Animación de recogida: escala hacia arriba y desvanece en dorado brillante
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.13)
	tween.tween_property(self, "modulate", Color(1.8, 1.6, 0.2, 0.0), 0.20)
	tween.chain().tween_callback(queue_free)
