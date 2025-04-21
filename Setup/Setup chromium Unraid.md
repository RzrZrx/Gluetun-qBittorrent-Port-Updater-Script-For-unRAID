# Chromium Setup for Unraid 6.12.14

This document outlines the configuration for running Chromium in a Docker container on Unraid 6.12.14, integrated with GluetunVPN.

## Docker Configuration

### Enable Advanced View
- Turn on Advanced view in the qBittorrent template to access additional settings.
- WebUI: `<your-device-IP>:<port>/`    

### Docker Network Configuration
- **Network Type**: Set to `None`
- **Extra Parameters**: Include `--shm-size=1gb --net=container:GluetunVPN` to route qBittorrent traffic through the GluetunVPN container.

### Storage Configuration
- **Config Type**: Path
- **Name**: Chromium Download Folder
- **Container Path**: `/config/Downloads`
- **Host Path**: `/mnt/user/downloads_array/chromium/`
- **Default Value**: (None)
- **Access Mode**: Read/Write
- **Description**: Specifies the directory for storing downloads made through the Chromium browser. By default, downloads are saved in `/mnt/user/downloads_array/chromium/` on the host system.

### Access the Chromium WebUI at: 
- **`<your-device-IP>:<port>/`**

### Docker Template Screenshot
![Chromium Docker Template](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Setup/img/chromium_template.png)
