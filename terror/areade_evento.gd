extends Node3D


@export_group("Configuração")
@export var tempo_minimo: float = 15.0
@export var tempo_maximo: float = 30.0


@export_group("Eventos")
@export var eventos: Array[Node3D] = []

var esperando: bool = false

func _ready() -> void:

	randomize()

	await get_tree().create_timer(5.0).timeout

	iniciar_eventos()


func iniciar_eventos() -> void:

	if esperando:
		return

	esperando = true


	while true:

		var tempo: float = randf_range(
			tempo_minimo,
			tempo_maximo
		)

		await get_tree().create_timer(
			tempo
		).timeout


		if eventos.is_empty():
			continue


		var evento: Node3D = eventos.pick_random()

		if evento == null:
			continue


		var tipo: int = randi_range(
			0,
			3
		)

		if evento.has_method("ativar_evento"):

			evento.ativar_evento(tipo)
