extends Control

# ─────────────────────────────────────────────────────────────────────────────
#  MoleMiners — Menú principal  (fondo de mina estilo Minecraft)
# ─────────────────────────────────────────────────────────────────────────────

const MENU_MUSIC = preload("res://assets/music/MainMenu.mp3")
@onready var music_player = $MusicPlayer

const TILE := 32

# ── Colores de capas de terreno ───────────────────────────────────────────────
const GRASS_C := [
	Color(0.267, 0.545, 0.118, 1.0),
	Color(0.235, 0.490, 0.094, 1.0),
	Color(0.306, 0.580, 0.153, 1.0),
]
const DIRT_C := [
	Color(0.545, 0.341, 0.153, 1.0),
	Color(0.490, 0.298, 0.122, 1.0),
	Color(0.592, 0.380, 0.184, 1.0),
	Color(0.514, 0.318, 0.137, 1.0),
	Color(0.459, 0.275, 0.110, 1.0),
]
const GRAVEL_C := [
	Color(0.435, 0.412, 0.388, 1.0),
	Color(0.392, 0.369, 0.345, 1.0),
	Color(0.459, 0.435, 0.408, 1.0),
]
const STONE_C := [
	Color(0.490, 0.490, 0.490, 1.0),
	Color(0.447, 0.447, 0.451, 1.0),
	Color(0.514, 0.506, 0.514, 1.0),
	Color(0.467, 0.463, 0.467, 1.0),
]
const DEEPSTONE_C := [
	Color(0.196, 0.192, 0.204, 1.0),
	Color(0.176, 0.173, 0.184, 1.0),
	Color(0.212, 0.208, 0.220, 1.0),
]
const GRID_LINE := Color(0.0, 0.0, 0.0, 0.28)

# ── Minerales: [color, cada_N_tiles, hash_mul_row, hash_mul_col] ──────────────
const ORES := [
	[Color(0.098, 0.098, 0.098, 1.0), 7,  6271, 2381],  # Carbón
	[Color(0.816, 0.682, 0.580, 1.0), 16, 4733, 1847],  # Hierro
	[Color(0.980, 0.851, 0.259, 1.0), 38, 3571, 2143],  # Oro
	[Color(0.141, 0.341, 0.710, 1.0), 52, 5113, 3001],  # Lapislázuli
	[Color(0.859, 0.082, 0.082, 1.0), 58, 2803, 4127],  # Redstone
	[Color(0.322, 0.882, 0.941, 1.0), 78, 7177, 1993],  # Diamante
	[Color(0.059, 0.890, 0.376, 1.0), 88, 6899, 3217],  # Esmeralda
	[Color(0.780, 0.400, 0.180, 1.0), 44, 3923, 5501],  # Cobre
]

# Raíces en la capa de tierra (líneas marrones oscuras)
const ROOT_C := Color(0.306, 0.165, 0.059, 1.0)

var _t := 0.0  # Tiempo para animación de llama

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	play_music(MENU_MUSIC)
	queue_redraw()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.8)

	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  DIBUJO PRINCIPAL
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var w := size.x
	var h := size.y
	var cols := int(w / TILE) + 2
	var rows := int(h / TILE) + 2

	# Zonas en filas de tiles
	var grass_end   := 2
	var dirt_end    := grass_end + 5
	var gravel_end  := dirt_end  + 2
	# stone_start = gravel_end en adelante

	# 1 ── Tiles de terreno
	for row in range(rows):
		for col in range(cols):
			var rect := Rect2(col * TILE, row * TILE, TILE, TILE)
			draw_rect(rect, _tile_color(row, col, rows, grass_end, dirt_end, gravel_end))
			draw_rect(rect, GRID_LINE, false, 0.5)

	# 2 ── Raíces en la capa de tierra
	_draw_roots(cols, grass_end, dirt_end)

	# 3 ── Cueva oscura central (arco de herradura)
	_draw_cave(w * 0.5, h * 0.60, w * 0.19, h * 0.30)

	# 4 ── Antorchas con halo de luz y llama animada
	_draw_torch(w * 0.20, h * 0.50, _t + 0.0)
	_draw_torch(w * 0.80, h * 0.50, _t + 1.7)

# ─────────────────────────────────────────────────────────────────────────────
#  COLOR DE CADA TILE
# ─────────────────────────────────────────────────────────────────────────────
func _tile_color(row: int, col: int, total_rows, grass_end, dirt_end, gravel_end) -> Color:
	var ha := row * 7919 + col * 3119
	var hb := row * 1031 + col * 5237
	var hc := row * 2657 + col * 7523

	if row < grass_end:
		return GRASS_C[ha % GRASS_C.size()]

	if row < dirt_end:
		return DIRT_C[ha % DIRT_C.size()]

	if row < gravel_end:
		return GRAVEL_C[ha % GRAVEL_C.size()]

	# ── Zona de piedra ────────────────────────────────────────────────────────
	var depth := float(row - gravel_end) / float(max(total_rows - gravel_end, 1))

	# Minerales aparecen a partir del 20% de profundidad
	if depth > 0.20:
		for ore in ORES:
			if (row * (ore[2] as int) + col * (ore[3] as int)) % (ore[1] as int) == 0:
				return ore[0] as Color

	# Deepstone en el 55%+ de profundidad
	if depth > 0.55:
		return DEEPSTONE_C[hb % DEEPSTONE_C.size()]

	return STONE_C[hc % STONE_C.size()]

# ─────────────────────────────────────────────────────────────────────────────
#  RAÍCES EN TIERRA (líneas de 1-tile de ancho en dirección vertical)
# ─────────────────────────────────────────────────────────────────────────────
func _draw_roots(cols: int, grass_end: int, dirt_end: int) -> void:
	for col in range(cols):
		# Una raíz cada ~5 columnas, posición determinista
		if (col * 3 + 7) % 5 != 0:
			continue
		var start_row := grass_end + 1
		var length    := 2 + ((col * 17 + 3) % 3)   # 2 a 4 tiles de largo
		for r in range(start_row, min(start_row + length, dirt_end)):
			draw_rect(
				Rect2(col * TILE + TILE * 0.35, r * TILE, TILE * 0.30, TILE),
				ROOT_C
			)

# ─────────────────────────────────────────────────────────────────────────────
#  CUEVA CENTRAL (arco pixelado oscuro)
# ─────────────────────────────────────────────────────────────────────────────
func _draw_cave(cx: float, cy: float, rw: float, rh: float) -> void:
	var snap   := float(TILE)
	var cols_r := int(rw / snap) + 2
	var rows_r := int(rh / snap) + 2

	for r in range(-rows_r, rows_r + 1):
		for c in range(-cols_r, cols_r + 1):
			# Elipse ligeramente achatada arriba → arco de herradura
			var nx := float(c) / (rw / snap)
			var ny := float(r) / (rh / snap)
			var inside := nx * nx + ny * ny * 0.75 <= 1.0
			# Recortar parte superior para que no flote sobre el suelo
			var above_center := r < 0
			if inside and (above_center or ny * ny * 0.75 + nx * nx <= 1.0):
				var tx := cx + c * snap - snap * 0.5
				var ty := cy + r * snap - snap * 0.5
				# Oscuridad progresiva hacia el centro
				var alpha := 0.75 + (1.0 - (nx * nx + ny * ny * 0.75)) * 0.20
				draw_rect(Rect2(tx, ty, snap, snap), Color(0.01, 0.01, 0.02, alpha))

# ─────────────────────────────────────────────────────────────────────────────
#  ANTORCHA CON LLAMA ANIMADA
# ─────────────────────────────────────────────────────────────────────────────
func _draw_torch(x: float, y: float, phase: float) -> void:
	var flicker := sin(phase * 8.5) * 0.04 + sin(phase * 13.1) * 0.02

	# Halo de luz (3 capas concéntricas suaves)
	draw_circle(Vector2(x, y - 24), 96.0 + flicker * 20, Color(1.0, 0.55, 0.05, 0.055 + flicker))
	draw_circle(Vector2(x, y - 24), 60.0,                Color(1.0, 0.65, 0.12, 0.070))
	draw_circle(Vector2(x, y - 24), 32.0,                Color(1.0, 0.78, 0.20, 0.095))

	# Palo de madera (3px de ancho, pixelado)
	draw_rect(Rect2(x - 4, y - 8,  8, 24), Color(0.314, 0.188, 0.063, 1.0))  # sombra
	draw_rect(Rect2(x - 3, y - 8,  6, 24), Color(0.451, 0.275, 0.094, 1.0))  # cuerpo
	draw_rect(Rect2(x - 1, y - 8,  2, 24), Color(0.518, 0.333, 0.122, 1.0))  # borde claro

	# Llama (altura y ancho animados)
	var fh := 18.0 + sin(phase * 9.3) * 3.5
	var fw := 10.0 + sin(phase * 6.1) * 2.0
	var fy := y - 8.0 - fh

	# Capa exterior naranja
	draw_rect(Rect2(x - fw * 0.5, fy,        fw,       fh      ), Color(0.918, 0.361, 0.035, 1.0))
	# Capa media amarillo-naranja
	draw_rect(Rect2(x - fw * 0.3, fy + fh * 0.18, fw * 0.6, fh * 0.65), Color(1.0,   0.804, 0.067, 1.0))
	# Núcleo blanco-amarillo (punta)
	draw_rect(Rect2(x - 2,        fy + fh * 0.05, 4,        fh * 0.45), Color(1.0,   0.976, 0.620, 0.95))

# ─────────────────────────────────────────────────────────────────────────────
#  NAVEGACIÓN
# ─────────────────────────────────────────────────────────────────────────────
func _on_start_pressed() -> void:
	music_player.stop()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/controls_screen.tscn")

func _on_quit_pressed() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await tw.finished
	get_tree().quit()
	
# Music Funcs
func play_music(new_stream: AudioStream):
	# Only change the music if it's not already playing
	if music_player.stream != new_stream:
		music_player.stream = new_stream
		music_player.play()
