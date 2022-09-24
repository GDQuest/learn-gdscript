"""Parse .pot and .po files with different string splits and matches already
translated strings."""
from dataclasses import dataclass
from enum import Enum
import re


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
    head = ""
    entries = []
    language = ""

    def as_string(self):
        return self.head + "\n\n".join([entry.as_string() for entry in self.entries])


def parse(filepath: str):
    """Parse one .pot or .po file and create a list of entries."""
    output = PoFile()

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
            output[entry.msgid][po_file.language] = entry.msgstr
    return output


def main():
    test = parse(
        "/home/gdquest/Repositories/learn-gdscript-translations/es/application.po"
    )
    catalog = make_catalog([test])
    print(catalog)


if __name__ == "__main__":
    main()
