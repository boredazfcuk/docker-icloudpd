docker pull alpine:latest

# aarch=arm64v8
docker build C:\Users\boredazfcuk\Documents\GitHub\docker-icloudpd\ -f C:\Users\boredazfcuk\Documents\GitHub\docker-icloudpd\Dockerfile.aarch -t boredazfcuk/icloudpd:arm64v8

# armhf=arm32v7
docker build C:\Users\boredazfcuk\Documents\GitHub\docker-icloudpd\ -f C:\Users\boredazfcuk\Documents\GitHub\docker-icloudpd\Dockerfile.armhf -t boredazfcuk/icloudpd:arm32v7

docker push boredazfcuk/icloudpd