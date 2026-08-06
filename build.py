#!/usr/bin/env python3
"""
Build script for Learn GDScript From Zero.

This script handles building and exporting the Godot project for different platforms,
pushing builds to itch.io, and running a local development server for web builds.
"""

import argparse
import hashlib
import os
import shutil
import socket
import subprocess
import sys
import urllib.request
import zipfile
from datetime import datetime
from pathlib import Path

GODOT_EXPORT_PRESET_NAMES = {
    "linux": "Linux",
    "windows": "Windows Desktop",
    "osx": "macOS",
    "web": "Web",
}

# Make sure it matches what's in the Github workflow, ExportGodot.yaml
GODOT_BINARY_NAME = "godot_server.x86_64"


class BuildInfo:
    """
    This global object holds information about the current build: git info,
    timestamps, and environment variables. We populate it at startup before any
    commands run. See main() below.
    """

    def __init__(self):
        # Load variables from .env file into os.environ.
        env_path = Path(".env")
        if not env_path.exists():
            print(f"Error: .env file not found at {env_path.absolute()}")
            print(
                "This file is required for build configuration (the GODOT_VERSION, TEMPLATES_REPO env vars are required)"
            )
            sys.exit(1)

        for line in env_path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            value = value.strip('"').strip("'")
            if value:
                os.environ[key] = value

        is_ci = (
            os.environ.get("CI") == "true" or os.environ.get("GITHUB_ACTIONS") == "true"
        )
        if is_ci:
            # In CI we get some info from github actions through env variables
            # TODO: add support for version tags later
            self.git_commit = os.environ.get("BUILD_GIT_COMMIT")
            self.git_branch = os.environ.get("BUILD_GIT_BRANCH")

            if not self.git_commit:
                print("Error: BUILD_GIT_COMMIT environment variable is required in CI")
                sys.exit(1)
            if not self.git_branch:
                print("Error: BUILD_GIT_BRANCH environment variable is required in CI")
                sys.exit(1)
        else:
            # If we're building locally we use git directly
            self.git_commit = run_command("git rev-parse HEAD", capture_output=True)
            self.git_branch = run_command(
                "git branch --show-current", capture_output=True, check=False
            )

        self.build_date_iso = datetime.now().strftime("%Y-%m-%d")

        self.base_url = os.environ.get(
            "url", "https://gdquest.github.io/learn-gdscript"
        )
        is_release = self.git_branch == "release"
        if not is_release:
            self.base_url = f"{self.base_url}/{self.git_branch}"

        self.godot_version = os.environ.get("GODOT_VERSION", "")
        self.templates_repo = os.environ.get("TEMPLATES_REPO", "")
        self.godot_editor_sha256 = os.environ.get("GODOT_EDITOR_SHA256", "")
        self.godot_templates_sha256 = os.environ.get("GODOT_TEMPLATES_SHA256", "")
        self.butler_version = os.environ.get("BUTLER_VERSION", "")
        self.butler_sha256 = os.environ.get("BUTLER_SHA256", "")
        self.butler_api_key = os.environ.get("BUTLER_API_KEY", "")
        self.itchio_username = os.environ.get("ITCHIO_USERNAME", "")
        self.itchio_game = os.environ.get("ITCHIO_GAME", "")

    def is_ci(self):
        """Returns True if running in CI environment."""
        return (
            os.environ.get("CI") == "true" or os.environ.get("GITHUB_ACTIONS") == "true"
        )

    def get_output_directory(self, platform):
        """Get output directory for a platform. Web builds on non-release branches get a subfolder."""
        BUILD_DIRECTORIES = {
            "linux": "build/linux",
            "windows": "build/windows",
            "osx": "build/osx",
            "web": "build/web",
        }
        base = BUILD_DIRECTORIES[platform]
        if platform == "web" and self.git_branch != "release":
            return f"{base}/{self.git_branch}"
        return base


# Global instance, populated in main() before any command runs
build_info: BuildInfo = None


def run_command(command, check=True, capture_output=False):
    """Run a shell command. Returns stdout as string if capture_output is True."""
    print(f"  > {command}")
    result = subprocess.run(
        command, shell=True, check=check, capture_output=capture_output, text=True
    )
    return result.stdout.strip() if capture_output else None


def download_or_retrieve_from_cache(url, filename, expected_sha256):
    """Downloads a build dependency once if needed, stores it in a cache
    direction, and returns its local archive path. If the file is already cached
    and the SHA256 checksum matches, it returns the cached path instead."""

    def calculate_file_sha256(file_path):
        file_hash = hashlib.sha256()
        with file_path.open("rb") as file:
            for chunk in iter(lambda: file.read(1024 * 1024), b""):
                file_hash.update(chunk)
        return file_hash.hexdigest()

    if not expected_sha256:
        print(f"Error: SHA-256 checksum is missing for {filename}")
        sys.exit(1)
    cache_directory = Path(
        os.environ.get("BUILD_DOWNLOAD_CACHE", ".cache/build-downloads")
    )
    cache_directory.mkdir(parents=True, exist_ok=True)
    archive_path = cache_directory / filename
    if archive_path.exists():
        if calculate_file_sha256(archive_path) == expected_sha256:
            print(f"Using cached {filename}")
            return archive_path
        print(f"Cached {filename} failed checksum validation; downloading it again")
        archive_path.unlink()

    print(f"Downloading {filename}")
    temporary_path = archive_path.with_suffix(archive_path.suffix + ".tmp")
    urllib.request.urlretrieve(url, temporary_path)
    actual_sha256 = calculate_file_sha256(temporary_path)
    if actual_sha256 != expected_sha256:
        temporary_path.unlink()
        print(f"Error: SHA-256 checksum mismatch for {filename}")
        sys.exit(1)
    temporary_path.replace(archive_path)
    return archive_path


def download_butler(target_dir=None):
    """
    Download Butler CLI tool for itch.io uploads.

    Args:
        target_dir: Directory to install Butler to. If None, installs to current directory.
    """
    print("Preparing Butler...")
    butler_dir = Path(target_dir) if target_dir else Path("")
    butler_dir.mkdir(parents=True, exist_ok=True)
    if not build_info.butler_version:
        print("Error: BUTLER_VERSION environment variable is not set")
        sys.exit(1)
    version = build_info.butler_version
    url = f"https://broth.itch.zone/butler/linux-amd64/{version}/archive/default"
    archive_path = download_or_retrieve_from_cache(
        url, f"butler-{version}-linux-amd64.zip", build_info.butler_sha256
    )
    with zipfile.ZipFile(archive_path, "r") as archive:
        archive.extractall(butler_dir)
    butler_path = (butler_dir / "butler").resolve()
    os.chmod(butler_path, 0o755)
    run_command(f'"{butler_path}" -V')
    print("✓ Butler ready\n")

    return butler_dir


def download_godot():
    """Download the custom Godot headless build from GitHub."""
    if not build_info.godot_version:
        print("Error: GODOT_VERSION environment variable is not set")
        sys.exit(1)
    if not build_info.templates_repo:
        print("Error: TEMPLATES_REPO environment variable is not set")
        sys.exit(1)

    version = build_info.godot_version
    repo = build_info.templates_repo

    print("Preparing Godot headless build...")
    headless_url = f"https://github.com/{repo}/releases/download/learn-{version}/godot-learn.{version}.editor.zip"
    archive_path = download_or_retrieve_from_cache(
        headless_url,
        f"godot-learn.{version}.editor.zip",
        build_info.godot_editor_sha256,
    )
    with zipfile.ZipFile(archive_path, "r") as archive:
        archive.extractall(".")

    source_file = "godot.linuxbsd.editor.x86_64"

    if not os.path.exists(source_file):
        print(f"Error: {source_file} not found after download")
        sys.exit(1)

    shutil.move(source_file, GODOT_BINARY_NAME)
    os.chmod(GODOT_BINARY_NAME, 0o755)

    print("✓ Godot headless ready\n")


def download_export_templates():
    """Download the custom Godot export templates from GitHub."""
    version = build_info.godot_version
    repo = build_info.templates_repo

    print("Preparing export templates...")
    templates_url = f"https://github.com/{repo}/releases/download/learn-{version}/godot-learn.{version}.templates.zip"
    archive_path = download_or_retrieve_from_cache(
        templates_url,
        f"godot-learn.{version}.templates.zip",
        build_info.godot_templates_sha256,
    )
    Path("templates").mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive_path, "r") as archive:
        archive.extractall("templates")
    print("✓ Export templates ready\n")


def download_godot_and_templates():
    """Download the custom Godot build and the export templates from GitHub."""
    download_godot()
    download_export_templates()


def prepare_course_scripts():
    """
    Copy .gd files to .lgd format so the learning app can show source code.
    Godot converts scripts to bytecode during export, removing the source.
    The app reads .lgd files to display code examples to students.
    """
    print("Preserving course scripts...")
    count = 0
    for gd_file in Path("course").rglob("*.gd"):
        shutil.copy(gd_file, gd_file.with_suffix(".lgd"))
        count += 1
    print(f"✓ Copied {count} scripts to .lgd format")


def prepare_ci():
    """
    Set up the CI environment: download Godot headless build, export templates,
    Butler, import the project, and prepare course scripts.
    """
    print("Preparing CI environment...\n")

    download_godot_and_templates()
    download_butler()

    if not os.path.exists(GODOT_BINARY_NAME):
        print(f"Error: {GODOT_BINARY_NAME} not found after download")
        sys.exit(1)

    print("✓ Prepared Godot headless binary\n")

    prepare_course_scripts()
    run_command(f"./{GODOT_BINARY_NAME} --headless --editor --quit")
    print("\n✓ CI environment ready")


def prepare_test():
    """Set up the custom Godot binary and generated scripts required by tests.
    Import the project in Godot."""
    print("Preparing test environment...\n")
    download_godot()
    prepare_course_scripts()
    run_command(f"./{GODOT_BINARY_NAME} --headless --editor --quit")
    print("\n✓ Test environment ready")


def prepare_local():
    """
    Prepare the local development environment by downloading Godot and templates.
    Run this once before exporting locally.
    """
    print("Preparing local environment...\n")

    download_godot_and_templates()
    download_butler()

    prepare_course_scripts()
    print("\n✓ Local environment ready")


def export_platform(platform):
    godot_binary_path = Path(GODOT_BINARY_NAME)
    if not godot_binary_path.exists():
        print(f"Error: Godot executable '{GODOT_BINARY_NAME}' not found.")
        print(f"Please make sure the binary exists at: {godot_binary_path.absolute()}")
        print("Did you run the 'prepare' command first?")
        sys.exit(1)

    if platform not in GODOT_EXPORT_PRESET_NAMES:
        print(
            f"Error: Unknown platform '{platform}'. Available: {', '.join(GODOT_EXPORT_PRESET_NAMES.keys())}"
        )
        sys.exit(1)

    print(f"Exporting for {platform}...\n")

    generated_gdscript_version_script = f'''# AUTO GENERATED FILE, YOUR CHANGES WILL NOT REMAIN
class_name AppVersion

const git_commit := "{build_info.git_commit}";
const build_date := "{build_info.build_date_iso}";
'''
    Path("utils/version.gd").write_text(generated_gdscript_version_script)
    print("Created version file")

    # For web builds, process the HTML template
    if platform == "web":
        template = Path("html_export/index_template.html").read_text()
        template = template.replace(
            "GDQUEST_ENVIRONMENT = {}",
            f'''GDQUEST_ENVIRONMENT = {{
     git_commit: "{build_info.git_commit}",
   }}''',
        )
        template = template.replace("%url%", build_info.base_url)
        Path("html_export/index.html").write_text(template)
        print("Created HTML template")

    output_dir = build_info.get_output_directory(platform)
    APP_NAME = "learn_to_code"
    OUTPUT_FILES = {
        "linux": f"{APP_NAME}.x86_64",
        "windows": f"{APP_NAME}.exe",
        "osx": f"{APP_NAME}.zip",
        "web": "index.html",
    }
    output_path = f"{output_dir}/{OUTPUT_FILES[platform]}"
    Path(output_dir).mkdir(parents=True, exist_ok=True)

    run_command(
        f'./{GODOT_BINARY_NAME} --headless --quiet --no-window --export-debug "{GODOT_EXPORT_PRESET_NAMES[platform]}" "{output_path}"'
    )

    if platform == "web":
        static_dir = Path("html_export/static")
        if static_dir.exists():
            for item in static_dir.iterdir():
                if item.is_file():
                    shutil.copy(item, output_dir)
                else:
                    shutil.copytree(
                        item, Path(output_dir) / item.name, dirs_exist_ok=True
                    )
            print("Copied static web files")

    print(f"\n✓ Exported {platform} to {output_dir}")


def push_platform(platform):
    if platform not in GODOT_EXPORT_PRESET_NAMES:
        print(
            f"Error: Unknown platform '{platform}'. Available: {', '.join(GODOT_EXPORT_PRESET_NAMES.keys())}"
        )
        sys.exit(1)

    print(f"Pushing {platform} to itch.io...\n")

    local_butler = Path("butler")
    if local_butler.exists():
        print("Using local butler installation")
        os.environ["PATH"] = f"{local_butler.parent}:{os.environ['PATH']}"
        run_command("butler -V")
    elif shutil.which("butler"):
        print("Using system butler installation")
        run_command("butler -V")
    else:
        print("Butler not found, downloading for local use...")
        butler_dir = download_butler()
        os.environ["PATH"] = f"{butler_dir}:{os.environ['PATH']}"
        run_command("butler -V")

    # Validate credentials
    missing = []
    if not build_info.butler_api_key:
        missing.append("BUTLER_API_KEY")
    if not build_info.itchio_username:
        missing.append("ITCHIO_USERNAME")
    if not build_info.itchio_game:
        missing.append("ITCHIO_GAME")
    if missing:
        print(f"Error: Missing itch.io credentials: {', '.join(missing)}")
        sys.exit(1)

    build_dir = build_info.get_output_directory(platform)
    if not Path(build_dir).exists():
        print(
            f"Error: Build directory does not exist: {build_dir}\nDid you run 'export' first?"
        )
        sys.exit(1)

    target = f"{build_info.itchio_username}/{build_info.itchio_game}:{platform}-{build_info.git_branch}"
    run_command(f'butler push "{build_dir}" "{target}"')
    print(f"\n✓ Pushed {platform} to {target}")


# ----------------------
# The commands below are for testing the web version locally
# ----------------------


def web_server():
    """Start a local web server for testing. Open http://localhost:8000 in your browser."""
    web_dir = build_info.get_output_directory("web")
    if not Path(web_dir).exists():
        print(
            f"Error: Web build not found at {web_dir}\nRun 'python build.py export web' first"
        )
        sys.exit(1)

    print(f"""Starting web server...
Directory: {web_dir}
URL: http://localhost:8000
Press Ctrl+C to stop
""")
    run_command(f'python3 -m http.server 8000 --directory "{web_dir}"')


LOCAL_CERTIFICATE_DIRECTORY = Path(".dev_local")
LOCAL_CERTIFICATE_PATH = LOCAL_CERTIFICATE_DIRECTORY / "certificate_local.pem"
LOCAL_KEY_PATH = LOCAL_CERTIFICATE_DIRECTORY / "key_local.pem"


def get_local_ip():
    """Return the local address normally used to reach this computer."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as connection:
        try:
            connection.connect(("8.8.8.8", 80))
            return connection.getsockname()[0]
        except OSError:
            return "127.0.0.1"


def create_certificate(host=None, force=False):
    """Create a short-lived self-signed certificate for local HTTPS testing."""
    host = host or get_local_ip()
    if host == "127.0.0.1":
        print("Warning: could not detect a LAN address; using 127.0.0.1")

    if LOCAL_CERTIFICATE_PATH.exists() and LOCAL_KEY_PATH.exists() and not force:
        print(
            f"Certificate already exists at {LOCAL_CERTIFICATE_PATH}. "
            "Use --force to replace it."
        )
        return

    if not shutil.which("openssl"):
        print("Error: openssl is required to create the local certificate")
        sys.exit(1)

    LOCAL_CERTIFICATE_DIRECTORY.mkdir(parents=True, exist_ok=True)
    command = [
        "openssl",
        "req",
        "-x509",
        "-newkey",
        "rsa:2048",
        "-nodes",
        "-days",
        "7",
        "-keyout",
        str(LOCAL_KEY_PATH),
        "-out",
        str(LOCAL_CERTIFICATE_PATH),
        "-subj",
        f"/CN={host}",
        "-addext",
        f"subjectAltName=IP:{host}",
    ]

    import shlex

    print(f"  > {' '.join(shlex.quote(part) for part in command)}")
    subprocess.run(command, check=True)
    print(f"Created certificate for {host} at {LOCAL_CERTIFICATE_PATH}")


def serve_https(host=None, port=8443):
    """Serve the web export over HTTPS for testing on local devices."""
    web_dir = build_info.get_output_directory("web")
    if not Path(web_dir).exists():
        print(
            f"Error: Web build not found at {web_dir}\nRun 'python build.py export web' first"
        )
        sys.exit(1)

    if not LOCAL_CERTIFICATE_PATH.exists() or not LOCAL_KEY_PATH.exists():
        create_certificate(host)

    import ssl
    from functools import partial
    from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

    class Handler(SimpleHTTPRequestHandler):
        def end_headers(self):
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
            super().end_headers()

    handler = partial(Handler, directory=web_dir)
    server = ThreadingHTTPServer(("0.0.0.0", port), handler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(str(LOCAL_CERTIFICATE_PATH), str(LOCAL_KEY_PATH))
    server.socket = context.wrap_socket(server.socket, server_side=True)

    display_host = host or get_local_ip()
    print(f"Serving HTTPS on https://{display_host}:{port}")
    print("Press Ctrl+C to stop")
    server.serve_forever()


def web_watch():
    """Watch for file changes and rebuild automatically. Requires inotifywait."""
    if not shutil.which("inotifywait"):
        print("""Error: inotifywait is not installed
Install it with:
  - Debian/Ubuntu: sudo apt-get install inotify-tools
  - Arch/Manjaro: sudo pacman -S inotify-tools
  - Fedora: sudo dnf install inotify-tools""")
        sys.exit(1)

    print("Watching for changes... Press Ctrl+C to stop\n")

    command = (
        "inotifywait --monitor --recursive --quiet "
        "--event modify,move,create,delete "
        '--format "%w%f" . | '
        'grep -E "\\.(gd|tscn|tres|js|css|html)$" | '
        "while read file; do "
        'echo "Change detected: $file"; '
        "python3 build.py export web; "
        "done"
    )
    run_command(command, check=False)


def clean_web_build():
    print("Cleaning web build...")
    web_dir = build_info.get_output_directory("web")
    if Path(web_dir).exists():
        shutil.rmtree(web_dir)
    print("✓ Cleaned web build")


def prepare_clean():
    """Remove files downloaded by 'prepare local' command."""
    print("Cleaning prepare files...")

    files_to_remove = [
        GODOT_BINARY_NAME,
        "butler",
        "7z.so",
        "libc7zip.so",
    ]

    for filename in files_to_remove:
        file_path = Path(filename)
        if file_path.exists():
            file_path.unlink()
            print(f"  Removed {filename}")

    templates_dir = Path("templates")
    if templates_dir.exists():
        shutil.rmtree(templates_dir)
        print("  Removed templates/")

    download_cache_directory = Path(
        os.environ.get("BUILD_DOWNLOAD_CACHE", ".cache/build-downloads")
    )
    if download_cache_directory.exists():
        shutil.rmtree(download_cache_directory)
        print(f"  Removed {download_cache_directory}/")

    # Remove .lgd files created by prepare_course_scripts
    lgd_count = 0
    for lgd_file in Path("course").rglob("*.lgd"):
        lgd_file.unlink()
        lgd_count += 1
    if lgd_count > 0:
        print(f"  Removed {lgd_count} .lgd files")

    print("✓ Cleaned prepare files")


def web_debug():
    """Full dev mode: clean, build, serve, and watch for changes."""
    # Check for inotifywait before doing anything else
    if not shutil.which("inotifywait"):
        print("""Error: inotifywait is not installed
Install it with:
  - Debian/Ubuntu: sudo apt-get install inotify-tools
  - Arch/Manjaro: sudo pacman -S inotify-tools
  - Fedora: sudo dnf install inotify-tools""")
        sys.exit(1)

    print("""Web debug mode starting...

This will:
  1. Clean and rebuild the web export
  2. Start a local server at http://localhost:8000
  3. Watch for changes and rebuild automatically

Make sure you have run 'python build.py prepare local' first!
""")

    clean_web_build()
    export_platform("web")

    import threading

    server_thread = threading.Thread(
        target=lambda: run_command(
            f'python3 -m http.server 8000 --directory "{build_info.get_output_directory("web")}"',
            check=False,
        )
    )
    server_thread.daemon = True
    server_thread.start()

    print("\nServer started at http://localhost:8000\n")
    web_watch()


def main():
    parser = argparse.ArgumentParser(
        description="Build script for Learn GDScript From Zero",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python build.py export linux       Export for Linux
    python build.py export web         Export for web
    python build.py export all         Export all platforms
        """,
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    export_cmd = subparsers.add_parser("export", help="Export the project")
    export_cmd.add_argument(
        "platform", choices=list(GODOT_EXPORT_PRESET_NAMES.keys()) + ["all"]
    )

    push_cmd = subparsers.add_parser("push", help="Push build to itch.io")
    push_cmd.add_argument(
        "platform", choices=list(GODOT_EXPORT_PRESET_NAMES.keys()) + ["all"]
    )

    prepare_cmd = subparsers.add_parser("prepare", help="Prepare build environment")
    prepare_cmd.add_argument("target", choices=["ci", "test", "local", "clean"])

    clean_cmd = subparsers.add_parser("clean", help="Remove build files")
    clean_cmd.add_argument("target", choices=["all", "web"])

    web_cmd = subparsers.add_parser("web", help="Web development commands")
    web_cmd.add_argument(
        "action",
        choices=["server", "create_certificate", "serve_https", "watch", "debug"],
    )
    web_cmd.add_argument("--host", help="LAN IP to include in the local certificate")
    web_cmd.add_argument("--port", type=int, default=8443)
    web_cmd.add_argument(
        "--force-certificate",
        action="store_true",
        help="Replace an existing certificate",
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    global build_info
    build_info = BuildInfo()

    if args.command == "export":
        # When building locally, we need to manually call the function to
        # prepare the exports. This mainly creates a copy of the GDScript files that
        # we can read in the exported app for interactive practices.
        #
        # In the CI we do it as a separate CI step ran manually because we want
        # to prepare things only once and then build the different platforms in
        # a build matrix in parallel.
        if not build_info.is_ci():
            print("Preparing course scripts for local export...\n")
            prepare_course_scripts()
            print()

        if args.platform == "all":
            print("Exporting all platforms...\n")
            for platform in GODOT_EXPORT_PRESET_NAMES:
                export_platform(platform)
            print("\n✓ All platforms exported")
        else:
            export_platform(args.platform)
    elif args.command == "push":
        if args.platform == "all":
            print("Pushing all platforms to itch.io...\n")
            for platform in GODOT_EXPORT_PRESET_NAMES:
                push_platform(platform)
            print("\n✓ All platforms pushed")
        else:
            push_platform(args.platform)
    elif args.command == "prepare":
        if args.target == "ci":
            prepare_ci()
        elif args.target == "test":
            prepare_test()
        elif args.target == "clean":
            prepare_clean()
        else:
            prepare_local()
    elif args.command == "clean":
        if args.target == "all":
            print("Cleaning all builds...")
            if Path("build").exists():
                shutil.rmtree("build")
            Path("build").mkdir(parents=True, exist_ok=True)
            Path("build/.gdignore").touch()
            print("✓ Cleaned all builds")
        else:
            clean_web_build()
    elif args.command == "web":
        if args.action == "create_certificate":
            create_certificate(args.host, args.force_certificate)
        elif args.action == "serve_https":
            serve_https(args.host, args.port)
        else:
            {"server": web_server, "watch": web_watch, "debug": web_debug}[
                args.action
            ]()


if __name__ == "__main__":
    main()
