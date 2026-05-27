extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var wave_manager: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD
@onready var music_player = $MusicPlayer

var score: int = 0
var is_paused: bool = false
var game_active: bool = true  # Evita que pausa se active en game over / victoria

# ----- Sistema de oro -----
const GOLD_SCENE := preload("res://scenes/gold_nugget.tscn")
const GOLD_COUNT := 6  # Pepitas por fase de recolección
# Área del mapa donde se pueden generar pepitas (coordenadas del mundo)
const GOLD_AREA_X_MIN := 40.0
const GOLD_AREA_X_MAX := 390.0
const GOLD_AREA_Y_MIN := -80.0
const GOLD_AREA_Y_MAX := 80.0

var _spawned_gold: Array = []

# Songs to use
const INTER_MUSIC = preload("res://assets/music/Inter.mp3")
const BATTLE_MUSIC = preload("res://assets/music/Combate.mp3")
const VICTORY_MUSIC = preload("res://assets/music/Victory.mp3")

func _ready() -> void:
	# Necesario para recibir _unhandled_input incluso cuando el árbol está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Señales del wave manager
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	wave_manager.enemy_count_changed.connect(_on_enemy_count_changed)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	wave_manager.gold_phase_started.connect(_on_gold_phase_started)
	wave_manager.gold_phase_ended.connect(_on_gold_phase_ended)

	# Señales del jugador
	player.health_changed.connect(_on_player_health_changed)
	player.player_died.connect(_on_player_died)

	# Puntos de spawn para el wave manager
	wave_manager.spawn_points = [
		$SpawnPoint1,
		$SpawnPoint2,
		$SpawnPoint3,
		$SpawnPoint4
	]

	# Inicializa HUD
	hud.update_health(player.health)
	hud.update_score(score)

	# Arranca oleadas tras un breve delay
	await get_tree().create_timer(1.0).timeout
	wave_manager.start_waves()


func _unhandled_input(event: InputEvent) -> void:
	# Solo permite pausar mientras el juego está activo (no en game over / victoria)
	if event.is_action_pressed("pause") and game_active:
		_toggle_pause()


func _toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	if is_paused:
		hud.show_pause()
		play_music(INTER_MUSIC)
	else:
		hud.hide_pause()
		play_music(BATTLE_MUSIC)


# Suma puntos y actualiza el HUD. Llámalo desde cualquier fuente de score:
#   game_manager.add_score(100)  → enemigo muerto
#   game_manager.add_score(50)   → oro recolectado (listo para integrarse)
func add_score(points: int) -> void:
	score += points
	hud.update_score(score)


# ----- Callbacks de wave_manager -----

func _on_wave_started(wave_number: int) -> void:
	hud.update_wave(wave_number)
	play_music(BATTLE_MUSIC)

func _on_wave_completed(_wave_number: int) -> void:
	pass

# ----- Fase de recolección de oro -----

func _on_gold_phase_started(duration: float) -> void:
	play_music(INTER_MUSIC)
	_spawn_gold()
	hud.show_gold_phase(duration)

func _on_gold_phase_ended() -> void:
	_despawn_gold()
	hud.hide_gold_phase()

func _spawn_gold() -> void:
	_spawned_gold.clear()
	for i in range(GOLD_COUNT):
		var nugget = GOLD_SCENE.instantiate()
		nugget.position = Vector2(
			randf_range(GOLD_AREA_X_MIN, GOLD_AREA_X_MAX),
			randf_range(GOLD_AREA_Y_MIN, GOLD_AREA_Y_MAX)
		)
		# Captura la referencia en el closure antes de añadirlo al árbol
		var ref := nugget
		nugget.collected.connect(func(points: int) -> void:
			_spawned_gold.erase(ref)
			add_score(points)
		)
		add_child(nugget)
		_spawned_gold.append(nugget)

func _despawn_gold() -> void:
	for nugget in _spawned_gold:
		if is_instance_valid(nugget):
			nugget.queue_free()
	_spawned_gold.clear()

func _on_all_waves_completed() -> void:
	game_active = false
	get_tree().paused = true
	play_music_once(VICTORY_MUSIC)
	hud.show_victory(score)

func _on_enemy_count_changed(count: int) -> void:
	hud.update_enemy_count(count)

func _on_enemy_killed() -> void:
	add_score(100)  # +100 puntos por enemigo eliminado


# ----- Callbacks del jugador -----

func _on_player_health_changed(new_health: int) -> void:
	hud.update_health(new_health)

func _on_player_died() -> void:
	game_active = false
	hud.show_game_over(score)
	get_tree().paused = true

# Music Funcs
func play_music_once(new_stream: AudioStream):
	# Only change the music if it's not already playing
	if music_player.stream != new_stream:
		# DISCONNECT the loop signal if it was previously connected
		if music_player.finished.is_connected(_on_music_finished):
			music_player.finished.disconnect(_on_music_finished)
			
		music_player.stream = new_stream
		music_player.play()

func play_music(new_stream: AudioStream):
	# Only change the music if it's not already playing
	if music_player.stream != new_stream:
		music_player.stream = new_stream
		music_player.play()
		
		# Connect the 'finished' signal so it loops when the song ends
		if not music_player.finished.is_connected(_on_music_finished):
			music_player.finished.connect(_on_music_finished)

# Helper function: When the music finishes, play it again
func _on_music_finished():
	music_player.play()
