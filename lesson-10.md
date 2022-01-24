As we've seen, Godot has functions that do certain actions. For example, the `show()` and `hide()` functions change the visibility of things.

We can also create our own functions to make custom effects like adding or removing health to a character.

Godot also has special functions we can customise or add to.

Take the `_process()` function.

- Show process() code example

The `_process()` function gets its name because it does calculations or continuous actions.

It's like a factory that **processes** food; the food is always moving along a conveyer belt.

- Animation of a conveyer belt

It's similar in Godot, but this function can run **hundreds of times a second**.

- Note: Other game engines might use different names for this like update.

Godot runs this function on its own; we don't have to keep telling Godot to run it.

The `_process()` function won't do anything until we add something to it.

You might notice the underscore in front of the function name. This means the function is built-in to Godot and we can add to it.

Using an underscore in this way is common in lots of languages to show developers they can add to the function.

- example "process" functions in other languages

But how and why is the process useful?

It's perhaps better to see the process function in action. Take the following example.

- Example of a sprite rotating all of the time continuously.

We've added to the character's process function so that it continuously rotate.

In the practice, you'll learn how to use the process function to rotate continuously yourself.