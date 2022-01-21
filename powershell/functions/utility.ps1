Write-Output "
============================
Utility PS1 Functions Loaded
============================
"
function set_title_windows_terminal {
  param
  (
      [Parameter(Mandatory=$true)] $_title
  )
  $Host.UI.RawUI.WindowTitle = "${_title}"
}
function reload_functions_utility {
  . ${HOME}/code/dotfiles/powershell/functions/utility.ps1
  Write-Output "
  . `${HOME}/code/dotfiles/powershell/functions/utility.ps1
  "
}
function new_directory ($directory) {
  New-Item -Path $PWD -Name $directory -ItemType "Directory"
}

function getInstalledPackageGuid ($filter) {
  # get-wmiobject Win32_Product | Format-Table IdentifyingNumber, Name, LocalPackage -AutoSize
  (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall).Name | % { $path = "Registry::$_"; Get-ItemProperty $path } | Where-Object { $_.DisplayName -like $filter } | Select-Object -Property DisplayName, PsChildName

}

function which([string]$cmd) {
  gcm -ErrorAction "SilentlyContinue" $cmd | ft Definition
  # | Select-ColorString $cmd
}


function reload_shell {
  . $PROFILE
}
Set-Alias g -value gvim
function which($name) {
  Get-Command $name | Select-Object Definition
}

function rm-rf($item) {
  Remove-Item $item -Recurse -Force
}

function touch($file) {
  "" | Out-File $file -Encoding ASCII
}

function show_filelist {
  Get-ChildItem -Recurse | select FullName,Length | Format-Table -HideTableHeaders | Out-File filelist.txt
}

function now {
  Write-Output "====================================="
  Write-Output "The Current Date time is:"
  Get-Date
  Write-Output "====================================="
}

function ln_s_directory {
  param
  (
      [Parameter(Mandatory=$true)] $_link,
      [Parameter(Mandatory=$true)] $_source
  )
  Write-Output "Symbolic Link:"
  New-Item -Name $_link -ItemType Junction -Value $_source
}

function ln_s_file {
  param
  (
      [Parameter(Mandatory=$true)] $_link,
      [Parameter(Mandatory=$true)] $_source
  )
  # https://developer.amazon.com/docs/fire-app-builder/configure-windows-symlinks-no-admin-priv.html
  Write-Output "Your user has been added to security group to allow for symbolic links"
  Write-Output "Symbolic Link:"
  New-Item -Path $_link -ItemType SymbolicLink -Target $_source
}

function ultragrep {
  param
  (
      [Parameter(Mandatory=$true)] $_search_string
  )
  Write-Output "Ultragrep:"
  #New-Item -Name $_link -ItemType Junction -Value $_source
  # Get-ChildItem -Recurse | Select-String $_search_string | Select Path
  rg -n -w $_search_string
}

function tail ($file) {
  Get-Content -wait $file
}


Function Search-String
{
  # $PSHelp = "$PSHOME\en-US\*.txt"
  # Select-String -Path $PSHelp -Pattern 'About_'
}
function get_environment_variables {
  Get-ChildItem -Path Env:\
}
function set_google_api_key {
  $env:google_api_key = "AIzaSyD9bRuzvI5mzZxJATNLnxgnoreRQUO8sJ0"
}

function cat_helper {
  Write-Output "Try 'bat' instead 'cat'."
}


function Set {
  If (-Not $ARGS) {
    Get-ChildItem ENV: | Sort-Object Name
    Return
  }
  $myLine = $MYINVOCATION.Line
  $myName = $MYINVOCATION.InvocationName
  $myArgs = $myLine.Substring($myLine.IndexOf($myName) + $myName.Length + 1)
  $equalPos = $myArgs.IndexOf("=")

  # If the "=" character isn't found, output the variables.
  If ($equalPos -eq -1) {
    $result = Get-ChildItem ENV: | Where-Object { $_.Name -like "$myArgs" } | Sort-Object Name
    If ($result) { $result } Else { Throw "Environment variable not found" }
  }

  # If the "=" character is found before the end of the string, set the variable.

  ElseIf ($equalPos -lt $myArgs.Length - 1) {
    $varName = $myArgs.Substring(0, $equalPos)
    $varData = $myArgs.Substring($equalPos + 1)
    Set-Item ENV:$varName $varData
  }

  # If the "=" character is found at the end of the string, remove the variable.

  Else {
    $varName = $myArgs.Substring(0, $equalPos)
    If (Test-Path ENV:$varName) { Remove-Item ENV:$varName }
  }
}

# Color Helper
function Select-ColorString {
  <#
 .SYNOPSIS

 Find the matches in a given content by the pattern and write the matches in color like grep.

 .NOTES

 inspired by: https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/

 .EXAMPLE

 > 'aa bb cc', 'A line' | Select-ColorString a

 Both line 'aa bb cc' and line 'A line' are displayed as both contain "a" case insensitive.

 .EXAMPLE

 > 'aa bb cc', 'A line' | Select-ColorString a -NotMatch

 Nothing will be displayed as both lines have "a".

 .EXAMPLE

 > 'aa bb cc', 'A line' | Select-ColorString a -CaseSensitive

 Only line 'aa bb cc' is displayed with color on all occurrences of "a" case sensitive.

 .EXAMPLE

 > 'aa bb cc', 'A line' | Select-ColorString '(a)|(\sb)' -CaseSensitive -BackgroundColor White

 Only line 'aa bb cc' is displayed with background color White on all occurrences of regex '(a)|(\sb)' case sensitive.

 .EXAMPLE

 > 'aa bb cc', 'A line' | Select-ColorString b -KeepNotMatch

 Both line 'aa bb cc' and 'A line' are displayed with color on all occurrences of "b" case insensitive,
 and for lines without the keyword "b", they will be only displayed but without color.

 .EXAMPLE

 > Get-Content app.log -Wait -Tail 100 | Select-ColorString "error|warning|critical" -MultiColorsForSimplePattern -KeepNotMatch

 Search the 3 key words "error", "warning", and "critical" in the last 100 lines of the active file app.log and display the 3 key words in 3 colors.
 For lines without the keys words, hey will be only displayed but without color.

 .EXAMPLE

 > Get-Content "C:\Windows\Logs\DISM\dism.log" -Tail 100 -Wait | Select-ColorString win

 Find and color the keyword "win" in the last ongoing 100 lines of dism.log.

 .EXAMPLE

 > Get-WinEvent -FilterHashtable @{logname='System'; StartTime = (Get-Date).AddDays(-1)} | Select-Object time*,level*,message | Select-ColorString win

 Find and color the keyword "win" in the System event log from the last 24 hours.
 #>

 [Cmdletbinding(DefaultParametersetName = 'Match')]
 param(
     [Parameter(
         Position = 0)]
     [ValidateNotNullOrEmpty()]
     [String]$Pattern = $(throw "$($MyInvocation.MyCommand.Name) : " `
             + "Cannot bind null or empty value to the parameter `"Pattern`""),

     [Parameter(
         ValueFromPipeline = $true,
         HelpMessage = "String or list of string to be checked against the pattern")]
     [String[]]$Content,

     [Parameter()]
     [ValidateSet(
         'Black',
         'DarkBlue',
         'DarkGreen',
         'DarkCyan',
         'DarkRed',
         'DarkMagenta',
         'DarkYellow',
         'Gray',
         'DarkGray',
         'Blue',
         'Green',
         'Cyan',
         'Red',
         'Magenta',
         'Yellow',
         'White')]
     [String]$ForegroundColor = 'Black',

     [Parameter()]
     [ValidateSet(
         'Black',
         'DarkBlue',
         'DarkGreen',
         'DarkCyan',
         'DarkRed',
         'DarkMagenta',
         'DarkYellow',
         'Gray',
         'DarkGray',
         'Blue',
         'Green',
         'Cyan',
         'Red',
         'Magenta',
         'Yellow',
         'White')]
     [ValidateScript( {
             if ($Host.ui.RawUI.BackgroundColor -eq $_) {
                 throw "Current host background color is also set to `"$_`", " `
                     + "please choose another color for a better readability"
             }
             else {
                 return $true
             }
         })]
     [String]$BackgroundColor = 'Yellow',

     [Parameter()]
     [Switch]$CaseSensitive,

     [Parameter(
         HelpMessage = "Available only if the pattern is simple non-regex string " `
             + "separated by '|', use this switch with fast CPU.")]
     [Switch]$MultiColorsForSimplePattern,

     [Parameter(
         ParameterSetName = 'NotMatch',
         HelpMessage = "If true, write only not matching lines; " `
             + "if false, write only matching lines")]
     [Switch]$NotMatch,

     [Parameter(
         ParameterSetName = 'Match',
         HelpMessage = "If true, write all the lines; " `
             + "if false, write only matching lines")]
     [Switch]$KeepNotMatch
 )

 begin {
     $paramSelectString = @{
         Pattern       = $Pattern
         AllMatches    = $true
         CaseSensitive = $CaseSensitive
     }
     $writeNotMatch = $KeepNotMatch -or $NotMatch

     [System.Collections.ArrayList]$colorList =  [System.Enum]::GetValues([System.ConsoleColor])
     $currentBackgroundColor = $Host.ui.RawUI.BackgroundColor
     $colorList.Remove($currentBackgroundColor.ToString())
     $colorList.Remove($ForegroundColor)
     $colorList.Reverse()
     $colorCount = $colorList.Count

     if ($MultiColorsForSimplePattern) {
         # Get all the console foreground and background colors mapping display effet:
         # https://gist.github.com/timabell/cc9ca76964b59b2a54e91bda3665499e
         $patternToColorMapping = [Ordered]@{}
         # Available only if the pattern is a simple non-regex string separated by '|', use this with fast CPU.
         # We dont support regex as -Pattern for this switch as it will need much more CPU.
         # This switch is useful when you need to search some words,
         # for example searching "error|warn|crtical" these 3 words in a log file.
         $expectedMatches = $Pattern.split("|")
         $expectedMatchesCount = $expectedMatches.Count
         if ($expectedMatchesCount -ge $colorCount) {
             Write-Host "The switch -MultiColorsForSimplePattern is True, " `
                 + "but there're more patterns than the available colors number " `
                 + "which is $colorCount, so rotation color list will be used." `
                 -ForegroundColor Yellow
         }
         0..($expectedMatchesCount -1) | % {
             $patternToColorMapping.($expectedMatches[$_]) = $colorList[$_ % $colorCount]
         }

     }
 }

 process {
     foreach ($line in $Content) {
         $matchList = $line | Select-String @paramSelectString

         if (0 -lt $matchList.Count) {
             if (-not $NotMatch) {
                 $index = 0
                 foreach ($myMatch in $matchList.Matches) {
                     $length = $myMatch.Index - $index
                     Write-Host $line.Substring($index, $length) -NoNewline

                     $expectedBackgroupColor = $BackgroundColor
                     if ($MultiColorsForSimplePattern) {
                         $expectedBackgroupColor = $patternToColorMapping[$myMatch.Value]
                     }

                     $paramWriteHost = @{
                         Object          = $line.Substring($myMatch.Index, $myMatch.Length)
                         NoNewline       = $true
                         ForegroundColor = $ForegroundColor
                         BackgroundColor = $expectedBackgroupColor
                     }
                     Write-Host @paramWriteHost

                     $index = $myMatch.Index + $myMatch.Length
                 }
                 Write-Host $line.Substring($index)
             }
         }
         else {
             if ($writeNotMatch) {
                 Write-Host "$line"
             }
         }
     }
 }

 end {
 }
}

function helpFunctions {
  Write-Output "Functions that you probably use often"
  Write-Host "
    -----------------------------
    helpAbby
    addTodoAbby
    -----------------------------
    helpFilevine
    addTodoFilevine
    -----------------------------
    GoGitWork (_gcw)
    GoGitPersonal (_gcp)
    -----------------------------
    set-sshkeys-filevine
    set-sshkeys-abby
    -----------------------------
    which
    rm-rf
    touch
    g (gvim)
    git_log_one_line
    clean-git
    now
    -----------------------------
    help_filevine_powershell_piping_commands
    getInstalledPackageGuid
    ultragrep
    tail
    docker_list
    docker_logs
    docker_start
    docker_stop
    git_fp
    Search-String
    Select-ColorString
    get_environment_variables
    set_google_api_key
    Set
    -----------------------------
    aws_configservice_describe_compliance_by_config_rule
    aws_configservice_compliance_details_by_config_rules
    aws_configservice_describe_aggregate_compliance_by_config_rules
    aws_configservice_describe_config_rules
    aws_configservice_remadiation_exceptions
    -----------------------------
    aws_sso_signin
    aws_sso_configure
    install_aws_cli
    aws_turn_off_cli_auto_prompt
    aws_turn_on_cli_auto_prompt
    aws_view_config_and_credentials
    aws_find_ec2_by_name
    aws_ssm_start_session
    -----------------------------
    # Installed yaml validator via npm
    yaml-validator random_file.yml
    yamllint random_file.yml
    -----------------------------
    To Reload Profile
    . `$PROFILE
  "
}

function help_install_js_jsonlint () {
  npm install jsonlint -g
}

function lint_yaml ($_filename) {
  yamllint $_filename
}

function help_install_tflint () {
  # choco install tflint
  scoop install tflint
}

#function lint_terraform_docker_command () {
#  docker run --rm -v $(pwd):/data -t wata727/tflint
#}

function lint_terraform () {
  tflint
}

function lint_json ($_filename) {
  jsonlint $_filename
}

function help_install_ntop () {
  # https://github.com/gsass1/NTop
  scoop install ntop
}

function diff_compare_files () {
  param
  (
      [Parameter(Mandatory=$true)] $_file1,
      [Parameter(Mandatory=$true)] $_file2
  )
  diff (get-content ${_file1}) (get-content ${_file2})
  diff ${_file1} ${_file2}
}
function mv_to_not_ready () {
  param
  (
      [Parameter(Mandatory=$true)] $_file1
  )
  mv ${_file1} "${_file1}.not_ready" -Force
}
function mv_to_ready () {
  param
  (
      [Parameter(Mandatory=$true)] $_file1
  )
  mv ${_file1} ${_file1}.substring(0, ${_file1}.IndexOf("not_ready")) -Force
}

function helper_tools_to_install {
    Write-Output "
* https://github.com/ManrajGrover/organize-cli
* https://github.com/ddopson/underscore-cli
* https://github.com/nvbn/thefuck (linux)
* https://github.com/dthree/wat
* https://awesomeopensource.com/project/agarrharr/awesome-cli-apps
# * https://github.com/klaussinani/taskbook
"
}
function helper_name_of_task  {
  # param($file1, $file2)
    write-output "hello-world"
}

