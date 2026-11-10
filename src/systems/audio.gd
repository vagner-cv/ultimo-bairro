extends Node

var sounds: Dictionary = {}
var pool: Array[AudioStreamPlayer] = []
var cursor: int = 0
var wind: AudioStreamPlayer
var volume: float = .7
var muted: bool = false

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for key in ["shot", "impact", "door", "step", "hurt"]:
		sounds[key] = load("res://art/%s.wav" % key)
	for i in range(12):
		var channel := AudioStreamPlayer.new()
		add_child(channel)
		pool.append(channel)
	wind = AudioStreamPlayer.new()
	wind.stream = load("res://art/wind.wav")
	wind.volume_db = -4
	add_child(wind)
	wind.finished.connect(wind.play)
	wind.play()
	set_volume(volume)

func play(key: String, gain: float = 0.0) -> void:
	if not sounds.has(key) or pool.is_empty():
		return
	var channel := pool[cursor % pool.size()]
	cursor += 1
	channel.stream = sounds[key]
	channel.volume_db = gain
	channel.pitch_scale = randf_range(.94, 1.06)
	channel.play()

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, .001)))

func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)

func shutdown() -> void:
	for channel in pool:
		channel.stop()
		channel.stream = null
	if is_instance_valid(wind):
		wind.stop()
		wind.stream = null
	sounds.clear()

func _exit_tree() -> void:
	shutdown()
