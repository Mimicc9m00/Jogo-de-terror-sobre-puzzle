
extends Area3D

@export_file("*.tscn") var proxima_cena: String = ""

var ativado: bool = false


func _ready() -> void:
	body_entered.connect(_ao_entrar_na_area)


func _ao_entrar_na_area(corpo: Node3D) -> void:
	if ativado:
		return

	if corpo.is_in_group("player"):
		ativado = true

		if proxima_cena.is_empty():
			ativado = false
			return

		var erro: Error = get_tree().change_scene_to_file(proxima_cena)

		if erro != OK:
			ativado = false
