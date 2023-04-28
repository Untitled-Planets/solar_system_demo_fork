extends Button

var _context: IActionsContext.ActionContext

func set_context(p_context: IActionsContext.ActionContext) -> void:
	_context = p_context
	text = _context.name

#func do_call() -> void:
#	_context.function.call()


func _on_pressed():
	_context.function.call()
