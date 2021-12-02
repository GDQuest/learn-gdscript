Welcome to GDScript Learn.

GDScript Learn is a Free and Open-Source app and series to help you learn to code, **from zero**, with Godot's GDScript programming language.

Whether you want to learn game development or just code with exciting interactive projects, this app is for you.

There are no hidden fees: 1600 backers who pre-ordered our course on Kickstarter funded this app.

As a result, we could make everything in here free for everyone.

We're making a complete course to get up to speed with the GDScript programming language.

It complements the free course you will find in the Godot documentation (we contributed to it too).

Disclaimer: The app is in a beta state. You may encounter bugs, typos, and more.

Please use the button in the top menu to report the issue when this happens.

It is crucial: we'll use your reports to fix issues for you and everyone else.

# Lesson 1: What Code is Like

Learning to program can be daunting. 

Yet, if you want to make video games, there is no way around learning to program because every game is a computer program.

Programming is the process of giving precise instructions to the computer to have it tackle tasks for you.

In the case of a game, those instructions are things like moving characters multiple times per second, drawing life and energy bars, playing sounds, and so on.

To do any of that, you need to learn a programming language: a specialized language to tell the computer what to do.

Programming languages are different from natural ones like English or Spanish because the computer does not think. It can't _interpret_ what you tell it.

So you can't tell it something vague like "draw a circle."

To draw a circle, the computer may need to know the drawing coordinates, the radius, and the thickness and color you want for the outline.

The code to do so _may_ look like this.

```
draw_circle(Vector2(0, 0), 100, 4, Color.green)
```

In the following lessons, you'll learn how this code works and what each part means.

For now, I just want to give you a slight sense of what computer code is like: each parenthesis, capital letter, period, and comma matter in this example.

The computer will always do what you tell it to. No more, no less.

It _blindlessly_ follows every letter and comma, which means you have complete control over what happens.

When you program, you're in charge, and you're free to do anything you want.

At the same time, there is a lot to learn to tame the dumb beast that is your computer.

## You'll learn to code with GDScript

In this course, you will learn the GDScript programming language.

This is a language by game developers for game developers. You can use it within the Godot game engine to create games and applications.

SEGA used the Godot engine to create the remake of Sonic Colors Ultimate. Engineers at Tesla use it for their cars' dashboards.

It's an excellent language to get started with programming because it's specialized. Unlike some other languages, it doesn't have an overwhelming amount of features for you to learn.

Now, you won't be locked with it. When you learn a programming language, you learn concepts that apply to all other programming languages. 

Once you learn one, it becomes much faster to get productive with the next one because most languages have more similarities than differences.

Like most game developers, I learned and used more than ten programming languages.

Here's an example of the same code in three languages: GDScript, Python, and JavaScript.

It doesn't look _that_ different, does it?

```gdscript
func take_damage(amount):
    health -= amount
    if health < 0:
        die()
```

```py
def take_damage(amount):
    health -= amount
    if health < 0:
        die()
```

```js
function take_damage(amount) {
  health -= amount
  if (health < 0) {
    die()
  }
}
```

## This is a course for beginners

If you want to learn to make games or code but don't know where to start, this course should be perfect.

We designed it for absolute beginners, although if you already know another language, it can also be a fun way to get started with Godot.

We will give you the coding foundations you need to start making games and applications with Godot.

Mind that it will take you time before making your first complete game or app alone.

Creating games is more accessible than ever, but it still takes a lot of work and practice.

So try to enjoy the learning process and every little success.

It's important because you will never stop learning as a game designer and developer. You will keep discovering new and more efficient ways to program as you gain experience. 

It's just part of the process.

Also, you shouldn't expect any single course or book to turn you into a professional or teach you everything there is to know. You'll improve a ton through practice.

I've been coding professionally for years, and I still learn new things almost every day.

## What and how you'll learn

By the end of the series, you will create this.

<!-- INSERT INTERACTIVE DEMO ON THE SIDE -->

Along the way, we'll teach you:

- Some of the mindset you need as a developer. Too many programming courses skip that, but it's essential.
- Some foundations of game programming. Knowing that will help you with any game engine.
- How to write real code with the GDScript language.
- Most of the GDScript language's syntax.

As you go through the course, you will have many questions. We will answer them as we go.

But at first, there is so much to cover that we'll have to take a few shortcuts.

We don't want to _overwhelm_ you with information. We also want to respect the pace at which our brains memorize things.

We broke down the course into bite-size lessons with many short practices to get to use, repeat, and remember everything.

If we shoved too much in each part, you'd learn slower.

If at any time you're left with burning questions, you're more than welcome to join [our Discord community](https://discord.gg/87NNb3Z).

## Programming is a skill

Programming is a skill, so to get good at it, you must practice. It is why we built this app.

Here, you will constantly bounce between short lessons and interactive practices, so you instantly get to use what you learn.

Speaking of which, it's time to look at the practice screen.

To continue, click the practice button below. It will give you a short run through how practices work.
