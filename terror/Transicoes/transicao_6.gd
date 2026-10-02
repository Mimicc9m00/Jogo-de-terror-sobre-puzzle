extends Control

@export_file("*.tscn") var proxima_cena: String = "res://ato_final.tscn"

func _ready() -> void:
	await get_tree().create_timer(3).timeout

	if proxima_cena != "":
		get_tree().change_scene_to_file(proxima_cena)
