extends Node

@export var auto_spawn_server: bool = true
@export var server_args: PackedStringArray = PackedStringArray(["--server"])

func _ready() -> void:
	if OS.get_cmdline_args().has("--server"):
		call_deferred("_load_main_scene")
		return

	if auto_spawn_server:
		var args: PackedStringArray = PackedStringArray(["--path", ProjectSettings.globalize_path("res://")])
		args.append_array(server_args)
		OS.create_process(OS.get_executable_path(), args)

	call_deferred("_load_main_scene")

func _load_main_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
