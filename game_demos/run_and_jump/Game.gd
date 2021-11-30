extends CanvasLayer

var points := 0

const Menu := preload("./Menu.gd")
const Level := preload("./Level.gd")

onready var _level := $Level as Level
onready var _menu := $Menu as Menu
onready var _score := $Score as Label


func _ready() -> void:
	randomize()
	_menu.connect("request_play", self, "play")
	_level.connect("add_point", self, "increase_points")
	_level.connect("game_over", self, "game_over")


func increase_points() -> void:
	points += 1
	_menu.set_new_score_if_is_highest(points)
	_score.text = String(points).pad_zeros(5)


func game_over() -> void:
	_level.game_over()
	_menu.show()
	_menu.set_focus()
	points = 0


func play() -> void:
	game_over()
	_menu.hide()
	_level.start()
