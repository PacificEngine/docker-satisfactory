ARG DISTRIBUTION='ubuntu-20'
FROM steamcmd/steamcmd:${DISTRIBUTION}

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    coreutils \
    curl \
    jq

ARG INSTALL_DIRECTORY='/home/satisfactory'
ARG LOG_DIRECTORY="${INSTALL_DIRECTORY}/FactoryGame/Saved/Logs"
ARG USERNAME='satisfactory'
ARG USERGROUP='satisfactory'
RUN mkdir --parents ${LOG_DIRECTORY} && \
  mkdir --parents ${INSTALL_DIRECTORY} && \
  groupadd ${USERGROUP} && \
  useradd --system --gid ${USERGROUP} --shell /usr/sbin/nologin ${USERNAME} && \
  chown ${USERNAME}:${USERGROUP} -R ${LOG_DIRECTORY} && \
  chown ${USERNAME}:${USERGROUP} -R ${INSTALL_DIRECTORY} && \
  chmod 755 -R ${LOG_DIRECTORY} && \
  chmod 755 -R ${INSTALL_DIRECTORY}

ARG GAME_ID='1690800'
COPY install ${INSTALL_DIRECTORY}
RUN cat "${INSTALL_DIRECTORY}/update.script.template" \
    | sed --regexp-extended "s/<%INSTALL_DIRECTORY%>/${INSTALL_DIRECTORY//\//\\/}/g" \
    | sed --regexp-extended "s/<%LOG_DIRECTORY%>/${LOG_DIRECTORY//\//\\/}/g" \
    | sed --regexp-extended "s/<%USERNAME%>/${USERNAME//\//\\/}/g" \
    | sed --regexp-extended "s/<%USERGROUP%>/${USERGROUP//\//\\/}/g" \
    | sed --regexp-extended "s/<%GAME_ID%>/${GAME_ID//\//\\/}/g" \
    > "${INSTALL_DIRECTORY}/update.script" && \
  rm "${INSTALL_DIRECTORY}/update.script.template" && \
  chmod 555 "${INSTALL_DIRECTORY}/update.script"

RUN chmod 777 -R /tmp && \
  su --login ${USERNAME} --shell /bin/bash --command "steamcmd +runscript '${INSTALL_DIRECTORY}/update.script'"

ARG PORT_SERVER=''
ARG AUTO_UPDATE=''
COPY docker /
RUN cat '/server/properties.template' \
    | sed --regexp-extended "s/<%INSTALL_DIRECTORY%>/${INSTALL_DIRECTORY//\//\\/}/g" \
    | sed --regexp-extended "s/<%LOG_DIRECTORY%>/${LOG_DIRECTORY//\//\\/}/g" \
    | sed --regexp-extended "s/<%USERNAME%>/${USERNAME//\//\\/}/g" \
    | sed --regexp-extended "s/<%USERGROUP%>/${USERGROUP//\//\\/}/g" \
    | sed --regexp-extended "s/<%GAME_ID%>/${GAME_ID//\//\\/}/g" \
    | sed --regexp-extended "s/<%PORT_SERVER%>/${PORT_SERVER:-7777}/g" \
    | sed --regexp-extended "s/<%AUTO_UPDATE%>/${AUTO_UPDATE:-true}/g" \
    > '/server/properties' && \
  rm '/server/properties.template' && \
  chmod 555 /server/*.sh && \
  chmod 555 /build/*.sh

ENTRYPOINT ["/bin/bash", "/build/start.sh"]