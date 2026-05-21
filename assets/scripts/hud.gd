extends CanvasLayer

const MAX_HEALTH := 5
const TOTAL_WAVES := 5

@onready var hearts_label: Label = $TopBar/HPPanel/HPContainer/HeartsLabel
@onready var wave_label: Label = $TopBar/WavePanel/WaveContainer/WaveLabel
@onready var enemy_count_label: Label = $TopBar/WavePanel/WaveContainer/EnemyCountLabel
@onready var wave_announcement: Label = $WaveAnnouncement
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_title: Label = $GameOverPanel/GameOverContent/GameOverTitle
@onready var play_again_button: Button = $GameOverPanel/GameOverContent/PlayAgainButton

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)

func update_wave(wave_number: int) -> void:
	wave_label.text = "Wave: %d / %d" % [wave_number, TOTAL_WAVES]
	show_announcement("Wave %d!" % wave_number)

func update_enemy_count(count: int) -> void:
	enemy_count_label.text = "Enemies: %d" % count

func update_health(health: int) -> void:
	var hearts := ""
	for i in range(MAX_HEALTH):
		hearts += "♥" if i < health else "♡"
		if i < MAX_HEALTH - 1:
			hearts += " "
	hearts_label.text = hearts
	if health > 0:
		_flash_hearts()

func _flash_hearts() -> void:
	var tween := create_tween()
	tween.tween_property(hearts_label, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.06)
	tween.tween_property(hearts_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)

func show_announcement(text: String) -> void:
	wave_announcement.text = text
	wave_announcement.modulate.a = 1.0
	wave_announcement.scale = Vector2(0.4, 0.4)
	wave_announcement.visible = true

	var tween := create_tween()
	tween.tween_property(wave_announcement, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(1.4)
	tween.tween_property(wave_announcement, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): wave_announcement.visible = false)

func show_victory() -> void:
	game_over_title.text = "VICTORY!"
	game_over_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.45))
	dim_overlay.visible = true
	game_over_panel.visible = true

func show_game_over() -> void:
	game_over_title.text = "GAME OVER"
	game_over_title.add_theme_color_override("font_color", Color(1.0, 0.18, 0.08))
	dim_overlay.visible = true
	game_over_panel.visible = true

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
