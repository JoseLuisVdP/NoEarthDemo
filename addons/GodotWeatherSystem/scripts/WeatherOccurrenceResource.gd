extends Resource

# Weather occurrence: Basically just warps a WeatherResource, and has a weighted probability ratio of the weather to occur.
class_name WeatherOccurrenceResource

# WeatherResource to be used
@export var weather: WeatherResource

# Weighted probability ratio of the specified weather
# Set to a lower value if you want the weather to occur rarely
@export var probability_ratio: float = 1.0
