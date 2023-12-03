$downloadUrl="https://github.com/apunin/pwsh-prompt/raw/main/prompt.ps1"

$installDir="$($HOME)/.pwsh-prompt"

New-Item -ItemType Directory -Force -Path "$installDir" >$null

Invoke-WebRequest "$downloadUrl" -OutFile "$installDir/prompt.ps1"

$profileLine=". ""`$(`$HOME)/.pwsh-prompt/prompt.ps1"""

if(! (Get-Content $profile).Contains("$profileLine") ) {
    "`n# pwsh-prompt`n$profileLine" | Add-Content $profile
}
