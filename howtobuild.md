Pushing to Github will build artifacts using Github Actions.

Pushing to itch.io will only happen for the `release` and `staging` branches.

Github releases will only happen if the commit has a tag.

Pushing to Github pages will happen when the `web` version of the project is built (which should happen on every run). Pushes to `release` will build in the root of the `gh-pages` branch, while pushes to other branches will build to a subfolder named after the branch.