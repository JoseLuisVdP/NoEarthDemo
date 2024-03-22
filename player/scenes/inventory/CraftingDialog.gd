extends Control
class_name CraftingDialog

@export var item_slot:PackedScene
@onready var recipe_list = %RecipeList
@onready var more_info = %MoreInfo

@onready var ingredients = $HBoxContainer/CraftingDialog/Margin/VBoxContainer/MarginContainer2/Recipe/Ingredients
@onready var results = $HBoxContainer/CraftingDialog/Margin/VBoxContainer/MarginContainer2/Recipe/Results
@onready var btn_craft = %BtnCraft

var _inventory : Inventory
var _current_recipe : Recipe

func _ready():
	hide()
	btn_craft.hide()

func open(recipes:Array[Recipe], inventory:Inventory):
	_inventory = inventory
	print("open crafting")
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	recipe_list.clear()
	for i in ingredients.get_children(false):
		i.queue_free()
	for i in results.get_children(false):
		i.queue_free()
	for r in recipes:
		var index = recipe_list.add_item(r.name)
		recipe_list.set_item_metadata(index, r)
	
func close():
	print("close crafting")
	btn_craft.hide()
	hide()
	
func _on_recipe_list_item_selected(index):
	_current_recipe = recipe_list.get_item_metadata(index)
	ingredients.display(_current_recipe.ingredients)
	results.display(_current_recipe.results)
	
	btn_craft.show()
	btn_craft.disabled = not _inventory.has_all(_current_recipe.ingredients)

func _on_btn_more_pressed():
	if more_info.is_visible_in_tree():
		more_info.close()
		%BtnMore.text = "+"
	else:
		more_info.open()
		%BtnMore.text = "-"		

func _on_btn_craft_pressed():
	for i in _current_recipe.ingredients:
		_inventory.remove_item(i)
	for i in _current_recipe.results:
		_inventory.add_item(i)
	
	btn_craft.disabled = not _inventory.has_all(_current_recipe.ingredients)
