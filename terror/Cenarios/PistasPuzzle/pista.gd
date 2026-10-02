extends Area3D

@export_multiline var texto_pista: String = "Digite aqui a pista."

var jogador: CharacterBody3D = null
var mostrando_pista: bool = false

var painel: Panel
var texto_label: RichTextLabel


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

	_criar_interface()


func _ao_entrar(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	jogador = body as CharacterBody3D


func _ao_sair(body: Node3D) -> void:
	if body != jogador:
		return

	jogador = null

	if mostrando_pista:
		_fechar_pista()


func _unhandled_input(event: InputEvent) -> void:
	if jogador == null:
		return

	if not event.is_action_pressed("interagir"):
		return

	if mostrando_pista:
		_fechar_pista()
	else:
		_mostrar_pista()


func _criar_interface() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "InterfacePista"
	add_child(canvas)

	painel = Panel.new()
	painel.name = "Painel"
	painel.set_anchors_preset(Control.PRESET_CENTER)
	painel.position = Vector2(-350, -150)
	painel.size = Vector2(700, 300)
	painel.visible = false
	canvas.add_child(painel)

	texto_label = RichTextLabel.new()
	texto_label.name = "Texto"
	texto_label.position = Vector2(35, 30)
	texto_label.size = Vector2(630, 220)
	texto_label.bbcode_enabled = true
	texto_label.fit_content = false
	texto_label.scroll_active = false
	texto_label.add_theme_font_size_override("normal_font_size", 24)

	painel.add_child(texto_label)


func _mostrar_pista() -> void:
	if jogador == null:
		return

	mostrando_pista = true

	texto_label.text = texto_pista
	painel.visible = true

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _fechar_pista() -> void:
	mostrando_pista = false
	painel.visible = false

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
