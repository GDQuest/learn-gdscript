# Learn GDScript From Zero: Interactive practices docs

This document explains how the interactive practices work in the app and gives some guidelines for maintaining or creating new practices.

We'll start with the technical side and then focus on the content side.

## How practices work

Practices are interactive coding exercises where students write code to solve a specific problem.

Each lesson folder in `course/` contains practice subfolders. For example, `course/lesson-3-standing-on-shoulders-of-giants/` has practices like `make-visible/` and `make-upright/`.

### Practice structure

Each practice consists of:

1. A `Practice` resource stored in the lesson's `lesson.tres` file with:

   - A unique practice ID
   - Title and goal (the instructions students see)
   - Starting code (what students see in the editor initially)
   - Path to the validator script (tests the student's solution)
   - Path to the script slice (contains the reference solution and practice supporting code)
   - Slice name (identifies which export region to use)

2. Script slice: A GDScript file containing the full working code, including:

   - The reference solution wrapped in export comment regions
   - Helper code students don't need to see yet (signals, setup, etc.)

3. Validator script: Tests that check if the student's solution works correctly. They extend the `PracticeTester` class.

### Practice tester class

Practices are tested by the `PracticeTester` class. This class uses code reflection to automatically find and run test functions.

To create tests, write methods that start with `test_`. For example, `test_character_moves()` or `test_health_increases()`. The class finds these methods automatically.

Each test method should return a string:

- Return an empty string `""` if the test passed.
- Return an error message if the test failed. The student will see this message.

Here's an example:

```gdscript
func test_character_is_visible() -> String:
    if not _scene_root_viewport.get_node("Character").visible:
        return tr("The character should be visible. Did you call show()?")
    return ""
```

The `PracticeTester` class also has two helper methods you can override:

- `_prepare()`: Called before running the tests. Use this to set up any state you need.
- `_clean_up()`: Called after all tests finish. Use this to reset or clean up anything.

Practices can also have a `_run()` method in the slice script (not in the tester). This method runs when students click the "Run" button. The practice UI replaces the script and calls `_run()` if it exists. Use this to animate the scene or show the result of the student's code.

**Note about translations:** Use the `tr()` function around error messages to make them translatable.

### Export comment regions

We use special comment regions to mark the reference solution code. These regions tell the app which code to show when students peek at the solution. The syntax is like this:

```gdscript
# EXPORT slice_name
var test = 42
 
func run():
	print(test)
# /EXPORT slice_name
```

**Note:** The `slice_name` is optional. We originally planned to sometimes use multiple slices per practice and let students switch between different script files. We decided against this to keep practices simpler.

Here's an example from MakeCharacterVisible.gd:

```gdscript
extends Node2D

onready var _animation_tree := find_node("AnimationTree")

func _ready():
    _animation_tree.travel("saying_hi")

func _run():
    run()
    yield(get_tree().create_timer(1.0), "timeout")
    Events.emit_signal("practice_run_completed")

# EXPORT show
func run():
    show()
# /EXPORT show
```

Here, only the `run()` function becomes the suggested solution. The rest stays hidden from the student.

That's for the technical part of practices.

## Creating effective practice content

When you write practices, your goal is to check if students learned what you wanted to teach them. Here are some guidelines to help you write good practices.

### Test the program's state, not the source code

As much as possible, check variables and how the program behaves rather than checking the source code itself.

For example, if you want students to make a character visible, check if the character is visible. Don't check if they wrote `show()` in their code.

However, some practices do need source code checks. This happens because GDScript doesn't let you write code at the root level of a script. We didn't want to hide this from students, so we teach them to write code inside functions, usually in a function called `run()`. This means they often create local variables inside functions, which you can't check by looking at the program's state.

When you need to check source code (for example, to verify the order of operations), use the `preprocess_practice_code()` function from the script slice. This function removes whitespace and comments, which makes your checks simpler. Call it like this: `ScriptSlice.preprocess_practice_code(code)`.

### Show students the complete picture

Some students get confused when they don't see how their code fits into the whole script. They wonder where the variables are defined or how their code runs/where values come from.

When you create a practice, try to show students the property definitions they're working with. Also, explain how their code gets executed, either in the practice goal text or in the lesson content before the practice.

In the future, we might add a dedicated UI element to the practice editor to show this context more clearly. For now, we have to use the starting code and Goals sections to explain this.

### Document what students need

Make sure your practice includes documentation for all the member variables and methods students need to complete the exercise. If your goal tells students to "set the speed to 400," they need to know that a `speed` variable exists and what it does.

Check that the lesson content before the practice covers everything students need. If it doesn't, add it to the lesson or include it in the practice's goal text.
