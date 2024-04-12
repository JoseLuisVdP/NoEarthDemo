extends Resource

# Minimum duration, in seconds
@export var min_duration: float = 40000.0
# Maximum duration, in seconds
@export var max_duration: float = 100000.0
# How fast the clouds move
@export var cloud_speed: float = 0.001
# Small cloud cover (0.0 - 1.0)
@export var small_cloud_cover: float = 0.5
# Large cloud cover (0.0 - 1.0)
@export var large_cloud_cover: float = 0.5
# Inner color of clouds
@export var cloud_inner_color: Color = Color(1.0, 1.0, 1.0)
# Outer color of clouds
@export var cloud_outer_color: Color = Color(0.5, 0.5, 0.5)
# Precipitation resource
@export var precipitation : PrecipitationResource
# Density of fog
@export var fog_density: float = 0.0
