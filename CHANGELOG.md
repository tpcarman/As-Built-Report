# New-AsBuiltReport Changelog

## 0.2.0
### What's New
- New As-Built JSON configuration structure
  - new `AsBuiltConfigPath` parameter
  - allows unique configuration files to be created and saved
  - if `AsBuiltConfigPath` parameter is not specified, user is prompted for As Built report configuration information
  - `New-AsBuiltConfig.ps1` & `Config.json` files are no longer required 