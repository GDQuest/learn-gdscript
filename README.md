# GDScript Live Editor

This is a Godot project demonstrating loading a scene and enabling live editing and reloading of the scene's scripts

At the moment, the project only runs in the editor, as the script's source is only available there.

Conversely, parsing errors are only recoverable from in an export, as the editor will break.


# Test App Navigation 

When exporting html, make sure to set `html/custom_html_shell` to [`res://html-template.html`](./html-template.html)

You will need a server that defaults back to `index.html` when a path is not found.

One possible test server (not for production!) is [PushState Server](https://github.com/scottcorgan/pushstate-server/).

```
npm install -g pushstate-server
cd releases/html
pushstate-server -d . -f index.html
```

Another way to access a page directly is to pass a command-line argument:

```
cd releases/linux
./live-editor.x86_64 --file=res://course/lesson-1-what-code-is-like/practice-55916.tres
```

## Possible future inspirations:

- https://github.com/williamd1k0/gdscript-cli
- https://github.com/SjVer/GDscript-Shell