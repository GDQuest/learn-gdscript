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
        lines += ["msgid " + self.msgid, "msgstr " + self.msgstr]
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
        return self.head + "\n\n".join([entry.as_string() for entry in self.entries])


def parse_po_file(filepath: str):
    """Parse one .pot or .po file and create a list of entries."""
    output = PoFile()
    output.filename = os.path.basename(filepath)

    content = []
    with open(filepath, "r") as po_file:
        content = po_file.read()

    head_end = content.find("\n\n")
    output.head = content[0:head_end]
    match = re.search(
        r'^"Language: (?P<language>\w+)\\n"', output.head, flags=re.MULTILINE
    )
    if match:
        output.language = match.group(1)

    current_entry = Entry()
    current_prop = ""
    for line in content[head_end:-1].split("\n"):
        if line == "":
            output.entries.append(current_entry)
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

    return output


def make_catalog(po_files: list[PoFile]):
    """Returns a map of source strings and corresponding translations in
    different languages."""

    print("Creating translation catalog...")

    output = {}
    skipped_count = 0
    count = 0
    file_count = 0

    for po_file in po_files:
        file_count += 1
        for entry in po_file.entries:
            if not entry.msgstr:
                continue

            count += 1
            if entry.msgid not in output:
                output[entry.msgid] = {}

            translated_lines = [line for line in entry.msgstr.split(r"\n") if line]
            source_lines = [line for line in entry.msgid.split(r"\n") if line]

            source_count, translated_count = len(source_lines), len(translated_lines)
            if source_count != translated_count:
                skipped_count += 1
                continue

            for index in range(len(source_lines)):
                line = source_lines[index]
                if not line:
                    continue
                if not line in output:
                    output[line] = {}
                output[line][po_file.language] = translated_lines[index]

    print("Number of po files processed: {}".format(file_count))
    print("Translation entries: {}".format(count))
    languages = set([f.language for f in po_files])
    print("{} languages: {}".format(len(languages), languages))
    print("Skipped entries: {}".format(skipped_count))
    return output


def main():
    args = parse(Args)
    for f in args.files:
        assert os.path.exists(f)

    po_files = list(map(parse_po_file, args.files))
    catalog = make_catalog(po_files)


def print_catalog_head(catalog):
    count = 0
    for msgid in catalog:
        if count > 5:
            break
        print(msgid)
        for lang in catalog[msgid]:
            print(catalog[msgid][lang])
        print("-------")
        count += 1


if __name__ == "__main__":
    main()
