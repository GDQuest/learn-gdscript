# Testing the web export locally

This guide explains how to build the web export on a local machine, serve it locally, and open it from another device on your local network.

## Build and serve locally

Run these commands from the repository root.

The project uses a custom Godot build. This command with our build script downloads the our copy of the Godot editor (a headless export binary) and the export templates defined by the repository's root `.env` file:

```bash
python build.py prepare local
```

You only need to run this preparation step once, at least until the version of Godot we base the app on or the custom build changes.

### Export the web build

Run this command to export the web build:

```bash
python build.py export web
```

This writes the output to `build/web/<branch-name>`.

### Serve the build over http

To serve the build locally over HTTP, run this command:

```bash
python build.py web server
```

This uses Python's built-in `http.server` module and serves your build over HTTP port `8000`. Access this URL in your browser to run the app:

```text
http://localhost:8000
```

`localhost` means "this same computer". The server listens on all network interfaces, so another device can usually reach it through the computer's LAN address as well:

```text
http://COMPUTER_LAN_IP_ADDRESS:8000
```

Stop the server with `Ctrl+C`.

## Accessing the build from another device

For testing on local devices, simply accessing the build over HTTP will not work. You need to serve the application over HTTPS instead. The rest of the guide explains how to make that work on a local network. Note that devices must be connected to the same network for this address to work.

**Warning:** Only ever use this on a private network you own like your home or a secure office network. Never use this on a public network or a network you do not own.

---

The web export uses browser APIs for audio processing. In particular, there's one called `AudioWorklet` that is available only in a secure context.

Browsers make an exception for accessing the local web server on the same machine which is why you can immediately test a web build on the same device. But when accessing files served from another device on the local network, the browser sees the server as a different origin and does not trust it. If you try to access the app from another computer, phone, or tablet, you will see an error like this:

```text
undefined is not an object (evaluating 'ctx.audioWorklet.addModule')
```

To access the application you need to serve it over HTTPS. The build script detects the computer's LAN IP address automatically. If it detects the wrong address, you can find the correct address manually and pass it to the certificate command.

To find the computer's LAN address manually on Linux, run:

```bash
hostname -I
```

Use the address belonging to the home network, usually something like `192.168.1.X`. You only need to do this if automatic detection chooses the wrong address or falls back to `127.0.0.1`.

On macOS, you can run:

```bash
ipconfig getifaddr en0
```

If that returns nothing, try another active interface like `en1`.


### Serve the app over HTTPS

To serve the app over HTTPS, you will need to:

1. Create a local certificate
2. Start the HTTPS server

The build script can create the certificate and start the HTTPS server for you on Linux and macOS. First, create a local certificate. The script detects the computer's LAN address automatically:

```bash
python build.py web create_certificate
```

This creates a temporary self-signed certificate. The files are stored locally in `.dev_local/`. `key_local.pem` is the private key used by the server. Do not share it. `certificate_local.pem` is the public certificate sent to browsers.

Note: we're generating a self-signed certificate, so every other device will likely show a security warning when accessing the app. You will need to review and accept that warning in the browser. That is normal.

If automatic detection chooses the wrong network address, provide the correct one (Replace `192.168.40.167` with your actual LAN IP, run `hostname -I` on Linux or `ipconfig getifaddr en0` on macOS to find it):

```bash
python build.py web create_certificate --host 192.168.40.167
```

Use `--force-certificate` to replace an existing certificate, for example after switching networks, or to re-generate a new one:

```bash
python build.py web create_certificate --host 192.168.40.167 --force-certificate
```

Now start the HTTPS server:

```bash
python build.py web serve_https
```

Open this URL on the other device, replacing `COMPUTER_LAN_IP_ADDRESS` with the address included in the certificate:

```text
https://COMPUTER_LAN_IP_ADDRESS:8443
```
