# qBittorrent Setup on Unraid 6.12.14

## Configuration

### Enable Advanced View
- Turn on Advanced view in the qBittorrent template to access additional settings.

### WebUI Access
- Access the qBittorrent WebUI at: `http://192.168.100.66:8080/`

### Docker Network Configuration
- **Network Type**: Set to `None`.
- **Extra Parameters**: Include `--net=container:GluetunVPN` to route qBittorrent traffic through the GluetunVPN container.

### Reference
- Below is a screenshot of the qBittorrent Docker template for reference:
![Screenshot of the Gluetun Docker template](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/raw/main/Setup/img/GluetunVPN_template.png)