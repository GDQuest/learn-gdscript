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


# for each #: comment
# map each src string lines to translation string
# strip explicit \n from each line


def make_catalog(po_files: list[PoFile]):
    """Returns a map of source strings and corresponding translations in
    different languages."""
    return {}


def main():
    test = parse(
        "/home/gdquest/Repositories/learn-gdscript-translations/es/application.po"
    )
    print(test.entries[0])


if __name__ == "__main__":
    main()
