# qBittorrent Setup on Unraid 6.12.14 with GluetunVPN

## Overview
This guide provides instructions for setting up qBittorrent on Unraid 6, integrated with GluetunVPN, including environment variables and network configuration.

## Configuration

### Enable Advanced View
- Turn on Advanced view in the qBittorrent template to access additional settings.
- WebUI: `<your-device-IP>:<port>/`    
  Example: `http://192.168.1.10:3000/` (as used in the template)

### Docker Network Configuration
- **Network Type**: Set to `None`
- **Extra Parameters**: Include `--net=container:GluetunVPN` to route qBittorrent traffic through the GluetunVPN container.

### Access the qBittorrent WebUI at: 
- **`<your-device-IP>:<port>/`**

### Docker Template Screenshot
![Screenshot of the qBittorrent Docker template](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Setup/img/qBittorrent_template.png)
