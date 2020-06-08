docker pull alpine:3.12

# aarch=arm64v8
docker build . -f Dockerfile.aarch -t boredazfcuk/icloudpd:arm64v8

# armhf=arm32v7
docker build . -f Dockerfile.armhf -t boredazfcuk/icloudpd:arm32v7

docker push boredazfcuk/icloudpd