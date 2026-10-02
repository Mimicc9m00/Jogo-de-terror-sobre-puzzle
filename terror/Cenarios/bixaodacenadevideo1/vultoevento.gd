extends Node3D

@export var tempo_visivel: float = 0.5

@onready var vulto: Node3D = $Vulto
@onready var som_susto: AudioStreamPlayer3D = $SomSusto

var acontecendo: bool = false


func _ready() -> void:
	vulto.visible = false

func ativar_evento() -> void:

	if acontecendo:
		return

	acontecendo = true

	vulto.visible = true

	if som_susto != null:
		som_susto.play()

	await get_tree().create_timer(tempo_visivel).timeout

	vulto.visible = false

	acontecendo = false
