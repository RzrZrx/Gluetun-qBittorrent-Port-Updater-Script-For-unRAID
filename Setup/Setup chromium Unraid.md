# Chromium Setup for Unraid 6.12.14

This document outlines the configuration for running Chromium in a Docker container on Unraid 6.12.14, integrated with GluetunVPN.

## WebUI
Access the Chromium WebUI at:  
`http://192.168.1.10:3000/`

## Docker Configuration

### Network
- **Network Type**: None
- **Extra Parameters**:  
  ```
  --shm-size=1gb --net=container:GluetunVPN
  ```

### Storage Configuration
- **Config Type**: Path
- **Name**: Chromium Download Folder
- **Container Path**: `/config/Downloads`
- **Host Path**: `/mnt/user/downloads_array/chromium/`
- **Default Value**: (None)
- **Access Mode**: Read/Write
- **Description**: Specifies the directory for storing downloads made through the Chromium browser. By default, downloads are saved in `/mnt/user/downloads_array/chromium/` on the host system.

### Access the qBittorrent WebUI at: 
- **`<your-device-IP>:3000/`**

### Docker Template Screenshot
![Chromium Docker Template](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Setup/img/chromium_template.png)
