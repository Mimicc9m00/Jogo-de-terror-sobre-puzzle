extends Node3D

@export_group("Configuração")
@export var tempo_visivel: float = 2.0
@export var distancia_som: float = 10.0

@onready var som_passos: AudioStreamPlayer3D = $SomPassos
@onready var som_folhas: AudioStreamPlayer3D = $SomFolhas

var acontecendo: bool = false

func ativar_evento(tipo: int) -> void:

	if acontecendo:
		return

	acontecendo = true
	match tipo:
		0:
			await evento_passos()
		1:
			await evento_folhas()
	acontecendo = false

func evento_passos() -> void:

	if som_passos == null:
		return
	som_passos.play()

	await get_tree().create_timer(
		3.0
	).timeout

func evento_folhas() -> void:

	if som_folhas == null:
		return

	som_folhas.play()

	await get_tree().create_timer(
		2.0
	).timeout
