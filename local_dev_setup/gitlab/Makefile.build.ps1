# Glab is a gitlab CLI application
# that relies on information based
# on the directory that it's in
task gitlab_auth {
  #get-content -path token.txt
  #glab auth login --stdin < token.txt
  glab auth --help
}
task auth_git_credential {

  $test = "glab auth git-credential [flags]"
  Write-Output $test
}

task auth_login {
  Write-Output @"
 The minimum required scopes for the token are: 'api', 'write_repository'.
"@

  $test = @"
  get-content -path token.txt

  glab auth login --stdin < token.txt
"@
  Write-Output $test
}

task auth_status {
  $test = "glab auth status [flags]"
  Write-Output $test
}

task check_update {
  $test = "glab check-update [flags]"
  Write-Output $test
}

task completion_setup {
  # See https://glab.readthedocs.io/en/latest/completion/index.html
}

task config {
  # https://glab.readthedocs.io/en/latest/config/index.html
}
task config_get {
  # https://glab.readthedocs.io/en/latest/config/index.html
}
task config_init {
  # https://glab.readthedocs.io/en/latest/config/index.html
}
task config_set {
  # https://glab.readthedocs.io/en/latest/config/index.html
}


task issue_board {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_close {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_create {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_delete {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_list {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_note {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_reopen {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_subscibe {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_unsubscibe {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_update {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task issue_view {
  # https://glab.readthedocs.io/en/latest/issue/index.html
}
task label_create {
  # https://glab.readthedocs.io/en/latest/label/index.html
}
task label_list {
  # https://glab.readthedocs.io/en/latest/label/index.html
}
task mr_approve {
}
task mr_approvers {
}
task mr_checkout {
}
task mr_close {
}
task mr_create {
}
task mr_delete {
}
task mr_diff {
}
task mr_for {
}
task mr_issues {
}
task mr_list {
}
task mr_merge {
}
task mr_note {
}
task mr_rebase {
}
task mr_reopen {
}
task mr_revoke {
}
task mr_subscribe {
}
task mr_todo {
}
task mr_unsubscribe {
}
task mr_update {
}
task mr_view {
}
task release_create {
}
task release_delete {
}
task release_download {
}
task release_list {
}
task release_upload {
}
task release_view {
}
task repo_archive {
}
task repo_clone {
}
task repo_contributors {
}
task repo_create {
}
task repo_delete {
}
task repo_fork {
}
task repo_mirror {
}
task repo_search {
}
task repo_view {
}
task pipeline_ci {
}

# Checks if .gitlab-ci.yml file if it's valid
task pipeline_ci_lint {
  glab pipeline ci lint
}
task pipeline_ci_trace {
  $test = @"
  glab pipeline ci trace <job-id>
  # -b <branch_string>
  # -R <OWNER/REPO or GROUP/NAMESPACE/REPO>
"@
  Write-Output $test
}
task pipeline_ci_view {
  $test = @"
  glab pipeline ci view
  glab pipeline ci view master
  glab pipeline ci view -b master
  glab pipeline ci view -b master -R profclems/glab
  # -b <branch_string>
  # -R <OWNER/REPO or GROUP/NAMESPACE/REPO>
"@
  Write-Output $test
}
task pipeline_delete {
}
task pipeline_list {
}
task pipeline_run {
}
task pipeline_status {
}
task version {
  glab version
}

task mr_view_help {
  glab mr view
}

task mr_note_help {
  glab mr note help
}

task issues_view_help {
  glab issues view
}

task issue_list {
  glab issue list
}

task pipeline_list {
  glab pipeline list
}

task release {
  glab release
}

task repo {
  glab repo
}

task label {
  glab label
}

task alias {
  glab alias --help
}
task alias_delete {
  $test = "glab alias delete <alias_name> [flags]"
  Write-Output $test
}
task alias_list {
  $test = "glab alias list [flags]"
  Write-Output $test
}
task alias_set {
  $test = "glab alias set <alias> '<command>' [flags]"
  Write-Output $test
}
task install_glab {
  scoop install glab
}

task update_glab {
  scoop update glab
}
