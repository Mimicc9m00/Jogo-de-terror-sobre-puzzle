extends CharacterBody3D

@export_group("Movimento")
@export var velocidade_perseguicao: float = 3.8
@export var velocidade_patrulha: float = 1.8
@export var distancia_deteccao: float = 15.0

@export_group("Ataque")
@export var distancia_ataque: float = 1.6
@export var tempo_ataque: float = 1.2

@export_group("Morte")
@export_file("*.tscn") var cena_apos_morte: String = "res://game_over.tscn"

@export_group("Pulo")
@export var forca_do_pulo: float = 5.5
@export var gravidade: float = 14.0
@export var distancia_verificacao: float = 1.4
@export var altura_maxima_obstaculo: float = 1.0

@export_group("Desvio")
@export var distancia_desvio: float = 1.5
@export var raio_seguranca: float = 0.65

@export_group("Patrulha")
@export var tempo_minimo_parado: float = 3.0
@export var tempo_maximo_parado: float = 7.0
@export var tempo_minimo_andando: float = 2.0
@export var tempo_maximo_andando: float = 5.0

@export_group("Armário")
@export var tempo_afastamento_armario: float = 4.0
@export var velocidade_afastamento_armario: float = 2.5

@export_group("Sons")
@export var intervalo_minimo_passos: float = 0.32
@export var intervalo_maximo_passos: float = 0.48

@export var intervalo_minimo_grunhido: float = 2.5
@export var intervalo_maximo_grunhido: float = 5.0

@export var pitch_minimo_grunhido: float = 0.82
@export var pitch_maximo_grunhido: float = 1.12

@export var pitch_minimo_passos: float = 0.92
@export var pitch_maximo_passos: float = 1.06

@onready var animation_player: AnimationPlayer = $MonsterPSX/AnimationPlayer
@onready var area: Area3D = $visao

@onready var som_passos: AudioStreamPlayer3D = $SomPassos
@onready var som_grunhido: AudioStreamPlayer3D = $SomGrunhido
@onready var som_ataque: AudioStreamPlayer3D = $SomAtaque

var jogador: CharacterBody3D = null

var perseguindo: bool = false
var atacando: bool = false

var patrulhando: bool = false
var esperando: bool = true

var direcao_patrulha: Vector3 = Vector3.ZERO

var tempo_patrulha: float = 0.0
var tempo_preso: float = 0.0

var fugindo_do_armario: bool = false
var tempo_fugindo: float = 0.0
var direcao_fuga: Vector3 = Vector3.ZERO

var tempo_proximo_passo: float = 0.0
var tempo_proximo_grunhido: float = 0.0

var som_movimento_ativo: bool = false

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

	var jogadores = get_tree().get_nodes_in_group("player")

	if jogadores.size() > 0:
		jogador = jogadores[0] as CharacterBody3D

	area.body_entered.connect(_ao_jogador_entrar)
	area.body_exited.connect(_ao_jogador_sair)
	_preparar_animacoes()
	começar_espera()
	_reiniciar_timer_grunhido()

func _preparar_animacoes() -> void:

	var animacoes = [
		"MonsterPSX_Rig|Idle_Watchful",
		"MonsterPSX_Rig|Walk_Nervous",
		"MonsterPSX_Rig|Run_Frantic"
	]
	for nome in animacoes:
		if animation_player.has_animation(nome):
			var animacao = animation_player.get_animation(nome)
			if animacao:
				animacao.loop_mode = Animation.LOOP_LINEAR


func _tocar_animacao(nome: String) -> void:

	if animation_player == null:
		return

	if not animation_player.has_animation(nome):
		return

	if animation_player.current_animation != nome:
		animation_player.play(nome, 0.2)


func _physics_process(delta: float) -> void:

	if not is_on_floor():

		velocity.y -= gravidade * delta

	else:

		if velocity.y < 0.0:
			velocity.y = 0.0


	_atualizar_perseguicao()

	if atacando:

		velocity.x = 0.0
		velocity.z = 0.0

		_parar_passos()

		_parar_grunhido_se_necessario()

		olhar_para_jogador()

		move_and_slide()

		return

	if fugindo_do_armario:

		_processar_fuga_armario(delta)

		move_and_slide()

		_atualizar_som_movimento(delta)

		return

	if perseguindo and jogador != null:

		_processar_perseguicao()

	else:

		_processar_patrulha(delta)

	move_and_slide()
	_atualizar_som_movimento(delta)
	_atualizar_grunhido(delta)

	_verificar_se_ficou_preso(delta)

func _atualizar_perseguicao() -> void:

	if jogador == null:
		return

	if jogador.escondido:

		_iniciar_fuga_do_armario()

		return

	var distancia = global_position.distance_to(jogador.global_position)

	if distancia <= distancia_deteccao:

		perseguindo = true

	else:

		perseguindo = false

func _processar_perseguicao() -> void:

	if jogador == null:
		return

	var distancia = global_position.distance_to(jogador.global_position)
	
	if distancia <= distancia_ataque:

		velocity.x = 0.0
		velocity.z = 0.0

		olhar_para_jogador()

		_iniciar_ataque()

		return

	var direcao = jogador.global_position - global_position

	direcao.y = 0.0

	if direcao.length() < 0.1:

		velocity.x = 0.0
		velocity.z = 0.0

		_tocar_animacao("MonsterPSX_Rig|Idle_Watchful")

		return

	direcao = direcao.normalized()

	var direcao_final = encontrar_melhor_direcao(direcao)

	velocity.x = direcao_final.x * velocidade_perseguicao
	velocity.z = direcao_final.z * velocidade_perseguicao


	olhar_para(direcao_final)

	_tocar_animacao("MonsterPSX_Rig|Run_Frantic")

func encontrar_melhor_direcao(direcao_objetivo: Vector3) -> Vector3:

	direcao_objetivo.y = 0.0

	if direcao_objetivo.length() < 0.01:
		return Vector3.ZERO

	direcao_objetivo = direcao_objetivo.normalized()

	var resultado_direto = verificar_direcao(direcao_objetivo)

	if resultado_direto == 0:

		return direcao_objetivo

	if resultado_direto == 1:
		
		if is_on_floor():
			velocity.y = forca_do_pulo

		return direcao_objetivo

	var angulos = [
		-20.0, 20.0,
		-35.0, 35.0,
		-50.0, 50.0,
		-70.0, 70.0,
		-90.0, 90.0,
		-110.0, 110.0,
		-135.0, 135.0,
		-160.0, 160.0,
		180.0
	]

	var melhor_direcao = Vector3.ZERO
	var melhor_pontuacao = -999999.0

	for graus in angulos:

		var rotacao = deg_to_rad(graus)

		var direcao_testada = direcao_objetivo.rotated(
			Vector3.UP,
			rotacao
		).normalized()

		var tipo_obstaculo = verificar_direcao(direcao_testada)

		if tipo_obstaculo == 2:
			continue

		if tipo_obstaculo == 1:
			continue

		var pontuacao = direcao_testada.dot(direcao_objetivo)

		pontuacao += rng.randf_range(0.0, 0.05)

		if pontuacao > melhor_pontuacao:

			melhor_pontuacao = pontuacao

			melhor_direcao = direcao_testada

	if melhor_direcao != Vector3.ZERO:

		return melhor_direcao

	var recuo = -direcao_objetivo

	if verificar_direcao(recuo) == 0:

		return recuo

	return Vector3(
		-direcao_objetivo.z,
		0.0,
		direcao_objetivo.x
	).normalized()

func verificar_direcao(direcao: Vector3) -> int:

	if direcao.length() < 0.01:
		return 2

	direcao = direcao.normalized()

	var inicio_baixo = global_position + Vector3.UP * 0.35

	var fim_baixo = inicio_baixo + direcao * distancia_verificacao

	var query_baixo = PhysicsRayQueryParameters3D.create(
		inicio_baixo,
		fim_baixo
	)

	query_baixo.exclude = [self]

	if jogador != null:
		query_baixo.exclude.append(jogador)

	var resultado_baixo = get_world_3d().direct_space_state.intersect_ray(
		query_baixo
	)

	if resultado_baixo.is_empty():

		return 0

	var objeto = resultado_baixo.collider

	if objeto == jogador:
		return 0

	if objeto is Node:

		if objeto.is_in_group("player"):
			return 0

	var inicio_alto = global_position + Vector3.UP * 1.5

	var fim_alto = inicio_alto + direcao * distancia_verificacao

	var query_alto = PhysicsRayQueryParameters3D.create(
		inicio_alto,
		fim_alto
	)

	query_alto.exclude = [self]

	if jogador != null:
		query_alto.exclude.append(jogador)

	var resultado_alto = get_world_3d().direct_space_state.intersect_ray(
		query_alto
	)

	if not resultado_alto.is_empty():

		var objeto_alto = resultado_alto.collider

		if objeto_alto == jogador:
			return 0

		if objeto_alto is Node:

			if objeto_alto.is_in_group("player"):
				return 0

		return 2

	return 1

func _processar_patrulha(delta: float) -> void:

	tempo_patrulha -= delta

	if esperando:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			0.5
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			0.5
		)

		_tocar_animacao(
			"MonsterPSX_Rig|Idle_Watchful"
		)

		return

	if patrulhando:

		var direcao = encontrar_melhor_direcao(
			direcao_patrulha
		)

		if direcao.length() > 0.01:

			direcao_patrulha = direcao

		velocity.x = direcao_patrulha.x * velocidade_patrulha

		velocity.z = direcao_patrulha.z * velocidade_patrulha

		olhar_para(direcao_patrulha)

		_tocar_animacao(
			"MonsterPSX_Rig|Walk_Nervous"
		)

		if tempo_patrulha <= 0.0:

			começar_espera()

func começar_patrulha() -> void:

	esperando = false

	patrulhando = true

	tempo_patrulha = rng.randf_range(
		tempo_minimo_andando,
		tempo_maximo_andando
	)

	var angulo = rng.randf_range(
		0.0,
		TAU
	)

	direcao_patrulha = Vector3(
		cos(angulo),
		0.0,
		sin(angulo)
	).normalized()

func começar_espera() -> void:

	esperando = true

	patrulhando = false

	tempo_patrulha = rng.randf_range(
		tempo_minimo_parado,
		tempo_maximo_parado
	)

	velocity.x = 0.0
	velocity.z = 0.0


	_tocar_animacao(
		"MonsterPSX_Rig|Idle_Watchful"
	)

func _iniciar_fuga_do_armario() -> void:

	if fugindo_do_armario:
		return

	fugindo_do_armario = true

	perseguindo = false

	patrulhando = false

	esperando = false

	tempo_fugindo = tempo_afastamento_armario

	if jogador != null:

		var direcao = global_position - jogador.global_position

		direcao.y = 0.0

		if direcao.length() > 0.1:

			direcao_fuga = direcao.normalized()

		else:

			var angulo = rng.randf_range(
				0.0,
				TAU
			)
			direcao_fuga = Vector3(
				cos(angulo),
				0.0,
				sin(angulo)
			).normalized()

	else:

		var angulo = rng.randf_range(
			0.0,
			TAU
		)

		direcao_fuga = Vector3(
			cos(angulo),
			0.0,
			sin(angulo)
		).normalized()


	_tocar_animacao(
		"MonsterPSX_Rig|Walk_Nervous"
	)

func _processar_fuga_armario(delta: float) -> void:

	tempo_fugindo -= delta

	var direcao = encontrar_direcao_de_fuga(
		direcao_fuga
	)

	if direcao.length() > 0.01:

		direcao_fuga = direcao

	velocity.x = direcao_fuga.x * velocidade_afastamento_armario

	velocity.z = direcao_fuga.z * velocidade_afastamento_armario

	olhar_para(direcao_fuga)

	_tocar_animacao(
		"MonsterPSX_Rig|Walk_Nervous"
	)

	if tempo_fugindo <= 0.0:

		fugindo_do_armario = false

		velocity.x = 0.0
		velocity.z = 0.0

		começar_espera_curta()

func encontrar_direcao_de_fuga(
	direcao_original: Vector3
) -> Vector3:

	direcao_original.y = 0.0

	if direcao_original.length() < 0.01:
		return Vector3.ZERO

	direcao_original = direcao_original.normalized()

	if verificar_direcao(direcao_original) == 0:

		return direcao_original

	var angulos = [
		-30.0, 30.0,
		-60.0, 60.0,
		-90.0, 90.0,
		-120.0, 120.0,
		-150.0, 150.0
	]

	for graus in angulos:

		var direcao = direcao_original.rotated(
			Vector3.UP,
			deg_to_rad(graus)
		).normalized()

		var resultado = verificar_direcao(direcao)

		if resultado == 0:

			return direcao

		if resultado == 1:

			if is_on_floor():
				velocity.y = forca_do_pulo

			return direcao

	return -direcao_original

func _verificar_se_ficou_preso(delta: float) -> void:

	if not perseguindo and not patrulhando:
		return

	var velocidade_horizontal = Vector2(
		velocity.x,
		velocity.z
	).length()

	if velocidade_horizontal < 0.15:

		tempo_preso += delta

	else:

		tempo_preso = 0.0

	if tempo_preso > 0.5:

		tempo_preso = 0.0

		if perseguindo and jogador != null:

			var direcao = jogador.global_position - global_position

			direcao.y = 0.0

			if direcao.length() > 0.1:

				var nova_direcao = encontrar_melhor_direcao(
					direcao.normalized()
				)

				velocity.x = nova_direcao.x * velocidade_perseguicao

				velocity.z = nova_direcao.z * velocidade_perseguicao

		elif patrulhando:

			var angulo = rng.randf_range(
				0.0,
				TAU
			)

			direcao_patrulha = Vector3(
				cos(angulo),
				0.0,
				sin(angulo)
			).normalized()

func começar_espera_curta() -> void:

	esperando = true

	patrulhando = false

	tempo_patrulha = rng.randf_range(
		0.4,
		0.9
	)

	_tocar_animacao(
		"MonsterPSX_Rig|Idle_Watchful"
	)

func _iniciar_ataque() -> void:

	if atacando:
		return

	if jogador == null:
		return

	atacando = true

	velocity.x = 0.0
	velocity.z = 0.0

	_parar_passos()

	if som_ataque != null:
		som_ataque.play()

	if jogador.has_method("morrer_para_monstro"):
		jogador.morrer_para_monstro(global_position)

	olhar_para_jogador()

	_tocar_animacao(
		"MonsterPSX_Rig|Attack_Lunge"
	)

	_finalizar_ataque()

func _finalizar_ataque() -> void:

	var duracao_animacao: float = tempo_ataque

	if animation_player.has_animation(
		"MonsterPSX_Rig|Attack_Lunge"
	):

		var animacao = animation_player.get_animation(
			"MonsterPSX_Rig|Attack_Lunge"
		)

		if animacao != null:
			duracao_animacao = animacao.length

	await get_tree().create_timer(
		duracao_animacao
	).timeout

	if cena_apos_morte != "":
		get_tree().change_scene_to_file(
			cena_apos_morte
		)

func _ao_jogador_entrar(body: Node3D) -> void:

	if body.is_in_group("player"):

		jogador = body as CharacterBody3D

		perseguindo = true

func _ao_jogador_sair(body: Node3D) -> void:

	if body == jogador:

		return

func olhar_para(direcao: Vector3) -> void:

	if direcao.length() < 0.01:
		return

	var alvo = global_position + direcao

	look_at(
		Vector3(
			alvo.x,
			global_position.y,
			alvo.z
		),
		Vector3.UP
	)

func olhar_para_jogador() -> void:

	if jogador == null:
		return

	var direcao = jogador.global_position - global_position
	direcao.y = 0.0

	olhar_para(direcao)

func _atualizar_som_movimento(delta: float) -> void:

	var velocidade_horizontal = Vector2(
		velocity.x,
		velocity.z
	).length()

	var andando = (
		is_on_floor()
		and velocidade_horizontal > 0.2
		and not atacando
	)

	if not andando:

		_parar_passos()

		return

	som_movimento_ativo = true

	tempo_proximo_passo -= delta

	if tempo_proximo_passo <= 0.0:

		_tocar_passo()

		tempo_proximo_passo = rng.randf_range(
			intervalo_minimo_passos,
			intervalo_maximo_passos
		)

func _tocar_passo() -> void:

	if som_passos == null:
		return

	som_passos.pitch_scale = rng.randf_range(
		pitch_minimo_passos,
		pitch_maximo_passos
	)

	som_passos.play()

func _parar_passos() -> void:

	if som_passos != null and som_passos.playing:

		som_passos.stop()

	som_movimento_ativo = false

func _atualizar_grunhido(delta: float) -> void:

	if som_grunhido == null:
		return

	if not perseguindo:
		return

	if jogador == null:
		return

	if jogador.escondido:
		return

	tempo_proximo_grunhido -= delta

	if tempo_proximo_grunhido <= 0.0:

		_tocar_grunhido()

		_reiniciar_timer_grunhido()

func _tocar_grunhido() -> void:

	if som_grunhido == null:
		return

	som_grunhido.pitch_scale = rng.randf_range(
		pitch_minimo_grunhido,
		pitch_maximo_grunhido
	)

	som_grunhido.play()

func _reiniciar_timer_grunhido() -> void:

	tempo_proximo_grunhido = rng.randf_range(
		intervalo_minimo_grunhido,
		intervalo_maximo_grunhido
	)

func _parar_grunhido_se_necessario() -> void:

	if som_grunhido != null and som_grunhido.playing:

		som_grunhido.stop()
