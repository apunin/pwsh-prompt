$downloadUrl="https://github.com/apunin/pwsh-prompt/raw/main/prompt.ps1"

$installDir="$($HOME)/.pwsh-prompt"

New-Item -ItemType Directory -Force -Path "$installDir" >$null
New-Item -ItemType Directory -Force -Path "$([System.IO.Path]::GetDirectoryName("$profile"))" >$null

Invoke-WebRequest "$downloadUrl" -OutFile "$installDir/prompt.ps1"

$profileLine=". ""`$(`$HOME)/.pwsh-prompt/prompt.ps1"""

$installed = "$(Get-Content $profile)".Contains("$profileLine") 2>$null
if(! $installed) {
    "`n# pwsh-prompt`n$profileLine`n`n" | Add-Content "$profile"
}
