extends Area3D
var jogador: CharacterBody3D = null
var pode_pegar: bool = true

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

	if not pode_pegar:
		return

	pode_pegar = false

	var porta = get_tree().get_first_node_in_group("porta_frente")

	if porta != null:
		porta.chave_do_olho_pegada = true

	var chave = get_parent()

	if chave is Sprite3D:
		chave.visible = false
