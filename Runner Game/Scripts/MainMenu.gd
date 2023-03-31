extends Node2D


onready var levelImage  = $CanvasLayer/Control/LevelImage
onready var levelText = $CanvasLayer/Control/HBoxContainer/Select

#const LEVEL1 = preload("res://Scenes/Level1.tscn")

#const LEVEL1_IMAGE = preload("res:///Assets/LevelImages/Level1.png")
#const LEVEL2_IMAGE = preload("res://Assets/LevelImages/Level2.png")

var level_names = ["snowy mountains", "mystical forest"]

var level_selected = 1


func _ready() -> void:
	levelText.text = level_names[level_selected - 1]



func _on_StartButton_pressed() -> void:
	get_tree().change_scene("res://Scenes/Level" + str(level_selected) + ".tscn")


func _on_LeaderboardButton_pressed() -> void:
	pass # Replace with function body.




func _on_QuitButton_pressed() -> void:
	get_tree().quit()


func _on_LevelImage_pressed() -> void:
	get_tree().change_scene("res://Scenes/Level" + str(level_selected) + ".tscn")


func _on_LevelImage_mouse_entered() -> void:
	levelImage.rect_min_size = Vector2(255, 180)


func _on_LevelImage_mouse_exited() -> void:
	levelImage.rect_min_size = Vector2(250, 175)


func _on_BackButton_pressed() -> void:
	level_selected = max(level_selected - 1, 1)
	levelText.text = level_names[level_selected - 1]
	levelImage.texture_normal = load("res:///Assets/LevelImages/Level" + str(level_selected) + ".png")


func _on_FwdButton_pressed() -> void:
	level_selected = min(level_selected + 1, len(level_names))
	levelText.text = level_names[level_selected - 1]
	levelImage.texture_normal = load("res:///Assets/LevelImages/Level" + str(level_selected) + ".png")
