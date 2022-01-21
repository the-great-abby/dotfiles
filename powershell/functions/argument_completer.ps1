# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
    git complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -Native -CommandName terraform -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
    terraform complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
    aws complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


function reload_functions_argumentCompleter {
  . ${HOME}/code/dotfiles/powershell/functions/argument_completer.ps1
}
