#!/bin/bash
source /build/regex.sh
source /build/process.sh
source /build/properties.sh

DATE="$(date "+%F-%H:%M:%S")"
LOG_DATE_FORMAT="+%FT%H:%M:%S"
INPUT_FILE="${LOG_DIRECTORY}/input.log"
UPDATE_LOG_FILE="${LOG_DIRECTORY}/update.log"
SIMPLE_LOG_FILE="${LOG_DIRECTORY}/simple.log"
MAIN_LOG_FILE="${LOG_DIRECTORY}/FactoryGame.log"
PROCESS_ID_FILE="${INSTALL_DIRECTORY}/process.id"
PROCESS_STATUS_FILE="${INSTALL_DIRECTORY}/process.status"
UPDATE_SCRIPT="${INSTALL_DIRECTORY}/update.script"
START_SCRIPT="${INSTALL_DIRECTORY}/FactoryServer.sh"
SERVER_SCRIPT="${INSTALL_DIRECTORY}/Engine/Binaries/Linux/UE4Server-Linux-Shipping"

log() {
  su --login "${USERNAME}" --shell /bin/bash --command "echo '[$(date "${LOG_DATE_FORMAT}")] ${1}' >> '${SIMPLE_LOG_FILE}'"
}

getServerProcessId() {
  local id="$(cat "${PROCESS_ID_FILE}")"
  if [[ -z "${id}" || -z "$(ps --pid ${id} --no-headers)" ]]; then
    id=$(getProcess "${SERVER_SCRIPT}" 'FactoryGame')
    if [[ -n "${id}" ]]; then
      echo "${id}" > "${PROCESS_ID_FILE}"
    fi
  fi
  echo "${id}"
}

saveLogFiles() {
  if [[ -f "${INPUT_FILE}" ]]; then
    mv "${INPUT_FILE}" "${LOG_DIRECTORY}/$(head --lines=1 "${INPUT_FILE}")"
  fi
  if [[ -f "${UPDATE_LOG_FILE}" ]]; then
    mv "${UPDATE_LOG_FILE}" "${LOG_DIRECTORY}/$(head --lines=1 "${UPDATE_LOG_FILE}")"
  fi
  if [[ -f "${SIMPLE_LOG_FILE}" ]]; then
    mv "${SIMPLE_LOG_FILE}" "${LOG_DIRECTORY}/$(head --lines=1 "${SIMPLE_LOG_FILE}")"
  fi
}

createLogFiles() {
  saveLogFiles
  echo "input.${DATE}.log" > "${INPUT_FILE}"
  echo "update.${DATE}.log" > "${UPDATE_LOG_FILE}"
  echo "simple.${DATE}.log" > "${SIMPLE_LOG_FILE}"
}

updateUser() {
  if [[ -n "${PUID}" ]]; then
    usermod -u "${PUID}" "${USERNAME}"
  fi
  if [[ -n "${PGID}" ]]; then
    groupmod -g "${PGID}" "${USERGROUP}"
  fi
  chown "${USERNAME}":"${USERGROUP}" -R "${INSTALL_DIRECTORY}"
  chown "${USERNAME}":"${USERGROUP}" "${LOG_DIRECTORY}"
}

updateServer() {
  cd "${INSTALL_DIRECTORY}"
  if [[ "${AUTO_UPDATE}" == "true" ]]; then
    chmod 777 -R /tmp
    log "Updating Server"
    su --login "${USERNAME}" --shell /bin/bash --command "steamcmd +runscript '${UPDATE_SCRIPT}' >> '${UPDATE_LOG_FILE}'"
  fi
}

stopServer() {
  local id=''
  local waitTime=0;
  local maximumWaitTime=30

  echo "STOP" > "${PROCESS_STATUS_FILE}"

  id="$(getServerProcessId)"
  if [[ -n "${id}" ]]; then
    log "Server Shutting Down"
    stopProcess "${id}"
    for (( waitTime=0; waitTime<=${maximumWaitTime}; waitTime++ )); do
      if [[ -z "$(ps --pid ${id} --no-headers)" ]]; then
        break
      fi
      sleep 1
    done

    if [[ -n "$(ps --pid ${id} --no-headers)" ]]; then
      killProcess "${id}"
      for (( waitTime=0; waitTime<=${maximumWaitTime}; waitTime++ )); do
        if [[ -z "$(ps --pid ${id} --no-headers)" ]]; then
          break
        fi
        sleep 1
      done
    fi

    killProcess "$(getProcess 'tail' "${INPUT_FILE}")"
    killProcess "$(getProcess 'tail' "${MAIN_LOG_FILE}")"
    killProcess "$(getProcess "${START_SCRIPT}")"

    tail --pid=${id} --follow=descriptor /dev/null
  else
    id="$(getProcess 'steamcmd' "${UPDATE_SCRIPT}")"
    killProcess "${id}"
  fi
}

startServer() {
  local id=""

  echo "STARTED" > "${PROCESS_STATUS_FILE}"

  trap "{ log 'Quit Signal Received' ; stopServer ; }" SIGQUIT
  trap "{ log 'Abort Signal Received' ; stopServer ; }" SIGABRT
  trap "{ log 'Interrupt Signal Received' ; stopServer ; }" SIGINT
  trap "{ log 'Terminate Signal Received' ; stopServer ; }" SIGTERM

  createLogFiles
  updateUser
  if [[ "$(cat "${PROCESS_STATUS_FILE}")" == "STARTED" ]]; then
    updateServer
  fi

  if [[ "$(cat "${PROCESS_STATUS_FILE}")" == "STARTED" ]]; then
    log "Booting Server"
    su --login "${USERNAME}" --shell /bin/bash --command "tail --follow=name --retry --lines=0 '${INPUT_FILE}' | '${START_SCRIPT}' -ServerQueryPort=${PORT_SERVER_QUERY} -BeaconPort=${PORT_BEACON} -Port=${PORT_SERVER} -log -unattended" &
    sleep 10
    if [[ "$(cat "${PROCESS_STATUS_FILE}")" == "STARTED" ]]; then
      tail --pid=$(cat "$(getServerProcessId)") --follow=descriptor /dev/null
    else
      stopServer
    fi
  fi
  log "Server Shutdown"

  saveLogFiles

  trap - SIGQUIT SIGABRT SIGINT SIGTERM
}