extends Area3D

@export_file("*.tscn") var proxima_cena: String

var jogador: CharacterBody3D = null
var pode_interagir: bool = true
var chave_do_olho_pegada: bool = false


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

	add_to_group("porta_frente")


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

	if not pode_interagir:
		return

	pode_interagir = false

	if chave_do_olho_pegada:
		abrir_porta()

	pode_interagir = true


func abrir_porta() -> void:
	if proxima_cena == "res://Transicoes/transicao_4.tscn":
		return

	if proxima_cena.is_empty():
		return

	get_tree().change_scene_to_file(proxima_cena)
