extends PracticeTester

const TEST_DAMAGE_SMALL = 10
const TEST_DAMAGE_LARGE = 30

var first_node: Node2D


# Saves how much damage the character takes at a given level.
class DamageTaken:
	var amount_small := 0.0
	var amount_large := 0.0


var level_to_damage_taken: Dictionary[int, DamageTaken] = {
	2: DamageTaken.new(),
	3: DamageTaken.new(),
	4: DamageTaken.new(),
}


func _prepare():
	first_node = _scene_root_viewport.get_child(0)

	for level in [2, 3, 4]:
		var level_record: DamageTaken = level_to_damage_taken[level]
		first_node.level = level

		first_node.health = 100
		var health_before = first_node.health
		first_node.take_damage(TEST_DAMAGE_SMALL)
		level_record.amount_small = health_before - first_node.health

		first_node.health = 100
		health_before = first_node.health
		first_node.take_damage(TEST_DAMAGE_LARGE)
		level_record.amount_large = health_before - first_node.health


func _define(checks: Array[Check]) -> void:
	checks.append(
		Check.new(tr("Damage Amount Is Correct Value"), tr(""), test_damage_amount_is_correct_value)
	)


func test_damage_amount_is_correct_value() -> String:
	var total_damage_taken := 0.0
	for current_level: int in level_to_damage_taken.keys():
		var level_record: DamageTaken = level_to_damage_taken[current_level]
		total_damage_taken += level_record.amount_small + level_record.amount_large

	if total_damage_taken == 0:
		return tr(
			"The character's health never changes when taking damage. Did you forget to subtract the damage amount from the health variable?"
		)

	var took_half_damage_above_level_2 := true
	for current_level: int in level_to_damage_taken.keys():
		if current_level < 3:
			continue

		var level_record: DamageTaken = level_to_damage_taken[current_level]
		if (
			level_record.amount_small != TEST_DAMAGE_SMALL / 2.0
			or level_record.amount_large != TEST_DAMAGE_LARGE / 2.0
		):
			took_half_damage_above_level_2 = false
	if not took_half_damage_above_level_2:
		return tr(
			"The character did not take half damage despite being above level 2. Did you multiply the amount by 0.5 to reduce it?"
		)

	var damage_taken_at_level_2: DamageTaken = level_to_damage_taken[2]
	if (
		damage_taken_at_level_2.amount_small != TEST_DAMAGE_SMALL
		or damage_taken_at_level_2.amount_large != TEST_DAMAGE_LARGE
	):
		if damage_taken_at_level_2.amount_small + damage_taken_at_level_2.amount_large > 0:
			return tr(
				"The character is not taking full damage when their level is less than 3. Did you use a condition to reduce damage only when the level is greater or equal to 3?"
			)
		else:
			return tr(
				"The character is taking 0 damage when its level is less than 3. Did you subtract the amount to health when the level is less than 3?"
			)
	return ""
