extends Node3D

@export var item:Item

func _ready():
	var instance = item.scene.instantiate()
	add_child(instance)
