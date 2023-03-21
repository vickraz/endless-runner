extends Node2D

class_name GroundPart


onready var edge = $Edge
onready var startEdge = $StartEdge

const PATH = "res://Scenes/GroundParts/"

var player: Player

func _ready() -> void:
	player = get_parent().get_parent().get_node("Player")

func _process(delta: float) -> void:
	if player:
		if edge.global_position.x < player.global_position.x - 500:
			queue_free()

