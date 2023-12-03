
function prompt{
    $exitStatus=$?
    $code=$global:LASTEXITCODE

    $PwshPromptStatus=0x6C6C6C
    $PwshPromptPath=0x81A1C1
    $PwshPromptAccent=0x88C0D0
    $PwshPromptDuration=0xA3BE8C
    $PwshPromptExitCode=0xB48EAD
    $PwshPromptUsername=0xBF616A
    $PwshPromptHighlight=0xFFAFD7

    $PwshPromptAnsiStatus = [System.ConsoleColor]::DarkGray
    $PwshPromptAnsiPath = [System.ConsoleColor]::DarkBlue
    $PwshPromptAnsiAccent = [System.ConsoleColor]::DarkCyan
    $PwshPromptAnsiDuration = [System.ConsoleColor]::DarkGreen
    $PwshPromptAnsiExitCode = [System.ConsoleColor]::Red
    $PwshPromptAnsiUsername = [System.ConsoleColor]::DarkRed
    $PwshPromptAnsiHighlight = [System.ConsoleColor]::DarkMagenta


    enum PwshPromptColor {
        Status = 0
        Path
        Accent
        Duration
        ExitCode
        Username
        Highlight
    }

    $colors = @($PwshPromptStatus,$PwshPromptPath,$PwshPromptAccent,$PwshPromptDuration,$PwshPromptExitCode,$PwshPromptUsername,$PwshPromptHighlight)
    $ansiColors = @($PwshPromptAnsiStatus,$PwshPromptAnsiPath,$PwshPromptAnsiAccent,$PwshPromptAnsiDuration,$PwshPromptAnsiExitCode,$PwshPromptAnsiUsername,$PwshPromptAnsiHighlight)
    $AnsiColor = @(30, 34, 32, 36, 31, 35, 33, 37, 90, 94, 92, 96, 91, 95, 93, 97)
    $EscChar = [char]27
    $AnsiFormat = "$EscChar[{0}m{1}$EscChar[{2}m"

    function wc{
        param([PwshPromptColor]$color, $message)
        
        if($Host.UI.SupportsVirtualTerminal){
            if($PSStyle.Foreground -eq $null) { 
                return "$($AnsiFormat -f $AnsiColor[[int]$ansiColors[[int]$color]], $message, 39)"
            }
            return "$($PSStyle.Foreground.FromRgb($colors[[int]$color]))$message$($PSStyle.Reset)"
        } else {
            return "$message"
        }
    }

    function git-icon {
        $url=$(git ls-remote --get-url)
        if(! $?) {return "$([char]0xe702)"}

        if($url.Contains("gitea")) { return "$([char]0xf339)" }
        if($url.Contains("gitlab")) { return "$([char]0xF296)" }
        if($url.Contains("github")) { return "$([char]0xF408)" }
        if($url.Contains("azure")) { return "$([char]0xEBE8)" }
        if($url.Contains("bitbucket")) { return "$([char]0xF171)" }
        if($url.Contains("codecommit")) { return "$([char]0xF270)" }

        return "$([char]0xe702)"
    }

    if( ! $exitStatus ){
        if( $code ) {
            Write-Host "$(wc ExitCode "[$code]") " -NoNewLine
        } else {
            Write-Host "$(wc ExitCode "[$([char]0xd7)]") " -NoNewLine
        }
    }
    $dir = "$($executionContext.SessionState.Path.CurrentLocation)"
    Write-Host "$(wc Username $env:USERNAME)" -NoNewLine
    Write-Host " $(wc Path $dir)" -NoNewLine

    $gs = git status -s -b --ahead-behind --show-stash --porcelain=v2 2>$null
    if($?){
        $unmerged=0
        $untracked=0
        $modified_i=0
        $modified_w=0
        $added_i=0
        $deleted_i=0
        $deleted_w=0
        $gs | % {
            $line = $_
            if($line.StartsWith("# branch.head ")) {
                $branch = $line.Substring(14)
            }
            elseif($line.StartsWith("# branch.upstream ")) {
                $upstream = $line.Substring(18)
            }
            elseif($line.StartsWith("# branch.ab ")) {
                $ahead  = $line | select-string -pattern  "\+(\d+)" | %{ $_.Matches[0].Groups[1].Value }
                $behind = $line | select-string -pattern "\-(\d+)" | %{ $_.Matches[0].Groups[1].Value }
            }
            elseif($line.StartsWith("# stash ")){
                $stash = $line.Substring(8)
            }
            elseif($line[0] -eq "u"){
                $unmerged++
            }
            elseif(($line[0] -eq "1") -or ($line[0] -eq "2")){
                if($line[5] -eq "N"){
                    $ix = $line[2]
                    $wt = $line[3]

                    if($ix -eq "A") { $added_i++ }
                    if($ix -eq "D") { $deleted_i++ }
                    if($ix -in ("M","T","R","C")) { $modified_i++ }

                    if($wt -eq "D") { $deleted_w++ }
                    if($wt -in ("M","T","R","C")) { $modified_w++ }
                }
            }
            elseif ($line.StartsWith("?")) { 
                $untracked++ 
            }
        }

        Write-Host " $(wc Status "$(git-icon) $([char]0xE0A0)$branch")" -NoNewLine

        if($ahead -and ($ahead -ne "0")){
            Write-Host " $(wc Accent "$([char]0x21e1)$ahead")" -NoNewLine
        }

        if($behind -and ($behind -ne "0")){
            Write-Host " $(wc Accent "$([char]0x21e3)$behind")" -NoNewLine
        }

        if((!$ahead -and !$behind) -or ("0" -in ($ahead,$behind))){
            Write-Host " $(wc Status "$([char]0x2261)")" -NoNewLine
        }

        if($untracked -or $modified_w -or $deleted_w -or $added_i -or $modified_i -or $deleted_i){
            Write-Host " $(wc Highlight "*")" -NoNewLine
        }

        if($unmerged){
            Write-Host " $(wc Status "$([char]0xd7)$unmerged")" -NoNewLine
        }

        if($untracked){
            Write-Host " $(wc Status "?$untracked")" -NoNewLine
        }

        if($modified_w){
            Write-Host " $(wc Status "~$modified_w")" -NoNewLine
        }

        if($deleted_w){
            Write-Host " $(wc Status "-$deleted_w")" -NoNewLine
        }

        if(($untracked -or $modified_w -or $deleted_w) -and ($added_i -or $modified_i -or $deleted_i)){
            Write-Host " $(wc Status "|")" -NoNewLine
        }

        if($added_i -or $modified_i -or $deleted_i){
            Write-Host " $(wc Status "$([char]0xf046)")" -NoNewLine
        }

        if($added_i){
            Write-Host " $(wc Status "+$added_i")" -NoNewLine
        }

        if($modified_i){
            Write-Host " $(wc Status "~$modified_i")" -NoNewLine
        }

        if($deleted_i){
            Write-Host " $(wc Status "-$deleted_i")" -NoNewLine
        }

        if($stash){
            Write-Host " $(wc Status "$([char]0xf692) $stash")" -NoNewLine
        }
    }
    
    $history = @(Get-History)

    if($history.Count -gt 0){
        $lastItem = $history[$history.Count-1]
        if($lastItem.Duration.TotalMilliseconds -gt 1){
            Write-Host " $(wc Duration "$($lastItem.Duration.ToString("d\d\ hh\h\ mm\m\ ss\.fff\s").TrimStart(' ','d','h','m','s','0'))")" -NoNewLine
        }
    }
        
    Write-Host

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    if (Test-Path variable:/PSDebugContext) { Write-Host '(DBG)' -NoNewLine }
    elseif($principal.IsInRole($adminRole)) { Write-Host "(ADMIN)" -NoNewLine }

    Write-Host "$(wc Username $("$([char]0x276f)" * ($nestedPromptLevel + 1)))" -NoNewLine

    # make sure PSReadLine knows if we have a multiline prompt
    Set-PSReadLineOption -ExtraPromptLineCount 1

    $global:LASTEXITCODE=$code
    return " "
}
