#!/bin/bash
source /server/regex.sh
source /server/process.sh
source /server/properties.sh

INSTALL_DIRECTORY="$(getProperty "INSTALL_DIRECTORY")"
LOG_DIRECTORY="$(getProperty "LOG_DIRECTORY")"
USERNAME="$(getProperty "USERNAME")"
USERGROUP="$(getProperty "USERGROUP")"
GAME_ID="$(getProperty "GAME_ID")"

PORT_SERVER="${PORT_SERVER:-$(getProperty "PORT_SERVER")}"
PORT_BEACON="${PORT_BEACON:-$(getProperty "PORT_BEACON")}"
PORT_QUERY="${PORT_QUERY:-$(getProperty "PORT_QUERY")}"
AUTO_UPDATE="${AUTO_UPDATE:-$(getProperty "AUTO_UPDATE")}"

DATE="$(date "+%F-%H:%M:%S")"
LOG_DATE_FORMAT="+%FT%H:%M:%S"
INPUT_FILE="${LOG_DIRECTORY}/input.log"
UPDATE_LOG_FILE="${LOG_DIRECTORY}/update.log"
SIMPLE_LOG_FILE="${LOG_DIRECTORY}/simple.log"
CURRENT_USERS_FILE="${LOG_DIRECTORY}/user.csv"
MAIN_LOG_FILE="${LOG_DIRECTORY}/FactoryGame.log"
PROCESS_ID_FILE="${INSTALL_DIRECTORY}/process.id"
PROCESS_STATUS_FILE="${INSTALL_DIRECTORY}/process.status"
UPDATE_SCRIPT="${INSTALL_DIRECTORY}/update.script"
START_SCRIPT="${INSTALL_DIRECTORY}/FactoryServer.sh"

runCommandAsLocalUser() {
  su --login "${USERNAME}" --shell /bin/bash --command "${@}"
}

log() {
  runCommandAsLocalUser "echo '[$(date "${LOG_DATE_FORMAT}")] ${1}' >> '${SIMPLE_LOG_FILE}'"
}

getServerProcessId() {
  local id="$(cat "${PROCESS_ID_FILE}")"
  if [[ -z "${id}" || -z "$(ps --pid ${id} --no-headers)" ]]; then
    id=$(getProcess '' '\sFactoryGame\s')
    runCommandAsLocalUser "echo '${id}' > '${PROCESS_ID_FILE}'"
  fi
  echo "${id}"
}

saveLogFiles() {
  if [[ -f "${INPUT_FILE}" ]]; then
    runCommandAsLocalUser "mv '${INPUT_FILE}' '${LOG_DIRECTORY}/$(head --lines=1 "${INPUT_FILE}")'"
  fi
  if [[ -f "${UPDATE_LOG_FILE}" ]]; then
    runCommandAsLocalUser "mv '${UPDATE_LOG_FILE}' '${LOG_DIRECTORY}/$(head --lines=1 "${UPDATE_LOG_FILE}")'"
  fi
  if [[ -f "${SIMPLE_LOG_FILE}" ]]; then
    runCommandAsLocalUser "mv '${SIMPLE_LOG_FILE}' '${LOG_DIRECTORY}/$(head --lines=1 "${SIMPLE_LOG_FILE}")'"
  fi
  runCommandAsLocalUser "rm ${CURRENT_USERS_FILE}"
}

createLogFiles() {
  saveLogFiles
  runCommandAsLocalUser "echo 'input.${DATE}.log' > '${INPUT_FILE}'"
  runCommandAsLocalUser "echo 'update.${DATE}.log' > '${UPDATE_LOG_FILE}'"
  runCommandAsLocalUser "echo 'simple.${DATE}.log' > '${SIMPLE_LOG_FILE}'"
  runCommandAsLocalUser "touch '${CURRENT_USERS_FILE}'"
}

updateUser() {
  if [[ -n "${PUID}" ]]; then
    usermod --non-unique --uid "${PUID}" ${USERNAME}
  fi
  if [[ -n "${PGID}" ]]; then
    groupmod --non-unique --gid "${PGID}" ${USERGROUP}
  fi
  chown "${USERNAME}":"${USERGROUP}" -R "${INSTALL_DIRECTORY}"
  chown "${USERNAME}":"${USERGROUP}" "${LOG_DIRECTORY}"
}

updateServer() {
  cd "${INSTALL_DIRECTORY}"
  if [[ "${AUTO_UPDATE}" == "true" ]]; then
    chmod 777 -R /tmp
    log "Updating Server"
    runCommandAsLocalUser "steamcmd +runscript '${UPDATE_SCRIPT}' >> '${UPDATE_LOG_FILE}'"
  fi
}

stopServer() {
  local id=''
  local waitTime=0;
  local maximumWaitTime=30

  echo "STOPPING" > "${PROCESS_STATUS_FILE}"

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
    killProcess "$(getProcess 'steamcmd' "${UPDATE_SCRIPT}")"
  fi
}

startServer() {
  local id=''
  local line=''

  echo "STARTING" > "${PROCESS_STATUS_FILE}"

  trap "{ echo 'Quit Signal Received' ; /build/stop.sh ; }" SIGQUIT
  trap "{ echo 'Abort Signal Received' ; /build/stop.sh ; }" SIGABRT
  trap "{ echo 'Interrupt Signal Received' ; /build/stop.sh ; }" SIGINT
  trap "{ echo 'Terminate Signal Received' ; /build/stop.sh ; }" SIGTERM

  updateUser
  createLogFiles
  if [[ "$(cat "${PROCESS_STATUS_FILE}")" == "STARTING" ]]; then
    updateServer
  fi

  if [[ "$(cat "${PROCESS_STATUS_FILE}")" == "STARTING" ]]; then
    log "Booting Server"
    runCommandAsLocalUser "tail --follow=name --retry --lines=0 '${INPUT_FILE}' | '${START_SCRIPT}' -ServerQueryPort=${PORT_QUERY} -BeaconPort=${PORT_BEACON} -Port=${PORT_SERVER} -log -unattended" &
    while [[ "$(cat "${PROCESS_STATUS_FILE}")" == "STARTING" ]]; do
      id="$(getServerProcessId)"
      if [[ -n "${id}" ]]; then
        break
      fi
      sleep 1
    done
    if [[ "$(cat "${PROCESS_STATUS_FILE}")" == "STARTING" && -n "${id}" ]]; then
      echo "STARTED" > "${PROCESS_STATUS_FILE}"
      sleep 10
      while [[ "$(cat "${PROCESS_STATUS_FILE}")" == "STARTED" ]]; do
        id="$(getServerProcessId)"
        if [[ -z "${id}" ]]; then
          break
        fi
        runCommandAsLocalUser "tail --pid=${id} --follow=name --lines +1 '${MAIN_LOG_FILE}' | perl /build/perl/logs.pl '${SIMPLE_LOG_FILE}' '${CURRENT_USERS_FILE}'"
        sleep 1
      done
    else
      stopServer
    fi
  fi
  log "Server Shutdown"
  echo "STOPPED" > "${PROCESS_STATUS_FILE}"

  saveLogFiles

  trap - SIGQUIT SIGABRT SIGINT SIGTERM
}