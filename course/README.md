# The Learn GDScript From Zero course curriculum

Welcome to the Learn GDScript curriculum!

This document outlines the course's lessons and goals. It also first lists a couple of teaching principles that we'll use throughout the course.

## Audience and learning goals

This series is for programming beginners. In particular, teenagers and adults who have little to no programming experience.

It should also work for students who have some experience with a programming language other than GDScript.

Our goals are to get the students comfortable with:

- The basic syntax of GDScript.
- Basic programming concepts like variables, functions, loops, arrays, objects, and more.
- Basic game development concepts like the game loop or input handling.

Our focus is on the absolute basics.

As a result, the following are _not_ goals in this series:

- Teaching object-oriented programming principles.
- Covering multiple programming paradigms.
- Explaining how to organize or structure a game project.
- Teaching the SOLID principles.

## Teaching principles

There are a couple of teaching principles and practices we try to follow with this course.

- We go from concrete to abstract.
- We strive to teach sane programming practices: translating mechanics and features into what the computer needs to do.
- We avoid unnecessary abstractions. Meaning we favor the most straightforward imperative code that solves the problem at hand.
- We try to keep the course as accessible as possible. We write in an easy-to-read and transparent way, even for teenagers. We favor simple language.
- We break down the learning into small steps that respect the students' working memory.

Let's start with the last point: we want to respect people's cognitive load. The human brain can only process about three new pieces of information at a time in their working memory.

If we pile too many new pieces of information at once or go too fast, we'll easily overwhelm students.

Repetition is also key to learning.

For the students to learn well, we also need them to process the information at the deepest level possible: that's why we want to start concrete.

We should introduce new concepts as solutions to problems the students need to solve.

For example, too many programming courses start by showing you variables, then arithmetic, and so on.

Instead, we can start by using existing functions, hard-coding values, and present variables as a tool to label values and make the code more readable (or easily reuse those values).

Or as a way to reuse the same value multiple times without changing it everywhere.

This way, the user instantly cares about the new tool they just learned.

Finally, we don't want unnecessary abstractions and principles without measurable benefits. Like applying "DRY" (Don't Repeat Yourself) for the sake of it or various object-oriented programming ideas that make code more complicated than it needs to be.

This doesn't mean we reject all related practices.

But instead of starting from principles, we start from the problem to solve, the existing code, and what the computer needs to do.

Doing so naturally leads to sometimes reusing code, breaking it down, or bundling data and functions together.

## The course's outline

This section builds upon the principles above to outline the course.

<!-- TODO: build repetition into the lessons -->

### Welcome message

Introduce the student to the app, its state, and what they'll get from it.

### Lesson 1: What code is like

This first lesson motivates students by showing them the results they'll get by following the course.

Covers:

- What computer code looks like.
- How code gives precise instructions to the computer.
- Every video game is a computer program (thus, you need to learn to program to make one).
- How video games rely on computer code (and how a couple of lines of code do magical things).
- You will undoubtedly have questions as we show you new features, but please bear with us as we will eventually explain everything.
- It will take time for you to learn to code and make your first game. Enjoy learning and trying new things.
  You never stop learning as a game designer and a developer. Don't expect any course to turn you into a professional and teach you everything there is to know. You will keep learning new and more efficient ways to get work done your whole life.
- This course will give you the necessary foundations to get started.

We first show the final target for this series: a piece of code containing many concepts taught in the following lessons.

We introduce the student to computer code, how it looks, and how it works, and show the result.

This first lesson should also present the course's goal and tell the student what they'll have learned by the end.

We'll show the same code at the end of the series. At that point, they should understand all of it.

_Note: Should we mention and show how the app will use your code? In the exercise view, we could show a tab with a frozen code listing that shows exactly how it calls code, even if the user first won't use it or can't understand everything. Just to be transparent about what the app does in each exercise._

_Note: We could show how the computer parses code and how it all works: with a tokenizer and syntax tree. This shows how a graphical language is not so different from code._

#### Practice: run your first bit of code

This practice is unique because it triggers the app's initial interactive tutorial.

Covers:

- How the app works.
- How to run code and get an output.

Requirements:

- Go through the tutorial prompts.
- Run the pre-existing code.

The student first gets interactive prompts explaining what each main pane is for.

The app then invites them to run the completed code, which can be restored, to get the game running.

In this interactive tutorial, we should ensure the user gets to read every part.

For instance, by having a "Next" or "Got it" button, they have to click explicitly to move to the next prompt.

### Lesson 2: your first error

Students are bound to run into errors early on. A key feature of the app is it tries to make errors friendly and gives troubleshooting steps.

However, students can still easily be put off by error messages, especially as many learned at school that mistakes are wrong and have negative consequences.

So we should immediately put them at ease with code errors.

Covers:

- You will encounter errors, and that's okay; all programmers do (even professionals).
- Errors are a good thing. They help you write correct programs.
- Errors were designed on purpose by a programmer who came before you and anticipated you might make those mistakes. This is a peer helping you from the past.

#### Practice: your first error

This practice is the second interactive tutorial of the app. It highlights the _Run_ button first to run incorrect code.

The error displays in a popup, reminding us that errors are okay and how the app eases you into error messages.

The popup shows:

- The original error message.
- A clear explanation of what the error means.
- Common troubleshooting steps.

Requirements:

- Go through the tutorial prompts.
- Make a simple edit to the code to remove the error (removing a comment `#` sign).

### Lesson 3: We Stand on the Shoulders of Giants

Programmers always use a lot of code created by others. We introduce this idea from the 3rd lesson.

Doing so allows the student to get visible and appealing results right away, with one-line examples.

Covers:

- The existence of libraries and the engine as a goldmine of time-saving code.
- Calling functions.
- Function arguments.
- You will also build code others will use.
- The computer reads instructions sequentially.

Explaining why it has an underscore and how blocks of code work are extra information the student doesn't need yet.

#### Practices: calling predefined functions

Several short practices invite the students to call their first functions.

They first call show() or hide() to toggle the sprite's visibility.

Then we move on to a function call with one argument, and perhaps with two arguments, to show parameters in action.

Requirements:

1. Show a sprite.
2. Rotate a sprite.
3. Call `move_local_x()` and `move_local_y()` to move? If so, mention we will learn a better way moving forward.

Practice 1:

```gdscript
show()
```

Practice 2:

```gdscript
rotate(1)
```

Note: `rotate()` only works in radians, so we have to introduce that. An option would be to split this practice and introduce nested function calls with `rotate(deg2rad(90))` for example.

Practice 3:

```gdscript
move_local_x(100)
move_local_y(100)
```

_Note: We should at some point find something repetitive so the user clearly sees how their first custom function and the parameter helps them reuse code. The turtle's exercise could be a good one for that as you have to walk 4 times to draw a square._

### Lesson 4: Drawing a Rectangle

This lesson and practice build upon the educational programming language Turtle. In this language, the user moves and rotates a turtle with simple but repetitive instructions.

Covers:

- Using an existing function.

The student will do the same. We provide a "turtle," or marker the student can move in a straight line or rotate.

For this assignment, we can use degrees as students should be more comfortable with them compared to radians.

Here, we can introduce a new feature: a code reference embedded in the practice interface.

```gdscript
move_forward(100) # Moves 100 pixel forward
turn_right(90) # Does a 90-degrees turn to the right
turn_left(90) # Does a 90-degrees turn to the left
```

The lesson should explain how the "turtle" and each function works.

It should also give examples of the turtle in action with the corresponding code. Lastly, the turtle should animate drawing for this first assignment. We should clarify it's our code that makes the turtle animate.

The turtle should work like so for these first mini-challenges:

- At the start, the user should see a dotted line representing the target shape and points representing the target vertices.
- Internally, the turtle should store vertices based on the user's input. We can turn all inputs to ints to make coordinates precise.
  - We record a vertex every time the turtle moves forward.
  - This allows us to test the student drew the correct shape, by matching every vertex.
  - We need to be careful as turning right or left are both valid approaches but will lead to different order of vertices.

### Practice 1: Draw a Rectangle

Using the turtle, the student draws a rectangle of length 200 and height 120.

```gdscript
move_forward(200)
turn_right(90)
move_forward(120)
turn_right(90)
move_forward(200)
turn_right(90)
move_forward(120)
turn_right(90)
```

### Practice 2: Draw a Bigger Rectangle

This time, the student has to draw a bigger rectangle. We give them the code listing from before to save some typing, but they have to go change the values. This time, the rectangle should be of length 220 and height 260.

```gdscript
move_forward(220)
turn_right(90)
move_forward(260)
turn_right(90)
move_forward(220)
turn_right(90)
move_forward(260)
turn_right(90)
```

### Lesson 5: Coding Your First Function

To prepare for the next lesson, we introduce the notion of functions as, in GDScript, all your behavior lives inside of functions.

We explain how the code the user wrote so far, we wrapped into a function.

Covers:

- Using a function to group multiple instructions.
- Defining a function without arguments.
- How we write identifiers with underscores in code because we can't use spaces.

Mention that to use a function, someone needs to call it by its name like you did in the previous part:

> The code inside a function doesn't run until you call it.
>
> In exercises like this one, the app will automatically call the function for you.

---

Note: do we want a practice showing `call("function_name")` first? To show that functions are lists of instructions with a name and we can litterally call them using their name. Issue: we didn't introduce strings yet.

We can then introduce the more common way to call functions:

> ... but for ease of use, we have a shortcut notation that's simpler: function_name()

Or we can do that by first calling functions, then showing the `call("function_name")` alternative.

#### Practice: defining your first functions

The student defines a function that combines everything they did so far: showing, rotating, and moving a sprite on the screen.

_Note: Should we have a predefined function that we can freeze in the editor to represent the app using the student's code? E.g. `test()`, or `test_assignment()`, to demistify how we test the student's code._

```gdscript
func show_and_move():
    show()
    rotate(1)
    move_local_x(100)
    move_local_y(100)
```

### Lesson 6: Your First Value Identifier

Until now, the student had to type values directly.

In preparation for the following lesson, they need to learn about named values, whether variables or arguments.

Covers:

- Naming and reusing a value.
- Replacing hardcoded values with a named value.
- Only function arguments.

#### Practice: Making a function to draw rectangles of any size

Requirements:

- Make a function to draw rectangles of different sizes.

```gdscript
# We should freeze this code if possible, so the student can't erase it.
func test_assignment():
    draw_rectangle(200, 120)
    draw_rectangle(260, 200)


# What the student needs to write (or fill/replace)
func draw_rectangle(length, height):
    move_forward(length)
    turn_right(90)
    move_forward(height)
    turn_right(90)
    move_forward(length)
    turn_right(90)
    move_forward(height)
    turn_right(90)
```

### Lesson 7: Introduction to member variables

We can draw rectangles but we can't control their position. Introduce a member variable of the turtle to change its position and draw rectangles in different places.

Like we first used existing functions, before defining a custom property, we use one created by fellow developers: position.

Covers:

- Assigning a value to a property.
- Changing the position of an entity (here, the turtle).
- Coordinate system: X is positive right, and Y is positive down.
- The position has two components: position.x and position.y.

Should we explain the link between functions that move the object and changing the position?

#### Practice: Drawing rectangles at any position

The user reuses their draw_rectangle() function but changes the position before drawing.

```gdscript
func test_assignment():
    position.x = 120
    position.y = 100
    draw_rectangle(200, 120)
```

Code reference:

- Position.x and position.y
- draw_rectangle(length, height)

### Lesson 8: Defining your own variables

Covers:

- Defining a variable.
- Initializing its value.

#### Practice: a variable to store health

Define a variable named `health` with an initial value of `100`.

``` gdscript
var health = 100
```

### Lesson 9: Adding and subtracting

Covers:

- Adding and subtracting.
- Changing the value stored in a variable.

#### Practice: Taking damage

Goal: In our game, the main character has a certain amount of `health`. When it gets hit, the health should go down by a varying `amount` of damage.

Write a function named take_damage that takes a varying `amount` as its only parameter.

Its only instructions should be to subtract the `amount` to the predefined `health` variable.

```gdscript
var health = 100

func take_damage(amount):
    health -= amount
```

#### Practice: Healing up

```gdscript
var health = 100

func heal(amount):
    health += amount
```

### Lesson 10: The Game Loop

Following the previous lessons, we explain how games run in a loop.

We don't introduce the keywords to write loops in GDScript yet. We only hint at the game loop, show the `_process()` function, and explain how it works.

Covers:

- Defining a function with a special meaning for Godot.
- Making something update many times every second.

We need to stress that the `_process()` function name is a convention.

There are many conventions like those in programming that allow programs and programmers to communicate with one another.

Also, other engines may provide a different name to connect to their update loop.

#### Practice: The Game Loop

Requirements:

- Move the sprite in a circle by combining rotation and local movement.

_Note: we should explain or remind that move_local means "move to the right, depending on where the sprite is facing."_

```gdscript
func _process(delta):
    rotate(0.05)
    move_local_x(5)
```

### Lesson 11: Time delta

The student learns about the `delta` argument and when they should use it.

Covers:

- Frame in video games take a varying amount of time to calculate.
- Multiplication.
- You need to multiply time-sensitive values by delta to make motion time-dependent rather than frame-dependent.
- Thinking of the movement values we use as speed (radians per second, pixels per second).

Important: `delta` is a small fraction of a second, so it's a very small value. That's why we need to use much larger values than in the previous exercise.

#### Practice: Using the delta parameter

Requirements:

- Move in a circle, but using the time delta.

```gdscript
func _process(delta):
    rotate(3 * delta)
    move_local_x(500 * delta)
```

Note: we need to think of how to test and validate the assignment accurately. How to test that the code uses delta? String matching?

### Lesson 12: Using variables to make code easier to read

Covers:

- A variable is a label for a value you can save, change, and read later.
- Defining a script-wide variable.
- Using variables and constants allows you to name values that otherwise make your code hard to read.
- Variables defined outside functions are available to all functions.

We introduce two ways in which we use variables:

- To name an otherwise unclear value and make the code easier to read: both for you now and in the future.
- To group values that control how an entity behaves.

Important: although it makes the code longer at this point, two things:

1. It makes the function `_process()` easier to read and understand by itself.
2. The benefits increase as your code becomes larger and more complex. We can give two examples side-by-side with more lines.

```gdscript
# Find some good code example that is hard to read without clear names.
func _process(delta):
    rotate(4 * delta)
    move_local_x(500 * delta)
    move_local_y(200 * delta)
    #...
```

#### Practice: Making movement clearer

```gdscript
var angular_speed = 3
var horizontal_speed = 500

func _process(delta):
    rotate(angular_speed * delta)
    move_local_x(horizontal_speed * delta)
```

### Lesson 13: Conditions

Covers:

- One or more condition with `if`.
- Code blocks inside functions.

In the previous lesson, we increased and lowered a character's health, but there was no limit.

As a result, the player could increase their character's health indefinitely, which we do not want.

We can use conditions to run code in specific cases.

Conditions make your code branch into two paths: if the condition is met, the computer will run the corresponding instructions. Otherwise, those instructions do not run at all.

Videogames and other computer programs are full of conditions. For example, game input largely relies on conditions: _if_ the player presses the button on a gamepad, the character jumps.

In our case, _if_ the health goes over a maximum, we can reset it to the maximum.

To define a condition, we use the if keyword. We write a line starting with if, type the condition to evaluate, and end the line with a colon.

<!-- Picture showing the structure: if SPACE CONDITION: -->

We've seen how function definitions use a colon at the end of the first line and nest content inside.

This syntax is a recurring pattern for all code blocks that different GDScript features, like conditions, use.

Thanks to that, the computer knows which instructions belong to the condition thanks to that: and the extra leading tab for every instruction inside the conditional block.

```gdscript
func heal(amount):
    health += amount
    if health > 100:
        health = 100
```

#### Practice: Limiting healing

Goal: We have a heal function that adds an amount to the character's health. The character's health should never get above a maximum of `80`.

Hints:

- You can use a condition to check if the health is above 80.
- You need to reset the health to 80 when the health value goes above 80.

```gdscript
func heal(amount):
    health = health + amount
    if health > 80:
        health = 80
```

Errors:

- The health goes above 80 when we heal the character a lot. Did you set the health to 80 when that happens?

#### Practice: preventing health from going below zero

Goal:

When the character takes damage, their health can take negative values.

Say we want to display the health number on screen, like in Japanese RPGs.

We don't want negative numbers: we want instead to stop at zero.

Hints:

- You can use a condition to check if the health goes below zero.
- You need to reset the health to 0 when the health value goes below 0.

Errors:

- The health becomes negative if we deal 400 damage to the character. Did you forget to set it to 0?

```gdscript
func take_damage(amount):
    health = health - amount
    if health < 0:
        health = 0
```

### Lesson 14: multiplying

Covers:

- Multiplication.
- Using `*=` as a shortcut to multiply.
- Combining multiplications with conditions.

#### Practice: Bonus stats

Adding bonuses to character stats upon leveling up

```gdscript
var level = 1
var max_health = 100

func level_up():
    level += 1
    max_health *= 1.1
```

### Lesson 16: 2D vectors

Solves: Storing position or scale, many useful calculations in 2D videogames.

Vectors are not common in all computer programming, but they are prevalent in video games.

This is why we look at them early on here. The user already got a glimpse of them when working with positions. Then, we can use them in the following lessons, for example, to move a character on a board using a loop. We can use them in arrays of coordinates to draw a shape. And so on.

In Godot, vectors are a call kind of value, just like numbers. Precisely, they are the Association of 2 decimal numbers: one for the X coordinate and one for the Y coordinate.

Whenever you access the position or scale of a character, you are dealing with a Vector2.

----

If the student is too young or forgot what they learned about vectors at school, we should link to a good video lesson to get a refresher on what they are and how they work.

Cover:

- Syntax to create vectors: `Vector2(x, y)`
- adding vectors: `position += Vector2(100, 100)`
- subtracting vectors: `position -= Vector2(100, 100)`

### Lesson 17: Introduction to while loops

Solves: repeating instructions any number of times, especially when that number is not known in advance.

While loops make the computer repeat a block of code until you meet a specific condition or decide to break from the loop.

We use while loops every time we need to loop an unknown number of times.

For example, games run in a loop that typically generates 60 images per second until the user closes the game. This is possible thanks to while loops.

The computer also reads the code you write using a while loop because it doesn't know the length of your code in advance.

Concrete examples: drawing a shape many times or making a character walk on a grid many times.

```
var number = 0
while number < 5:
    draw_square()
    position.x += 100
    number += 1
```

Disclaimer: if you're not careful, your while loop can run infinitely. In that case, the application will freeze.

In the next lesson, you will see a much safer kind of loop that does not have this limitation.

### Lesson 18: Introduction to for loops

Solves: doing things a fixed number of times or processing every element of a list.

In this introductory lesson, we only show how to repeat code a fixed number of times using the `range()` function. We can present the range function as producing a list of numbers.

It allows us to first introduce the concept of for loops and later build upon it with lessons dedicated to arrays.

Unlike while loops, for loops do not run infinitely, so it is much less likely that you will get bugs in your game. Because of that, we recommend favoring for loops over while loops.

To cover:

- Looping a fixed number of times (range)

### Lesson 19: Creating arrays

Solves: storing a list of related items, like a list of coordinates, items in the player's inventory, characters in the player's party, and more.

This first lesson focuses on creating an array to store some important data. For example, items in a player's inventory.

The range function we saw in the previous lesson created an array of numbers. For example, calling `range(3)` produces the value `[0, 1, 2]`. It's an array of three numbers starting from zero.

The for loop takes this array and loops over the numbers sequentially.

Arrays are a core data type in computer programs just like numbers. An array is a list of things. Those things can be whole numbers, decimal numbers, 2D vectors, or anything else.

### Lesson 20: Looping over arrays with for loops

Solves: reading and processing the data inside an array.

### Lesson 21: Strings

We need to introduce strings to give nice examples for arrays and dictionaries.

### Lesson 22: Appending and popping values from arrays

The user knows how to create hardcoded arrays, but arrays are really only useful if you can add and remove values whenever needed.

This lesson focuses on just that: adding values at the end of the array and popping values.

This lesson should come after strings to be useful. With only 2D vectors and numbers, can be a bit difficult to should show good uses of those functions.

### Lesson 23: Accessing values in arrays

This lesson can come right before dictionaries because while you can find an index in an array, dictionary lookups can be easier and there will often be more efficient, especially when arrays get large.

While those performance details won't matter too much to students at this point, the dictionary is really much easier to understand and use than arrays for accessing specify keys than arrays.

The examples here could build upon the previous lesson and have us directly access the 3rd order, the for folder, et cetera in the queue without having to use a for loop or some other approach.

### Lesson 24: Creating dictionaries

Creating an inventory mapping item names to whole numbers.

Dictionaries are also called associative arrays: they map elements from one array to the elements of another array.

Take a phone numbers list. Having just the phone numbers is not very useful. Instead, you want to associate names with phone numbers. Dictionary can do that for you.

In games, a typical use for dictionaries is player inventories. You can use a dictionary to store the number of each item you own.

Say you want an inventory with five health potions and ten arrows.

Each entry in the dictionary maps the item's name to the quantity contained in the player's inventory.

### Lesson 25: Looping over dictionaries

We can loop over the keys and values of a dictionary with for loops.

### Lesson 26: Value types

We already talked about value types in the course up to this point, but users have only been writing dynamic code.

This lesson should just focus on value types. It should highlight the problems you will face if you do not master the types and don't understand them.

For example, when trying to add a number to a string directly, you will get an error. You need to convert the number into a string using the `str()` function.

### Lesson 27: type hints

After discovering value types and seeing that we need to be careful with them, we introduce type hints.

Type hints are most useful when getting frequent compilation and linting in Godot so the scope of this lesson is a bit limited. Yet, writing types is a good learning practice: too many self-taught programmers rely on dynamic code and get stuck when a type-related error occurs.

This lesson should show how to specify the expected type of a variable or function argument. We haven't talked about functions that return values yet so we'll introduce the `->` syntax for return types in the corresponding lesson.

We could also introduce type inference here as a shortcut.

Finally, we should make the advantages of using strong typing or dynamic code clear:

It is good for learning as you will get lots of type warnings that will help you improve your understanding of what the code is doing.
Inside Godot, it will also improve auto completion: the computer will better understand your code and will be able to suggest code completions for you more efficiently.

### Lesson 28: Functions that return a value

We haven't covered making pure functions or functions that return values at this stage because the student had too few techniques in their toolbelt.

At this stage, we can make them write useful pure functions, for example, to filter arrays, or to convert vector coordinates from grid to screen coordinates and vice versa.

This lesson should also talk about specifying the return type of a function with the `->` syntax as we didn't get to cover it in the type hints lesson.

There are 3 advantages of functions that only calculate and return values:

1. They make your code easier to read.
2. You can test them in isolation.
3. As a result, they are easy to debug.

## Extra topics to cover

List of extra lessons and topics to consider adding in future app updates:

- Booleans.
- The `elif` keyword.
- Breaking from a loop with the `break` keyword.
- Continuing in a loop with the `continue` keyword.
- Drawing functions (and `_draw()`)
- Creating nested dictionaries (e.g. grid inventory mapping cells to {name: amount}).
- Using arrays inside dictionaries (e.g. `{square = [Vector2(0, 0), Vector2(100, 0), ...]}`).
- Constants.
- Pattern matching with the `match` keyword.
- Useful 2D vector calculations (dot product, direction, length).
- Useful built-in functions like `lerp()`, `range_lerp`, `clamp()`, `min()`, `max()`, etc.
- Combining multiple techniques in small projects, like coding an inventory. 
- Listening to player input.
- Coroutines?
- Signals?

Note that we don't plan to teach objects and object-oriented programming using the app.

We think it'd be better first to teach nodes etc. inside of Godot and later build upon the students' intuitive understanding of game entities to teach the more abstract classes, objects, and so on.
