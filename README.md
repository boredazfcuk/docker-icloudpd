# docker-icloudpd
An Alpine Linux Docker container for iCloud Photos Downloader. I use it for syncing the photo streams of all the iDevices in my house back to my server because it's the only way of backing up multiple devices to a single location. It uses the system keyring to securely store credentials, has HEIC to JPG conversion capability, and can send Telegram, Prowl, Pushover, WebHook, DingTalk, Discord, openhab, IYUU and WeCom notifications.

# Now with 2-way comms via Telegram!
Just send a message Telegram chat and the container will pick that up and sync immediately

# Also with built in Nextcloud upload/delete!
Just configure the Nextcloud settings and every file downloaded will be uploaded to a nextcloud server. It will also upload the JPGs it creates from HSIC file conversions. It will also sync deletes too.

## CONFIGURING ICLOUDPD

The README on Dockerhub has a hard limit of 25,000 characters, and I've hit this limit too many times now. All in all, I'm up at about 35k characters for the documentation, so this README is just a placeholder. Please see CONFIGURATION.md for info on how to configure this container. It is available here: https://github.com/boredazfcuk/docker-icloudpd/blob/master/CONFIGURATION.md

Bitcoin: 1E8kUsm3qouXdVYvLMjLbw7rXNmN2jZesL or bc1q7mpp4253xeqsyafl4zkak6kpnfcsslakuscrzw

Litecoin: LfmogjcqJXHnvqGLTYri5M8BofqqXQttk4

Ethereum: 0x752F0Fc9c1D1a10Ae3ea429505a0bbe259D60C6c