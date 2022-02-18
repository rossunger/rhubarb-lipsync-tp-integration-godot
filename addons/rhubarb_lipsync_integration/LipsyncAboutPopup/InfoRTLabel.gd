@tool
extends RichTextLabel

func _ready() -> void:
	connect( "meta_clicked", _on_meta_clicked)

func _on_meta_clicked(meta :String):
	OS.shell_open(meta)

