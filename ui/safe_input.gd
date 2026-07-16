extends RefCounted
## Helper: set_input_as_handled an toàn (tránh crash khi viewport null).


static func mark_handled(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not node.is_inside_tree():
		return
	var vp = node.get_viewport()
	if vp != null:
		vp.set_input_as_handled()
