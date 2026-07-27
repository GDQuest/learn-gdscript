# Coding Guidelines

These guidelines help us keep the application understandable, fast enough, and safe to change. In short, we favor simple, co-located, statically typed procedural code. Always prefer simple, efficient code over clever constructs.

## Writing Code

- Prefer straightforward and inlined procedural code. A reader should be able to follow the main execution order from top to bottom.
- Use clear, complete names. Long names like `clear_and_rebuild_menu()` are fine when they make the purpose clear. Do not use abbreviations.
- Keep code in one place when it is used once. Extract a function only when the code is actually duplicated, or if it's a large complex chunk that really benefits from being separated for comprehension.
- Do not hide important state changes in unrelated objects or global state.
- Prefer exchanging stable IDs like enums at system boundaries. Avoid keeping long-lived references to data that can become stale after navigation, reloading, or a language change.
- Add comments to explain decisions, ownership, or any workarounds we've implemented.

## Scenes and nodes

- Use scene-unique node names and `%NodeName` when a node belongs to the same scene and does not need to be changed by scene instances.
- Export a typed node reference only when a scene instance needs to configure which node is used. Do not export node references just to avoid a local node lookup.
- Check that resources and nodes are valid regardless of their source (files, memory). Give errors enough context to identify what is affected: which lesson, practice, resource path, operation... We want to be able to debug problems quickly in CI and when testing manually too.

## Robustness

- Validate the data passed around upon populating or consuming it. This includes files, resources, parsed lessons, navigation input, translations, and especially student code. Whenever possible, validate it in CI (for example, generated translations).
- Handle expected user-facing problems gracefully with clear feedback. Do not silently continue after getting invalid content or a failed loading. If you use any defensive code that shouldn't normally be needed to gracefully handle errors, make it log a stack trace and clear message so we can trace back issues.
- Pay attention to code errors, warnings, timeouts, and leaked memory. Treat them as issues to address even when the application is working OK.
- Always look for the root cause of a warning or error. Don't suppress warnings or use fallbacks that hide mistakes. You may use defensive code to handle errors gracefully in student practice testing code, because students may write buggy code. But in our code, avoid defensive code that hides mistakes.

## Testing and changes

- Test any code changes by hand. Always check the user flow that the change affects, and all variants you can think of: any potential failure paths, changing settings, navigating back and forth for UI...
- Add, improve, or update regression tests whenever behavior changes. Always prefer integration tests that use real application systems and data over synthetic unit tests that validate implementation details.
- Test both expected success and expected failure.
- Make sure any integration tests are deterministic. You want to control the user profile, settings, locale...
- You may run the narrowest relevant test while developing but always run all integration tests before pushing a completed project or set of changes.
- Unexpected engine errors, warnings, timeouts, and memory leaks should fail automated test runs in CI.
- Write down manual test procedures for important user flows (e.g. how to test a practice or how to QA test settings) and verified commands in documentation so the next contributor can repeat them.
