class_name GDArrayExpr
extends GDExpr


var _elements: Array[GDExpr]


func _init(elements: Array[GDExpr]) -> void:
	_elements = elements


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.ARRAY:
		return false
	var array_node := node as GDArrayNode
	var elements := array_node.get_elements()
	if elements.size() < _elements.size():
		return false
	for i in _elements.size():
		if not _elements[i].matches(elements[i]):
			return false
	return true
