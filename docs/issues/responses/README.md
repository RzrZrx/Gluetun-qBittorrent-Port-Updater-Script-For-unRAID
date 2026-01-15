# Issue Response Templates

This directory contains detailed response templates for common issues reported by users.

## Purpose

These templates serve as:
- 📋 **Copy-paste responses** for GitHub issues
- 📚 **Detailed troubleshooting guides** for specific problems
- 🔍 **Reference documentation** for recurring issues

## Current Templates

### [authentication-error-cannot-retrieve-port.md](authentication-error-cannot-retrieve-port.md)
**Issue:** Error retrieving forwarded port from Gluetun  
**Cause:** Authentication configuration problems  
**Solution:** TOML config with Basic Auth setup

---

## Using These Templates

1. **For maintainers:** Copy the relevant section from a template and paste into GitHub issue responses
2. **For users:** Reference these guides for detailed troubleshooting steps
3. **For contributors:** Use these as examples when creating new response templates

## Creating New Templates

When adding a new response template:
1. Name the file descriptively: `issue-description-error.md`
2. Include:
   - Problem description
   - Root cause analysis
   - Step-by-step diagnostic process
   - Solution with commands
   - Prevention tips
3. Update this README with a link and brief description
4. Update `../KNOWN_ISSUES.md` if it's a recurring issue

---

*For general troubleshooting, see [TROUBLESHOOTING_QUICK_REF.md](../TROUBLESHOOTING_QUICK_REF.md)*
