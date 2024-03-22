extends Label

@onready var args : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#MONITOR VALUES
	var text : String = str("")
	
	for key in args.keys():
		var arg = args[key]
		text += str(key) + " : " + str(arg) + "\n"
	
	self.text = text
