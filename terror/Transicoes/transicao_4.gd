extends Control

@export_file("*.tscn") var proxima_cena: String = "res://ato_3.tscn"

func _ready() -> void:
	await get_tree().create_timer(1.5).timeout

	if proxima_cena != "":
		get_tree().change_scene_to_file(proxima_cena)
