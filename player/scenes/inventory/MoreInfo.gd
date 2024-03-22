extends Control
class_name MoreInfo

func open():
	show()

func close():
	hide()

func _ready():
	hide()

func _on_btn_close_more_pressed():
	close()
