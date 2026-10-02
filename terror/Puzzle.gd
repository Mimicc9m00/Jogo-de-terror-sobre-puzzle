extends Area3D

@export_enum("olho", "estrela", "lua", "cruz")
var simbolo: String = "olho"

var jogador: CharacterBody3D = null

func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

func _ao_entrar(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	jogador = body as CharacterBody3D

func _ao_sair(body: Node3D) -> void:
	if body == jogador:
		jogador = null

func _unhandled_input(event: InputEvent) -> void:
	if jogador == null:
		return

	if not event.is_action_pressed("interagir"):
		return

	var puzzle = get_tree().get_first_node_in_group("puzzle_quadros")

	if puzzle == null:
		return

	if puzzle.has_method("selecionar_quadro"):
		puzzle.selecionar_quadro(simbolo)
