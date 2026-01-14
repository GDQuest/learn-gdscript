#!/usr/bin/env python3
"""
Build script for Learn GDScript From Zero.

This script handles building and exporting the Godot project for different platforms,
pushing builds to itch.io, and running a local development server for web builds.
"""

import argparse
import os
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from datetime import datetime
from pathlib import Path

GODOT_EXPORT_PRESET_NAMES = {
    "linux": "Linux/X11",
    "windows": "Windows Desktop",
    "osx": "Mac OSX",
    "web": "HTML5",
}


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
            os.environ[key] = value.strip('"').strip("'")

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
        self.butler_api_key = os.environ.get("BUTLER_API_KEY", "")
        self.itchio_username = os.environ.get("ITCHIO_USERNAME", "")
        self.itchio_game = os.environ.get("ITCHIO_GAME", "")

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


def download_butler(target_dir=None):
    """
    Download Butler CLI tool for itch.io uploads.

    Args:
        target_dir: Directory to install Butler to. If None, installs to current directory.
                    For local development, typically ~/.local/bin is used.
    """
    print("Downloading Butler...")
    butler_dir = Path(target_dir) if target_dir else Path(".")
    butler_dir.mkdir(parents=True, exist_ok=True)
    zip_path = butler_dir / "butler.zip"

    BUTLER_DOWNLOAD_URL = (
        "https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default"
    )
    urllib.request.urlretrieve(BUTLER_DOWNLOAD_URL, zip_path)
    with zipfile.ZipFile(zip_path, "r") as archive:
        archive.extractall(butler_dir)
    butler_path = (butler_dir / "butler").resolve()
    os.chmod(butler_path, 0o755)
    zip_path.unlink()
    run_command(f'"{butler_path}" -V')
    print("✓ Downloaded Butler\n")

    return butler_dir


def download_godot_and_templates():
    """Download Godot headless build and export templates from GitHub."""
    if not build_info.godot_version:
        print("Error: GODOT_VERSION environment variable is not set")
        sys.exit(1)
    if not build_info.templates_repo:
        print("Error: TEMPLATES_REPO environment variable is not set")
        sys.exit(1)

    version = build_info.godot_version
    repo = build_info.templates_repo

    print("Downloading Godot headless build...")
    headless_url = f"https://github.com/{repo}/releases/download/learn-{version}/godot-learn.{version}.headless.zip"
    headless_zip = f"godot-learn.{version}.headless.zip"

    urllib.request.urlretrieve(headless_url, headless_zip)
    with zipfile.ZipFile(headless_zip, "r") as archive:
        archive.extractall(".")
    os.remove(headless_zip)
    print("✓ Downloaded Godot headless\n")

    print("Downloading export templates...")
    templates_url = f"https://github.com/{repo}/releases/download/learn-{version}/godot-learn.{version}.templates.zip"
    templates_zip = f"godot-learn.{version}.templates.zip"

    urllib.request.urlretrieve(templates_url, templates_zip)
    Path("templates").mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(templates_zip, "r") as archive:
        archive.extractall("templates")
    os.remove(templates_zip)
    print("✓ Downloaded export templates\n")


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
    Set up the CI environment: download Godot headless build and export templates,
    install required software, download Butler, and prepare course scripts.
    """
    print("Preparing CI environment...\n")

    download_godot_and_templates()
    # download_butler()

    # Rename Godot binary to a standard name and make it executable
    source_file = "godot_server.x11.opt.tools.64"
    target_path = "godot"

    if not os.path.exists(source_file):
        print(f"Error: {source_file} not found after download")
        sys.exit(1)

    shutil.move(source_file, target_path)
    os.chmod(target_path, 0o755)

    if not os.path.exists(target_path):
        print(f"Error: Failed to rename Godot to {target_path}")
        sys.exit(1)

    print("✓ Prepared Godot headless binary\n")

    print("Installing required software...")
    run_command("apt-get install -y --no-install-recommends sed rsync")

    if os.environ.get("ACT") == "true":
        print("Running in ACT, installing Node.js...")
        run_command("wget -qO- https://deb.nodesource.com/setup_24.x | bash -")
        run_command("DEBIAN_FRONTEND=noninteractive TZ=UTC apt-get install -y nodejs")
    print("✓ Installed software\n")

    prepare_course_scripts()
    print("\n✓ CI environment ready")


def prepare_local():
    """
    Prepare the local development environment by downloading Godot and templates.
    Run this once before exporting locally.
    """
    print("Preparing local environment...\n")

    download_godot_and_templates()

    prepare_course_scripts()
    print("\n✓ Local environment ready")


def export_platform(platform):
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
        f'godot --quiet --no-window --export-debug "{GODOT_EXPORT_PRESET_NAMES[platform]}" "{output_path}"'
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

    if not shutil.which("butler"):
        print("Butler not found in PATH, downloading for local use...")
        butler_dir = download_butler(Path.home() / ".local" / "bin")
        os.environ["PATH"] = f"{butler_dir}:{os.environ['PATH']}"
    else:
        run_command("butler -V")

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
    prepare_cmd.add_argument("target", choices=["ci", "local"])

    clean_cmd = subparsers.add_parser("clean", help="Remove build files")
    clean_cmd.add_argument("target", choices=["all", "web"])

    web_cmd = subparsers.add_parser("web", help="Web development commands")
    web_cmd.add_argument("action", choices=["server", "watch", "debug"])

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    global build_info
    build_info = BuildInfo()

    if args.command == "export":
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
        {"server": web_server, "watch": web_watch, "debug": web_debug}[args.action]()


if __name__ == "__main__":
    main()
