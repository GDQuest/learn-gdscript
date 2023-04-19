from typing import List

import os
import csv
from babel.messages import extract
from babel.messages import Catalog
from babel.messages import pofile

PROJECT = "Learn GDScript From Zero"
VERSION = " "
COPYRIGHT_HOLDER = "GDQuest"
BUGS_ADDRESS = "https://github.com/GDQuest/learn-gdscript"


def extract_application_messages() -> None:
    print("Reading application messages...")

    globs_map = [
        ("resources/**/**.gd", "python"),
        ("ui/**/**.gd", "python"),
        ("ui/**/**.tscn", "godot_scene"),
    ]
    options_map = {
        "resources/**/**.gd": {"encoding": "utf-8"},
        "ui/**/**.gd": {"encoding": "utf-8"},
        "ui/**/**.tscn": {"encoding": "utf-8"},
    }

    keywords = {
        # Properties stored in scenes.
        "Label/text": None,
        "Button/text": None,
        "RichTextLabel/bbcode_text": None,
        "LineEdit/placeholder_text": None,
        "title": None,
        # Code-based translated strings
        "tr": None,
    }

    extract_babel_and_write(
        globs_map=globs_map,
        options_map=options_map,
        keywords=keywords,
        output_file="./i18n/application.pot",
    )


def extract_course_messages() -> None:
    lessons_directory = "./course"
    for filename in os.listdir(lessons_directory):
        full_path = os.path.join(lessons_directory, filename)
        if filename.startswith("lesson-") and os.path.isdir(full_path):
            extract_lesson_messages(lesson=filename)


def extract_lesson_messages(lesson: str) -> None:
    print(
        "Reading lesson messages from '" + "course/" + lesson + "/lesson.tres" + "'..."
    )

    globs_map = [
        ("course/" + lesson + "/lesson.tres", "godot_resource"),
    ]
    options_map = {
        "course/" + lesson + "/lesson.tres": {"encoding": "utf-8"},
    }

    keywords = {
        # Content blocks.
        "Resource/title": None,
        "Resource/text": None,
        # Quizzes.
        "Resource/question": None,
        "Resource/hint": None,
        "Resource/content_bbcode": None,
        "Resource/explanation_bbcode": None,
        "Resource/valid_answer": None,
        "Resource/answer_options": None,
        "Resource/valid_answers": None,
        # Practices.
        "Resource/goal": None,
        "Resource/description": None,
        "Resource/hints": None,
    }

    extract_babel_and_write(
        globs_map=globs_map,
        options_map=options_map,
        keywords=keywords,
        output_file="./i18n/" + lesson + ".pot",
    )


def extract_babel_and_write(
    globs_map,
    options_map,
    keywords,
    output_file: str,
) -> None:

    print("  Starting extraction...")
    catalog = Catalog(
        project=PROJECT,
        version=VERSION,
        copyright_holder=COPYRIGHT_HOLDER,
        msgid_bugs_address=BUGS_ADDRESS,
    )

    extractor = extract.extract_from_dir(
        dirname=".",
        method_map=globs_map,
        options_map=options_map,
        keywords=keywords,
        comment_tags=(),
        callback=_log_extraction_file,
        strip_comment_tags=False,
    )

    # (filename, lineno, message, comments, context)
    for message in extractor:
        message_id = message[2]
        message_id = message_id.replace("\r\n", "\n")

        catalog.add(
            id=message_id,
            string="",
            locations=[(message[0], message[1])],
            auto_comments=message[3],
            context=message[4],
        )

    with open(output_file, "wb") as file:
        pofile.write_po(
            fileobj=file,
            catalog=catalog,
        )

    print("  Finished extraction.")


def extract_error_database() -> None:
    print("Reading error database messages...")

    extracted_fields = [
        "error_explanation",
        "error_suggestion",
    ]

    extract_csv_and_write(
        source_file="./script_checking/error_database.csv",
        extract_fields=extracted_fields,
        reference_field="error_code",
        output_file="./i18n/error_database.pot",
    )


def extract_classref_database() -> None:
    print("Reading classref database messages...")

    extracted_fields = [
        "explanation",
    ]

    extract_csv_and_write(
        source_file="./course/documentation.csv",
        extract_fields=extracted_fields,
        reference_field="identifier",
        output_file="./i18n/classref_database.pot",
    )


def extract_glossary_database() -> None:
    print("Reading glossary database messages...")

    extracted_fields = [
        "term",
        "optional_plural_form",
        "explanation",
    ]

    extract_csv_and_write(
        source_file="./course/glossary.csv",
        extract_fields=extracted_fields,
        reference_field="term",
        output_file="./i18n/glossary_database.pot",
    )


def extract_csv_and_write(
    source_file: str,
    extract_fields: List[str],
    reference_field: str,
    output_file: str,
) -> None:

    print("  Starting extraction...")
    catalog = Catalog(
        project=PROJECT,
        version=VERSION,
        copyright_holder=COPYRIGHT_HOLDER,
        msgid_bugs_address=BUGS_ADDRESS,
    )

    with open(source_file, "r", newline="") as cvsfile:
        reader = csv.DictReader(
            cvsfile, delimiter=",", quotechar='"', skipinitialspace=True
        )

        for row in reader:
            for field_name in extract_fields:
                message_id = row[field_name]
                if not message_id:
                    continue

                message_id = message_id.replace("\r\n", "\n")

                catalog.add(
                    id=message_id,
                    string="",
                    locations=[(source_file, reader.line_num)],
                    auto_comments=["Reference: " + row[reference_field]],
                    context=None,
                )

    with open(output_file, "wb") as file:
        pofile.write_po(
            fileobj=file,
            catalog=catalog,
        )

    print("  Finished extraction.")


def _log_extraction_file(filename, method, options):
    print("  Extracting from file '" + filename + "'")


def main():
    extract_application_messages()
    extract_course_messages()
    extract_error_database()
    extract_classref_database()
    extract_glossary_database()


if __name__ == "__main__":
    main()
