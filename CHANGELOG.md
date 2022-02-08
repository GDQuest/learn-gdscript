# Changelog

This document lists changes between releases.

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
