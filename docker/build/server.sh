#!/bin/bash
source /build/regex.sh
source /build/process.sh
source /build/properties.sh

DATE="$(date "+%F-%H:%M:%S")"
LOG_DATE_FORMAT="+%FT%H:%M:%S"
INPUT_FILE="${LOG_DIRECTORY}/input.log"
UPDATE_FILE="${LOG_DIRECTORY}/update.log"
LOG_FILE="${LOG_DIRECTORY}/simple.log"
PROCESS_ID_FILE="${INSTALL_DIRECTORY}/process.id"
UPDATE_SCRIPT="${INSTALL_DIRECTORY}/update.script"
START_SCRIPT="${INSTALL_DIRECTORY}/FactoryServer.sh"
SERVER_SCRIPT="${INSTALL_DIRECTORY}/Engine/Binaries/Linux/UE4Server-Linux-Shipping"

log() {
  su --login "${USERNAME}" --shell /bin/bash --command "echo '[$(date "${LOG_DATE_FORMAT}")] ${1}' >> '${LOG_FILE}'"
}

getServerProcessId() {
  local id="$(cat "${PROCESS_ID_FILE}")"
  if [[ -z "${id}" || -z "$(ps --pid ${id} --no-headers)" ]]; then
    id=getProcess "${SERVER_SCRIPT}" 'FactoryGame'
    if [[ -n "${id}" ]]; then
      echo "${id}" > > "${PROCESS_ID_FILE}"
    fi
  fi
  echo "${id}"
}

saveLogFiles() {
  if [[ -f "${INPUT_FILE}" ]]; then
    mv "${INPUT_FILE}" "${LOG_DIRECTORY}/$(head --lines=1 "${INPUT_FILE}")"
  fi
  if [[ -f "${UPDATE_FILE}" ]]; then
    mv "${UPDATE_FILE}" "${LOG_DIRECTORY}/$(head --lines=1 "${UPDATE_FILE}")"
  fi
  if [[ -f "${LOG_FILE}" ]]; then
    mv "${LOG_FILE}" "${LOG_DIRECTORY}/$(head --lines=1 "${LOG_FILE}")"
  fi
}

createLogFiles() {
  saveLogFiles
  echo "input.${DATE}.log" > "${INPUT_FILE}"
  echo "update.${DATE}.log" > "${UPDATE_FILE}"
  echo "simple.${DATE}.log" > "${LOG_FILE}"
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
    su --login "${USERNAME}" --shell /bin/bash --command "steamcmd +runscript '${UPDATE_SCRIPT}' >> '${UPDATE_FILE}'"
  fi
}

stopServer() {
  local id="$(getServerProcessId)"
  local waitTime=0;
  local maximumWaitTime=30

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
    killProcess "$(getProcess "${START_SCRIPT}")"

    tail --pid=${id} --follow=descriptor /dev/null
  fi
}

startServer() {
  local id=""

  createLogFiles
  updateUser
  updateServer

  trap "{ echo 'Quit Signal Received, Stopping the service' ; stopServer ; }" SIGQUIT
  trap "{ echo 'Abort Signal Received, Stopping the service' ; stopServer ; }" SIGABRT
  trap "{ echo 'Interrupt Signal Received, Stopping the service' ; stopServer ; }" SIGINT
  trap "{ echo 'Terminate Signal Received, Stopping the service' ; stopServer ; }" SIGTERM

  log "Booting Server"
  su --login "${USERNAME}" --shell /bin/bash --command "tail --follow=name --retry --lines=0 '${INPUT_FILE}' | '${START_SCRIPT}' -ServerQueryPort=${PORT_SERVER_QUERY} -BeaconPort=${PORT_BEACON} -Port=${PORT_SERVER} -log -unattended" &
  tail --pid=$(cat "$(getServerProcessId)") --follow=descriptor /dev/null
  log "Server Shutdown"

  saveLogFiles
}