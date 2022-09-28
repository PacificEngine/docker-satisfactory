#!/bin/bash
# /server/properties.sh
source /server/regex.sh

propertyFile=/server/properties

getProperty() {
	local property="${1}"; shift
	local propertyLength="$((${#property} + 1))"
	local line="$(cat "${propertyFile}" | grep "${property}")"
	echo "${line:$propertyLength}" | regex --trim
}