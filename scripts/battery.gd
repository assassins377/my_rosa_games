extends StaticBody2D

const BATTERY_TEXTURES := [
	preload("res://assets/battery_frames/battery_00.png"),
	preload("res://assets/battery_frames/battery_01.png"),
	preload("res://assets/battery_frames/battery_02.png"),
	preload("res://assets/battery_frames/battery_03.png"),
	preload("res://assets/battery_frames/battery_04.png"),
	preload("res://assets/battery_frames/battery_05.png"),
]

@export var capacity_wh := 15.0
@export var stored_energy_wh := 15.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var status_label: Label = $StatusLabel
@onready var info_button: Button = $InfoButton
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_text: Label = $InfoPanel/Margin/InfoText

var language: Node


func _ready() -> void:
	add_to_group("battery")
	add_to_group("power_source")
	stored_energy_wh = clampf(stored_energy_wh, 0.0, capacity_wh)
	language = get_node_or_null("/root/Language")

	if language != null and language.has_signal("language_changed"):
		language.connect("language_changed", Callable(self, "_update_visual"))

	info_button.mouse_entered.connect(_show_info_panel)
	info_button.mouse_exited.connect(_hide_info_panel)
	info_button.pressed.connect(_toggle_info_panel)
	info_panel.visible = false
	_update_visual()


func has_energy() -> bool:
	return stored_energy_wh > 0.0


func can_supply_energy(amount_wh: float = 0.0) -> bool:
	return stored_energy_wh >= maxf(amount_wh, 0.0)


func consume_energy(amount_wh: float) -> bool:
	amount_wh = maxf(amount_wh, 0.0)

	if not can_supply_energy(amount_wh):
		stored_energy_wh = 0.0
		_update_visual()
		return false

	stored_energy_wh -= amount_wh
	_update_visual()
	return true


func recharge(amount_wh: float) -> void:
	stored_energy_wh = clampf(stored_energy_wh + maxf(amount_wh, 0.0), 0.0, capacity_wh)
	_update_visual()


func get_charge_ratio() -> float:
	if capacity_wh <= 0.0:
		return 0.0

	return clampf(stored_energy_wh / capacity_wh, 0.0, 1.0)


func _update_visual() -> void:
	var charge_ratio := get_charge_ratio()
	var frame_index := 0

	if charge_ratio > 0.0:
		frame_index = int(ceil(charge_ratio * float(BATTERY_TEXTURES.size() - 1)))

	sprite.texture = BATTERY_TEXTURES[clampi(frame_index, 0, BATTERY_TEXTURES.size() - 1)]

	var title := "АКБ"
	var status_format := "%s\n%d%%"

	if language != null and language.has_method("t"):
		title = str(language.call("t", "battery_label"))
		status_format = str(language.call("t", "battery_status"))

	status_label.text = status_format % [title, int(round(get_charge_ratio() * 100.0))]
	_update_info_text()


func _update_info_text() -> void:
	var title := "АКБ"
	var info_format := "%s\n%.1f / %.1f Втч\n%d%%\n%s"
	var state_text := "Заряжен" if has_energy() else "Разряжен"

	if language != null and language.has_method("t"):
		title = str(language.call("t", "battery_label"))
		info_format = str(language.call("t", "battery_info"))
		state_text = str(language.call("t", "battery_state_charged")) if has_energy() else str(language.call("t", "battery_state_empty"))

	info_text.text = info_format % [
		title,
		stored_energy_wh,
		capacity_wh,
		int(round(get_charge_ratio() * 100.0)),
		state_text,
	]


func _show_info_panel() -> void:
	_update_info_text()
	info_panel.visible = true


func _hide_info_panel() -> void:
	info_panel.visible = false


func _toggle_info_panel() -> void:
	if info_panel.visible:
		_hide_info_panel()
	else:
		_show_info_panel()
