# Changelog

This document lists changes between releases.

## Learn GDScript From Zero 1.5.2

### Bug fixes

- Fix some symbols getting lost in code examples (=, <, >, etc.)

## Learn GDScript From Zero 1.5.1

### Improvements

- Add color highlighting for strings in bbcode

### Bug fixes

- Fix highlighting of numbers in bbcode
- Add missing commas in code example in lesson 23

## Learn GDScript From Zero 1.5.0

### Content changes

- Review every lesson and practice to make it work as well as possible for Godot 4. The course is still also compatible with Godot 3.
- Remove lesson 15, modulo.
- Add Italian translations.
- Add and update FR, ES, PT, PT_BR, and TR translations. FR and ES translations should be up to date, other languages need updates.
- Move the dot out of the quotes in lesson 3 (#793).
- Edit first lesson to be compatible with Godot 4.
- Remove type hint from code in lesson 1 practice.
- Clarify that turtle code is specific to app.
- Lesson 7 explanation fix (#865).
- Add updated translations for 6 languages.

### Bug fixes

- Update quiz that broke after text fix in l3.
- Ignore word type in glossary in lesson 25.
- Remove type inference from practice in l25.
- Add check that student isn't passing entire combo array in l20.
- Rewrite l14 practice 2 tests to be more accurate.
- Rewrite code highlight algorithm for nicer highlighting of symbols and numbers.
- Reset robot to correct position in practice l17 practice.
- Apply translations to report problem popup.

## Learn GDScript From Zero 1.4.0

*Released on May 16 2023*

### New features

- Add script to extract, sync, check, and integrate new translations (#814)

### Content changes

- Replace parameter with argument in lesson 4 practices
- Add correct return types to documentation of str and int functions
- Correct typo in lesson 7
- Correct typo in lesson 9, improve wording
- Update Spanish translations for lessons 1 to 7
- Change parameter into argument in lesson 6
- Improve phrasing and correct typo in external error popup
- Correct tense in time delta lesson
- Improve lesson 15 note title (#740)
- Check for the use of two arguments in function call in lesson 11
- Improve explanations in lessons 2, 3, 7, 8, 10, 11, and 14
- Correct grammar in lesson 19

### Improvements

- Turn off vsync for faster response times

### Bug fixes

- Use low processor mode instead of target FPS to uncap framerate
- Lesson 21 - remove Step button from combo example (#801)
- Lesson 18 - fix unwrapped loop resetting (#800)
- Lesson 15 - fix traffic light resetting (#797)
- Allow writing decimal number in lesson 11 practice
- Update bar health when changing max health
- Check for play_animation() call in lesson 21
- Correct hint text for lesson 16 (#732)

## Learn GDScript From Zero 1.3.2

*Released on October 17, 2022*

### Improvements

- Make glossary entries work in other languages (#687)
- Add option to lower the main text's brightness (#689)

### Content changes

- Improve note block titles (#682)
- Fix typo in lesson 14
- Clarify requirements in lesson 21 combo practice

### Improvements

- Load translation into glossary and practice hints (#686)
- Add tiling background to demos

### Bug fixes

- Fix function call being partly eaten in lesson 24
- Restore Traffic Light example in Lesson 15 (#696)
- Ensure examples with no debugger nodes don't reset on every call to run()
- Make code examples work with debugger in lesson 21
- Remove visual jitter in orders animation in Lesson 23

## Learn GDScript From Zero 1.3.1

*Released on September 26, 2022*

### Bug fixes

- Fix numbers not being highlighted and being eaten in some cases

## Learn GDScript From Zero 1.3.0

*Released on September 25, 2022*

### New features

- Add syntax highlighting for code in lesson and practice text
- Add sponsorless end screen for Godot docs (#632)
- Add visualization of how values get assigned to cursor variable in for loops (#634)
- Add common macOS Cmd shortcuts in code editor in browser

### Content changes

- Improve loop explanations and examples in lessons 17 and 18 (#641)
- Rewrite lesson 9's first practice hint to make it clearer
- Add error explanation for can't assign to expression
- Explain pass keyword in lesson 13
- Improve Lesson 22 cell screen-position explanation (#655)
- Add specific error message for IN_EXPECTED_AFTER_IDENTIFIER error (#665)
- Clarify explanation of documented functions in lesson 22 (#664)
- Make numbers explicitly decimal in lesson 28 to make types clearer
- Add error explanation for EOL at string parse error
- Add explanation for "can't get index ... on base" error

### Improvements

- Move inline value display in code example to button
- Add practice index to lesson practices list and breadcrumb
- Make loop code example taller to avoid scroll bar
- Ensure that the content of runnable code examples is behind buttons
- Highlight symbols in lessons

### Bug fixes

- Make practice checks auto-wrap to not overflow window
- Use debug build to prevent crash on nonexistent functions and variables
- Prevent navigating during transitions
- Add missing reset to lesson 11 practices
- Don't highlight word "type" in lesson 13 (#656)
- Correct syntax highlighting on nested function calls

## Learn GDScript From Zero 1.2.2

*Released on August 5, 2022*

### Content changes

- Add Spanish version of the course
- Add explicit mention you need to use draw_rectangle() in lesson 7
- Fix typo in lesson 8
- Fix typo in error message in lessons 10 and 11
- Fix return type of array.pop_* functions
- Remove explanation of underscore prefix for some functions
- Fix typo in lesson 18
- Fix typo in lesson 16
- Use heal function in lesson 14 instead of take_damage
- Remove unnecessary conditioin in lesson 14 practice 2
- Correct typo in lesson 26

### Bug fixes

- Walk over closing bracket characters
- Typos in lesson 1
- Typo in lesson 18 (#577)
- Typo in lesson 19 (#578)
- Ensure canvas resolution scales with the parent containers to avoid blurry fonts (#585)
- Replace rectangle with square in lesson 5 (#571)
- Prevent crashes with division by zero, add error for this
- Prevent infinite recursion after function blocks
- Remove input detection on items in lesson 24
- Check the whole path in lesson 20
- Ignore first point in lesson 19 P1 if it's Vector2.ZERO
- Prevent side panel from overflowing window with the largest font size

## Learn GDScript From Zero 1.2.1

*Released on June 11, 2022*

### Improvements

- Auto complete dictionary braces

### Bug fixes

- Move cursor inside parens when writing parens without a selection
- Fix indent error in practice in lesson 24

## Learn GDScript From Zero 1.2.0

*Released on June 11, 2022*

### New features

- Add auto-closing brackets to code editor

### Content changes

- Fix cell coordinates in lesson 26
- Fix example converting string into number in lesson 27
- Correct example looping over values of an array in lesson 24
- Remove glossary underline from word type in lesson 6
- Clarify one answer in quiz in lesson 5
- Precise where to add the length parameter in lesson 6 practice
- Replace quiz in lesson 4 by a more appropriate one
- Remove leading underscore to delta in lesson 10
- Add extra test to drawing squares practice in lesson 6
- Add note to practice in lesson 11 not to use local variables

### Improvements

- Update warning popup text for small screen (#549)
- Allow to further reduce the text size for large displays

### Bug fixes

- Remove double border on example in lesson 1
- Ensure lesson examples always draw behind issue popup
- Fix error when calling print() without arguments
- Fix crashes when coding infinite while loops
- Fix practice in lesson 20 not passing if not solved at first trial
- Prevent error when not drawing any polygons in Back to the drawing board practice
- Prevent the mobile warning popup from going off-screen
- Check edited slice code instead of source text in practice tests
- Make animation play based on calls to play_animation() in lesson 21 practice

## Learn GDScript From Zero 1.1.0

_Released on June 3, 2022_

### New features

- Add offline script verifying support using custom build of Godot (#469)
- Add reset functionality to all relevant examples (#487)

### Content changes

- Remove extra line in lesson 22 practice solution
- Explain when you want to store return values in lesson 22
- Remove remaining uses of "pass" and update practice hints

### Bug fixes

- Handle optional parameters on `move_local_x()` in lesson 11 (#480)
- Correct typo in lesson 1
- Make practice pass if using float instead of int in lesson 11
- Updated moving turtle test for lesson 19 to include the starting point (#524)
- Delta check in the moving in a circle lesson (#526)
- Don't pass in lesson 11 practice if speed is 0.2 instead of 2

## Learn GDScript From Zero 1.0.0

_Released on April 1, 2022_

### Content changes

- Improve phrasing and formatting in lessons 16 to 28 (#463)
- Clarify practice description in lesson 7
- Add code mark to code in glossary entries
- Correct typo in lesson 8
- Make the solution in lesson 23 practice not use `Array.size()`
- Add variable definitions to lesson 14 practices
- Make it so using a loop in lesson 6 practice works
- Change "type" into "enter" in lesson 6 to avoid wrong glossary highlight

### Improvements

- Title screen redesign
- End screen redesign
- Redesign modulo examples to be more intuitive (#437)
- Give cursor more natural start position in practices
- Add new train track sprites in lesson 24
- Reset visibility and transform when pressing reset button in practices

### Bug fixes

- Change correct answer in quiz in lesson 25
- Reset glossary popup size when clicking a word with a short explanation
- Match number with boxes in even-odd example
- Correct error message in lesson 28
- Remove button to load incomplete Russian translation
- Correctly name array brackets
- Add missing period in error explanations (#450)
- Add missing documentation in practices in lessons 4 and 5
- Make turtle draw three parallel lines in lesson 5 example

## Learn GDScript From Zero release 0.4.0

_Released on March 7, 2022_

This update adds **12 new lessons**, completing the planned content for the 1.0 release on the app. 

Once more, we spent a lot of time refining the app to provide you with a better experience. You can find the details below.

The key feature in this update is **localization support**. We're now working on Spanish and French translation, and the community's contributing more languages in the [app translation repository](https://github.com/GDQuest/learn-gdscript-translations).

We also added desktop exports as performance and text rendering can be much better outside the browser. You can find desktop builds on [the app's itch.io](https://gdquest.itch.io/learn-godot-gdscript) page.

### New features

- Add server connection indicator in practice screen
- Animate turtle turning
- Add localization support to the app
- Add interactive glossary

### Content changes

- Add lesson 17: Introduction to while loops
- Add lesson 18: Introduction to for loops
- Add lesson 19: Creating arrays
- Add lesson 20: Looping over arrays
- Add lesson 21: Strings
- Add lesson 22: functions that return values
- Add lesson 23: array append and pop
- Add lesson 24: array access by index
- Add lesson 25: creating dictionaries
- Add lesson 26: Looping over dictionaries
- Add lesson 27: value types
- Add lesson 28: type hints
- Edit first 15 lessons to make phrasing a bit more explicit
- Use explicit functions in lessons 1 to 3, explain in lesson 3
- Make function calls explicit in lessons 3 and 4, rework practices
- Make function calls explicit in lessons 5 to 7
- Make function calls explicit in lessons 8 to 11, update practices
- Reset practice visuals with reset button
- Stress the importance of multiplying by delta in lesson 11
- Clarify the server disconnected error and steps to address it
- Add duplicate variable definition error in lesson 8
- Remind that you use = to change a variable's value in lesson 7
- Remove an example that was too technical in lesson 6
- Add 7 new error explanations
- Add examples of what vectors are and what they can do in lesson 16
- Introduce else keyword in lesson 13
- Tidy up visual example in lesson 23
- Add health variable definition in lesson 9 practices
- Clarify pop() example in lesson 23
- Make lesson 6 square practice more precise, improve tests
- Shorten text in lessons 1 and 2, add 2 new glossary entries
- Load and translate a real error example in lesson 2
- Add application UI translations in French

### Improvements

- Reduce app CPU usage (up to 90% less usage)
- Add option to disable labels in DrawingTurtle
- Give outline buttons a white outline when in focus
- Add keyboard focus when opening various popups
- Allow for small demos that can receive mouse input
- Remove and dim text outlines in buttons and progress bars
- Give outliner button a fixed width
- Add new turtle design by Kay Lousberg
- Integrate new GDQuest boy design by Kay Lousberg
- Change indicator when running code without connection to server
- Make all big green and red buttons use outline styles
- Allow changing the button name in RunnableCodeExample
- Make function calls explicit in lessons 12 to 16
- Animate the turtle jumping
- Added exports and itch support
- Add CI setup scripts
- Testing workflow
- Make the code cursor jump to the last character by default
- Add setting to change the app's framerate
- Add board_size and cell code references
- Swap the order of buttons in quizzes and settings
- Add translation support with live updating to lessons and practices
- Add translation support to the rest of the application
- Support recompiling html template while watching
- Make outlined button theme consistent and less confusing
- Make separator lines thicker by default
- Redo and unify button styles
- Make inventory items more distinct
- Start in fullscreen mode on desktop
- Add illustrations to lesson 1, improve phrasing

### Bug fixes

- Fix typo in lesson 16 practice error message
- Prevent lesson 11 practices from passing when multiplying after call
- Use websockets
- Use websockets for heartbeat connection
- Restore "is_connected_to_server"
- Address full-screen toggle issues by handling it browser-side
- Attempt to correct fullscreen woes
- Resize canvas through JS
- Workflow does not depend on another
- Wrong Godot build
- Typo in Godot version number
- Prevent smooth scrolling from overshooting when framerate goes down
- Correct handling of camera and position when drawing with the turtle
- Fix error when adding a scene as a child of RunnableCodeExample
- Correct typo in lesson 15 practice 2
- Force Unix-friendly line endings in translations
- Add missing icons for the option button
- Correctly save user settings when changing language
- Restored proper variables for logging
- Support generating logs in desktop app
- Added a container to aid button placement
- Typo in run file
- Do not call methods before js interface exists
- Open links when clicking them in lessons
- Restore normal scrolling speed on desktop platforms
- Ensure the robot doesn't clip when wrapping in lesson 3
- Typo "directoin" in lesson 16
- Typos in lesson 17
- Pick correct node to check in validation script
- Correct variable name in leson 17 practice
- Properly reject incorrect solutions
- Remove trailing whitespace in two examples in lesson 18
- Constrain robot to game board in lessons 17 and 18
- Properly remove checks when switching language
- Second exercis expecting four rectangles
- Remove Report Issue button on end screen
- Match while loop content to run code
- Restore working modulo example
- Make build script more portable
- Make practice description render bbcode
- Output scroll container should clip content
- Pop gems starting from the top one
- Prefer fuzzy font on scale rather than pixelated
- Match inventory order with visual textures
- TextEdit text not changing properly
- Prevent commented code lines from making L10 practices pass
- Prevent invisible fullscreen button from grabbing focus

## Learn GDScript From Zero release 0.3.0

_Released on February 8, 2022_

### New features

- Smooth scrolling (#201)
- Warn user before losing progress on an unfinished practice (#277)

### Content changes

- Add lesson 16 about creating 2D vectors
- Clarify lesson 12, practice 1
- Add turtle jump() explanation in lesson 5
- Add explanation about modulos with a larger divisor than dividend in lesson 15
- Add radian conversion formula to lesson 3, complete radian explanation
- Add space symbols in function syntax example in lesson 6, improve explanation
- Clarify the robot should turn clockwise in lesson 11 practice 2
- Don't limit health at 100 in lesson 9 healing example
- Change traffic light color names to match US standard
- Update dice practice description in lesson 15 to match solution
- In lesson 3, talk about function arguments instead of parameters
- Explain the syntaxes for adding and subtracting in lesson 9
- Add explanation about camelCase name convention
- Add extra info box about the Y axis pointing down in lesson 3
- Improve MISPLACED_IDENTIFIER error with function definition case

### Improvements

- Add a post-lesson popup and inform the user if there are incomplete practices
- Add more transition animations for post-practice/post-lesson dialogs
- Add particles to the post-lesson dialog
- Add a solution panel to let students compare their approach with the suggested one
- Add temporary turtle sprite for the turtle practices
- Increase the content column width when increasing font size
- Make code examples increase height when the font size increases
- Allow controlling scroll bars with the keyboard without clicking first
- Confirm quiz type change in course builder (#214)
- Allow navigating back to outliner from end screen
- Animate quiz resizing (#247)
- Add extra error messages to lesson 5 practice 2 (#262)
- Add a function to report type errors in variable assignment
- Dynamically update tooltip and cursor on back button
- Have a single Robot scene for visuals and practices (#276)

### Code changes

- Make lesson files self-contained

### Bug fixes

- Ensure squares have the expected coordinates in lesson 6 practice
- Account for more valid solutions in lesson 15 practice 1
- Add max health value to error message in lesson 15 practice 3
- Ensure the turtle sprite resets position in runnable examples
- Correctly handle slidable panels on resize/fullscreen
- Allow modulos larger than number in lesson 15
- Typo in lesson 15, practice 1 hint
- Check corner coordinates in lesson 6 practice 2
- Allow using a loop in lesson 5 practice 2
- Correct two typos in lessons 13 and 15
- Fix error when trying to scroll with arrow keys
- Force text wrapping to update when changing font size
- Always correctly position post-practice popup
- Restore ability to click on links in welcome screen
- Respect restored lesson position in smooth scroll container
- Fix typo in lesson 9 practice hint
- Enter pause mode when showing suggested solution
- Correct typo in lesson 11 (#231)
- Incorrect button label in lesson 9
- Remove empty line in lesson 8
- Make health value reset to starting value in lesson 13
- Remove confusing navigation options from the practice screen
- Correct typo "want to want to" (#238)
- Add missing space between a number and modulo sign (#240)
- Prevent visual scroll bars in lessons 14 and 15
- Traffic light colors, match example and text (#241)
- Throttle scroll events (#218)
- Lesson 9 and 13 health bars now show proper values on ready (#248)
- Make practice screen ignore global pause
- Correct typo in lesson 11: "dependant" -> "dependent"
- Correct typo  in lesson 14: "multiple" -> "multiply" (#267)
- Correct typo  in lesson 15: "evening" -> "even" (#269)
- Make code examples read-only
- Force the full screen toggle button to update on click in browser
- Prevent pressing left from triggering a back event in well done popup
- Don't increase indent level when removing pass after a function definition
- Make practices pass in lesson 11 when pressing Ctrl+Enter
- Prevent code examples in lesson 13 from getting a scrollbar
- Fix lesson 16 practice 2 tests
- Correct typo in lesson 16 practice 2 tests
- Use versioned lsp url
- Restore ability to scroll with the keyboard
- Ensure long practice titles don't push the UI outside the page

## Learn GDScript From Zero release 0.2.1

_Released on January 27, 2022_

### Improvements

- Let students to stay in the lesson and experiment upon completion
- Show an indicator when practice was completed before and solution was used
- Make cursor pointing hand on all buttons
- Adjust the slice plugin toolbar for better visual clarity

### Content changes

- Update error log text and link in issue report form
- Added missing apostrophe in lesson 6
- Explain jump function in lesson 5 practice

### Bug fixes

- Fix "shortcut" appearing multiple times in practice button tooltips
- Fix bbcode formatting appearing as plain text in multiple choice quizzes
- Ensure health takes different values in lesson 13 practices
- Make the slice plugin UI conflict with editor UI less
- Unify hover behavior for buttons with icons
- Hide code in jump visual in lesson 13

## Learn GDScript From Zero 0.2.0

_Released on January 26, 2022_

This release brings 7 new lessons and many improvements and fixes to the app. For this release, we focused on improving stability, responsiveness, and your experience with the core app.

We delayed adding new features to instead refine what we already had.

### New features

- Add 7 new lessons
- Remember and restore position in the lesson
- Add optional header and separator for lesson content blocks
- Add navigation between practices of the same lesson
- Add server and client logging

### Improvements

- Add clearer radio button icons to match checkboxes
- Make the turtle start with an offset position in lesson 4
- Create UUID for  user
- Better script display in inspector
- Make scrollbars easier to click on, align lesson bar with the window
- Provide a way for users to download client log
- Handle GDQuest errors like GDScript's
- Allow JS to communicate errors to Godot
- Slightly increase the space between content blocks
- Rewrite the revealer component; Style it better across the app also remove unused spoiler content block type
- Pull lsp url from project settings
- Run checks after the test scene has finished animating
- Mark practice as completed immediately upon checks passing 
- Give visual status to validating and running code
- Allow staging CI to pick a different LSP
- Ignore local overrides
- Error out if LSP url is not set
- Add a tcp socket client, specify socket URL from project configuration
- Suppress error if run button manually hidden
- Animate practice checks
- Add finished signal to turtle
- Standardize practice title capitalization
- Make many content improvements to lessons 1 to 9 and 12 to 14
- Make breadcrumbs navigatable and infinite
- Indicate when a quiz may have multiple answers
- Add a button to toggle the app full-screen
- Make some popups stand out more
- Reveal the entire lesson when running from the editor plugin
- Hide GDScript code in runnable examples without code
- Add shortcuts to buttons in the app and in practice view

### Changes

- Add a logging library
- Add UUID library
- Use resource names for node names to make content blocks easily identifiable
- Switch renderer to GLES2 to increase device compatibility
- Use action hash for CI

### Bug fixes

- Lesson 1: correct content (#127)
- Remove run action being emitted twice in CodeEditor
- Make Ctrl+Enter run code from code editor
- Remove empty hint in lesson 2
- Fix typos in quizzes in lesson 6
- Fix revealer folding animation not working in nested revealers (#119)
- Add missing space in lesson 8
- Fix typo on end screen
- Add move_local_x to list of methods
- Use ints as keys for blacklist codes
- Correct the list of GDScript keywords and tokens
- Add the remaining GDScript keywords to syntax highlighter
- Make the web export scale correctly in every browser (especially Firefox)
- Remove debug drawing from the lesson
- Use msecs for network measurements
- Allow scripts to run if server is unresponsive
- Fully reset the course progress when requested
- Make the insert block trigger slightly snappier in the course builder
- Re-run ready after changing script
- Prevent crashes when user writes recursive functions
- Enable buttons after reset or back navigation in practice window
- Restore signals to the revealer and make use of them in the error popup
- Fix scene using stale references
- Improve contrast for text and icons on green background
- Remove hardcoded width for the practice panel elements
- Github values have to be prefixed with `input`
- Github variables are under `inputs` namespace
- Set environement as a global constant
- Cast variables causing type errors
- Remove comments from override.cfg
- Set slider value to value in scene
- Allow creating squares and rectangles with negative coordinates in practices
- Prevent nested scrollbars in the practice UI
- Make the reset button reset everything, not just code
- Prevent DFM and fullscreen shortcuts conflicting
- Make instructions match solution in lesson 11 practice

## Learn GDScript From Zero 0.1.1

_Released on January 3, 2022_

This release fixes some important bugs blocking the completion of some assignments. It also brings some UI improvements.

### New features

- Add custom html shell (#70).
- Show warning for mobile screens.
- Show app version on the page.

### Improvements

- Add shake animation to quizzes (#79).
- Set resizePolicy to 0.
- Add opengraph web tags.
- Add library support for copy and paste.
- Increase contrast in button styles.

### Bug fixes

- Fix lesson 7's practice tests (#82)
- Change web page title
- Make html template adaptive and limited to 1920x1080
- Add static files to build script
- Fix breadcrumbs lesson navigation index (#87)
- Correct the tooltip of the home button
- Fix formatting in lesson 6

## Learn GDScript From Zero 0.1.0

_Released on January 2, 2022_

This is the first beta release of the app.

### New features

Main features:

- Slices to edit a portion of a script.
- Allow sending GDScript code to an LSP server, compile online, and report errors.
- Scripts to test assignments locally.
- Practice interface with a code editor.
- Game viewport that reloads based on the students' changes, handles errors.
- Output console that can print messages and errors.
- Editor plugin to author lessons and practices.
- 8 lessons and 10 practices.

More features:

- Add support for relative file paths for visual elements.
- Add error database for GDScript errors and warnings.
- Add ability to quickly test lesson or practice from plugin.
- Add support for spoiler content blocks and inverting visuals.
- Add single and multiple choice quizz widgets.
- Add quizz widget with int, float, and string input field.
- Add support for quizzes in course builder plugin.
- Add widget to display a runnable scene with a code example.
- Code "turtle" to draw geometric shapes.
- Add welcome screen and loading screen.
- Add a report-an-issue popup, improve the look of tooltips.
- Add settings popup.
- Create a class to make 2D nodes wrap position within a Control.
- Make font size configurable throughout the app.
- Add ability to draw multiple polygons with turtle.
- Give each polygon a position in DrawingTurtle.
- Add documentation reference array.
- Add dynamic sliders to RunnableCodeExample.
- Add a way to display methods references.
- Design editor to list code ref items in practice tab.
- New console output log, improved indication for errors outside of student-editable range.
- Add error explanation to the output console.
- Add a way to insert a new content block in between two existing ones.
- Add ability to print plain messages to OutputConsole.
- Add course outliner/index.
- Add support for property descriptions in code reference panel.
- Start tracking student progression.
- Allow to continue the course from the last lesson you've started from the welcome screen.
- Add ability to skip quizzes.
- Hide the rest of the lesson until the student tried a quiz.
- Add end screen to display when completing the last practice.
- Add clickable GDQuest logo.
- Add screen displayed at the end of the course.
- Allow resetting course progress.
- Show overlay and text when pausing the game view.
- Display help messages from assignment unit tests.
- Add icon to go back from outliner to welcome screen.
- Git hash in the built HTML page.
- Loading screen.
