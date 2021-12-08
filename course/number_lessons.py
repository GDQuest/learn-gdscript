import re
import os

regex_lesson_heading = re.compile(r"### Lesson ?(\d+)?:(.+)")

this_directory = os.path.dirname(os.path.realpath(__file__))
readme_file = os.path.join(this_directory, "README.md")
output = []
with open(readme_file, "r") as f:
    index = 1
    for line in f.readlines():
        match = regex_lesson_heading.match(line)
        if not match:
            output.append(line)
        else:
            output.append(f"### Lesson {index}:{match.group(2)}\n")
            index += 1
with open(readme_file, "w") as f:
    f.writelines(output)
