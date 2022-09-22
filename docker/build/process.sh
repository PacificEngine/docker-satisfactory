#!/bin/bash
source /build/regex.sh

# Usage: getProcess [ProcessType] [RegEx]
getProcess() {
	local processesOfType="$(pidof "${1}")"
	local processesOfRegex="$(ps aux | regexFind ".*${2}.*" | awk '{print $2}')"

	local processList="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | regexReplace ' ' '\n' | sort | uniq -d)"
	echo "$(echo ${processList} | regexReplace '\s+' ' ')"
}

# Usage: stopProcess [ProcessList]
stopProcess() {
	if [ -n "${1}" ]; then
		kill ${1}
	fi
}

# Usage: killProcess [ProcessList]
killProcess() {
	if [ -n "${1}" ]; then
		kill -9 ${1}
	fi
}