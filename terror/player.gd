extends CharacterBody3D

@export_group("Stamina")
@export var stamina_maxima: float = 100.0
@export var consumo_stamina: float = 25.0
@export var recuperacao_stamina: float = 15.0

var stamina: float = 100.0
var pode_correr: bool = true

@onready var barra_stamina: ProgressBar = $Stamina/ProgressBar

@export_group("Movimentação")
@export var velocidade: float = 5.0
@export var velocidade_de_corrida: float = 8.0
@export var sensibilidade_do_mouse: float = 0.003

@export_group("Pulo")
@export var forca_do_pulo: float = 5.0

@export_group("Gravidade")
@export var gravidade: float = 9.8

@export_group("Morte")
@export_file("*.tscn") var cena_apos_morte: String = "res://game_over.tscn"

@onready var camera: Camera3D = $Camera3D
@onready var som_passos: AudioStreamPlayer3D = $SomPassos
@onready var som_passos_area: AudioStreamPlayer3D = $SomPassosArea
@onready var som_passos_labirinto: AudioStreamPlayer3D = $SomPassosLabirinto
@onready var som_entrar_armario: AudioStreamPlayer = $SomEntrarArmario
@onready var lanterna: SpotLight3D = $Camera3D/SpotLight3D

var lanterna_ligada: bool = false
var rotacao_camera: float = 0.0

var escondido: bool = false
var morto: bool = false

var dentro_area_passos: bool = false
var dentro_labirinto: bool = false

var camera_posicao_original: Vector3
var camera_rotacao_original: Vector3


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	camera_posicao_original = camera.position
	camera_rotacao_original = camera.rotation

	rotacao_camera = camera_rotacao_original.x

	lanterna.visible = false

	add_to_group("player")

	stamina = stamina_maxima

	barra_stamina.max_value = stamina_maxima
	barra_stamina.value = stamina


func _unhandled_input(event: InputEvent) -> void:
	if morto:
		return

	if escondido:
		if event is InputEventMouseMotion:
			return
		return

	if event is InputEventMouseMotion:
		rotate_y(
			-event.relative.x * sensibilidade_do_mouse
		)

		rotacao_camera -= (
			event.relative.y * sensibilidade_do_mouse
		)

		rotacao_camera = clamp(
			rotacao_camera,
			deg_to_rad(-89.0),
			deg_to_rad(89.0)
		)

		camera.rotation.x = rotacao_camera

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("lanterna"):
		lanterna_ligada = not lanterna_ligada
		lanterna.visible = lanterna_ligada


func _physics_process(delta: float) -> void:
	if morto:
		velocity = Vector3.ZERO
		return

	if escondido:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= gravidade * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	if Input.is_action_just_pressed("pular") and is_on_floor():
		var pulo_atual: float = forca_do_pulo

		if dentro_labirinto:
			pulo_atual = 2.0

		velocity.y = pulo_atual

	var entrada: Vector2 = Input.get_vector(
		"A",
		"D",
		"W",
		"S"
	)

	var direcao: Vector3 = (
		transform.basis
		* Vector3(
			entrada.x,
			0.0,
			entrada.y
		)
	).normalized()

	var velocidade_atual: float = velocidade

	if dentro_labirinto:
		velocidade_atual = 2.0

	var correndo: bool = false

	if Input.is_action_pressed("correr") and pode_correr and direcao.length() > 0.0:
		correndo = true
		velocidade_atual = velocidade_de_corrida

		if dentro_labirinto:
			velocidade_atual = 3.0

	if correndo:
		stamina -= consumo_stamina * delta

		if stamina <= 0.0:
			stamina = 0.0
			pode_correr = false
	else:
		stamina += recuperacao_stamina * delta

		if stamina >= stamina_maxima:
			stamina = stamina_maxima
			pode_correr = true

	barra_stamina.value = stamina

	if direcao:
		velocity.x = direcao.x * velocidade_atual
		velocity.z = direcao.z * velocidade_atual
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			velocidade_atual
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			velocidade_atual
		)

	move_and_slide()

	var esta_andando: bool = (
		is_on_floor()
		and Vector2(
			velocity.x,
			velocity.z
		).length() > 0.2
	)

	if esta_andando:
		if dentro_labirinto:
			if not som_passos_labirinto.playing:
				som_passos_labirinto.play()

			if som_passos.playing:
				som_passos.stop()

			if som_passos_area.playing:
				som_passos_area.stop()

		elif dentro_area_passos:
			if not som_passos_area.playing:
				som_passos_area.play()

			if som_passos.playing:
				som_passos.stop()

			if som_passos_labirinto.playing:
				som_passos_labirinto.stop()

		else:
			if not som_passos.playing:
				som_passos.play()

			if som_passos_area.playing:
				som_passos_area.stop()

			if som_passos_labirinto.playing:
				som_passos_labirinto.stop()

	else:
		if som_passos.playing:
			som_passos.stop()

		if som_passos_area.playing:
			som_passos_area.stop()

		if som_passos_labirinto.playing:
			som_passos_labirinto.stop()


func entrar_no_armario(
	ponto_dentro: Marker3D,
	ponto_camera: Marker3D
) -> void:
	if morto:
		return

	if escondido:
		return

	velocity = Vector3.ZERO
	escondido = true

	if som_passos.playing:
		som_passos.stop()

	if som_passos_area.playing:
		som_passos_area.stop()

	if som_passos_labirinto.playing:
		som_passos_labirinto.stop()

	global_position = ponto_dentro.global_position

	camera.global_position = ponto_camera.global_position
	camera.global_rotation = ponto_camera.global_rotation

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	tocar_som_entrar_armario()


func sair_do_armario(
	ponto_saida: Marker3D
) -> void:
	if morto:
		return

	if not escondido:
		return

	velocity = Vector3.ZERO

	global_position = ponto_saida.global_position

	camera.position = camera_posicao_original
	camera.rotation = camera_rotacao_original

	rotacao_camera = camera_rotacao_original.x

	escondido = false

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func tocar_som_entrar_armario() -> void:
	if som_entrar_armario == null:
		return

	som_entrar_armario.play()


func entrar_area_passos() -> void:
	dentro_area_passos = true


func sair_area_passos() -> void:
	dentro_area_passos = false


func entrar_area_labirinto() -> void:
	dentro_labirinto = true


func sair_area_labirinto() -> void:
	dentro_labirinto = false


func set_escondido(valor: bool) -> void:
	escondido = valor

	if escondido:
		velocity = Vector3.ZERO

		if som_passos.playing:
			som_passos.stop()

		if som_passos_area.playing:
			som_passos_area.stop()

		if som_passos_labirinto.playing:
			som_passos_labirinto.stop()


func morrer_para_monstro(
	posicao_monstro: Vector3
) -> void:
	if morto:
		return

	morto = true
	velocity = Vector3.ZERO

	if som_passos.playing:
		som_passos.stop()

	if som_passos_area.playing:
		som_passos_area.stop()

	if som_passos_labirinto.playing:
		som_passos_labirinto.stop()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var direcao: Vector3 = (
		posicao_monstro - global_position
	)

	direcao.y = 0.0

	if direcao.length() > 0.01:
		camera.look_at(
			posicao_monstro,
			Vector3.UP
		)
