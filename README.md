# Docker Repo
https://hub.docker.com/r/pacificengine/satisfactory

# Usage
```shell
# Configuration Parameters
serverport=7777
beaconport=15000
queryport=15777
directory=/home/satisfactory
username=satisfactory
service=satisfactory
version=release

# Setup Commands
mkdir -p "${directory}/logs"
mkdir -p "${directory}/config"
mkdir -p "${directory}/saves"
touch "${directory}/GUID.ini"
chown $(id -u ${username}):$(id -g ${username}) -R "${directory}"
chmod 755 -R "${directory}"

# Docker Run Command
docker run -d --name ${service} \
  --publish ${serverport}:${serverport}/udp \
  --publish ${beaconport}:${beaconport}/udp \
  --publish ${queryport}:${queryport}/udp \
  --env PORT_SERVER_QUERY=${queryport} \
  --env PORT_BEACON=${beaconport} \
  --env PORT_SERVER=${serverport} \
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

## Release
```shell
docker build --file "build.Dockerfile" --tag "satisfactory:latest" .
docker image tag satisfactory:latest pacificengine/satisfactory:ubuntu-20-release
docker image tag satisfactory:latest pacificengine/satisfactory:release
docker image tag satisfactory:latest pacificengine/satisfactory:ubuntu-20-latest
docker image tag satisfactory:latest pacificengine/satisfactory:latest
docker image tag satisfactory:latest pacificengine/satisfactory:$(git rev-parse --short HEAD)-release
docker image tag satisfactory:latest pacificengine/satisfactory:$(git rev-parse --short HEAD)
docker push pacificengine/satisfactory:ubuntu-20-release
docker push pacificengine/satisfactory:release
docker push pacificengine/satisfactory:ubuntu-20-latest
docker push pacificengine/satisfactory:latest
docker push pacificengine/satisfactory:$(git rev-parse --short HEAD)-release
docker push pacificengine/satisfactory:$(git rev-parse --short HEAD)
```
