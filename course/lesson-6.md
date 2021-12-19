# Your First Value Identifier

In the previous part, you created a function to draw a square of a fixed size.

It's a bit limiting, you'll admit.

Instead, it would be much better if we had a function to draw any square. Or better: any kind of rectangle (a square is a specific kind of rectangle).

We can do that by giving our function _parameters_. Parameters are labels you give to values passed to the function.

You used a function parameter when calling the rotate() function in a previous lesson.

```
rotate(0.5)
```

Under the hood, the `rotate()` function looks like the following:

```
func rotate(radians):
    set_rotation(get_rotation() + radians)
```

It sets the entity's rotation to the sum of its rotation and the extra angle in radians.

> Note
>
> The `radians` can be a positive or negative number, which allows you to rotate both clockwise and counter-clockwise.

For now, please focus on the first line. When you call `rotate(0.5)`, the function receives the value `0.5` under the label `radians`.

Wherever the computer sees `radians` inside the function, it replaces it with the `0.5`.

The parameter name is always a label you use to refer to a _value_. The value in question can be a number, text, or anything else.

For now, we'll stick to numbers as we have yet to see other value types.

## How to create functions with parameters

You can give your function parameters when writing its _definition_ (the line starting with the `func` keyword).

To do so, you add a name inside of the parentheses.

```
func draw_square(length):
    #...
```

You can give parameters any name. How you name functions and parameters is up to you. 

Just remember that names cannot contain spaces. To write parameter names with multiple words, you need to use underscores.

These two function definitions are equivalent.

```
func draw_square(length):
    #...

func draw_square(side_length):
    #...
```


<!-- Illustration of a function definition, function call, and how the label gets replaced by the value -->

The advantage of parameters is they make your code more flexible and reusable.

Here's an example with a function to draw any square. Use the slider to change the value passed to the function and draw squares of different sizes.

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

## Functions can have multiple parameters

You can use multiple parameters in a function. In fact, you can use as many as you _need_.

To separate the function parameters, you need to write a comma between them.

<!-- Illustration with comma -->

The following example defines a function that uses two parameters to move an entity on both the X and Y axes.

```
func move_local_xy(offset_x, offset_y):
    move_local_x(offset_x)
    move_local_y(offset_y)
```

> Note on names (identifiers):
> 
> The names of functions, parameters, or other things in your code are entirely up to you.
> 
> There are written by us programmers for other programmers. You want to use the names that make the most sense to you and fellow programmers.
> 
> You could absolutely write single-letter names like in maths classes: `a`, `b`, `f`.
> 
> You can also write abbreviated names like `pos` for position, `bg` for background, and so on.
> 
> Many programmers do either or both of the above.
> 
> At GDQuest, we favor complete and explicit names.
> 
> We generally try to write code that is explicit and relatively easy to read.
> 
> Right now, you have to type every letter when you code, so long names may feel inconvenient.
> 
> However, this is good for learning: it trains your fingers to type precisely.
> 
> Then, after you finish this course, you will see that the computer assists you a lot when you code real games with a feature called auto-completion.
> 
> Based on a few characters you type, it will offer you to complete long names.

Now it's your turn to create a function with multiple parameters: a function to draw rectangles of any size.

You'll get to do that in the following practice.

# Practice

Drawing rectangles of any size

We want a function to draw rectangles of any size.

This will allow us to draw squares and rectangles anytime in our games. We could use them as outlines when selecting units in a tactical game, as a frame for items in an inventory, and more.

Your job is to code a function named `draw_rectangle` that takes two arguments: the `length` and the `height` of the rectangle.


Hints:

When calling move_forward, you need to alternate between using the length and the height arguments when calling move_forward.
