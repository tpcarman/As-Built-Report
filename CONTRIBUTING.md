# Contributing
Your input is welcome! Contributing to this project is as easy as:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Creating a new report

When contributing to this repository, please first discuss the change you wish to make via [issue](https://github.com/tpcarman/As-Built-Report/issues), or [direct message](https://powershell.slack.com/messages/D3MU9DP8S) in the [PowerShell Slack](https://powershell.slack.com) channel before making a change.

## Develop with Github
This project uses Github to host code, to track issues and feature requests, as well as accept pull requests.

## We use [Github Flow](https://guides.github.com/introduction/flow/index.html)
Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests.

### Creating quality pull requests
A good quality pull request will have the following characteristics:

- It will be a complete piece of work that adds value in some way.
- It will have a title that reflects the work within, and a summary that helps to understand the context of the change.
- There will be well written commit messages, with well crafted commits that tell the story of the development of this work.
- Ideally it will be small and easy to understand. Single commit PRs are usually easy to submit, review, and merge.
- The code contained within will meet the best practices set by the team wherever possible.

### Submitting pull requests
1. Fork this repository.
2. Add `https://github.com/tpcarman/As-Built-Report.git` as a remote named `upstream`.
    - `git remote add upstream https://github.com/tpcarman/As-Built-Report.git`
3. Create your feature branch from `dev`.
4. Work on your feature.
    - Update CHANGELOG.md with add / remove / change information
    - Update README.md with any new information, such as features, instructions, parameters and/or examples
5. Squash commits into one or two succinct commits.
    - `git rebase -i HEAD~n` # n being the number of previous commits to rebase
6. Ensure that your branch is up to date with `upstream/dev`.
    - `git checkout <branch>`
    - `git fetch upstream`
    - `git rebase upstream/dev`
7. Push branch to your fork.
    - `git push --force`
8. Open a Pull Request against the `dev` branch of this repository.

## Any contributions you make will be under the MIT Software License
In short, when you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report Issues and Bugs
[GitHub issues](https://github.com/tpcarman/As-Built-Report/issues) is used to track issues and bugs. Report a bug by opening a new issue, it's that easy!

## Submit bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Use a Consistent Coding Style
Code contributors should follow the [PowerShell Guidelines](https://github.com/PoshCode/PowerShellPracticeAndStyle) wherever possible to ensure scripts are consistent in style.

Use [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) to check code quality against PowerShell Best Practices.

### DO
- Use [\#requires](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-6) statements in all report scripts to ensure Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met.
- Use [PascalCasing](https://docs.microsoft.com/en-us/dotnet/standard/design-guidelines/capitalization-conventions) for all public member, type, and namespace names consisting of multiple words.
- Keep the number of required PowerShell modules to 2 per script.
- Use custom label headers within tables, where required, to make easily readable labels.
- Favour readability over brevity 

### DON'T
- Do not include code within report script to install or import PowerShell modules. Instead, use [\#requires](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-6) statements to ensure Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met.

## License
By contributing, you agree that your contributions will be licensed under its MIT License.
