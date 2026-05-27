extends Control

# Paleta de colores para simular piedra estilo Minecraft
const GRID_SIZE := 32
const STONE_COLORS := [
	Color(0.090, 0.090, 0.090, 1.0),
	Color(0.102, 0.102, 0.102, 1.0),
	Color(0.078, 0.078, 0.078, 1.0),
	Color(0.114, 0.114, 0.114, 1.0),
	Color(0.086, 0.086, 0.086, 1.0),
	Color(0.098, 0.098, 0.098, 1.0),
]
const GRID_LINE_COLOR := Color(0.050, 0.050, 0.050, 0.9)

func _ready() -> void:
	queue_redraw()

	# Fade-in al entrar al menú
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

	# Conectar botones
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

# Dibuja el fondo de piedra pixelada estilo Minecraft
func _draw() -> void:
	var cols := int(size.x / GRID_SIZE) + 2
	var rows := int(size.y / GRID_SIZE) + 2
	for row in range(rows):
		for col in range(cols):
			var rect := Rect2(
				col * GRID_SIZE,
				row * GRID_SIZE,
				GRID_SIZE,
				GRID_SIZE
			)
			# Color pseudo-aleatorio determinista para variación de piedra
			var idx := (row * 7919 + col * 3119) % STONE_COLORS.size()
			draw_rect(rect, STONE_COLORS[idx])
			draw_rect(rect, GRID_LINE_COLOR, false, 0.5)

func _on_start_pressed() -> void:
	# Fade-out antes de cambiar de escena
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().quit()
