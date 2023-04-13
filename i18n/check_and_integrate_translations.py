import os.path
from os import system
import sys
from getopt import getopt
from shutil import move
from match_and_merge_po_translations import parse_po_file


def help_output():
    """
    Displays the script help message and exit process.
    """
    print("Usage 1: check_and_integrate_translations.py [-T] TRANSLATIONS_TARGET")
    print("Usage 2: check_and_integrate_translations.py [-T] TRANSLATIONS_TARGET [-C] 95")
    print("""This script performs text extraction from the application and move generated POT files in the translations 
    project in order to compare with translations source and output a translation completion indicator for each 
    language.
    Usage 2: The script will then automatically integrate translations files with a completion above given value, 95% in
     the given example""")
    sys.exit()


def main(argv):
    # Recovering options and arguments from command line
    opts, args = getopt(argv, "ht:c:ES", ["help", "trans_path=", "completion_threshold=", "skip-extract", "skip-sync"])
    opts_dict = {opt[0]: opt[1] for opt in opts}

    # Getting Translations Directory Path from options
    translations_path = ''
    if '-t' in opts_dict.keys():
        translations_path = opts_dict['-t']
    elif '--trans_path' in opts_dict.keys():
        translations_path = opts_dict['--trans_path']

    # Getting Threshold value from options
    if '-c' in opts_dict.keys():
        try:
            threshold = int(opts_dict["-c"])
        except ValueError:
            print("WARN: Incorrect Threshold value. Script will proceed without languages integration.")
            threshold = None
    elif '--completion_threshold' in opts_dict.keys():
        try:
            threshold = int(opts_dict["--completion_threshold"])
        except ValueError:
            print("WARN: Incorrect Threshold value. Script will proceed without languages integration.")
            threshold = None
    else:
        print("WARN: Missing Threshold value. Script will proceed without languages integration.")
        threshold = None

    # Triggering Help message if translations path missing or help options present.
    if translations_path == '' or not os.path.exists(translations_path)\
            or len(opts) == 0 or '-h' in opts_dict.keys() or '--help' in opts_dict.keys():
        help_output()

    # Prevent execution from another directory than script source directory
    if not os.getcwd().endswith('learn-gdscript'):
        sys.exit("ERROR: This script should be executed from learn-gdscript project directory.")

    # Generating POT files from extract.py
    extract_result = -1
    if not ('-E' in opts_dict.keys() or '--skip-extract' in opts_dict.keys()):
        print("INFO: Extracting strings and generating POT files...")
        extract_result = system("python3 i18n/extract.py")

        if extract_result:
            sys.exit("ERROR: Extraction scripts ended with errors")

        # Moving POT files to translations project
        print("INFO: Moving POT files to translations folder")
        pot_files = [file for file in os.listdir('i18n') if file.endswith(".pot")]
        for pot_file in pot_files:
            move(os.path.join('i18n', pot_file), os.path.join(translations_path, pot_file))
    else:
        print("WARN: Skipping strings extraction and POT files generation...")

    # Updating PO files with sync_translations.py
    os.chdir(translations_path)
    if not ('-S' in opts_dict.keys() or '--skip-sync' in opts_dict.keys()):
        print("INFO: Running synchronization script")
        system("python3 sync_translations.py")
    else:
        print("WARN: Skipping PO files merging with POT...")

    # Parsing and Analyzing PO files
    print("INFO: Parsing PO files in ")
    languages_directories = [lan_dir.path for lan_dir in os.scandir() if lan_dir.is_dir() and lan_dir.path[:3] != './.']
    analysis_results = {}

    for lan_dir in languages_directories:
        po_files = [os.path.join(lan_dir, file) for file in os.listdir(lan_dir) if file.endswith(".po")]
        parsed_po_files = list(map(parse_po_file, po_files))

        # Iterating through PO files entries in order to count missing and fuzzy translations
        missing_translations = 0
        fuzzy_translations = 0
        strings_number = 0
        for po_file in parsed_po_files:
            strings_number += len(po_file.entries)
            for entry in po_file.entries:
                if entry.msgstr == '' and entry.msgid != '':
                    # Case 1 : entry has no translated string whereas it has an id value
                    missing_translations += 1
                elif entry.is_fuzzy:
                    # Case 2 : entry has a translation, but it is tagged as fuzzy by msgmerge
                    fuzzy_translations += 1

        if strings_number > 0:
            analysis_results[lan_dir] = {"total": strings_number,
                                         "missings": missing_translations,
                                         "fuzzies": fuzzy_translations}

    # Computing translations indicator values
    print("INFO: Computing completion indicator for each language.")
    languages_to_integrate = list()
    for lang, results in analysis_results.items():
        results["completion"] = 100 - (100 * results["missings"] // results["total"])
        results["rework"] = 100 * results['fuzzies'] // results['total']
        if threshold is not None and results["completion"] >= threshold:
            languages_to_integrate.append(lang)

    # Sorting and Outputting results
    for lang, results in sorted(analysis_results.items(), key=lambda v: v[1]["completion"], reverse=True):
        print(f"Language : {lang.upper()[2:]} - {results['completion']}% including {results['rework']}% fuzzy")

    # Integrating translations in GD_Learn project
    if len(languages_to_integrate) > 0:
        print(f"INFO: Integrating languages above {threshold}%.")
        for lang in languages_to_integrate:
            print("Copying ", lang)
    else:
        print("WARN: No language complete enough to be integrated.")


if __name__ == "__main__":
    main(sys.argv[1:])
