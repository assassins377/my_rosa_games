extends Node

signal language_changed

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "language"
const SETTINGS_KEY := "current"
const DEFAULT_LANGUAGE := "ru"

const LANGUAGES := ["ru", "en"]
const LANGUAGE_NAMES := {
	"ru": "Русский",
	"en": "English",
}

const TEXT := {
	"ru": {
		"menu_subtitle": "Старый учёный против чужой планеты.",
		"menu_play": "Играть",
		"menu_how_to_play": "Как играть",
		"menu_hide_help": "Скрыть помощь",
		"menu_story": "Сюжет",
		"menu_hide_story": "Скрыть сюжет",
		"menu_settings": "Настройки",
		"menu_hide_settings": "Скрыть настройки",
		"settings_title": "Настройки",
		"settings_language": "Язык",
		"settings_screen_mode": "Режим экрана",
		"settings_windowed_mode": "Оконный",
		"settings_fullscreen_mode": "Полный экран",
		"settings_adaptive": "Адаптивность интерфейса: включена",
		"settings_save": "Сохранить",
		"settings_saved": "Настройки сохранены",
		"settings_reset": "Сбросить настройки",
		"settings_close": "Закрыть",
		"controls_title": "Кнопки управления",
		"controls_hint": "Нажми кнопку действия справа, затем нажми новую клавишу.",
		"control_waiting": "Нажмите клавишу...",
		"control_waiting_status": "Ожидание новой клавиши",
		"controls_saved": "Кнопка управления сохранена",
		"control_unassigned": "Не назначено",
		"control_move_up": "Вверх",
		"control_move_down": "Вниз",
		"control_move_left": "Влево",
		"control_move_right": "Вправо",
		"control_dash": "Рывок",
		"control_build_factory": "Поставить L1 Nord",
		"control_build_battery": "Поставить аккумулятор",
		"control_build_wire": "Поставить провод",
		"control_pause": "Пауза",
		"control_restart": "Заново",
		"menu_quit": "Выход",
		"menu_instructions": "Исследуй чужую планету, собирай ядра измерения и разворачивай базу. Строй машины, подключай питание и готовь защиту от местных существ.",
		"menu_story_text": "Вам 70 лет. Вы посвятили жизнь исследованию чёрных дыр и наконец нашли способ перейти в другое измерение. Эксперимент сработал, но выбросил вас на чужую планету. Вокруг недружественные существа, а выжить можно только собирая редкие ядра, строя добывающие машины, защитные устройства и всё, что поможет превратить лагерь в дом.",
		"settings_resolution": "Разрешение",
		"settings_fullscreen": "Полный экран",
		"settings_windowed": "Оконный режим",
		"language_button": "Язык: %s",
		"game_help_builder": "Исследуй планету, строй базу и подключай питание к L1 Nord.",
		"game_factories": "Заводы: %d",
		"game_buildings": "Заводы: %d    Аккумуляторы: %d    Провода: %d",
		"build_button": "Поставить L1 Nord",
		"build_button_cancel": "Отменить размещение",
		"build_battery_button": "Поставить аккумулятор",
		"build_battery_button_cancel": "Отменить аккумулятор",
		"build_wire_button": "Поставить провод",
		"build_wire_button_cancel": "Отменить провод",
		"mobile_dash": "Рывок",
		"mobile_factory": "L1",
		"mobile_battery": "Акк.",
		"mobile_wire": "Пров.",
		"mobile_place": "Поставить",
		"mobile_cancel": "Отмена",
		"mobile_pause": "Пауза",
		"build_hint_idle": "Процедурная карта. Найди ровное место для первого обесточенного завода.",
		"build_hint_active": "Выбери подходящую клетку для выбранного здания. Трещины и камень не подходят.",
		"move_hint_active": "Выбери новое место для переносимого здания. Его можно поставить только на свободную ровную клетку.",
		"build_status_choose": "Режим строительства: L1 Nord без питания",
		"build_status_choose_battery": "Режим строительства: аккумулятор",
		"build_status_choose_wire": "Режим строительства: провод питания",
		"build_status_blocked": "Здесь нельзя поставить здание: мешает рельеф, игрок или другое здание.",
		"build_status_placed": "L1 Nord построен. Состояние: обесточен.",
		"build_status_battery_placed": "Аккумулятор установлен. L1 Nord включится, если он в радиусе 10 клеток.",
		"build_status_wire_placed": "Провод установлен. Он передаст питание от аккумулятора или другого провода.",
		"move_status_choose_factory": "Режим переноса: L1 Nord. Выбери новое место.",
		"move_status_choose_battery": "Режим переноса: аккумулятор. Выбери новое место.",
		"move_status_choose_wire": "Режим переноса: провод. Выбери новое место.",
		"move_status_placed_factory": "L1 Nord перенесён.",
		"move_status_placed_battery": "Аккумулятор перенесён.",
		"move_status_placed_wire": "Провод перенесён.",
		"move_button_cancel": "Отменить перенос",
		"game_help": "Исследуй планету, собирай ядра измерения и избегай местных существ.",
		"game_crystals": "Ядра измерения: %d / %d",
		"game_health": "Здоровье: %d / %d",
		"game_win": "Ядра собраны. Теперь можно строить первый добывающий модуль.",
		"game_lose": "Местные существа тебя настигли.",
		"factory_locked": "L1 Nord\nОбесточен\nНужен аккумулятор или провод",
		"factory_active": "L1 Nord\nПитание подключено",
		"factory_destroyed": "L1 Nord\nРазрушен",
		"factory_stats": "Прочность: %d / %d\nРасход: %.1f Вт/ч\nРадиус: %d клетки",
		"factory_state_active": "работает",
		"factory_state_unpowered": "обесточен",
		"factory_state_destroyed": "разрушен",
		"factory_info": "Характеристики L1 Nord\nСостояние: %s\nПрочность: %d / %d\nПотребление: %.1f Вт/ч\nРадиус питания: %d клеток\nИсточник: %s",
		"power_source_found": "найден",
		"power_source_missing": "нет",
		"battery_label": "Аккумулятор",
		"battery_status": "%s\n%d%%",
		"battery_info": "%s\nЗаряд: %.1f / %.1f Втч\nЗаполнен: %d%%\nСостояние: %s",
		"battery_state_charged": "заряжен",
		"battery_state_empty": "разряжен",
		"pause_title": "Пауза",
		"pause_resume": "Продолжить",
		"pause_restart": "Заново",
		"pause_menu": "Главное меню",
	},
	"en": {
		"menu_subtitle": "An old scientist against an alien planet.",
		"menu_play": "Play",
		"menu_how_to_play": "How to play",
		"menu_hide_help": "Hide help",
		"menu_story": "Story",
		"menu_hide_story": "Hide story",
		"menu_settings": "Settings",
		"menu_hide_settings": "Hide settings",
		"settings_title": "Settings",
		"settings_language": "Language",
		"settings_screen_mode": "Screen mode",
		"settings_windowed_mode": "Windowed",
		"settings_fullscreen_mode": "Fullscreen",
		"settings_adaptive": "Adaptive UI: enabled",
		"settings_save": "Save",
		"settings_saved": "Settings saved",
		"settings_reset": "Reset settings",
		"settings_close": "Close",
		"controls_title": "Control buttons",
		"controls_hint": "Press an action button on the right, then press a new key.",
		"control_waiting": "Press key...",
		"control_waiting_status": "Waiting for a new key",
		"controls_saved": "Control button saved",
		"control_unassigned": "Unassigned",
		"control_move_up": "Move up",
		"control_move_down": "Move down",
		"control_move_left": "Move left",
		"control_move_right": "Move right",
		"control_dash": "Dash",
		"control_build_factory": "Place L1 Nord",
		"control_build_battery": "Place battery",
		"control_build_wire": "Place wire",
		"control_pause": "Pause",
		"control_restart": "Restart",
		"menu_quit": "Quit",
		"menu_instructions": "Explore the alien planet, gather dimension cores, and build a base. Construct machines, connect power, and prepare defenses against local creatures.",
		"menu_story_text": "You are 70 years old. You spent your life studying black holes and finally discovered a way into another dimension. The experiment worked, but it threw you onto an alien planet. Hostile creatures are everywhere, and survival means gathering rare cores, building mining machines, defense devices, and everything needed to turn a camp into a home.",
		"settings_resolution": "Resolution",
		"settings_fullscreen": "Fullscreen",
		"settings_windowed": "Windowed",
		"language_button": "Language: %s",
		"game_help_builder": "Explore the planet, build a base, and connect power to L1 Nord.",
		"game_factories": "Factories: %d",
		"game_buildings": "Factories: %d    Batteries: %d    Wires: %d",
		"build_button": "Place L1 Nord",
		"build_button_cancel": "Cancel placement",
		"build_battery_button": "Place battery",
		"build_battery_button_cancel": "Cancel battery",
		"build_wire_button": "Place wire",
		"build_wire_button_cancel": "Cancel wire",
		"mobile_dash": "Dash",
		"mobile_factory": "L1",
		"mobile_battery": "Bat.",
		"mobile_wire": "Wire",
		"mobile_place": "Place",
		"mobile_cancel": "Cancel",
		"mobile_pause": "Pause",
		"build_hint_idle": "Procedural map. Find stable ground for the first unpowered factory.",
		"build_hint_active": "Choose a stable cell for the selected building. Cracks and stone are blocked.",
		"move_hint_active": "Choose a new place for the moved building. It can only be placed on a free stable cell.",
		"build_status_choose": "Build mode: unpowered L1 Nord",
		"build_status_choose_battery": "Build mode: battery",
		"build_status_choose_wire": "Build mode: power wire",
		"build_status_blocked": "You cannot place a building here: terrain, player, or another building blocks it.",
		"build_status_placed": "L1 Nord built. Status: unpowered.",
		"build_status_battery_placed": "Battery placed. L1 Nord will power on if it is within 10 cells.",
		"build_status_wire_placed": "Wire placed. It will carry power from a battery or another wire.",
		"move_status_choose_factory": "Move mode: L1 Nord. Choose a new place.",
		"move_status_choose_battery": "Move mode: battery. Choose a new place.",
		"move_status_choose_wire": "Move mode: wire. Choose a new place.",
		"move_status_placed_factory": "L1 Nord moved.",
		"move_status_placed_battery": "Battery moved.",
		"move_status_placed_wire": "Wire moved.",
		"move_button_cancel": "Cancel moving",
		"game_help": "Explore the planet, collect dimension cores, and avoid local creatures.",
		"game_crystals": "Dimension cores: %d / %d",
		"game_health": "Health: %d / %d",
		"game_win": "Cores collected. You can build the first mining module now.",
		"game_lose": "The local creatures caught you.",
		"factory_locked": "L1 Nord\nUnpowered\nNeeds a battery or wire",
		"factory_active": "L1 Nord\nPower connected",
		"factory_destroyed": "L1 Nord\nDestroyed",
		"factory_stats": "Durability: %d / %d\nUsage: %.1f W/h\nRadius: %d cells",
		"factory_state_active": "working",
		"factory_state_unpowered": "unpowered",
		"factory_state_destroyed": "destroyed",
		"factory_info": "L1 Nord characteristics\nState: %s\nDurability: %d / %d\nUsage: %.1f W/h\nPower radius: %d cells\nSource: %s",
		"power_source_found": "found",
		"power_source_missing": "missing",
		"battery_label": "Battery",
		"battery_status": "%s\n%d%%",
		"battery_info": "%s\nCharge: %.1f / %.1f Wh\nFilled: %d%%\nState: %s",
		"battery_state_charged": "charged",
		"battery_state_empty": "empty",
		"pause_title": "Paused",
		"pause_resume": "Resume",
		"pause_restart": "Restart",
		"pause_menu": "Main menu",
	},
}

var current_language := DEFAULT_LANGUAGE


func _ready() -> void:
	_load_language()


func t(key: String) -> String:
	var language_text: Dictionary = TEXT.get(current_language, TEXT["en"])
	return language_text.get(key, TEXT["en"].get(key, key))


func current_language_name() -> String:
	return LANGUAGE_NAMES.get(current_language, current_language)


func language_count() -> int:
	return LANGUAGES.size()


func language_code(index: int) -> String:
	return LANGUAGES[clamp(index, 0, LANGUAGES.size() - 1)]


func language_name(index: int) -> String:
	return LANGUAGE_NAMES.get(language_code(index), language_code(index))


func current_language_index() -> int:
	return max(LANGUAGES.find(current_language), 0)


func toggle_language() -> void:
	var current_index := LANGUAGES.find(current_language)
	var next_index := 0 if current_index == -1 else (current_index + 1) % LANGUAGES.size()
	set_language(LANGUAGES[next_index])


func set_language(language_code: String) -> void:
	if not LANGUAGES.has(language_code) or current_language == language_code:
		return

	current_language = language_code
	language_changed.emit()
	_save_language()


func save_settings() -> void:
	_save_language()


func reset_settings() -> void:
	current_language = DEFAULT_LANGUAGE
	_save_language()
	language_changed.emit()


func _load_language() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)

	if error == OK:
		var saved_language := str(config.get_value(SETTINGS_SECTION, SETTINGS_KEY, current_language))

		if LANGUAGES.has(saved_language):
			current_language = saved_language


func _save_language() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, current_language)
	config.save(SETTINGS_PATH)
