class_name DynamicActionContext
extends IActionsContext


var _actions: Array[IActionsContext.ActionContext] = []


func add_actions(p_actions: Array[IActionsContext.ActionContext]) -> void:
	_actions.append_array(p_actions)

func get_actions() -> Array[IActionsContext.ActionContext]:
	return _actions
