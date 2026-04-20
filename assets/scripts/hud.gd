extends CanvasLayer

@onready var wave_label: Label = $WaveLabel
@onready var enemy_count_label: Label = $EnemyCountLabel
@onready var health_label: Label = $HealthLabel
@onready var wave_announcement: Label = $WaveAnnouncement
@onready var play_again_button: Button = $PlayAgainButton

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)

func update_wave(wave_number: int) -> void:
	wave_label.text = "Wave: " + str(wave_number)
	show_announcement("Wave " + str(wave_number) + "!")

func update_enemy_count(count: int) -> void:
	enemy_count_label.text = "Enemies: " + str(count)

func update_health(health: int) -> void:
	health_label.text = "HP: " + str(health)

func show_announcement(text: String) -> void:
	wave_announcement.text = text
	wave_announcement.visible = true
	wave_announcement.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(wave_announcement, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): wave_announcement.visible = false)

func show_victory() -> void:
	show_announcement("All Waves Cleared!")

func show_game_over() -> void:
	wave_announcement.text = "Game Over!"
	wave_announcement.visible = true
	wave_announcement.modulate.a = 1.0
	play_again_button.visible = true

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
