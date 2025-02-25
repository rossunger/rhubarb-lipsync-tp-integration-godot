@tool
extends HBoxContainer

#AudioTrackHBox

@onready var button :MenuButton= $Button
@onready var popupMenu :PopupMenu
@onready var warningIcon :TextureRect= $WarningIcon

func _ready() -> void:
	popupMenu = button.get_popup()
	if button.last_index == -1:
		enable_warning("No AudioStreamPlayer node selected. Can't proceed")
	
	popupMenu.connect("id_pressed", _on_PopupMenu_item_selected)

func _on_PopupMenu_item_selected(id :int):
	if id != -1:
		disable_warning()

func enable_warning(message :String):
	warningIcon.visible = true
	warningIcon.hint_tooltip = message

func disable_warning():
	warningIcon.visible = false
