# Learn GDScript From Zero

Learn GDScript From Zero is an app to learn to program with Godot's GDScript programming language from zero.

We designed it for programming beginners, although it should also help self-taught people coming from other programming languages and domains.

You can test the latest release live here: [Learn GDScript From Zero](https://gdquest.github.io/learn-gdscript/).

This app is the free part of a larger paid course to learn game creation with the Godot game engine: [Learn to Code From Zero, with Godot](https://gdquest.mavenseed.com/courses/learn-to-code-from-zero-with-godot).

We're early in production and plan to complete the project at the end of May 2022.

Over 1600 backers funded this project on Kickstarter, which is why we could make a complete interactive app to learn GDScript for free.

## The app is in beta

We first released the app on December 28, 2021. It's currently in a beta testing phase.

While we're doing our best to make everything work, you should expect issues. Please report any issue or bug you face to help make the app better for you and everyone else.

To do so:

- Head to the [Issues](https://github.com/GDQuest/learn-gdscript/issues) tab.
- Search for a report matching your issue.
- If you can't find any, click the _New issue_ button in the top-right corner.
- Follow the instructions on the screen.

## How to run the app

You can test the app online here:

- Bleeding edge version: https://gdquest.github.io/learn-gdscript/staging/ (we update this version periodically as we make improvements)
- Latest stable release: https://gdquest.github.io/learn-gdscript/

You can download the app for Windows, macOS, and Linux on itch.io: https://gdquest.itch.io/learn-godot-gdscript

The desktop version offers better performance than the online version. We recommend it if your computer is a little old or has a slow processor.

### Running the app in Godot to contribute

You can also run the project straight in Godot by cloning the repository and importing the folder into the engine.

We only recommend importing the app in Godot to study its source code or [contribute](#how-to-contribute). You will need **Godot 3.4.2** or a more recent stable version of Godot 3. The project requires features we added to Godot 3.4.2.

Please note that practice errors will trigger the debugger and pause execution in Godot, unlike when using the online version. That's expected behavior, and you'll need to continue execution by pressing <kbd>F7</kbd> when that happens.

## Roadmap

In this section, you'll find a summary of our roadmap for the app.

For more details regarding the planned improvements for each milestone, please head to the [Milestones page](https://github.com/GDQuest/learn-gdscript/milestones).

### Milestone 1.0

_Planned release: by March 15, 2022_

This milestone will mark the first complete release of the app and GDScript course. It should contain 28 lessons and dozens of practices.

On the app's side, we will focus on polishing the user experience.

## Feedback, requests, and discussions

We value feedback and bug reports. We will also consider feature requests, especially if they fit our vision and we feel they benefit programming beginners.

When participating in any discussion around here, please respect our [Kind Communication Guidelines](https://www.gdquest.com/docs/guidelines/best-practices/communication/).

In the [Discussions](https://github.com/GDQuest/learn-gdscript/discussions) tab, you can suggest and upvote ideas for new features or **ask other community members for help**.

**To report bugs, typos,** and discuss existing tasks, please head to the [Issues](issues) tab instead.

## How to contribute

Contributions are welcome if you feel like giving a hand.

To contribute, you need to follow a couple of guidelines.

First, we ultimately decide on the app's design and features or changes that go in. Before you make a change, please ensure there's an existing [Issues](https://github.com/GDQuest/learn-gdscript/issues) for it and please let us know you're working on it. 

Here's our GDScript code style guide: [GDQuest GDScript style guide](https://www.gdquest.com/docs/guidelines/best-practices/godot-gdscript/).

Please always start pull request titles and commit messages with one of the following prefixes:

- `feat:` for new features.
- `improvement:` for an improvement to an existing feature.
- `fix:` for a bug fix.
- `docs:` for changes to the project's documentation.
- `build:` for anything related to GitHub actions.

### How we work

We may directly edit your code to merge it faster when reviewing your changes. This is something we do in our team too for efficiency. We may also request changes.

Finally, if some contribution doesn't work for us, we _may_ close the pull request. 

This happens primarily in two cases:

- The changes don't answer an issue we created or vetted.
- The pull request's author didn't make the requested changes for over a month.
