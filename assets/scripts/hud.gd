extends CanvasLayer

const MAX_HEALTH := 5
const TOTAL_WAVES := 5

# ---- TopBar ----
@onready var hearts_label: Label             = $TopBar/HPPanel/HPContainer/HeartsLabel
@onready var score_label: Label              = $TopBar/ScorePanel/ScoreContainer/ScoreLabel
@onready var wave_label: Label               = $TopBar/WavePanel/WaveContainer/WaveLabel
@onready var enemy_count_label: Label        = $TopBar/WavePanel/WaveContainer/EnemyCountLabel
@onready var wave_announcement: Label        = $WaveAnnouncement

# ---- Overlay oscuro compartido ----
@onready var dim_overlay: ColorRect          = $DimOverlay

# ---- Game Over ----
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_title: Label          = $GameOverPanel/GameOverContent/GameOverTitle
@onready var game_over_score_label: Label    = $GameOverPanel/GameOverContent/ScoreDisplayLabel
@onready var play_again_button: Button       = $GameOverPanel/GameOverContent/PlayAgainButton
@onready var game_over_quit_button: Button   = $GameOverPanel/GameOverContent/QuitButton

# ---- Victoria ----
@onready var victory_panel: PanelContainer          = $VictoryPanel
@onready var victory_score_label: Label             = $VictoryPanel/VictoryContent/VictoryScoreLabel
@onready var victory_play_again_button: Button      = $VictoryPanel/VictoryContent/PlayAgainButton
@onready var victory_credits_button: Button         = $VictoryPanel/VictoryContent/CreditsButton
@onready var victory_quit_button: Button            = $VictoryPanel/VictoryContent/QuitButton

# ---- Pausa ----
@onready var pause_panel: PanelContainer            = $PausePanel
@onready var resume_button: Button                  = $PausePanel/PauseContent/ResumeButton
@onready var pause_options_button: Button           = $PausePanel/PauseContent/OptionsButton
@onready var pause_how_to_play_button: Button       = $PausePanel/PauseContent/HowToPlayButton
@onready var pause_quit_button: Button              = $PausePanel/PauseContent/QuitButton

# ---- Opciones ----
@onready var options_panel: PanelContainer          = $OptionsPanel
@onready var master_slider: HSlider                 = $OptionsPanel/OptionsContent/MasterVolumeSlider
@onready var music_slider: HSlider                  = $OptionsPanel/OptionsContent/MusicVolumeSlider
@onready var sfx_slider: HSlider                    = $OptionsPanel/OptionsContent/SFXVolumeSlider
@onready var options_back_button: Button            = $OptionsPanel/OptionsContent/BackButton

# ---- Cómo jugar ----
@onready var how_to_play_panel: PanelContainer      = $HowToPlayPanel
@onready var how_to_play_back_button: Button        = $HowToPlayPanel/HowToPlayContent/BackButton

# ---- Créditos ----
@onready var credits_panel: PanelContainer          = $CreditsPanel
@onready var credits_back_button: Button            = $CreditsPanel/CreditsContent/BackButton

# ---- Fase de oro ----
@onready var gold_phase_panel: PanelContainer       = $GoldPhasePanel
@onready var gold_label: Label                      = $GoldPhasePanel/GoldLabel

var _gold_active: bool = false
var _gold_time_left: float = 0.0

# ---- Music -----
const BATTLE_MUSIC = preload("res://assets/music/Combate.mp3")
@onready var music_player = $"../MusicPlayer"


func _ready() -> void:
	# Game Over
	play_again_button.pressed.connect(_on_play_again_pressed)
	game_over_quit_button.pressed.connect(_on_quit_pressed)

	# Victoria
	victory_play_again_button.pressed.connect(_on_play_again_pressed)
	victory_credits_button.pressed.connect(_on_victory_credits_pressed)
	victory_quit_button.pressed.connect(_on_quit_pressed)

	# Pausa
	resume_button.pressed.connect(_on_resume_pressed)
	pause_options_button.pressed.connect(_on_pause_options_pressed)
	pause_how_to_play_button.pressed.connect(_on_pause_how_to_play_pressed)
	pause_quit_button.pressed.connect(_on_quit_pressed)

	# Opciones
	options_back_button.pressed.connect(_on_options_back_pressed)
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	# Cómo jugar
	how_to_play_back_button.pressed.connect(_on_how_to_play_back_pressed)

	# Créditos
	credits_back_button.pressed.connect(_on_credits_back_pressed)

	# Inicializa sliders de volumen desde AudioServer
	_init_volume_sliders()


func _init_volume_sliders() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_idx))

	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_idx))

	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx))


# ===== Actualización de HUD en juego =====

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

func update_score(score: int) -> void:
	score_label.text = "Score: %d" % score

func _process(delta: float) -> void:
	if not _gold_active:
		return
	# Pausa la cuenta mientras el juego esté pausado (el HUD corre en ALWAYS)
	if get_tree().paused:
		return
	_gold_time_left -= delta
	var secs: int = maxi(0, ceili(_gold_time_left))
	gold_label.text = "RECOGE EL ORO!  %ds" % secs
	# Parpadeo rojo en los últimos 3 segundos
	if _gold_time_left <= 3.0:
		gold_label.modulate = Color(1.0, 0.25, 0.25) if fmod(_gold_time_left, 0.5) < 0.25 else Color(1.0, 0.88, 0.0)
	else:
		gold_label.modulate = Color(1.0, 0.88, 0.0)


# ===== Fase de recolección de oro =====

func show_gold_phase(duration: float) -> void:
	_gold_time_left = duration
	_gold_active = true
	gold_label.modulate = Color(1.0, 0.88, 0.0)
	gold_label.text = "RECOGE EL ORO!  %ds" % int(duration)
	gold_phase_panel.visible = true
	show_announcement("¡Recoge el oro!")

func hide_gold_phase() -> void:
	_gold_active = false
	gold_phase_panel.visible = false


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


# ===== Pausa =====

func show_pause() -> void:
	dim_overlay.visible = true
	pause_panel.visible = true

func hide_pause() -> void:
	# Oculta todos los paneles relacionados con pausa
	dim_overlay.visible = false
	pause_panel.visible = false
	options_panel.visible = false
	how_to_play_panel.visible = false


# ===== Game Over =====

func show_game_over(score: int) -> void:
	game_over_title.text = "HAS MUERTO"
	game_over_title.add_theme_color_override("font_color", Color(1.0, 0.18, 0.08))
	game_over_score_label.text = "Puntos: %d" % score
	dim_overlay.visible = true
	game_over_panel.visible = true


# ===== Victoria =====

func show_victory(score: int) -> void:
	victory_score_label.text = "Puntos finales: %d" % score
	dim_overlay.visible = true
	victory_panel.visible = true


# ===== Botones — Game Over =====

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()


# ===== Botones — Pausa =====

func _on_resume_pressed() -> void:
	play_music(BATTLE_MUSIC)
	hide_pause()
	get_tree().paused = false

func _on_pause_options_pressed() -> void:
	pause_panel.visible = false
	options_panel.visible = true

func _on_pause_how_to_play_pressed() -> void:
	pause_panel.visible = false
	how_to_play_panel.visible = true


# ===== Botones — Opciones =====

func _on_options_back_pressed() -> void:
	options_panel.visible = false
	pause_panel.visible = true

func _on_master_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_music_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_sfx_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))


# ===== Botones — Cómo jugar =====

func _on_how_to_play_back_pressed() -> void:
	how_to_play_panel.visible = false
	pause_panel.visible = true


# ===== Botones — Créditos (desde victoria) =====

func _on_victory_credits_pressed() -> void:
	victory_panel.visible = false
	credits_panel.visible = true

func _on_credits_back_pressed() -> void:
	credits_panel.visible = false
	victory_panel.visible = true


# ===== music funcs ==========
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
