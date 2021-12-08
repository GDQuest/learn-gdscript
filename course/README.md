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

Explaining why it has an underscore and how blocks of code work are extra information the student doesn't need yet.

#### Practice: calling predefined functions

Several short practices invite the students to call their first functions.

They first call show() or hide() to toggle the sprite's visibility.

Then we move on to a function call with one argument, and perhaps with two arguments, to show parameters in action.

Requirements:

- Show a sprite.
- Rotate a sprite.
- Call `move_local_x()` and move_local_y() to move? If so, mention we will learn a better way moving forward.

```gdscript
show()
```

```gdscript
rotate(1)
```

```gdscript
move_local_x(100)
move_local_y(100)
```

_Note: We should at some point find something repetitive so the user clearly sees how their first custom function and the parameter helps them reuse code. The turtle's exercise could be a good one for that as you have to walk 4 times to draw a square._

### Lesson 4: Creating Your First Function

To prepare for the following lesson, we introduce the notion of functions as, in GDScript, all your behavior lives inside of functions.

We need to explain that our app can hide functions to help with learning, and that we will slowly reveal all the details of how everything works.

Covers:

- Using a function to group multiple instructions.
- Defining a function without arguments.
- How we write identifiers with underscores in code because we can't use spaces.

Mention that to use a function, someone needs to call it by its name like you did in the previous part:

> The code inside a function doesn't run until you call it.
>
> In exercises like this one, the app will automatically call the function by name for you.

_Note: do we want a practice showing `call("function_name")` first? To show that functions are lists of instructions with a name and we can litterally call them using their name. Issue: we didn't introduce strings yet._

_We can then introduce the more common way to call functions:_

> ... but for ease of use, we have a shortcut notation that's simpler: function_name()

#### Practice: defining your first functions

The student defines a function that combines everything they did so far: showing, rotating, and moving a sprite on the screen.

_Note: consider the turtle's exercise: making the turtle move with functions like walk(10), turn(90). If so, we should explain we wrote these functions for the user._

_Note: Should we have a predefined function that we can freeze in the editor to represent the app using the student's code?_

```gdscript
func show_and_move():
    show()
    rotate(1)
    move_local_x(100)
    move_local_y(100)
```

### Lesson 5: Your First Value Identifier

Until now, the student had to type values directly.

In preparation for the following lesson, they need to learn about named values, whether it's variables or arguments.

Covers:

- Naming and reusing a value.
- Replacing hardcoded values with a named value.
- Both variables and function arguments? Or only function arguments?

#### Practice: naming values

Requirements:

- Create an argument to name the value used to offset the sprite in the previous function

```gdscript
func show_and_move(offset):
    show()
    rotate(1)
    move_local_x(offset)
    move_local_y(offset)
```

Note: to make this work fully, the students should also call `do_things(100)`. This involves showing the `_ready()` function to make things work. We could explain this special case in the

> The \_ready() function is a special function definition Godot recognizes and that lets you run code when a game entity is ready to get work done.
>
> We'll later explain in detail how it works. Right now, we still need to explore more of GDScript to fully understand it as it relies on concepts we have yet to see.

### Lesson 6: The Game Loop

Following the previous lesson, we explain how games run in a loop.

We don't introduce the keywords to write loops in GDScript yet. We only hint at the game loop, show the `_process()` function, and explain how it works.

Covers:

- Defining a function with a special meaning for Godot.
- Making something update many times every second.

We need to stress that the_process function name is a convention.

There are many conventions like those in programming that allow programs and programmers to communicate with one another.

Also, other engines may provide a different name to connect to their update loop.

#### Practice: The Game Loop

Requirements:

- Make a sprite rotate continuously by calling the rotate function.
- Make a sprite move continuously by calling the `move_local_x()` function.

```gdscript
func _process(delta):
    rotate(0.05)
    move_local_x(5)
```

### Lesson 7: Variables

Covers:

- A variable is a label for a value you can save, change, and read later.
- Defining a script-wide variable.
- Using variables and constants allows you to name values that otherwise make your code hard to read.

### Lesson 8: Adding and subtracting

Your code is nothing without operations. Computers work exclusively with numbers, and all our code does is reading and writing numbers.

It's incredible how computers can do so many things out of just numbers and a few basic operations when you think of it.

In languages like GDScript, Python, or JavaScript, we don't have to worry about how the computer works exactly. We say that we work at a higher level, with tools that greatly simplify our job (at the cost of some performance).

Still, we need to make calculations often. Most of the time, you will use additions, subtractions, multiplications, and divisions. Simple arithmetic you learned in elementary school.

To add and remove numbers, you write a plus or a minus sign between them. When the computer reads the 2 numbers and the +, it will calculate the result for you.

```
9 + 9
```

You can assign the result of a calculation to a variable any time with `=`. Unlike in your maths class, on the computer, a single = stands for "assign the results of the part on the right to the variable on the left."

```
var health = 9 + 9
```

With the following code, the health variable will have a value of 18.

You can chain as many additions and subtractions as you want.

With the following code, the health variable will have a value of 12.

```
var health = 18 - 8 + 2
```

As the variable names represent a value, you can use the variable name to add or subtract to the current health, for example.

The following code adds 10 to the current health and then subtracts 20 to it, resulting in the health going down by 10 points.

```gdscript
var health = 100

func change_health():
    health = health + 10
    health = health - 20
```

#### Practice: Taking damage

Goal: In our game, the main character has a certain amount of `health`. When it gets hit, the health should go down by a varying `amount` of damage.

Write a function named take_damage that takes a varying `amount` as its only parameter.

Its only instructions should be to subtract the `amount` to the predefined `health` variable.

```gdscript
var health = 100

func take_damage(amount):
    health = health - amount
```

#### Practice: Healing up

```gdscript
var health = 100

func heal(amount):
    health = health + amount
```

### Lesson 9: Conditions

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
    health = health + amount
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

### Lesson 10: multiplying

#### Practice: multiplying

Adding bonuses to character stats upon leveling up

```gdscript
var max_health = 100
var attack = 10

func level_up():
    max_health = max_health * 1.1
    attack = attack * 1.1
```

### Lesson 11: modulo

The modulo operator calculates the remainder of the division. It only works on whole numbers, not decimal numbers.

This operation has important uses in programming like making a number cycle.

Take for example a traffic light. We decide to use a number to represent the lights' current state.

<!-- Demo: lights and their state. -->

The lights always cycle in the same way: first have the green light, then the orange, then the red.

To represent that cycle, you can periodically add one to the number and use the modulo operator to wrap back to 0.

Note that in computer code, we very often count from zero.

#### Practice: traffic lights

making a number wrap

#### Practice: finding even numbers

Doing something every other cell on a row?

### Lesson 12: introduction to loops

To cover:

- Looping over each element in an array
- Looping a fixed number of times (range)
- Looping until a specific condition becomes invalid
