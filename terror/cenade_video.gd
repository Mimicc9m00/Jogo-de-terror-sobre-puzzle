extends CharacterBody3D

@export var tempo_rotacao: float = 1.2
@export var atraso_som: float = 0.7
@export_file("*.tscn") var proxima_cena: String = "res://Transicoes/transicao2.tscn"

@onready var camera: Camera3D = $Camera3D
@onready var som_death: AudioStreamPlayer = $SomDeath

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	camera.rotation.x = 0.0

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"rotation:y",
		rotation.y + PI,
		tempo_rotacao
	)

	await get_tree().create_timer(atraso_som).timeout

	if not is_instance_valid(self):
		return

	if som_death.stream != null:
		som_death.play()
	await get_tree().create_timer(0.5).timeout

	if proxima_cena != "":
		get_tree().change_scene_to_file(proxima_cena)
