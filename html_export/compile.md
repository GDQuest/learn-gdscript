# Compiling for web

Because I need this often, here's a one-liner to compile for web:

```sh
rm -rf build/web && \
  mkdir -p build/web && \
  godot -v --export "HTML5" build/web/index.html && \
  cp -r html_export/static/* build/web && \
  cd build/web && \
  python -m http.server 8000 && \
  cd -
```

(This assumes `python` and `godot` are available on `$PATH`)