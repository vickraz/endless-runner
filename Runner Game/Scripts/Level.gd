extends Node2D

class_name LevelScript


onready var player: Player = $Player
onready var camera = $Camera2D
onready var gameOverMenu = $GameOverMenu


func _ready() -> void:
	player.get_node("RemoteTransform2D").remote_path = camera.get_path()
	player.connect("dead", self, "_on_Player_dead")
	player.connect("dead", gameOverMenu, "_on_Player_dead")


func _on_Player_dead(distance) -> void:
	gameOverMenu.visible = true
