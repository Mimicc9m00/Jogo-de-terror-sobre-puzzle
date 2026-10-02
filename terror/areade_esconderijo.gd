extends Area3D

@onready var ponto_dentro: Marker3D = $dentro
@onready var ponto_camera: Marker3D = $PontoCamera
@onready var ponto_saida: Marker3D = $fora

var jogador_dentro_da_area: CharacterBody3D = null
var jogador_no_armario: CharacterBody3D = null


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func _ao_entrar(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	jogador_dentro_da_area = body as CharacterBody3D


func _ao_sair(body: Node3D) -> void:
	if body != jogador_dentro_da_area:
		return

	if body != jogador_no_armario:
		jogador_dentro_da_area = null


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interagir"):
		return

	if jogador_no_armario != null:
		if jogador_no_armario == jogador_dentro_da_area:
			if jogador_no_armario.has_method("sair_do_armario"):
				jogador_no_armario.sair_do_armario(ponto_saida)
				jogador_no_armario = null
		return

	if jogador_dentro_da_area == null:
		return

	if jogador_dentro_da_area.has_method("entrar_no_armario"):
		jogador_dentro_da_area.entrar_no_armario(
			ponto_dentro,
			ponto_camera
		)

		jogador_no_armario = jogador_dentro_da_area
