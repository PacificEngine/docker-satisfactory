#!/bin/bash

# Usage: getProcess [ProcessType] [RegEx]
getProcess() {
  local processesOfType=''
  local processesOfRegex=''
  local processList=''
  if [[ -z "${1}" ]]; then
    ps aux | perl /build/regex.pl --find ".*${2}.*" | awk '{print $2}' | perl /build/regex.pl --multiline --replace '\s+' ' ' | perl /build/regex.pl --multiline --trim
  else
    processesOfType="$(pidof "${1}")"
    processesOfRegex="$(ps aux | perl /build/regex.pl --find ".*${2}.*" | awk '{print $2}')"
    processList="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | perl /build/regex.pl --multiline --replace '\s+' '\n' | sort | uniq -d)"
    echo "${processList}" | perl /build/regex.pl --multiline --replace '\s+' ' ' | perl /build/regex.pl --multiline --trim
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