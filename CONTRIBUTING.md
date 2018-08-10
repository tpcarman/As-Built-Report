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
Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. Fork the repo and create your branch from `dev`.
2. Update CHANGELOG.md with add / remove / change information
3. Update README.md with any new information, such as features, instructions, parameters and/or examples
4. Write a clear and descriptive Commit message
5. Open a Pull Request

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

### DO
- Use [\#requires](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-6) statements in all report scripts to ensure Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met.
- 

### DON'T
- Do not include code within report script to install or import PowerShell modules. Instead, use [\#requires](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-6) statements to ensure Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met.

## License
By contributing, you agree that your contributions will be licensed under its MIT License.