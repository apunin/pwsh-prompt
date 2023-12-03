$downloadUrl="https://github.com/apunin/pwsh-prompt/raw/main/prompt.ps1"

$installDir=$HOME/.pwsh-prompt

New-Item -ItemType Directory -Force -Path $HOME/.pwsh-prompt

Invoke-WebRequest $downloadUrl -OutFile "$installDir/prompt.ps1"

$profileLine=". `$HOME/.pwsh-prompt/prompt.ps1"

if(! (Get-Content $profile).Contains("$profileLine") ) {
    "# pwsh-prompt`n$profileLine" | Append-Content $profile
}

. $profile
