extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const PANEL_MAX_SIZE := Vector2(620.0, 680.0)
const PANEL_MIN_SIZE := Vector2(300.0, 320.0)
const SETTINGS_MAX_SIZE := Vector2(540.0, 540.0)
const SETTINGS_MIN_SIZE := Vector2(300.0, 340.0)
const STORY_MAX_SIZE := Vector2(600.0, 500.0)
const STORY_MIN_SIZE := Vector2(300.0, 300.0)
const SCREEN_MARGIN := 24.0

@onready var language = get_node("/root/Language")
@onready var screen = get_node("/root/Screen")
@onready var controls = get_node("/root/Controls")
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/Scroll/VBox/Title
@onready var subtitle_label: Label = $Panel/Margin/Scroll/VBox/Subtitle
@onready var showcase: HBoxContainer = $Panel/Margin/Scroll/VBox/Showcase
@onready var factory_preview: TextureRect = $Panel/Margin/Scroll/VBox/Showcase/FactoryPreview
@onready var play_button: Button = $Panel/Margin/Scroll/VBox/PlayButton
@onready var how_to_play_button: Button = $Panel/Margin/Scroll/VBox/HowToPlayButton
@onready var story_button: Button = $Panel/Margin/Scroll/VBox/StoryButton
@onready var settings_button: Button = $Panel/Margin/Scroll/VBox/SettingsButton
@onready var quit_button: Button = $Panel/Margin/Scroll/VBox/QuitButton
@onready var instructions: PanelContainer = $Panel/Margin/Scroll/VBox/Instructions
@onready var instructions_text: Label = $Panel/Margin/Scroll/VBox/Instructions/InstructionsMargin/Text
@onready var story_window: Control = $StoryWindow
@onready var story_panel: PanelContainer = $StoryWindow/Panel
@onready var story_title: Label = $StoryWindow/Panel/Margin/Scroll/VBox/TitleLabel
@onready var story_text: Label = $StoryWindow/Panel/Margin/Scroll/VBox/TextPanel/TextMargin/Text
@onready var close_story_button: Button = $StoryWindow/Panel/Margin/Scroll/VBox/CloseButton
@onready var settings_window: Control = $SettingsWindow
@onready var settings_panel: PanelContainer = $SettingsWindow/Panel
@onready var settings_title: Label = $SettingsWindow/Panel/Margin/Scroll/VBox/TitleLabel
@onready var resolution_label: Label = $SettingsWindow/Panel/Margin/Scroll/VBox/ResolutionLabel
@onready var resolution_option: OptionButton = $SettingsWindow/Panel/Margin/Scroll/VBox/ResolutionOption
@onready var screen_mode_label: Label = $SettingsWindow/Panel/Margin/Scroll/VBox/ScreenModeLabel
@onready var screen_mode_option: OptionButton = $SettingsWindow/Panel/Margin/Scroll/VBox/ScreenModeOption
@onready var language_label: Label = $SettingsWindow/Panel/Margin/Scroll/VBox/LanguageLabel
@onready var language_option: OptionButton = $SettingsWindow/Panel/Margin/Scroll/VBox/LanguageOption
@onready var adaptive_label: Label = $SettingsWindow/Panel/Margin/Scroll/VBox/AdaptiveLabel
@onready var controls_title_label: Label = $SettingsWindow/Panel/Margin/Scroll/VBox/ControlsTitleLabel
@onready var controls_hint_label: Label = $SettingsWindow/Panel/Margin/Scroll/VBox/ControlsHintLabel
@onready var controls_list: VBoxContainer = $SettingsWindow/Panel/Margin/Scroll/VBox/ControlsList
@onready var save_settings_button: Button = $SettingsWindow/Panel/Margin/Scroll/VBox/SaveButton
@onready var save_status_label: Label = $SettingsWindow/Panel/Margin/Scroll/VBox/SaveStatusLabel
@onready var reset_settings_button: Button = $SettingsWindow/Panel/Margin/Scroll/VBox/ResetButton
@onready var close_settings_button: Button = $SettingsWindow/Panel/Margin/Scroll/VBox/CloseButton

var _control_buttons: Dictionary = {}
var _control_labels: Dictionary = {}
var _rebinding_action := &""


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	story_button.pressed.connect(_on_story_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	screen_mode_option.item_selected.connect(_on_screen_mode_selected)
	language_option.item_selected.connect(_on_language_selected)
	close_story_button.pressed.connect(_on_close_story_pressed)
	save_settings_button.pressed.connect(_on_save_settings_pressed)
	reset_settings_button.pressed.connect(_on_reset_settings_pressed)
	close_settings_button.pressed.connect(_on_close_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	language.language_changed.connect(_update_text)
	controls.controls_changed.connect(_sync_control_buttons)
	screen.size_changed.connect(_fit_to_screen)
	screen.settings_changed.connect(_sync_settings_controls)
	instructions.visible = false
	story_window.visible = false
	settings_window.visible = false
	_fill_resolution_options()
	_fill_screen_mode_options()
	_fill_language_options()
	_build_control_rows()
	_fit_to_screen()
	_update_text()
	play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if settings_window.visible and _rebinding_action != &"":
		_handle_rebind_input(event)
		return

	if story_window.visible and event.is_action_pressed("ui_cancel"):
		_on_close_story_pressed()
		get_viewport().set_input_as_handled()
	elif settings_window.visible and event.is_action_pressed("ui_cancel"):
		_on_close_settings_pressed()
		get_viewport().set_input_as_handled()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_how_to_play_pressed() -> void:
	instructions.visible = not instructions.visible

	if instructions.visible:
		story_window.visible = false

	_update_text()


func _on_story_pressed() -> void:
	story_window.visible = true
	settings_window.visible = false
	instructions.visible = false
	_update_text()
	close_story_button.grab_focus()


func _on_close_story_pressed() -> void:
	story_window.visible = false
	story_button.grab_focus()


func _on_settings_pressed() -> void:
	settings_window.visible = true
	instructions.visible = false
	story_window.visible = false
	_sync_settings_controls()
	_update_text()
	resolution_option.grab_focus()


func _on_close_settings_pressed() -> void:
	_rebinding_action = &""
	_sync_control_buttons()
	settings_window.visible = false
	settings_button.grab_focus()


func _on_resolution_selected(index: int) -> void:
	_clear_saved_status()
	screen.set_resolution_index(index)


func _on_screen_mode_selected(index: int) -> void:
	_clear_saved_status()
	screen.set_screen_mode(index)


func _on_language_selected(index: int) -> void:
	_clear_saved_status()
	language.set_language(language.language_code(index))


func _on_save_settings_pressed() -> void:
	screen.save_settings()
	language.save_settings()
	controls.save_settings()
	save_status_label.text = language.t("settings_saved")


func _on_reset_settings_pressed() -> void:
	screen.reset_settings()
	language.reset_settings()
	controls.reset_settings()
	_rebinding_action = &""
	_sync_settings_controls()
	_update_text()
	save_status_label.text = language.t("settings_saved")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _update_text() -> void:
	subtitle_label.text = language.t("menu_subtitle")
	play_button.text = language.t("menu_play")
	how_to_play_button.text = language.t("menu_hide_help") if instructions.visible else language.t("menu_how_to_play")
	story_button.text = language.t("menu_story")
	settings_button.text = language.t("menu_settings")
	quit_button.text = language.t("menu_quit")
	instructions_text.text = language.t("menu_instructions")
	story_title.text = language.t("menu_story")
	story_text.text = language.t("menu_story_text")
	close_story_button.text = language.t("settings_close")
	settings_title.text = language.t("settings_title")
	resolution_label.text = language.t("settings_resolution")
	screen_mode_label.text = language.t("settings_screen_mode")
	language_label.text = language.t("settings_language")
	adaptive_label.text = language.t("settings_adaptive")
	controls_title_label.text = language.t("controls_title")
	controls_hint_label.text = language.t("controls_hint")
	save_settings_button.text = language.t("settings_save")
	if save_status_label.text != "":
		save_status_label.text = language.t("control_waiting_status") if _rebinding_action != &"" else language.t("settings_saved")
	reset_settings_button.text = language.t("settings_reset")
	close_settings_button.text = language.t("settings_close")
	_sync_settings_controls()
	_sync_control_buttons()


func _fill_resolution_options() -> void:
	resolution_option.clear()

	for index in range(screen.resolution_count()):
		resolution_option.add_item(screen.resolution_label(index), index)

	_sync_settings_controls()


func _fill_screen_mode_options() -> void:
	screen_mode_option.clear()
	screen_mode_option.add_item(language.t("settings_windowed_mode"), 0)
	screen_mode_option.add_item(language.t("settings_fullscreen_mode"), 1)
	_sync_settings_controls()


func _fill_language_options() -> void:
	language_option.clear()

	for index in range(language.language_count()):
		language_option.add_item(language.language_name(index), index)

	_sync_settings_controls()


func _sync_settings_controls() -> void:
	if resolution_option.get_item_count() > 0:
		resolution_option.select(screen.selected_resolution_index)

	if screen_mode_option.get_item_count() > 0:
		screen_mode_option.set_item_text(0, language.t("settings_windowed_mode"))
		screen_mode_option.set_item_text(1, language.t("settings_fullscreen_mode"))
		screen_mode_option.select(screen.current_screen_mode_index())

	if language_option.get_item_count() > 0:
		language_option.select(language.current_language_index())

	_sync_control_buttons()


func _build_control_rows() -> void:
	for child in controls_list.get_children():
		child.queue_free()

	_control_buttons.clear()
	_control_labels.clear()

	for index in range(controls.action_count()):
		var action_name: StringName = controls.action_name(index)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.86, 1))

		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 40)
		button.size_flags_horizontal = Control.SIZE_FILL
		button.add_theme_font_size_override("font_size", 15)
		_apply_button_style(button)
		button.pressed.connect(_start_rebinding.bind(action_name))

		row.add_child(label)
		row.add_child(button)
		controls_list.add_child(row)

		_control_labels[action_name] = label
		_control_buttons[action_name] = button

	_sync_control_buttons()


func _apply_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", save_settings_button.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("hover", save_settings_button.get_theme_stylebox("hover"))
	button.add_theme_stylebox_override("pressed", save_settings_button.get_theme_stylebox("pressed"))
	button.add_theme_stylebox_override("focus", save_settings_button.get_theme_stylebox("focus"))


func _start_rebinding(action_name: StringName) -> void:
	_rebinding_action = action_name
	save_status_label.text = language.t("control_waiting_status")
	_sync_control_buttons()


func _handle_rebind_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	var keycode := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode

	if keycode != KEY_NONE:
		controls.set_action_key(_rebinding_action, keycode)
		_clear_saved_status()
		save_status_label.text = language.t("controls_saved")

	_rebinding_action = &""
	_sync_control_buttons()
	get_viewport().set_input_as_handled()


func _sync_control_buttons() -> void:
	if controls_list == null:
		return

	for action_name in _control_buttons.keys():
		var label := _control_labels[action_name] as Label
		var button := _control_buttons[action_name] as Button
		label.text = language.t(controls.action_label_key(action_name))

		if _rebinding_action == action_name:
			button.text = language.t("control_waiting")
		else:
			var key_text: String = controls.action_key_text(action_name)
			button.text = key_text if key_text != "" else language.t("control_unassigned")


func _clear_saved_status() -> void:
	save_status_label.text = ""


func _fit_to_screen() -> void:
	var viewport_size := get_viewport_rect().size
	var available_size := viewport_size - Vector2(SCREEN_MARGIN * 2.0, SCREEN_MARGIN * 2.0)
	var panel_width = min(PANEL_MAX_SIZE.x, max(PANEL_MIN_SIZE.x, available_size.x))
	var panel_height = min(PANEL_MAX_SIZE.y, max(PANEL_MIN_SIZE.y, available_size.y))
	var settings_width = min(SETTINGS_MAX_SIZE.x, max(SETTINGS_MIN_SIZE.x, available_size.x))
	var settings_height = min(SETTINGS_MAX_SIZE.y, max(SETTINGS_MIN_SIZE.y, available_size.y))
	var story_width = min(STORY_MAX_SIZE.x, max(STORY_MIN_SIZE.x, available_size.x))
	var story_height = min(STORY_MAX_SIZE.y, max(STORY_MIN_SIZE.y, available_size.y))

	panel.offset_left = -panel_width * 0.5
	panel.offset_top = -panel_height * 0.5
	panel.offset_right = panel_width * 0.5
	panel.offset_bottom = panel_height * 0.5

	settings_panel.offset_left = -settings_width * 0.5
	settings_panel.offset_top = -settings_height * 0.5
	settings_panel.offset_right = settings_width * 0.5
	settings_panel.offset_bottom = settings_height * 0.5

	story_panel.offset_left = -story_width * 0.5
	story_panel.offset_top = -story_height * 0.5
	story_panel.offset_right = story_width * 0.5
	story_panel.offset_bottom = story_height * 0.5
	_fit_menu_content(viewport_size)


func _fit_menu_content(viewport_size: Vector2) -> void:
	var is_compact := viewport_size.x < 620.0 or viewport_size.y < 560.0
	var title_font_size := 42 if is_compact else 58
	var button_height := 42.0 if is_compact else 46.0
	var play_height := 46.0 if is_compact else 50.0

	title_label.add_theme_font_size_override("font_size", title_font_size)
	subtitle_label.add_theme_font_size_override("font_size", 13 if is_compact else 16)
	showcase.custom_minimum_size = Vector2(0.0, 112.0 if is_compact else 160.0)
	factory_preview.custom_minimum_size = Vector2(128.0, 108.0) if is_compact else Vector2(180.0, 160.0)
	play_button.custom_minimum_size = Vector2(260.0, play_height)

	for button in [how_to_play_button, story_button, settings_button, quit_button]:
		button.custom_minimum_size = Vector2(260.0, button_height)

	settings_title.add_theme_font_size_override("font_size", 28 if is_compact else 32)
	story_title.add_theme_font_size_override("font_size", 28 if is_compact else 32)
