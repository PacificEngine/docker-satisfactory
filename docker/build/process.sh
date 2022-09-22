#!/bin/bash
source /build/regex.sh

# Usage: getProcess [ProcessType] [RegEx]
getProcess() {
  local processesOfType=''
  local processesOfRegex=''
  local processList=''
  if [[ -z "${1}" ]]; then
    ps aux | regexFind ".*${2}.*" | awk '{print $2}' | regexReplaceMultiline '\s+' ' ' | trim
  else
    processesOfType="$(pidof "${1}")"
    processesOfRegex="$(ps aux | regexFind ".*${2}.*" | awk '{print $2}')"
    processList="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | regexReplace '\s+' '\n' | sort | uniq -d)"
    echo "${processList}" | regexReplaceMultiline '\s+' ' ' | trim
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