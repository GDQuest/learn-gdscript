class_name GDLiteralExpr
extends GDExpr


var _value: Variant
var _any_value := false
var _approx := false


func _init(value: Variant, approx: bool, any_value: bool) -> void:
	_value = value
	_any_value = any_value
	_approx = approx


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.LITERAL:
		return false
	if _any_value:
		return true
	var lit_node := node as GDLiteralNode
	if _approx:
		if _value is float and lit_node.get_value() is float:
			return is_equal_approx(lit_node.value as float, _value as float)
		elif _value is AABB and lit_node.get_value() is AABB:
			return (_value as AABB).is_equal_approx(lit_node.get_value() as AABB)
		elif _value is Basis and lit_node.get_value() is Basis:
			return (_value as Basis).is_equal_approx(lit_node.get_value() as Basis)
		elif _value is Color and lit_node.get_value() is Color:
			return (_value as Color).is_equal_approx(lit_node.get_value() as Color)
		elif _value is Plane and lit_node.get_value() is Plane:
			return (_value as Plane).is_equal_approx(lit_node.get_value() as Plane)
		elif _value is Quaternion and lit_node.get_value() is Quaternion:
			return (_value as Quaternion).is_equal_approx(lit_node.get_value() as Quaternion)
		elif _value is Rect2 and lit_node.get_value() is Rect2:
			return (_value as Rect2).is_equal_approx(lit_node.get_value() as Rect2)
		elif _value is Transform2D and lit_node.get_value() is Transform2D:
			return (_value as Transform2D).is_equal_approx(lit_node.get_value() as Transform2D)
		elif _value is Transform3D and lit_node.get_value() is Transform3D:
			return (_value as Transform3D).is_equal_approx(lit_node.get_value() as Transform3D)
		elif _value is Vector2 and lit_node.get_value() is Vector2:
			return (_value as Vector2).is_equal_approx(lit_node.get_value() as Vector2)
		elif _value is Vector3 and lit_node.get_value() is Vector3:
			return (_value as Vector3).is_equal_approx(lit_node.get_value() as Vector3)
		elif _value is Vector4 and lit_node.get_value() is Vector4:
			return (_value as Vector4).is_equal_approx(lit_node.get_value() as Vector4)
	var value: Variant = lit_node.value
	return value == _value
