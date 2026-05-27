extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed
signal enemy_count_changed(count: int)
signal enemy_killed            # Para sumar score por enemigo eliminado
signal gold_phase_started(duration: float)  # Emitida al iniciar fase de recolección
signal gold_phase_ended                     # Emitida al terminar fase de recolección

@export var enemy_scene: PackedScene   # Slimes — oleadas 1, 3, 5
@export var worm_scene: PackedScene    # Gusanos — oleadas 2, 4
@export var spawn_points: Array = []
@export var time_between_waves: float = 3.0
@export var time_between_spawns: float = 0.5

var current_wave: int = 0
var enemies_alive: int = 0
var is_spawning: bool = false
var wave_active: bool = false

# Wave definitions: each entry is the number of enemies for that wave
var wave_definitions: Array[int] = [3, 5, 7, 10, 14]

func start_waves() -> void:
	current_wave = 0
	_start_next_wave()

func _start_next_wave() -> void:
	if current_wave >= wave_definitions.size():
		all_waves_completed.emit()
		return

	current_wave += 1
	wave_active = true
	wave_started.emit(current_wave)

	await get_tree().create_timer(1.5, false).timeout
	_spawn_wave(wave_definitions[current_wave - 1])

func _spawn_wave(enemy_count: int) -> void:
	is_spawning = true
	for i in range(enemy_count):
		_spawn_enemy()
		await get_tree().create_timer(time_between_spawns, false).timeout
	is_spawning = false

func _spawn_enemy() -> void:
	# Oleadas pares (2, 4) → gusanos; oleadas impares (1, 3, 5) → slimes
	var scene_to_use: PackedScene
	if current_wave % 2 == 0 and worm_scene != null:
		scene_to_use = worm_scene
	else:
		scene_to_use = enemy_scene

	if scene_to_use == null:
		print("WaveManager: No enemy scene assigned")
		return

	var enemy = scene_to_use.instantiate()

	# Pick a random spawn point, or a random offset around the game area
	if spawn_points.size() > 0:
		var spawn = spawn_points[randi() % spawn_points.size()]
		enemy.global_position = spawn.global_position
	else:
		# Spawn at random edges around the player
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			var angle = randf() * TAU
			var distance = 150.0
			enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		else:
			enemy.global_position = Vector2(randf_range(-50, 200), randf_range(-80, 20))

	enemy.died.connect(_on_enemy_died)
	get_tree().current_scene.add_child(enemy)

	enemies_alive += 1
	enemy_count_changed.emit(enemies_alive)

func _on_enemy_died() -> void:
	enemies_alive -= 1
	enemy_count_changed.emit(enemies_alive)
	enemy_killed.emit()

	if enemies_alive <= 0 and not is_spawning:
		wave_active = false
		wave_completed.emit(current_wave)

		# Fase de recolección de oro entre oleadas (no aplica después de la última)
		if current_wave < wave_definitions.size():
			var gold_time := _get_gold_duration()
			gold_phase_started.emit(gold_time)
			await get_tree().create_timer(gold_time, false).timeout
			gold_phase_ended.emit()

		await get_tree().create_timer(time_between_waves, false).timeout
		_start_next_wave()

# Duración de la fase de oro: 8s tras oleada 1, -2s por cada oleada siguiente
# Oleada 1→8s | 2→6s | 3→4s | 4→2s
func _get_gold_duration() -> float:
	return 8.0 - (current_wave - 1) * 2.0
