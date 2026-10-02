extends Node3D

@export_file("*.tscn") var proxima_cena: String = "res://Transicoes/transicao_7.tscn"

func _ready() -> void:
	await get_tree().create_timer(10).timeout

	if proxima_cena != "":
		get_tree().change_scene_to_file(proxima_cena)
