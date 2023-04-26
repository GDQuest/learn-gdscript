import os
import sys
import argparse
import subprocess
import shutil
import glob
from match_and_merge_po_translations import parse_po_file
from dataclasses import dataclass


@dataclass
class TranslationsData:
    language_code: str
    directory_path: str
    total_strings: int = 0
    missing_translations: int = 0
    fuzzy_translations: int = 0

    _completion_rate: int = -1

    def get_completion_rate(self) -> int:
        """Returns the completion rate of the language with an int between 0 and 100, with 100 representing 100% completion."""
        if self._completion_rate == -1:
            todo_count = self.missing_translations + self.fuzzy_translations

            self._completion_rate = 100 - (100 * todo_count // self.total_strings)

        return self._completion_rate


@dataclass
class Args:
    translations_path: str
    threshold: int
    skip_extract: bool
    skip_sync: bool


def parse_command_line_arguments() -> Args:
    """
    Parses command line arguments and returns a dictionary containing options and arguments.
    """
    parser = argparse.ArgumentParser(
        description="This script performs text extraction from the application and move "
        "generated POT files in the translations project in order to compare "
        "with translations source and output a translation completion "
        "indicator for each language."
    )
    parser.add_argument(
        "translations_path",
        help="Relative or absolute path to the repository learn-gdscript-translations/.",
    )
    parser.add_argument(
        "-t",
        "--threshold",
        type=int,
        default=95,
        help="Minimum completion percentage value for a language to be integrated.",
    )
    parser.add_argument(
        "-E",
        "--skip-extract",
        action="store_true",
        help="Skip the extraction of strings and POT files generation.",
    )
    parser.add_argument(
        "-S",
        "--skip-sync",
        action="store_true",
        help="Skip the synchronization and merge of PO files with the reference POT files.",
    )
    return Args(**vars(parser.parse_args()))


def main():
    args = parse_command_line_arguments()

    I18N_DIRECTORY = os.path.dirname(os.path.realpath(__file__))

    if args.skip_extract:
        print("WARN: Skipping strings extraction and POT files generation...")
    else:
        print(
            "INFO: Extracting translation strings from learn-gdscript source code and generating POT files..."
        )
        EXTRACT_SCRIPT_PATH = os.path.join(I18N_DIRECTORY, "extract.py")
        result = subprocess.run(["python3", EXTRACT_SCRIPT_PATH], capture_output=True)

        # if there was an error, print stdout and stderr and exit
        if result.returncode > 0:
            sys.exit(
                "ERROR: Extraction scripts ended with errors. Aborting script.\n"
                f"Script {EXTRACT_SCRIPT_PATH} output the following errors:"
                f"Error code: {result.returncode}"
                f"\n{result.stderr.decode('utf-8')}"
            )

        print("INFO: Moving POT files to translations folder")

        pot_files = glob.glob("*.pot", root_dir=I18N_DIRECTORY)
        for pot_file in pot_files:
            shutil.move(
                os.path.join(I18N_DIRECTORY, pot_file),
                os.path.join(args.translations_path, pot_file),
            )

    # Updating PO files with sync_translations.py
    sync_translations_script_path = os.path.join(
        args.translations_path, "sync_translations.py"
    )
    if args.skip_sync:
        print("WARN: Skipping PO files merging with POT...")
    else:
        print("INFO: Running synchronization script")
        subprocess.run(["python3", sync_translations_script_path])

    # Parsing and Analyzing PO files
    print("INFO: Parsing PO files and counting missing translations")
    languages_directories = []
    for name in os.listdir(args.translations_path):
        folder_path = os.path.join(args.translations_path, name)
        if os.path.isdir(folder_path) and name not in [".git", "images"]:
            languages_directories.append(folder_path)

    translation_datas = []
    for language_directory in languages_directories:
        po_files = [os.path.join(language_directory, file) for file in glob.glob("*.po", root_dir=language_directory)]
        parsed_po_files = list(map(parse_po_file, po_files))
        data = TranslationsData(
            language_code=os.path.basename(language_directory),
            directory_path=language_directory,
            total_strings=0,
            missing_translations=0,
            fuzzy_translations=0,
        )

        # Iterating through PO files entries in order to count missing and fuzzy translations
        for po_file in parsed_po_files:
            data.total_strings += len(po_file.entries)
            for entry in po_file.entries:
                if entry.msgstr == "" and entry.msgid != "":
                    # Case 1 : entry has no translated string whereas it has an id value
                    data.missing_translations += 1
                elif entry.is_fuzzy:
                    # Case 2 : entry has a translation, but it is tagged as fuzzy by msgmerge
                    data.fuzzy_translations += 1

        if data.total_strings > 0:
            translation_datas.append(data)

    # Computing translations indicator values
    print("INFO: Computing completion indicator for each language.")

    # Sorting and Outputting results
    for data in sorted(
        translation_datas, key=lambda data: data.get_completion_rate(), reverse=True
    ):
        print(
            f"Language : {data.language_code} - translations are {data.get_completion_rate()}% complete, "
            f"including {data.fuzzy_translations} fuzzy and {data.missing_translations} missing translations."
        )

    languages_to_integrate = [
        data
        for data in translation_datas
        if data.get_completion_rate() >= args.threshold
    ]
    # Integrating translations in GD_Learn project
    if languages_to_integrate:
        print(
            f"INFO: Integrating languages with translations above {args.threshold}% complete."
        )
        for data in languages_to_integrate:
            print("Copying ", data.language_code)
            destination = os.path.join(I18N_DIRECTORY, data.language_code)
            if os.path.exists(destination):
                shutil.rmtree(destination)
            shutil.copytree(data.directory_path, destination)
    else:
        print("WARN: No language complete enough to be integrated.")


if __name__ == "__main__":
    main()
