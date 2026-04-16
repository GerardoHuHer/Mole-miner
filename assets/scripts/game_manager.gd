extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var wave_manager: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	# Connect HUD to wave manager signals
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	wave_manager.enemy_count_changed.connect(_on_enemy_count_changed)

	# Connect player signals
	player.health_changed.connect(_on_player_health_changed)
	player.player_died.connect(_on_player_died)

	# Set spawn points on wave manager
	wave_manager.spawn_points = [
		$SpawnPoint1,
		$SpawnPoint2,
		$SpawnPoint3,
		$SpawnPoint4
	]

	# Initialize HUD
	hud.update_health(player.health)

	# Start waves after a brief delay
	await get_tree().create_timer(1.0).timeout
	wave_manager.start_waves()

func _on_wave_started(wave_number: int) -> void:
	hud.update_wave(wave_number)

func _on_wave_completed(_wave_number: int) -> void:
	pass

func _on_all_waves_completed() -> void:
	hud.show_victory()

func _on_enemy_count_changed(count: int) -> void:
	hud.update_enemy_count(count)

func _on_player_health_changed(new_health: int) -> void:
	hud.update_health(new_health)

func _on_player_died() -> void:
	hud.show_game_over()
	get_tree().paused = true
