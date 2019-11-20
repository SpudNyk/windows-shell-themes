#requires -Version 2 -Modules posh-git

function Format-Elapsed {
    param(
        [timespan]
        $elapsed
    )
    $seconds = [math]::Round($elapsed.TotalSeconds)
    $minutes = [math]::Floor($seconds / 60)
    $hours = [math]::Floor($minutes / 60)
    if ($hours -gt 0) {
        $minutes = $minutes % 60
        $seconds = $seconds % 60
        return "${hours}h${minutes}m${seconds}s"
    }
    if ($minutes -gt 0) {
        $seconds = $seconds % 60
        return "${minutes}m${seconds}s"
    }
    return "${seconds}s"
}

function Format-GitStatus {
    param(
        [Object]
        $status
    )
    if ($status) {
        # Determine Colors
        $localChanges = ($status.HasIndex -or $status.HasUntracked -or $status.HasWorking)
        #Git flags
        $localChanges = $localChanges -or (($status.Untracked -gt 0) -or ($status.Added -gt 0) -or ($status.Modified -gt 0) -or ($status.Deleted -gt 0) -or ($status.Renamed -gt 0))
        #hg/svn flags

        $branchStatusSymbol = $null

        if ($status.BehindBy -eq 0 -and $status.AheadBy -eq 0) {
            # We are aligned with remote
            $branchStatusSymbol = $null
        }
        elseif ($status.BehindBy -ge 1 -and $status.AheadBy -ge 1) {
            # We are both behind and ahead of remote
            $branchStatusSymbol = $sl.GitSymbols.BranchDivergedSymbol
        }
        elseif ($status.BehindBy -ge 1) {
            # We are behind remote
            $branchStatusSymbol = $sl.GitSymbols.BranchBehindStatusSymbol
        }
        elseif ($status.AheadBy -ge 1) {
            # We are ahead of remote
            $branchStatusSymbol = $sl.GitSymbols.BranchAheadStatusSymbol
        }

        $result = ""
        if ($branchStatusSymbol) {
            $result += $branchStatusSymbol
        }

        # We have changes
        $added = $false
        $untracked = $false
        $modified = $false
        $deleted = $false
        $unmerged = $false

        if ($status.HasIndex) {
            $added = $added -or ($status.Index.Added.Count -gt 0)
            $modified = $modified -or ($status.Index.Modified.Count -gt 0)
            $deleted = $deleted -or ($status.Index.Deleted.Count -gt 0)
            $unmerged = $unmerged -or ($status.Index.Unmerged.Count -gt 0)
        }

        if ($status.HasWorking) {
            $untracked = $untracked -or ($status.Working.Added -gt 0)
            $modified = $modified -or ($status.Working.Modified.Count -gt 0)
            $deleted = $deleted -or ($status.Working.Deleted.Count -gt 0)
            $unmerged = $unmerged -or ($status.Working.Unmerged.Count -gt 0)
        }
        
        if ($unmerged) {
            $result += $sl.GitSymbols.UnmergedSymbol
        }

        if ($status.StashCount -gt 0) {
            $result += $sl.GitSymbols.StashSymbol
        }

        if ($deleted) {
            $result += $sl.GitSymbols.DeletedSymbol
        }

        if ($modified) {
            $result += $sl.GitSymbols.ModifiedSymbol
        }

        if ($added) {
            $result += $sl.GitSymbols.AddedSymbol
        }

        if ($untracked) {
            $result += $sl.GitSymbols.BranchUntrackedSymbol
        }

        $result
    }
}

function Write-Theme {
    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )
    $prompt = ""
    if ($sl.Sections.TimeStamp) {
        # write timestamp
        $timeStamp = Get-Date -Format $sl.TimeStampFormat
        $prompt += Write-Prompt "$timeStamp" -ForegroundColor $sl.Colors.TimeStampForegroundColor
    }
    
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

    if ($sl.Sections.Path) {
        # write in for folder
        $prompt += Write-Prompt -Object " in" -ForegroundColor $sl.Colors.PromptForegroundColor
        # write folder (prefer trailing sep to indicate root on drive)
        $dir = if ($pwd.path -eq "$($pwd.Drive.Name):\") { "$($pwd.Drive.Name):$($sl.PromptSymbols.PathSeparator)" } else { Get-FullPath -dir $pwd }
        $prompt += Write-Prompt -Object " $dir " -ForegroundColor $sl.Colors.PathForegroundColor
    }

    if ($sl.Sections.GitBranch -or $sl.Sections.GitStatus) {
        # write on (git:branchname status)
        $status = Get-VCSStatus
        if ($status) {
            $showBranch = $sl.Sections.GitBranch -and $status.Branch
            if ($showBranch) {
                $prompt += Write-Prompt -Object 'on ' -ForegroundColor $sl.Colors.PromptForegroundColor
                $prompt += Write-Prompt -Object "$($sl.GitSymbols.BranchSymbol) $($status.Branch) " -ForegroundColor $sl.Colors.GitBranchForegroundColor
            }

            if ($sl.Sections.GitStatus) {
                $statusText = Format-GitStatus $status
                if ($statusText) {
                    $prompt += Write-Prompt -Object "$($sl.GitSymbols.StatusPrefixSymbol)$($statusText)$($sl.GitSymbols.StatusSuffixSymbol) " -ForegroundColor $sl.Colors.GitStatusForegroundColor
                }
            }
        }
    }

    # write virtualenv
    if ($sl.Sections.VirtualEnv -and (Test-VirtualEnv)) {
        $prompt += Write-Prompt -Object 'inside env:' -ForegroundColor $sl.Colors.PromptForegroundColor
        $prompt += Write-Prompt -Object "$(Get-VirtualEnvName) " -ForegroundColor $sl.Colors.VirtualEnvForegroundColor
    }
    
    # write execution time
    if ($sl.Sections.ExecutionTime) {
        $history = Get-History
        if ($history) {
            $lastCommand = $history[-1]
            # don't show for already displayed
            if ($sl.ExecutionTime.LastCommandId -ne $lastCommand.Id) {
                $sl.ExecutionTime.LastCommandId = $lastCommand.id
                $elapsed = $lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime
                if ($elapsed.TotalSeconds -ge $sl.ExecutionTime.MinimumSeconds) {
                    $prompt += Write-Prompt -Object 'took ' -ForegroundColor $sl.Colors.PromptForegroundColor
                    $prompt += Write-Prompt -Object "$(Format-Elapsed($elapsed))" -ForegroundColor $sl.Colors.ExecutionTimeForegroundColor
                }
            }
        }
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
    TimeStamp     = $true
    User          = $false
    Computer      = $false
    Path          = $true
    GitBranch     = $true
    GitStatus     = $true
    VirtualEnv    = $false
    ExecutionTime = $true
}
$sl | Add-Member -NotePropertyName ExecutionTime -NotePropertyValue @{
    MinimumSeconds = 2
    LastCommandId  = 0
}
$sl | Add-Member -NotePropertyName TimeStampFormat -NotePropertyValue "HH:mm:ss"

$sl.PromptSymbols.StartSymbol = '#'
$sl.PromptSymbols.PromptIndicator = [char]::ConvertFromUtf32(0x2192)
$sl.GitSymbols.StatusPrefixSymbol = "["
$sl.GitSymbols.StatusSuffixSymbol = "]"
$sl.GitSymbols.BranchSymbol = [char]::ConvertFromUtf32(0xE0A0)
$sl.GitSymbols.BranchUntrackedSymbol = "!"
$sl.GitSymbols.BranchAheadStatusSymbol = "⇡"
$sl.GitSymbols.BranchBehindStatusSymbol = "⇣"
$sl.GitSymbols.BranchDivergedSymbol = "⇕"
$sl.GitSymbols.ModifiedSymbol = "~"
$sl.GitSymbols.DeletedSymbol = "-"
$sl.GitSymbols.AddedSymbol = "+"
$sl.GitSymbols.UnmergedSymbol = "≠"
$sl.GitSymbols.StashSymbol = "$"
$sl.Colors.TimeStampForegroundColor = [ConsoleColor]::Yellow
$sl.Colors.ExecutionTimeForegroundColor = [ConsoleColor]::Yellow
$sl.Colors.CommandFailedIconForegroundColor = [ConsoleColor]::Red
$sl.Colors.PathForegroundColor = [ConsoleColor]::Cyan
$sl.Colors.PromptHighlightColor = [ConsoleColor]::Green
$sl.Colors.PromptForegroundColor = [ConsoleColor]::Gray
$sl.Colors.GitBranchForegroundColor = [ConsoleColor]::Magenta
$sl.Colors.GitStatusForegroundColor = [ConsoleColor]::Red
$sl.Colors.WithForegroundColor = [ConsoleColor]::DarkRed
$sl.Colors.WithBackgroundColor = [ConsoleColor]::Magenta
$sl.Colors.VirtualEnvForegroundColor = [ConsoleColor]::Red

if (Get-Module PSReadline) {
    $PSReadLineOptions = @{
        # Wanted to Use "… " but PSReadline does not support it
        # Something to do with unicode roundtriping
        ContinuationPrompt = "$([char]::ConvertFromUtf32(0x00bb)) "
        Colors             = @{
            "ContinuationPrompt" = [ConsoleColor]::DarkGray
            "Command"            = [ConsoleColor]::White
            "Comment"            = [ConsoleColor]::DarkGreen
            "Number"             = [ConsoleColor]::Green
            "Member"             = [ConsoleColor]::Cyan
            "Operator"           = [ConsoleColor]::Cyan
            "Type"               = [ConsoleColor]::DarkGreen
            "String"             = [ConsoleColor]::DarkRed
            "Variable"           = [ConsoleColor]::Cyan
            "Parameter"          = [ConsoleColor]::DarkGreen
            "Default"            = [ConsoleColor]::White
            "Error"              = [ConsoleColor]::Red
            "Selection"          = [ConsoleColor]::Yellow
            "Keyword"            = [ConsoleColor]::Blue
        }
    }
    if ($(Get-Module PSReadline).Version.Major -ge 2) {
        Set-PSReadLineOption @PSReadLineOptions
    }
    else {
        # Handle PSReadline < 2
        Set-PSReadLineOption -ContinuationPrompt $PSReadLineOptions.ContinuationPrompt -ContinuationPromptForegroundColor $PSReadLineOptions.Colors.ContinuationPrompt
        # Set all the valid values for older PSReadline
        $colors = $PSReadLineOptions.Colors
        foreach ($token in ("None", "Comment", "Keyword", "String", "Operator", "Variable", "Command", "Parameter", "Type", "Number", "Member")) {
            if ($colors.ContainsKey($token)) {
                Set-PSReadlineOption -TokenKind $token -ForegroundColor $colors[$token]
            }
        }
    }
}