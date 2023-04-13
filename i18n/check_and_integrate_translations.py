import os.path
from os import system
import sys
from getopt import getopt
from shutil import move


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
    opts, args = getopt(argv, "ht:c", ["help", "trans_path=", "completion_threshold="])
    opts_dict = {opt[0]: opt[1] for opt in opts}

    # Getting Translations Directory Path from options
    translations_path = ''
    if '-t' in opts_dict.keys():
        translations_path = opts_dict['-t']
    elif '--trans_path' in opts_dict.keys():
        translations_path = opts_dict['--trans_path']

    # Triggering Help message if translations path missing or help options present.
    if translations_path == '' or not os.path.exists(translations_path)\
            or len(opts) == 0 or '-h' in opts_dict.keys() or '--help' in opts_dict.keys():
        help_output()

    # Prevent execution from another directory than script source directory
    if not os.getcwd().endswith('learn-gdscript'):
        print("ERROR: This script should be executed from learn-gdscript project directory.")
        sys.exit()

    # Generating POT files from extract.py
    print("Extracting strings and generating POT files...")
    print(system("python3 i18n/extract.py"))

    # Moving POT files to translations project
    pot_files = [file for file in os.listdir('i18n') if file.endswith(".pot")]
    for pot_file in pot_files:
        move(os.path.join('i18n', pot_file), os.path.join(translations_path, pot_file))

    # Updating PO files with sync_translations.py
    os.chdir(translations_path)
    print("Running synchronization script")
    system("python3 sync_translations.py")

    # Parsing and Analyzing PO files

    # Computing translations indicator values

    # Integrating translations in GD_Learn project


if __name__ == "__main__":
    main(sys.argv[1:])
