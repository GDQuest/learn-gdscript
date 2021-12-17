# Your First Value Identifier

In the previous part, you created a function to draw a square of a fixed size.

It's a bit limiting, you'll admit.

Instead, it would be much better if we had a function to draw any square. Or better: any kind of rectangle (a square is a specific kind of rectangle).

We can do that by giving our function a _parameter_.

You create function parameters when writing the function definition (the line starting with the `func` keyword).

To do so, you add a name inside of the parentheses.

<!-- EXAMPLE -->

Remember that names cannot contain spaces, so you need to use underscores instead.

The parameter name is a label you use to refer to a value. The value in question can be a number, text, or anything else. For now, we'll stick to numbers.

You give this number to the function when calling it like you did when calling the rotate() function in a previous lesson.

<!-- Example of a function definition, function call, and how the label gets replaced by the value -->

When calling the function, the computer will replace the parameter name with the corresponding value.

Instead of using hardcoded numbers like `200` in the function body, you want to use the parameter name to refer to the varying parameter.

Here's an example with a function to draw a square.

```gdscript
func draw_square(side_length):
    move_forward(side_length)
    turn_right(90)
    move_forward(side_length)
    turn_right(90)
    move_forward(side_length)
    turn_right(90)
    move_forward(side_length)
    turn_right(90)
```

When calling `draw_square(200)`, the computer will replace the `side_length` parameter with the number `200`.

## Functions can have multiple parameters

You can use multiple parameters in a function. In fact, you can use as many as you _need_.

To separate the function parameters, you need to write a comma.

<!-- example with comma -->

The following example defines a function that uses two parameters to move an entity on both the X and Y axes.

```
func move_local_xy(offset_x, offset_y):
    move_local_x(offset_x)
    move_local_y(offset_y)
```

Now it's your turn to create a function with multiple parameters: a function to draw rectangles of any size.

You'll get to do that in the following practice.



Note on names (identifiers):

The names of functions, parameters, or other things in your code are entirely up to you.

There are written by us programmers for other programmers. You want to use the names that make the most sense to you and fellow programmers.

You could absolutely write single-letter names like in maths classes: `a', `b`, `f`.

You can also write abbreviated names like `pos` for position, `bg` for background, and so on.

Many programmers do either or both of the above.

At GDQuest, we favor complete and explicit names.

We generally try to write code that is explicit and relatively easy to read.

Right now, you have to type every letter when you code, so long names may feel inconvenient.

However, this is good for learning: it trains your fingers to type precisely.

Then, after you finish this course, you will see that the computer assists you a lot when you code real games with a feature called auto-completion.

Based on a few characters you type, it will offer you to complete long names.


# Practice

Drawing rectangles of any size

We want a function to draw rectangles of any size.

This will allow us to draw squares and rectangles anytime in our games. We could use them as outlines when selecting units in a tactical game, as a frame for items in an inventory, and more.

Your job is to code a function named `draw_rectangle` that takes two arguments: the `length` and the `height` of the rectangle.


Hints:

When calling move_forward, you need to alternate between using the length and the height arguments when calling move_forward.
