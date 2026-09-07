# Docker Repo
https://hub.docker.com/r/pacificengine/satisfactory

# Usage
# Configuration Parameters
```shell
serverport=7777
reliableport=8888
directory=/home/satisfactory
username=satisfactory
service=satisfactory
version=release
```

# Setup Commands
```shell
mkdir -p "${directory}/logs"
mkdir -p "${directory}/config"
mkdir -p "${directory}/saves"
touch "${directory}/GUID.ini"
chown $(id -u ${username}):$(id -g ${username}) -R "${directory}"
chmod 755 -R "${directory}"
```

# Docker Run Command
```shell
docker run -d --name ${service} \
  --publish ${serverport}:${serverport}/udp \
  --publish ${serverport}:${serverport}/tcp \
  --publish ${reliableport}:${reliableport}/tcp \
  --env PORT_SERVER=${serverport} \
  --env PORT_RELIABLE=${reliableport} \
  --env AUTO_UPDATE=true \
  --env PUID=$(id -u ${username}) \
  --env PGID=$(id -g ${username}) \
  --mount type=bind,source=${directory}/logs,target=/home/satisfactory/FactoryGame/Saved/Logs \
  --mount type=bind,source=${directory}/config,target=/home/satisfactory/FactoryGame/Saved/Config/LinuxServer \
  --mount type=bind,source=${directory}/saves,target=/home/satisfactory/.config/Epic/FactoryGame/Saved/SaveGames \
  --mount type=bind,source=${directory}/GUID.ini,target=/home/satisfactory/.config/Epic/FactoryGame/GUID.ini \
  --restart unless-stopped pacificengine/satisfactory:${version}
```

# Build

## Clean Environment
```shell
docker rm $(docker ps -a -q)
docker rmi $(docker images -a -q)
docker volume prune
docker system prune -a
```

## Stable
```shell
DISTRIBUTION=ubuntu-24
GAME_VERSION=1.2.3.0
GIT_VERSION="$(git rev-parse --short HEAD)"
docker build --file "build-${DISTRIBUTION}.Dockerfile" --tag "satisfactory:${DISTRIBUTION}" --build-arg DISTRIBUTION=${DISTRIBUTION} .
docker image tag satisfactory:${DISTRIBUTION} pacificengine/satisfactory:${DISTRIBUTION}-stable
docker image tag satisfactory:${DISTRIBUTION} pacificengine/satisfactory:stable
docker image tag satisfactory:${DISTRIBUTION} pacificengine/satisfactory:${DISTRIBUTION}-latest
docker image tag satisfactory:${DISTRIBUTION} pacificengine/satisfactory:latest
docker image tag satisfactory:${DISTRIBUTION} pacificengine/satisfactory:${GIT_VERSION}-stable
docker image tag satisfactory:${DISTRIBUTION} pacificengine/satisfactory:${GIT_VERSION}
docker image tag satisfactory:${DISTRIBUTION} pacificengine/satisfactory:${GAME_VERSION}-stable
docker image tag satisfactory:${DISTRIBUTION} pacificengine/satisfactory:${GAME_VERSION}
docker push pacificengine/satisfactory:${DISTRIBUTION}-stable
docker push pacificengine/satisfactory:stable
docker push pacificengine/satisfactory:${DISTRIBUTION}-latest
docker push pacificengine/satisfactory:latest
docker push pacificengine/satisfactory:${GIT_VERSION}-stable
docker push pacificengine/satisfactory:${GIT_VERSION}
docker push pacificengine/satisfactory:${GAME_VERSION}-stable
docker push pacificengine/satisfactory:${GAME_VERSION}
```
