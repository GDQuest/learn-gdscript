# Lesson 5: Coding Your First Function

So far, we only called existing functions.

And as I told you before, those functions come from other developers who wrote them for you.

Functions are just _sequences of instructions_ we give a name.

Using the name, we can get the computer to execute all these instructions as many times as we need. This is what a function call does.


> Note: Identifiers
>
> In computer programming, we talk about _identifiers_ rather than "names".
> 
> It is because a function name is a label the computer uses to precisely _identify_ and refer to a function or other code elements.
>
> Identifiers are unique: you cannot reuse the same name in a given _space_ in your code.
>
> If you try to name two functions the same, the computer will raise an error.

The instructions inside a function can be anything. They can call other functions or do many operations you have yet to learn like creating variables, checking conditions, running loops, and more. You'll learn all those in upcoming lessons.

For now, here's the example of a `move_and_rotate()` function that moves the turtle forward and then turns it 90°.

```gdscript
func move_and_rotate():
    move_forward(200)
    turn_right(90)
```

The `move_and_rotate()` function consists of two instructions, each on a separate line. Both of those instructions call another familiar function.

You could write another function that calls `move_and_rotate()` four times to draw a square of length 200 pixels.

<!-- Runnable example -->

```gdscript
func draw_square():
    move_and_rotate()
    move_and_rotate()
    move_and_rotate()
    move_and_rotate()
```

You can do much better than that, as you'll see. But hopefully you can see that a function is a bunch of code that you can reuse.

## Defining your own functions

Let's break down how you define a function.

A function definition starts with the `func` keyword followed by the function's name, parentheses, and a colon.

<!-- TODO: illustration of syntax like english grammar. Use a regular scene? -->

The instructions inside the function must start with a leading tab character. You can insert that tab character by pressing the **Tab** key.

We call those leading tabs _indents_ and they're very important: the computer uses them to know which instructions are part of a code block, like the body of a function.

<!-- TODO: illustration of function body and indent -->

## Names in code cannot contain spaces

Your function names cannot contain spaces. In general, names in programming languages cannot contain spaces.

This is because the computer uses spaces to detect the separation between different keywords and names.


Instead of spaces, in GDScript, we write underscores ("_").

You saw this already with functions like `move_forward()` or `move_local_x()`.

> Note: there's nothing magical about functions
> 
> There's nothing magical about functions and most things on the computer. One could argue it's all math and physics!
> 
> In Godot, a function named `call()` allows you to call another function by giving its name an argument.
> 
> The following two code listings have the same effect.
> 
> ```
> call("show")
> ```
> 
> ```
> show()
> ```
> 
> Notice how in the leftmost listing we use quotes: We call those strings of text and will explore them in a future lesson.

---

# Practice

Create a function we can call multiple times to draw squares side-by-side.

Each square should be of length 200 pixels.

You should have a gap of 100 pixels between squares, meaning you should offset the turtle by 300 pixels.


Hints

You can draw the square the same way you drew the rectangle in the previous practice.

You need to move the turtle at the end of your draw_square() function by calling the function jump_horizontally().
