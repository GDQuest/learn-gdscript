extends Node2D

const START_CELL := Vector2(2, 0)

@export var board_size := Vector2(5, 5)
@export var cell_size := 64
@export var line_width := 4

var cell := START_CELL

@onready var _label := $Label
@onready var _robot := $Robot


func _ready() -> void:
	_robot.cell_size = cell_size
	_robot.cell = cell
	update()


func _run() -> void:
	move_after()
	_robot.cell = cell
	_update_label()
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")


# EXPORT move_to_end
func move_after():
	while cell.y < board_size.y - 1:
		cell += Vector2(0, 1)
# /EXPORT move_to_end


func reset() -> void:
	_robot.cell = START_CELL
	_update_label()
	

func _draw() -> void:
	for x in range(board_size.x):
		for y in range(board_size.y):
			draw_rect(Rect2(Vector2(x * cell_size, y * cell_size), Vector2.ONE * cell_size), Color.WHITE, false, line_width)


func _update_label() -> void:
	if not _label:
		await self.ready
	
	_label.text = "cell = Vector2%s" % [_robot.cell]
