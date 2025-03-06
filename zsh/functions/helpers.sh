function help_helpers_todo {
  echo "0: $0"
  echo "hello $1"
}
function kill_port_proc {
  lsof -i tcp:"$1" | grep LISTEN | awk '{print $2}'
}
if [ -f ~/.zsh/zshalias ]; then
  source ~/.zsh/zshalias
else
  print "404: ~/.zsh/zshalias not found."
fi

function removeCurrentDayEntry {

  local today=$(date +"%Y-%m-%d")
  local file="$SECOND_BRAIN"'/daily_notes/'$(date +"%Y-%m-%d").md
  ls $file
  rm $file
}
function htmlEscape() {
  local s
  s=${1//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  s=${s//'"'/&quot;}
  printf -- %s "$s"
}

# shellcheck shell=bash
## BEGIN DOTNET CONFIG
function _dotnet_bash_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}" IFS=$'\n' # On Windows you may need to use use IFS=$'\r\n'
  local candidates

  read -d '' -ra candidates < <(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null | dos2unix)
  read -d '' -ra COMPREPLY < <(compgen -W "${candidates[*]:-}" -- "$cur" | dos2unix)
}

complete -f -F _dotnet_bash_complete dotnet
## END DOTNET CONFIG

## BEGIN GO CONFIG
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
## END GO CONFIG

## BEGIN CUSTOM AWS AND KUBECTL BEHAVIOR
if type -p kubectl >/dev/null; then
  # shellcheck source=/dev/null
  source <(kubectl completion bash)
  complete -o default -F __start_kubectl k
fi
export KUBECONFIG=~/.kube/config

function kn() {
  local _new_namespace="${1}"
  if [[ -z "${_new_namespace}" ]]; then
    local -r _current_namespace="$(kubectl config view --minify | grep namespace | awk '{print $2}')"
    _new_namespace="$(echo -e "${_current_namespace:-"default"}\n$(kubectl get namespaces -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep -v "${_current_namespace:-"default"}" | sort -u)" | fzf)"
    kubectl config view --minify | grep namespace | cut -d" " -f6
  fi
  if [[ -n "${_new_namespace}" && ! "${_new_namespace}" =~ ^- ]]; then
    kubectl config set-context --current --namespace "${_new_namespace}"
  fi
  echo "[INFO] Current context: $(kubectl config current-context)"
  echo "[INFO] Current namespace: $(kubectl config view --minify | grep namespace | cut -d" " -f6)"
}

function kx() {
  local _new_context="${1}"
  if [[ -z "${_new_context}" ]]; then
    _current_context="$(kubectl config current-context)"
    _new_context="$(echo -e "${_current_context}\n$(kubectl config get-contexts -o name | grep -v "${_current_context}" | sort -u)" | fzf)"
  fi
  if [[ -n "${_new_context}" && ! "${_new_context}" =~ ^- ]]; then
    kubectl config use-context "${_new_context}"
  fi
  echo "[INFO] Current context: $(kubectl config current-context)"
  echo "[INFO] Current namespace: $(kubectl config view --minify | grep namespace | cut -d" " -f6)"
}

export AWS_PROFILE_DEFINITION="${HOME}/.aws_profile"
touch "${AWS_PROFILE_DEFINITION}"

function aws-profile() {
  # shellcheck source=/dev/null
  source "${AWS_PROFILE_DEFINITION}"
  local -r _profile=${1:-$(echo -e "${AWS_PROFILE:-"default"}\n$(/usr/local/bin/aws configure list-profiles | sort -u)" | fzf)}
  if [[ -n "${_profile}" ]]; then
    export AWS_PROFILE="${_profile}"
    echo "AWS_PROFILE=${_profile}" >"${AWS_PROFILE_DEFINITION}"
    echo "[INFO] AWS_PROFILE set to ${_profile}"
  fi
}

function eks-connect() {
  # shellcheck source=/dev/null
  source "${AWS_PROFILE_DEFINITION}"
  ALL_CLUSTERS="false"
  if [[ "${1}" == "--all" ]]; then
    ALL_CLUSTERS="true"
    shift
  fi
  local -r _profile=${1:-$(echo -e "${AWS_PROFILE:-"default"}\n$(/usr/local/bin/aws configure list-profiles | grep 'administrator-access' | sort -u)" | fzf)}
  if [[ -n "${_profile}" ]]; then
    export AWS_PROFILE="${_profile}"
    echo "AWS_PROFILE=${_profile}" >"${AWS_PROFILE_DEFINITION}"
    local -r _tmp_file=$(mktemp)
    /usr/local/bin/aws eks list-clusters --output json | jq -r '.clusters[]' >"${_tmp_file}"
    local -r _cluster_count=$(wc -l <"${_tmp_file}")
    local _clusters=""
    if [[ "${_cluster_count}" -eq 1 || "${ALL_CLUSTERS}" == "true" ]]; then
      _clusters=$(cat "${_tmp_file}")
    else
      _clusters=$(fzf <"${_tmp_file}")
    fi
    rm -f "${_tmp_file}"
    for _cluster in ${_clusters}; do
      /usr/local/bin/aws eks update-kubeconfig --name "${_cluster}"
    done
  fi
}

# function to add --profile to aws commands if not already present based on ~/.aws_profile
function aws() {
  if [[ "$*" != *" --profile "* ]]; then
    # shellcheck source=/dev/null
    source "${AWS_PROFILE_DEFINITION}"
    local -r _profile="${AWS_PROFILE:-"team_provider"}"
    command /opt/homebrew/bin/aws --profile "${_profile}" "$@"
  else
    command /opt/homebrew/bin/aws "$@"
  fi
}

function helm() {
  if [[ -z "${KUBECONFIG}" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
  fi
  if [[ ! -f "${KUBECONFIG}" ]]; then
    echo "[ERROR] KUBECONFIG file not found at ${KUBECONFIG}"
    return 1
  fi
  chmod 600 "${KUBECONFIG}"
  command /usr/local/bin/helm "$@"
}

function current-context() {
  echo "KUBECONFIG: ${KUBECONFIG}"
  echo "Current context: $(kubectl config current-context)"
  echo "Current namespace: $(kubectl config view --minify | grep namespace | cut -d" " -f6)"
  # shellcheck source=/dev/null
  source "${AWS_PROFILE_DEFINITION}"
  echo "AWS_PROFILE: ${AWS_PROFILE:-"default"}"
}

## END CUSTOM AWS AND KUBECTL BEHAVIOR
