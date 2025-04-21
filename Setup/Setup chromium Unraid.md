# Chromium Setup for Unraid 6.12.14

This document outlines the configuration for running Chromium in a Docker container on Unraid 6.12.14, integrated with GluetunVPN.

## Docker Configuration

### Enable Advanced View
- Turn on Advanced view in the qBittorrent template to access additional settings.
- WebUI: `<your-device-IP>:<port>/`  
  Example: `http://192.168.1.10:3000/` (as used in the default lscr.io/linuxserver/chromium template)

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
- **Description**: Specifies the directory for storing downloads made through the Chromium browser. By default, downloads are saved inside the Docker container at /mnt/config/Downloads, but this has been mapped to a custom path on the array for easier access. On the host system, downloads will be stored in /mnt/user/downloads_array/chromium/

### Access the Chromium WebUI at: 
- **`<your-device-IP>:<port>/`**

### Docker Template Screenshot
![Chromium Docker Template](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Setup/img/chromium_template.png)
