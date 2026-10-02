extends Control

@onready var jogar: Button = $Jogar
@onready var sair: Button = $Sair

func _ready() -> void:
	jogar.pressed.connect(_jogar)
	sair.pressed.connect(_sair)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func _jogar() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

func _sair() -> void:
	get_tree().quit()
