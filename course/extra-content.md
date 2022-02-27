## Lesson 24, extra practice

Title: Concatenating a list of strings with a separator
Description: We want to display a list of character names as a pretty comma-separated line. You'll code a function to turn an array of names into that.

Solution:

```gdscript
func concatenate(strings, separator):
	var result = ""
	for index in range(strings.size() - 1):
		result += strings[index] + separator

	result += strings[-1]
	return result
```

There is a common operation in games: taking a list of strings and turning them into one string with some added separator.

Say you have a list of character names in the game, and you want to present them separated by commas to the player.

You will code a function that does that. The function should take an array containing only strings and a [code]separator[/code], also a text string.

You should use a [code]for[/code] loop over the array sent to the function as it can have varying lengths.

You should add the separator only between 2 elements in the strings list. Be careful, as you don't want to add the separator [i]after the last element[/i].
