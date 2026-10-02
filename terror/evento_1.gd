extends Area3D

@export var evento_vulto: Node3D

var ativado: bool = false

func _ready() -> void:
	body_entered.connect(_ao_entrar)

func _ao_entrar(body: Node3D) -> void:

	if ativado:
		return

	if not body.is_in_group("player"):
		return

	if evento_vulto == null:
		return

	ativado = true

	if evento_vulto.has_method("ativar_evento"):
		evento_vulto.ativar_evento()
