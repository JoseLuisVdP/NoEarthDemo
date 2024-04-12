extends Node

var SKY_COLOUR_PARAMS = {
	"sky_colour": Color(0, 0, 0),
	"horizon_colour": Color(0, 0, 0),
	"ground_colour": Color(0, 0, 0),
	"cloud_brightness": 0.0
}

var SEASON_PARAMS = {
	"duration_in_days": 0.0,
	"sky_colour_daytime": SKY_COLOUR_PARAMS,
	"sky_colour_night": SKY_COLOUR_PARAMS,
	"day_night_cycle_curve": Curve.new()
}

var WEATHER_PARAMS = {
	"cloud_speed": 0.0,
	"small_cloud_cover": 0.0,
	"large_cloud_cover": 0.0,
	"cloud_inner_colour": Color(0, 0, 0),
	"cloud_outer_colour": Color(0, 0, 0),
	"fog_density": 0.0,
	"particle_amount_ratio": 0.0
}

@export var world_environment : WorldEnvironment
@export var directional_light : DirectionalLight3D
@export var seasons : Array[SeasonResource]
@export var day_duration : float = 86400.0
@export var time_speed_multiplier : float = 100.0
@export var start_time : float = 40000.0
@export var start_season : int = 0
@export var start_weather : int = 0

signal on_season_change
signal on_weather_change

var time_of_day = 0.0
var current_season_index = 0
var current_weather_index = 0
var next_weather_index = 0
var current_weather_length = 0.0
var current_weather_time = 0.0
var current_season_length = 0.0
var current_season_time = 0.0
var particle_system : GPUParticles3D

func set_season(season_index, weather_index = -1):
	if seasons.size() == 0:
		return
	
	current_season_index = season_index
	current_season_length = seasons[season_index].duration_in_days * day_duration
	current_season_time = 0.0
	
	if weather_index != -1:
		set_weather(weather_index)
	else:
		set_random_weather()
	
	emit_signal("on_season_change", seasons[current_season_index])

func set_random_weather():
	var season = seasons[current_season_index]
	var total = 0.0
	for weather in season.weathers:
		total += weather.probability_ratio
	var rand = randf() * total
	total = 0.0
	var weather_index = 0
	for weather in season.weathers:
		total += weather.probability_ratio
		if rand <= total:
			break
		weather_index += 1
	set_weather(weather_index)

func set_weather(weather_index):
	if seasons.size() == 0:
		return
	
	var season = seasons[current_season_index]
	if season.weathers.size() == 0:
		return
	
	current_weather_index = weather_index
	next_weather_index = randi() % season.weathers.size()
	var weather = season.weathers[current_weather_index].weather
	current_weather_length = lerp(weather.min_duration, weather.max_duration, randf())
	current_weather_time = 0.0
	
	if particle_system != null:
		remove_child(particle_system)
		particle_system = null
	
	if weather.precipitation != null and weather.precipitation.particles != null:
		particle_system = weather.precipitation.particles.instance()
		add_child(particle_system)

func _ready():
	if world_environment == null:
		printerr("WeatherController.world_environment is null! Please assign it.")
	if directional_light == null:
		printerr("WeatherController.directional_light is null! Please assign it.")
	
	set_season(start_season, start_weather)
	current_season_time += start_time
	time_of_day += start_time

func _process(delta):
	if world_environment == null:
		return

	if seasons.size() == 0:
		return

	time_of_day = fmod(time_of_day + delta * time_speed_multiplier, day_duration)
	current_weather_time += delta * time_speed_multiplier
	current_season_time += delta * time_speed_multiplier

	if current_weather_time >= current_weather_length:
		set_weather(next_weather_index)
	
	var season = seasons[current_season_index]
	var next_season = seasons[(current_season_index + 1) % seasons.size()]
	if season.weathers.size() == 0:
		return
	
	if current_season_time >= current_season_length:
		set_season((current_season_index + 1) % seasons.size())

	var season_params = interpolate_seasons(season, next_season, current_season_time / current_season_length)
	var weather_params = interpolate_weathers(season.weathers[current_weather_index].weather, season.weathers[next_weather_index].weather, current_weather_time / current_weather_length)

	var t_time_of_day = time_of_day / day_duration
	t_time_of_day = clamp(1.0 - season_params.day_night_cycle_curve.interpolate(t_time_of_day), 0.0, 1.0)
	
	var sky_material = world_environment.environment.sky.sky_material as ShaderMaterial
	sky_material.set_shader_param("small_cloud_cover", weather_params.small_cloud_cover)
	sky_material.set_shader_param("large_cloud_cover", weather_params.large_cloud_cover)
	sky_material.set_shader_param("cloud_speed", weather_params.cloud_speed)
	sky_material.set_shader_param("cloud_shape_change_speed", weather_params.cloud_speed)
	sky_material.set_shader_param("cloud_inner_colour", weather_params.cloud_inner_colour)
	sky_material.set_shader_param("cloud_outer_colour", weather_params.cloud_outer_colour)
	sky_material.set_shader_param("sky_top_color", interpolate_color(season_params.sky_colour_daytime.sky_colour, season_params.sky_colour_night.sky_colour, t_time_of_day))
	sky_material.set_shader_param("sky_horizon_color", interpolate_color(season_params.sky_colour_daytime.horizon_colour, season_params.sky_colour_night.horizon_colour, t_time_of_day))
	sky_material.set_shader_param("ground_horizon_color", interpolate_color(season_params.sky_colour_daytime.horizon_colour, season_params.sky_colour_night.horizon_colour, t_time_of_day))
	sky_material.set_shader_param("ground_bottom_color", interpolate_color(season_params.sky_colour_daytime.ground_colour, season_params.sky_colour_night.ground_colour, t_time_of_day))

	world_environment.environment.volumetric_fog_enabled = true
	world_environment.environment.volumetric_fog_density = weather_params.fog_density

	if particle_system != null:
		particle_system.amount_ratio = weather_params.particle_amount_ratio
		particle_system.transparency = sqrt(sqrt(sqrt(t_time_of_day)))
		particle_system.global_transform.origin = get_viewport().get_camera().global_transform.origin + Vector3.UP * 10.0

	if directional_light != null:
		var t_sun_angle = time_of_day / day_duration
		directional_light.global_rotation = Vector3(2.0 * PI * t_sun_angle + PI * 0.5, 0.0, 0.0)
		directional_light.light_energy = 1.0 - t_time_of_day
	
	world_environment.environment.ambient_light_sky_contribution = t_time_of_day

func interpolate_seasons(season_a, season_b, t):
	var season_params = {}
	season_params.sky_colour_daytime.sky_colour = interpolate_color(season_a.sky_colour_daytime.sky_colour, season_b.sky_colour_daytime.sky_colour, t)
	season_params.sky_colour_daytime.horizon_colour = interpolate_color(season_a.sky_colour_daytime.horizon_colour, season_b.sky_colour_daytime.horizon_colour, t)
	season_params.sky_colour_daytime.ground_colour = interpolate_color(season_a.sky_colour_daytime.ground_colour, season_b.sky_colour_daytime.ground_colour, t)
	season_params.sky_colour_daytime.cloud_brightness = lerp(season_a.sky_colour_daytime.cloud_brightness, season_b.sky_colour_daytime.cloud_brightness, t)
	season_params.sky_colour_night.sky_colour = interpolate_color(season_a.sky_colour_night.sky_colour, season_b.sky_colour_night.sky_colour, t)
	season_params.sky_colour_night.horizon_colour = interpolate_color(season_a.sky_colour_night.horizon_colour, season_b.sky_colour_night.horizon_colour, t)
	season_params.sky_colour_night.ground_colour = interpolate_color(season_a.sky_colour_night.ground_colour, season_b.sky_colour_night.ground_colour, t)
	season_params.sky_colour_night.cloud_brightness = lerp(season_a.sky_colour_night.cloud_brightness, season_b.sky_colour_night.cloud_brightness, t)
	season_params.duration_in_days = lerp(season_a.duration_in_days, season_b.duration_in_days, t)
	season_params.day_night_cycle_curve = season_a.day_night_cycle_curve # TODO: Interpolate curves?
	return season_params

func interpolate_weathers(weather_a, weather_b, t):
	var weather_params = {}
	weather_params.fog_density = lerp(weather_a.fog_density, weather_b.fog_density, t)
	weather_params.cloud_speed = lerp(weather_a.cloud_speed, weather_b.cloud_speed, t)
	weather_params.small_cloud_cover = lerp(weather_a.small_cloud_cover, weather_b.small_cloud_cover, t)
	weather_params.large_cloud_cover = lerp(weather_a.large_cloud_cover, weather_b.large_cloud_cover, t)
	weather_params.cloud_inner_colour = weather_a.cloud_inner_colour.linear_interpolate(weather_b.cloud_inner_colour, t)
	weather_params.cloud_outer_colour = weather_a.cloud_outer_colour.linear_interpolate(weather_b.cloud_outer_colour, t)
	weather_params.cloud_speed = lerp(weather_a.cloud_speed, weather_b.cloud_speed, t)
	weather_params.particle_amount_ratio = lerp(weather_a.precipitation.amount_ratio if weather_a.precipitation != null else 0.0, weather_b.precipitation.amount_ratio if weather_b.precipitation != null else 0.0, t)
	return weather_params

func interpolate_color(color_a, color_b, t):
	return Color(
		lerp(color_a.r, color_b.r, t),
		lerp(color_a.g, color_b.g, t),
		lerp(color_a.b, color_b.b, t),
		lerp(color_a.a, color_b.a, t)
	)
