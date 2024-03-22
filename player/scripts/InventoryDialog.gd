extends Control
class_name InventoryDialog

@onready var content : ItemsGrid = %Content
signal open_crafting

func _ready():
	hide()

func _on_close_btn_pressed() -> void:
	close()

func close():
	print("close inventory")
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func open(inventory:Inventory) -> void:
	print("open inventory")
	content.display(inventory.get_content())
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_btn_crafting_pressed():
	open_crafting.emit()
