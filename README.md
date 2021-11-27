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
version=early-access

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

## Early Access
```shell
docker build --file "build.Dockerfile" --tag "satisfactory:latest --build-arg EXPERIMENTAL=false .
docker image tag satisfactory:latest pacificengine/satisfactory:ubuntu-20-early-access
docker image tag satisfactory:latest pacificengine/satisfactory:early-access
docker image tag satisfactory:latest pacificengine/satisfactory:ubuntu-20-latest
docker image tag satisfactory:latest pacificengine/satisfactory:latest
docker push pacificengine/satisfactory:ubuntu-20-early-access
docker push pacificengine/satisfactory:early-access
docker push pacificengine/satisfactory:ubuntu-20-latest
docker push pacificengine/satisfactory:latest
```

## Experimental
```shell
docker build --file "build.Dockerfile" --tag "satisfactory:experimental" --build-arg EXPERIMENTAL=true .
docker image tag satisfactory:experimental pacificengine/satisfactory:ubuntu-20-experimental
docker image tag satisfactory:experimental pacificengine/satisfactory:experimental
docker push pacificengine/satisfactory:ubuntu-20-experimental
docker push pacificengine/satisfactory:experimental
```


