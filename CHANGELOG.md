# Changelog

This document lists changes between releases.

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
