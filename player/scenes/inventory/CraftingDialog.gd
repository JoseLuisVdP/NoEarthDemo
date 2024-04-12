extends Control
class_name CraftingDialog

@export var _all_items_rg:ResourceGroup
var _all_items : Array[Item] = []

@onready var recipe_list = %RecipeList
@onready var more_info = %MoreInfo
@onready var inventory_minimized = %InventoryMinimized

@onready var ingredients = %Ingredients
@onready var results = %Results
@onready var btn_craft = %BtnCraft

@onready var more_ingredients = %MoreIngredients
@onready var more_results = %MoreResults

var _inventory : Inventory
var _current_recipe : Recipe

func _ready():
	hide()
	btn_craft.hide()
	_all_items_rg.load_all_into(_all_items)

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
	open_mini_inventory(inventory)

func open_mini_inventory(inventory:Inventory):
	inventory_minimized.display_filled(inventory.get_content(), inventory.get_max_size())
	
func close():
	print("close crafting")
	# Esconde el boton de crafteo hasta que se seleccione un crafteo válido
	btn_craft.hide()
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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
		more_info.open(_all_items)
		%BtnMore.text = "-"

func _on_btn_craft_pressed():
	for i in _current_recipe.ingredients:
		_inventory.remove_item(i)
	for i in _current_recipe.results:
		_inventory.add_item(i)
		inventory_minimized.display_filled(_inventory.get_content(), _inventory.get_max_size())
	
	btn_craft.disabled = not _inventory.has_all(_current_recipe.ingredients)

func on_all_items_item_selected(item:Item):
	#Obtengo array de todas las recetas que contengan como resultado al item escogido
	var recipes : Array[Recipe] = [_current_recipe]

	#Muestro la receta
	more_ingredients.display(recipes[0].ingredients)
	more_results.display(recipes[0].results)
	#Mostrar receta y resultados del item seleccionado
	#A futuro, paginar diferentes crafteos para el mismo item con el addon de paginate tables
