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

    def as_string(self):
        return "\n".join([self.comment, "msgid " + self.msgid, "msgstr " + self.msgstr])


@dataclass
class PoFile:
    head: str = ""
    entries = []
    language: str = ""
    filename: str = ""

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
        r'^"Language: (?P<language>\w{2})\\n"', output.head, flags=re.MULTILINE
    )
    if match:
        output.language = match.group(1)

    current_entry = None
    current_prop = ""
    for line in content[head_end:-1].split("\n"):
        if line.startswith("#:"):
            current_entry = Entry()
            output.entries.append(current_entry)
            current_entry.comment = line
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
    output = {}
    for po_file in po_files:
        for entry in po_file.entries:
            if not entry.msgstr:
                continue

            if entry.msgid not in output:
                output[entry.msgid] = {}

            translated_lines = entry.msgstr.split(r"\n")
            source_lines = entry.msgid.split(r"\n")
            for index in range(len(source_lines)):
                line = source_lines[index]
                if not line:
                    continue
                if not line in output:
                    output[line] = {}
                output[line][po_file.language] = translated_lines[index]

    return output


def main():
    args = parse(Args)
    for f in args.files:
        assert os.path.exists(f)

    po_files = list(map(parse_po_file, args.files))
    catalog = make_catalog(po_files)
    # print_to_output(catalog)

def print_catalog(catalog):
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
