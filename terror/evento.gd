extends Area3D

@export var evento: Node3D

var ativado: bool = false

func _ready() -> void:
	body_entered.connect(_ao_entrar)

func _ao_entrar(body: Node3D) -> void:

	if ativado:
		return

	if not body.is_in_group("player"):
		return

	if evento == null:
		return

	ativado = true

	var tipo: int = randi_range(0, 1)


	if evento.has_method("ativar_evento"):
		evento.ativar_evento(tipo)
