"""Parse .pot and .po files with different string splits and matches already
translated strings."""
from dataclasses import dataclass
from enum import Enum
import os
import re
from datargs import parse, arg
from typing import Sequence


@dataclass
class Args:
    """Command-line arguments."""

    files: Sequence[str] = arg(
        positional=True,
        default=tuple(),
        help="List of paths to .po or .pot files to parse.",
    )
    output_directory: str = arg(
        default="dist",
        help="Directory to write .po files to.",
    )


class PropertyType(Enum):
    MSGID = 0
    MSGSTR = 1
    COMMENT = 2


@dataclass
class Entry:
    comment: str = ""
    msgid: str = ""
    msgstr: str = ""
    reference: str = ""
    is_fuzzy: bool = False
    is_python_format: bool = False

    def as_string(self):
        lines = [self.comment]
        if self.is_fuzzy:
            lines.append("#, fuzzy")
        if self.is_python_format:
            lines.append("#, python-format")
        if self.reference:
            lines.append(self.reference)
        lines += ['msgid "' + self.msgid + '"', 'msgstr "' + self.msgstr + '"']
        return "\n".join(lines)


@dataclass
class PoFile:
    head: str = ""
    entries = []
    language: str = ""
    filename: str = ""

    def __init__(self):
        self.entries = []

    def as_string(self):
        return (
            self.head + "\n" + "\n".join([entry.as_string() for entry in self.entries])
        )


def parse_po_file(filepath: str):
    """Parse one .pot or .po file and create a list of entries."""
    new_files = PoFile()
    new_files.filename = os.path.basename(filepath)

    content = []
    with open(filepath, "r") as po_file:
        content = po_file.read()

    head_end = content.find("\n\n")
    new_files.head = content[0:head_end]
    match = re.search(
        r'^"Language: (?P<language>\w+)\\n"', new_files.head, flags=re.MULTILINE
    )
    if match:
        new_files.language = match.group(1)

    current_entry = Entry()
    current_prop = ""
    for line in content[head_end:-1].split("\n"):
        if line == "":
            new_files.entries.append(current_entry)
            current_entry = Entry()
        elif line.startswith("#:"):
            current_entry.comment = line
        elif line.startswith("#,"):
            current_entry.is_fuzzy = "fuzzy" in line
            current_entry.is_python_format = "python-format" in line
        elif line.startswith("#."):
            current_entry.reference = line
        elif line.startswith("msgid"):
            current_prop = PropertyType.MSGID
        elif line.startswith("msgstr"):
            current_prop = PropertyType.MSGSTR
        elif line.strip() == "":
            current_prop = ""

        if current_prop:
            match = re.search(r'"(.*)"', line)
            if match and match.group(1):
                if current_prop == PropertyType.MSGID:
                    current_entry.msgid += match.group(1)
                elif current_prop == PropertyType.MSGSTR:
                    current_entry.msgstr += match.group(1)

    return new_files


def split_translations(po_files: list[PoFile]):
    """Returns a map of source strings and corresponding translations in
    different languages."""

    print("Creating new translation files with split entries...")

    new_files = []

    count = 0
    file_count = 0

    for po_file in po_files:
        new_file = PoFile()
        new_file.filename = po_file.filename
        new_file.language = po_file.language
        new_file.head = po_file.head
        new_files.append(new_file)
        file_count += 1

        # Workaround an issue where the same translation line may appear twice
        # in a document.
        split_strings = set()
        for entry in po_file.entries:

            translated_lines = [line for line in entry.msgstr.split(r"\n") if line]
            source_lines = [line for line in entry.msgid.split(r"\n") if line]

            source_count, translated_count = len(source_lines), len(translated_lines)
            count += source_count

            if source_count != translated_count:
                for msgid in source_lines:
                    entry = Entry()
                    entry.msgid = msgid
                    new_file.entries.append(entry)
            else:
                for index in range(len(source_lines)):
                    msgid = source_lines[index]
                    if msgid in split_strings:
                        continue

                    entry = Entry()
                    entry.msgid = msgid
                    entry.msgstr = translated_lines[index]
                    new_file.entries.append(entry)
                    split_strings.add(msgid)

    print("Number of po files processed: {}".format(file_count))
    print("Created translation entries: {}".format(count))
    return new_files


def main():
    args = parse(Args)
    for f in args.files:
        assert os.path.exists(f)

    po_files = list(map(parse_po_file, args.files))
    new_files = split_translations(po_files)

    languages = set([f.language for f in po_files])
    print("{} languages: {}".format(len(languages), languages))

    for language in languages:
        language_directory = os.path.join(args.output_directory, language)
        if not os.path.exists(language_directory):
            os.makedirs(language_directory)

    print("Writing new translation files to ", os.path.abspath(args.output_directory))
    for f in new_files:
        output_path = os.path.join(args.output_directory, f.language, f.filename)
        with open(output_path, "w") as output_file:
            output_file.write(f.as_string())


if __name__ == "__main__":
    main()
