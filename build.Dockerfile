FROM steamcmd/steamcmd:ubuntu-20

ARG INSTALL_DIRECTORY='/home/satisfactory'
ARG LOG_DIRECTORY="${INSTALL_DIRECTORY}/FactoryGame/Saved/Logs"
ARG USERNAME='satisfactory'
ARG USERGROUP='satisfactory'
ARG GAME_ID='1690800'
ARG EXPERIMENTAL='false'
ARG EXPERIMENTAL_ARGS='-beta experimental'

RUN apt-get update && \
	apt-get install -y \
		coreutils \
		curl

RUN mkdir --parents ${LOG_DIRECTORY} && \
	mkdir --parents ${INSTALL_DIRECTORY} && \
	groupadd ${USERGROUP} && \
	useradd --system --gid ${USERGROUP} --shell /usr/sbin/nologin ${USERNAME} && \
	chown ${USERNAME}:${USERGROUP} -R ${LOG_DIRECTORY} && \
	chown ${USERNAME}:${USERGROUP} -R ${INSTALL_DIRECTORY} && \
	chmod 755 -R ${LOG_DIRECTORY} && \
	chmod 755 -R ${INSTALL_DIRECTORY}

RUN echo '@ShutdownOnFailedCommand 1' $'\n' \
			'@NoPromptForPassword 1' $'\n' \
			'@sSteamCmdForcePlatformType linux' $'\n' \
			'force_install_dir '"${INSTALL_DIRECTORY}" $'\n' \
			'login anonymous' $'\n' \
			'app_update '"${GAME_ID}"' '"$(if [ "${EXPERIMENTAL}" = "true" ]; then echo "${EXPERIMENTAL_ARGS}"; fi)"' validate' $'\n' \
			'quit' $'\n' \
		> ${INSTALL_DIRECTORY}/update.script &&\
	chmod 555 ${INSTALL_DIRECTORY}/update.script
	
RUN chmod 777 -R /tmp &&\
	su --login ${USERNAME} --shell /bin/bash --command "steamcmd +runscript ${INSTALL_DIRECTORY}/update.script"

ARG PORT_SERVER_QUERY=''
ARG PORT_BEACON=''
ARG PORT_SERVER=''
ARG AUTO_UPDATE=''
RUN mkdir --parents /build && \
	echo '#!/bin/bash' $'\n' \
			'PORT_SERVER_QUERY="${PORT_SERVER_QUERY:-'"${PORT_SERVER_QUERY:-15777}"'}"' $'\n' \
			'PORT_BEACON="${PORT_BEACON:-'"${PORT_BEACON:-15000}"'}"' $'\n' \
			'PORT_SERVER="${PORT_SERVER:-'"${PORT_SERVER:-7777}"'}"' $'\n' \
			'AUTO_UPDATE="${AUTO_UPDATE:-'"${AUTO_UPDATE:-true}"'}"' $'\n' \
			'DATE="$(date "+%F-%H:%M:%S")"' $'\n' \
			'LOG_DATE_FORMAT="+%FT%H:%M:%S"' $'\n' \
			'LOG_FILE="simple-${DATE}.log"' $'\n' \
			'log() { su --login '"${USERNAME}"' --shell /bin/bash --command "echo '"'"'[$(date "${LOG_DATE_FORMAT}")] ${1}'"'"' >> '"'${LOG_DIRECTORY}"'/${LOG_FILE}'"'"'" ; } ' $'\n' \
			'if [[ -n "${PUID}" ]]; then usermod -u "${PUID}" '"${USERNAME}"'; fi ' $'\n' \
			'if [[ -n "${PGID}" ]]; then groupmod -g "${PGID}" '"${USERGROUP}"'; fi ' $'\n' \
			'chown '"${USERNAME}"':'"${USERGROUP}"' -R "'"${INSTALL_DIRECTORY}"'" ' $'\n' \
			'chown '"${USERNAME}"':'"${USERGROUP}"' "'"${LOG_DIRECTORY}"'" ' $'\n' \
			'cd "'"${INSTALL_DIRECTORY}"'"' $'\n' \
			'if [[ "${AUTO_UPDATE}" == "true" ]]; then' $'\n' \
			'  chmod 777 -R /tmp' $'\n' \
			'  log "Updating Server" ' $'\n' \
			'  su --login '"${USERNAME}"' --shell /bin/bash --command "steamcmd +runscript '"'${INSTALL_DIRECTORY}"'/update.script'"'"' > '"'${LOG_DIRECTORY}"'/update-${DATE}.log'"'"'"' $'\n' \
			'fi' $'\n' \
			'log "Booting Server" ' $'\n' \
			'su --login '"${USERNAME}"' --shell /bin/bash --command "'"${INSTALL_DIRECTORY}"'/FactoryServer.sh -ServerQueryPort=${PORT_SERVER_QUERY} -BeaconPort=${PORT_BEACON} -Port=${PORT_SERVER} -log -unattended"' $'\n' \
			'log "Server Shutdown" ' $'\n' \
		> /build/start.sh && \
	chmod 555 /build/start.sh

ENTRYPOINT ["/bin/bash", "/build/start.sh"]