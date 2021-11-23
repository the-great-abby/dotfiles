Install-Module InvokeBuild -Force -Scope CurrentUser

#Install-Module posh-git -Scope CurrentUser -Force
#Install-Module oh-my-posh -Scope CurrentUser -Force
# This is needed because I believe I'm using powershell core
Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck

#Import-Module posh-git
#Import-Module oh-my-posh
#Set-Theme Paradox
