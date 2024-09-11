#!/bin/bash
# /server/process.sh
source /server/regex.sh

# Usage: getProcess [ProcessType] [RegEx]
getProcess() {
  local processesOfType=''
  local processesOfRegex=''
  local processList=''
  if [[ -z "${1}" ]]; then
    ps aux | regex --find ".*${2}.*" | awk '{print $2}' | regex --multiline --find '\s+' --replace ' ' --trim
  else
    processesOfType="$(pidof "${1}")"
    processesOfRegex="$(ps aux | regex --find ".*${2}.*" | awk '{print $2}')"
    processList="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | regex --find '\s+' --replace '\n' | sort | uniq -d)"
    echo "${processList}" | regex --multiline --find '\s+' --replace ' ' --trim
  fi
}

# Usage: stopProcess [ProcessList]
stopProcess() {
  if [[ -n "${1}" ]]; then
    kill ${1}
  fi
}

# Usage: killProcess [ProcessList]
killProcess() {
  if [[ -n "${1}" ]]; then
    kill -9 ${1}
  fi
}