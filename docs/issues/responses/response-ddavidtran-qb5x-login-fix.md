# Response to u/ddavidtran — qBittorrent 5.x Login Fix

---

Hey @ddavidtran,

Thank you so much for this incredibly detailed bug report and the clean fix — this is exactly the kind of contribution that makes open source great. 🙌

Your root cause analysis was spot on. The `"Ok."` body check was broken by qBittorrent 4.6+/5.x silently switching to HTTP 204 with an empty body on successful login. The cookie-based detection you suggested is elegant — it's version-agnostic, works for both legacy and modern qBit, and checks what actually matters (the session cookie).

**What's been done:**

- ✅ Your fix has been applied to the script in **v3.10**
- ✅ You've been credited as a contributor in the [script header](../../../script/update_qbittorrent_listening_port.sh) and [CHANGELOG](../../../CHANGELOG.md)
- ✅ Your bug report has been documented in the [issue responses](../qbittorrent-5x-login-failure.md) for future reference

**Would you like to be added as a contributor on the GitHub repository?** If you're interested, I'd be happy to add you with collaborator access so you can contribute directly going forward. Just let me know! 🚀

Thanks again for taking the time to not just report the issue, but to dig into the root cause and provide a production-ready fix. Really appreciate it.

— Zerax
