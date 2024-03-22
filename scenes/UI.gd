extends CanvasLayer

@onready var _inventory = %Inventory
@onready var _pickable_items = %PickableItems
@onready var _player:Player = $"../3D/Player"
@onready var _crafting = %Crafting

@export var _all_recipes_rg:ResourceGroup
var _all_recipes : Array[Recipe] = []

func _ready():
	_all_recipes_rg.load_all_into(_all_recipes)

func _on_player_can_pickup_item(item):
	_pickable_items.draw_player_pickable_items(item)

func _on_player_can_not_pickup_item(item):
	_pickable_items.remove_player_pickable_items(item)

func inventory(player_inventory:Inventory) -> void:
	if _crafting.is_visible_in_tree():
		_crafting.close()
		_inventory.open(player_inventory)
	elif _inventory.is_visible_in_tree():
		_inventory.close()
	else:
		_inventory.open(player_inventory);

func _on_inventory_open_crafting():
	_inventory.hide()
	_crafting.open(_all_recipes, _player.inventory)
