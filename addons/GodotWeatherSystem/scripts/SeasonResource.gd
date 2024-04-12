extends Resource

class_name SeasonResource

@export var seasonId: String

@export var weathers: Array[WeatherOccurrenceResource] = []

@export var durationInDays: float = 10.0

@export var skyColourDaytime: SkyColourResource

@export var skyColourNight: SkyColourResource

@export var dayNightCycleCurve: Curve
