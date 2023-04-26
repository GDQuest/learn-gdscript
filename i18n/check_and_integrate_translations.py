import os
import sys
import argparse
import subprocess
import shutil
from match_and_merge_po_translations import parse_po_file


def parse_command_line_arguments():
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
    return vars(parser.parse_args())


def main():
    args = parse_command_line_arguments()

    I18N_DIRECTORY = os.path.dirname(os.path.realpath(__file__))
    SOURCE_DIRECTORY = os.path.join(I18N_DIRECTORY, "..")

    if not args["skip_extract"]:
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
        pot_files = [
            file for file in os.listdir(I18N_DIRECTORY) if file.endswith(".pot")
        ]
        for pot_file in pot_files:
            shutil.move(
                os.path.join(I18N_DIRECTORY, pot_file),
                os.path.join(args["translations_path"], pot_file),
            )
    else:
        print("WARN: Skipping strings extraction and POT files generation...")

    # Updating PO files with sync_translations.py
    # TODO: remove chdir, update from here down
    os.chdir(args["translations_path"])
    source_dir = os.path.join(args["translations_path"], "source")
    if not args["skip_sync"]:
        print("INFO: Running synchronization script")
        subprocess.run(["python3", "sync_translations.py"])
    else:
        print("WARN: Skipping PO files merging with POT...")

    # Parsing and Analyzing PO files
    print("INFO: Parsing PO files and counting missing translations")
    languages_directories = [
        lan_dir.path
        for lan_dir in os.scandir()
        if lan_dir.is_dir() and lan_dir.path[:3] != "./."
    ]
    analysis_results = {}
    for lan_dir in languages_directories:
        po_files = [
            os.path.join(lan_dir, file)
            for file in os.listdir(lan_dir)
            if file.endswith(".po")
        ]
        parsed_po_files = list(map(parse_po_file, po_files))

        # Iterating through PO files entries in order to count missing and fuzzy translations
        missing_translations = 0
        fuzzy_translations = 0
        strings_number = 0
        for po_file in parsed_po_files:
            strings_number += len(po_file.entries)
            for entry in po_file.entries:
                if entry.msgstr == "" and entry.msgid != "":
                    # Case 1 : entry has no translated string whereas it has an id value
                    missing_translations += 1
                elif entry.is_fuzzy:
                    # Case 2 : entry has a translation, but it is tagged as fuzzy by msgmerge
                    fuzzy_translations += 1

        if strings_number > 0:
            analysis_results[lan_dir] = {
                "total": strings_number,
                "missings": missing_translations,
                "fuzzies": fuzzy_translations,
            }

    # Computing translations indicator values
    print("INFO: Computing completion indicator for each language.")
    languages_to_integrate = list()
    threshold = args["threshold"]
    for lang, results in analysis_results.items():
        results["completion"] = 100 - (100 * results["missings"] // results["total"])
        results["rework"] = (
            100 * results["fuzzies"] // (results["total"] - results["missings"])
        )
        if threshold is not None and results["completion"] >= threshold:
            languages_to_integrate.append(lang)

    # Sorting and Outputting results
    for lang, results in sorted(
        analysis_results.items(), key=lambda v: v[1]["completion"], reverse=True
    ):
        print(
            f"Language : {lang.upper()[2:]} - {results['completion']}% including {results['rework']}% fuzzy"
        )

    # Integrating translations in GD_Learn project
    if len(languages_to_integrate) > 0:
        print(f"INFO: Integrating languages above {threshold}%.")
        for lang in languages_to_integrate:
            print("Copying ", lang)
            dest = os.path.join(source_dir, "i18n", lang)
            if os.path.exists(dest):
                shutil.rmtree(dest)
            shutil.copytree(lang, dest)
    else:
        print("WARN: No language complete enough to be integrated.")


if __name__ == "__main__":
    main()
