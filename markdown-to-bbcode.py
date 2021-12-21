import argparse
import os
import re

regex_bold = re.compile(r" \*\*(.*?)\*\*")
regex_italics = re.compile(r" [\*_](.*?)[\*_]")
regex_code = re.compile(r" (?!``)`(.+?)`")
regex_url = re.compile(r"\[(.*?)\]\((.*?)\)")
regex_strike = re.compile(r"~~(.*?)~~")
regex_heading = re.compile(r"^#+\s+(.*)", re.MULTILINE)
regex_html_comments = re.compile(r"\n?<!--.*?-->\n?", re.DOTALL)

regex_map = {
    regex_bold: r" [b]\1[/b]",
    regex_italics: r" [i]\1[/i]",
    regex_code: r" [code]\1[/code]",
    regex_url: r"[url=\2]\1[/url]",
    regex_strike: r"[s]\1[/s]",
    regex_heading: r"[font=res://ui/theme/fonts/font_title.tres]\1[/font]"
}


def parse_args():
    parser = argparse.ArgumentParser(description="Convert Markdown to BBCode")
    parser.add_argument("files", help="Input files", nargs="+")
    parser.add_argument("-i", "--in-place", help="If true, modify the files in place.")
    return parser.parse_args()


def main():
    args = parse_args()
    files = [f for f in args.files if f.endswith(".md") and os.path.isfile(f)]
    for f in files:
        with open(f, "r") as fh:
            text = fh.read()
            for regex, replacement in regex_map.items():
                text = regex.sub(replacement, text)
            text = regex_html_comments.sub("", text)
            if args.in_place:
                with open(f, "w") as fh:
                    fh.write(text)
            else:
                print(text)

if __name__ == "__main__":
    main()
