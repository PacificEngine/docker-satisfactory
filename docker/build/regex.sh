#!/bin/bash

# Usage: | regex [Expression]
# Usage: regex [Value] [Expression]
regex() {
  if [[ -z "${2}" && -p /dev/stdin ]]; then
    cat - | sed --regexp-extended --unbuffered "${1}"
  else
    echo "${1}" | sed --regexp-extended --unbuffered "${2}"
  fi
}

# Usage: | regexMultiline [Expression]
# Usage: regexMultiline [Value] [Expression]
regexMultiline() {
  if [[ -z "${2}" && -p /dev/stdin ]]; then
    cat - | tr --delete '\r' | tr '\n' '\r' | sed --regexp-extended --unbuffered "${1}" | tr '\r' '\n'
  else
    echo "${1}" | tr --delete '\r' | tr '\n' '\r' | sed --regexp-extended --unbuffered "${2}" | tr '\r' '\n'
  fi
}

# Usage: | regexReplace [Pattern] [Replacement]
# Usage: regexReplace [Value] [Pattern] [Replacement]
regexReplace() {
  if [[ -z "${3}" && -p /dev/stdin ]]; then
    cat - | regex "s/${1//\//\\/}/${2//\//\\/}/g"
  else
    regex "${1}" "s/${2//\//\\/}/${3//\//\\/}/g"
  fi
}

# Usage: | regexReplaceMultiline [Pattern] [Replacement]
# Usage: regexReplaceMultiline [Value] [Pattern] [Replacement]
regexReplaceMultiline() {
  if [[ -z "${3}" && -p /dev/stdin ]]; then
    cat - | regexMultiline "s/${1//\//\\/}/${2//\//\\/}/g"
  else
    regexMultiline "${1}" "s/${2//\//\\/}/${3//\//\\/}/g"
  fi
}

# Usage: | regexFind [Pattern]
# Usage: regexFind [Value] [Pattern]
regexFind() {
  if [[ -z "${2}" && -p /dev/stdin ]]; then
    cat - | grep --only-matching --extended-regexp --line-buffered "${1}"
  else
    echo "${1}" | grep --only-matching --extended-regexp --line-buffered "${2}"
  fi
}

# Usage: | regexFindMultiline [Pattern]
# Usage: regexFindMultiline [Value] [Pattern]
regexFindMultiline() {
  if [[ -z "${2}" && -p /dev/stdin ]]; then
    cat - | tr --delete '\r' | tr '\n' '\r' | grep --only-matching --extended-regexp --line-buffered "${1}" | tr '\r' '\n'
  else
    echo "${1}" | tr --delete '\r' | tr '\n' '\r' | grep --only-matching --extended-regexp --line-buffered "${2}" | tr '\r' '\n'
  fi
}

# Usage: | regexExtract [Pattern] [Group (Defaults: 0)]
# Usage: regexExtract [Value] [Pattern] [Group (Defaults: 0)]
regexExtract() {
  if [[ -z "${3}" && -p /dev/stdin ]]; then
    cat - | regexFind "${1}" | regexReplace "${1}" "\\${2:-0}"
  else
    regexFind "${1}" "${2}" | regexReplace "${2}" "\\${3:-0}"
  fi
}

# Usage: | regexExtractMultiline [Pattern] [Group (Defaults: 0)]
# Usage: regexExtractMultiline [Value] [Pattern] [Group (Defaults: 0)]
regexExtractMultiline() {
  if [[ -z "${3}" && -p /dev/stdin ]]; then
    cat - | tr --delete '\r' | tr '\n' '\r' | regexFind "${1}" | regexReplace "${1}" "\\${2:-0}" | tr '\r' '\n'
  else
    echo "${1}" | tr --delete '\r' | tr '\n' '\r' | regexFind "${2}" | regexReplace "${2}" "\\${3:-0}" | tr '\r' '\n'
  fi
}

# Usage: | regexCount [Pattern]
# Usage: regexCount [Value] [Pattern]
regexCount() {
  local value=""
  if [[ -z "${2}" && -p /dev/stdin ]]; then
    value="$(cat - | regexFind "${1}" | regexReplace "${1}" "1")"
  else
    value="$(regexFind "${1}" "${2}" | regexReplace "${2}" "1")"
  fi

  if [[ -n "${value}" ]]; then
    echo "${value}" | wc --lines
  else
    echo '0'
  fi
}

# Usage: | regexCountMultiline [Pattern]
# Usage: regexCountMultiline [Value] [Pattern]
regexCountMultiline() {
  local value=""
  if [[ -z "${2}" && -p /dev/stdin ]]; then
    value="$(cat - | tr --delete '\r' | tr '\n' '\r' | regexFind "${1}" | regexReplace "${1}" "1" | tr '\r' '\n')"
  else
    value="$(echo "${1}" | tr --delete '\r' | tr '\n' '\r' | regexFind "${2}" | regexReplace "${2}" "1" | tr '\r' '\n')"
  fi

  if [[ -n "${value}" ]]; then
    echo "${value}" | wc --lines
  else
    echo '0'
  fi
}

# Usage: | trim [Trim-Pattern (Defaults: \s)]
# Usage: trim [Value] [Trim-Pattern (Defaults: \s)]
trim() {
  if [[ -z "${2}" && -p /dev/stdin ]]; then
    cat - | regexReplaceMultiline "(^${1:-\s}+|${1:-\s}+$)" ""
  else
    regexReplaceMultiline "${1}" "(^${2:-\s}+|${2:-\s}+$)" ""
  fi
}