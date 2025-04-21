# qBittorrent Setup on Unraid 6.12.14

## Overview
This guide provides instructions for setting up qBittorrent on Unraid 7, integrated with GluetunVPN, including environment variables and network configuration.

## Configuration

### Enable Advanced View
- Turn on Advanced view in the qBittorrent template to access additional settings.
- WebUI: `http://192.168.100.66:8080/`    

### Docker Network Configuration
- **Network Type**: Set to `None`
- **Extra Parameters**: Include `--net=container:GluetunVPN` to route qBittorrent traffic through the GluetunVPN container.

### Docker Template Screenshot
![Screenshot of the qBittorrent Docker template](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Setup/img/qBittorrent_template.png)
