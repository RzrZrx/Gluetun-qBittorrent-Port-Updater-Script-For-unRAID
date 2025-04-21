# Chromium Setup for Unraid 6.12.14

This document outlines the configuration for running Chromium in a Docker container on Unraid 6.12.14, integrated with GluetunVPN.

## Docker Configuration

### Enable Advanced View
- Turn on **Advanced View** in the Chromium template to access additional settings.
- **WebUI**: `<your-device-IP>:<port>/`  
  Example: `http://192.168.1.10:3000/` (as used in the default `lscr.io/linuxserver/chromium` template)

### Docker Network Configuration
- **Network Type**: `None`
- **Extra Parameters**:  
  `--shm-size=1gb --net=container:GluetunVPN`  
  This routes Chromium traffic through the GluetunVPN container.

### Storage Configuration
- **Config Type**: Path
- **Name**: Chromium Download Folder
- **Container Path**: `/config/Downloads`
- **Host Path**: `<your-device:path>`  
  Example: `/mnt/user/downloads_array/chromium/` (this is just a sample path; use one that fits your setup)
- **Default Value**: (None)
- **Access Mode**: Read/Write
- **Description**:  
  Specifies the directory for storing downloads made through the Chromium browser. By default, downloads are saved inside the Docker container at `/mnt/config/Downloads`, but this can be mapped to a custom path on the array for easier access. For example, on the host system, downloads can be stored in a directory like `/mnt/user/downloads_array/chromium/`.

### Access the Chromium WebUI at:
- **`<your-device-IP>:<port>/`**

### Docker Template Screenshot
![Chromium Docker Template](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Setup/img/chromium_template.png)
