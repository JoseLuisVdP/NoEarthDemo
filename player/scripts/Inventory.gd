class_name Inventory

var _content:Array[Item] = []
var _max_size : int = 12

func add_item(item:Item) -> void:
	_content.append(item)

func remove_item(item:Item) -> void:
	_content.erase(item)

func get_content() -> Array[Item]:
	return _content

func has_all(items:Array[Item]) -> bool:
	var needed:Array[Item] = items.duplicate()
	for available in _content:
		needed.erase(available)
	
	return needed.is_empty()

func get_max_size() -> int:
	return _max_size

func set_max_size(size:int) -> void:
	_max_size = size
