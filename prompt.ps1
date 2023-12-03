function prompt{
    $exitStatus=$?
    $code=$global:LASTEXITCODE

    function wc{
        param($color, $message)

        return "$($PSStyle.Foreground.FromRgb($color))$message$($PSStyle.Reset)"
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
            Write-Host "$(wc 0xB48EAD "[$code]") " -NoNewLine
        } else {
            Write-Host "$(wc 0xB48EAD "[$([char]0xd7)]") " -NoNewLine
        }
    }
    $dir = "$($executionContext.SessionState.Path.CurrentLocation)"
    Write-Host "$(wc 0xBF616A $env:USERNAME)" -NoNewLine
    Write-Host " $(wc 0x81A1C1 $dir)" -NoNewLine

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

        Write-Host " $(wc 0x6C6C6C "$(git-icon) $([char]0xE0A0)$branch")" -NoNewLine

        if($ahead -and ($ahead -ne "0")){
            Write-Host " $(wc 0x88C0D0 "$([char]0x21e1)$ahead")" -NoNewLine
        }

        if($behind -and ($behind -ne "0")){
            Write-Host " $(wc 0x88C0D0 "$([char]0x21e3)$behind")" -NoNewLine
        }

        if((!$ahead -and !$behind) -or ("0" -in ($ahead,$behind))){
            Write-Host " $(wc 0x6C6C6C "$([char]0x2261)")" -NoNewLine
        }

        if($untracked -or $modified_w -or $deleted_w -or $added_i -or $modified_i -or $deleted_i){
            Write-Host " $(wc 0xFFAFD7 "*")" -NoNewLine
        }

        if($unmerged){
            Write-Host " $(wc 0x6C6C6C "$([char]0xd7)$unmerged")" -NoNewLine
        }

        if($untracked){
            Write-Host " $(wc 0x6C6C6C "?$untracked")" -NoNewLine
        }

        if($modified_w){
            Write-Host " $(wc 0x6C6C6C "~$modified_w")" -NoNewLine
        }

        if($deleted_w){
            Write-Host " $(wc 0x6C6C6C "-$deleted_w")" -NoNewLine
        }

        if(($untracked -or $modified_w -or $deleted_w) -and ($added_i -or $modified_i -or $deleted_i)){
            Write-Host " $(wc 0x6C6C6C "|")" -NoNewLine
        }

        if($added_i -or $modified_i -or $deleted_i){
            Write-Host " $(wc 0x6C6C6C "$([char]0xf046)")" -NoNewLine
        }

        if($added_i){
            Write-Host " $(wc 0x6C6C6C "+$added_i")" -NoNewLine
        }

        if($modified_i){
            Write-Host " $(wc 0x6C6C6C "~$modified_i")" -NoNewLine
        }

        if($deleted_i){
            Write-Host " $(wc 0x6C6C6C "-$deleted_i")" -NoNewLine
        }

        if($stash){
            Write-Host " $(wc 0x6C6C6C "$([char]0xf692) $stash")" -NoNewLine
        }
    }
    
    $history = @(Get-History)

    if($history.Count -gt 0){
        $lastItem = $history[$history.Count-1]
        if($lastItem.Duration.TotalMilliseconds -gt 1){
            Write-Host " $(wc 0xA3BE8C "$($lastItem.Duration.ToString("d\d\ hh\h\ mm\m\ ss\.fff\s").TrimStart(' ','d','h','m','s','0'))")" -NoNewLine
        }
    }
        
    Write-Host

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    if (Test-Path variable:/PSDebugContext) { Write-Host '(DBG)' -NoNewLine }
    elseif($principal.IsInRole($adminRole)) { Write-Host "(ADMIN)" -NoNewLine }

    Write-Host "$(wc 0xBF616A $("$([char]0x276f)" * ($nestedPromptLevel + 1)))" -NoNewLine

    # make sure PSReadLine knows if we have a multiline prompt
    Set-PSReadLineOption -ExtraPromptLineCount 1

    $global:LASTEXITCODE=$code
    return " "
}
