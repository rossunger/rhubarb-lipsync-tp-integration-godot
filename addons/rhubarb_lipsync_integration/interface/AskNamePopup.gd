@tool
extends Popup

signal name_settled

var new_name :String= ""

@onready var titlebar :HBoxContainer= $Panel/VBox/Titlebar
@onready var label :Label= $Panel/VBox/Label
var parent :Node
var lineEdit :LineEdit
var button :Button

func _ready() -> void:
	popup_centered($Panel.rect_min_size)
	button = $Panel/VBox/Button
	lineEdit = $Panel/VBox/LineEdit

	if !button.is_connected("pressed", _on_Button_pressed):
		button.connect("pressed", _on_Button_pressed)
	if !lineEdit.is_connected("text_entered", _on_LineEdit_entered):
		lineEdit.connect("text_entered", _on_LineEdit_entered)
	
	lineEdit.grab_focus()
	
func _on_Button_pressed() -> void:
	lineEdit = $Panel/VBox/LineEdit
	
	new_name = lineEdit.text
	emit_signal("name_settled")

func _on_LineEdit_entered(new_text :String) -> void:
	new_name = new_text
	emit_signal("name_settled")
	
