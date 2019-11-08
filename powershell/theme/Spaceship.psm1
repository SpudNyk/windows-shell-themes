#requires -Version 2 -Modules posh-git

function Write-Theme {
    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )
    # write [time]
    $timeStamp = Get-Date -Format T
    $prompt = Write-Prompt "[$timeStamp]" -ForegroundColor $sl.Colors.TimeStampForegroundColor
    # write user
    $user = $sl.CurrentUser
    if (Test-NotDefaultUser($user)) {
        if ($sl.Sections.User) {
            $prompt += Write-Prompt -Object " $user" -ForegroundColor $sl.Colors.PromptHighlightColor
        }
        if ($sl.Sections.Computer) {
            # write at (devicename)
            $device = Get-ComputerName
            $prompt += Write-Prompt -Object " at" -ForegroundColor $sl.Colors.PromptForegroundColor
            $prompt += Write-Prompt -Object " $device" -ForegroundColor $sl.Colors.GitDefaultColor
        }
    }
    # write in for folder
    $prompt += Write-Prompt -Object " in" -ForegroundColor $sl.Colors.PromptForegroundColor
    # write folder (prefer trailing sep to indicate root on drive)
    $dir = if ($pwd.path -eq "$($pwd.Drive.Name):\") { "$($pwd.Drive.Name):$($sl.PromptSymbols.PathSeparator)" } else { Get-FullPath -dir $pwd }
    $prompt += Write-Prompt -Object " $dir " -ForegroundColor $sl.Colors.PromptForegroundColor
    # write on (git:branchname status)
    $status = Get-VCSStatus
    if ($status) {
        $themeInfo = Get-VcsInfo -status ($status)
        $prompt += Write-Prompt -Object 'on ' -ForegroundColor $sl.Colors.PromptForegroundColor
        $prompt += Write-Prompt -Object "$($themeInfo.VcInfo) " -ForegroundColor $themeInfo.BackgroundColor
    }
    # write virtualenv
    if ($sl.Sections.VirtualEnv -and (Test-VirtualEnv)) {
        $prompt += Write-Prompt -Object 'inside env:' -ForegroundColor $sl.Colors.PromptForegroundColor
        $prompt += Write-Prompt -Object "$(Get-VirtualEnvName) " -ForegroundColor $themeInfo.VirtualEnvForegroundColor
    }
    # check for elevated prompt
    If (Test-Administrator) {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.ElevatedSymbol) " -ForegroundColor $sl.Colors.AdminIconForegroundColor
    }
    # check the last command state and indicate if failed
    $foregroundColor = $sl.Colors.PromptHighlightColor
    If ($lastCommandFailed) {
        $foregroundColor = $sl.Colors.CommandFailedIconForegroundColor
    }

    if ($with) {
        $prompt += Write-Prompt -Object "$($with.ToUpper()) " -BackgroundColor $sl.Colors.WithBackgroundColor -ForegroundColor $sl.Colors.WithForegroundColor
    }

    $prompt += Set-Newline
    $prompt += Write-Prompt -Object $sl.PromptSymbols.PromptIndicator -ForegroundColor $foregroundColor
    $prompt += ' '
    $prompt
}

$sl = $global:ThemeSettings #local settings
$sl | Add-Member -NotePropertyName Sections -NotePropertyValue @{
    User       = $false
    Computer   = $false
    VirtualEnv = $false
}
$sl.PromptSymbols.StartSymbol = '#'
$sl.PromptSymbols.PromptIndicator = [char]::ConvertFromUtf32(0x279C)
$sl.Colors.TimeStampForegroundColor = [ConsoleColor]::Yellow
$sl.Colors.CommandFailedIconForegroundColor = [ConsoleColor]::Red
$sl.Colors.PromptHighlightColor = [ConsoleColor]::Green
$sl.Colors.PromptForegroundColor = [ConsoleColor]::Cyan
$sl.Colors.GitForegroundColor = [ConsoleColor]::Magenta
$sl.Colors.WithForegroundColor = [ConsoleColor]::DarkRed
$sl.Colors.WithBackgroundColor = [ConsoleColor]::Magenta
$sl.Colors.VirtualEnvForegroundColor = [ConsoleColor]::Red
