extends Node3D

@export_group("Sequência correta")
@export var sequencia_correta: Array[String] = [
	"olho",
	"estrela",
	"lua",
	"cruz"
]

@export_group("Chaves")
@export var chaves: Node3D

var sequencia_atual: Array[String] = []
var puzzle_concluido: bool = false

func selecionar_quadro(simbolo: String) -> void:
	if puzzle_concluido:
		return

	sequencia_atual.append(simbolo)

	var indice_atual := sequencia_atual.size() - 1

	if sequencia_atual[indice_atual] != sequencia_correta[indice_atual]:
		sequencia_atual.clear()
		return
		
	if sequencia_atual.size() >= sequencia_correta.size():
		_verificar_sequencia()


func _verificar_sequencia() -> void:

	if sequencia_atual == sequencia_correta:
		_concluir_puzzle()
	else:
		sequencia_atual.clear()


func _concluir_puzzle() -> void:
	puzzle_concluido = true

	if chaves == null:
		return

	chaves.visible = true
