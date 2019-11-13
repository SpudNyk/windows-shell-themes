# Themes for ConEmu

This contains themes for ConEmu in the format used by [ConEmu Color Themes](https://github.com/joonro/ConEmu-Color-Themes).


## Themes

 - `monokai-pro.xml` This is a port of the Monokai Pro theme from OS X terminal.

## Installation

The install script is taken from [ConEmu Color Themes](https://github.com/joonro/ConEmu-Color-Themes)

- Use `Install-ConEmuTheme.ps1` PowerShell script. First, the script will always create
  a backup of your config file as `ConEmu.backup.xml` prior to doing anything else. It's
  got two operation modes:

  1. To add a theme to your config file:
     ```ps1
          .\Install-ConEmuTheme.ps1 [-ConfigPath Path] -Operation Add -ThemePathOrName themes\oceans16-dark.xml
     ```
  2. To remove a theme from your config file:
     ```ps1
          .\Install-ConEmuTheme.ps1 [-ConfigPath Path] -Operation Remove -ThemePathOrName "Oceans16 Dark"
     ```

- Note that `ConfigPath` argument is optional if your `ConEmu.xml` is located
  at the default location `C:\Users\You\AppData\Roaming\ConEmu.xml`.
