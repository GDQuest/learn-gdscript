# Lesson 3: We Stand on the Shoulders of Giants

As programmers, we rely on a lot of code created by others before us.

When you use any programming language, it comes with a wealth of features created by other programmers to save you time.

Game engines like Godot add a massive layer of time-saving code on top of a plain programming language.

We call a bundle of code created by fellow developers a _library_.

It's a bunch of code sitting there, just waiting for you to use it.

A game engine goes a step further: it brings multiple libraries together to solve game developers' problems.

It's a goldmine of time-saving code, especially when getting started.

## You'll always use a lot of existing code

When coding, you're never quite on your own. Even programming languages, which you'll use constantly, are based on programs created by fellow developers.

Throughout this course, you will use a lot of code created by the Godot developers.

The first code you'll write will _call functions_ created by other programmers.

A function is a list of instructions for the computer with an exact name. By calling that name, we tell the computer to execute all the instructions sequentially.

<!-- ILLUSTRATE THAT -->

To call the function, we write its exact name followed by parentheses.

```
show()
```

In Godot, the `show()` function makes something visible, like a character or object. There's a complementary `hide()` function to hide the object.

<!-- This would be a good place to have widgets where people can try things. -->

## Function parameters

Often, you will write inside the parentheses. Numbers, bits of text, and more, separated with commas (","). 

We call those comma-separated values _parameters_ or _arguments_ (there are many synonyms in computer programming). 

Parameters let you fine-tune the effect of the function call.

Here's a _sprite_ standing straight. If we call the `rotate()` function with a parameter of `0.05`, the character _sprite_ turns.

<!-- Draw a widget showing the code + the result? -->

```
rotate(0.05)
```

> The value of `0.05` is an angle in radians. In daily life, we're used to measuring angles in degrees. The radian is another scale commonly used in video games and math.
> 
> An angle of `PI` radians corresponds to `180` degrees. And `2 * PI` is a full turn: `360` degrees.
> 
> Even if you're not familiar with the term radian, you've most likely seen them before.
>
> You find that `2 * PI` in the calculation of a circle's perimeter, which you probably learned at school (`perimeter = 2 * PI * r`). Two times the number PI represents a full turn around the circle in radians.

We achieve this continuous rotation by levering Godot's game loop. When we tap into the game loop, Godot calls the `rotate()` function many times per second, making the character turn smoothly.

We will explain more about the game loop in a couple of lessons. For now, let's call our first couple of functions.

<!-- Because the computer uses spaces to separate keywords in code, we can't use spaces in names. Instead, in GDScript, we replace spaces by _underscores_ ("\_"). -->
