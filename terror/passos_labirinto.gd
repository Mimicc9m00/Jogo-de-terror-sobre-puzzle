extends Area3D

func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

func _ao_entrar(body: Node3D) -> void:

	if not body.is_in_group("player"):
		return

	if body.has_method("entrar_area_labirinto"):
		body.entrar_area_labirinto()

func _ao_sair(body: Node3D) -> void:

	if not body.is_in_group("player"):
		return

	if body.has_method("sair_area_labirinto"):
		body.sair_area_labirinto()
