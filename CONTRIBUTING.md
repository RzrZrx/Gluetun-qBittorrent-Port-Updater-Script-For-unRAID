# Contributing to Gluetun qBittorrent Port Synchronization Script

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Issues

Before creating an issue, please:
- Check existing issues to avoid duplicates
- Use the issue templates provided
- Include relevant details (Unraid version, Gluetun version, qBittorrent version, script version)

### Suggesting Enhancements

We welcome enhancement suggestions! Please:
- Use the feature request template
- Clearly describe the proposed functionality
- Explain the use case and benefits

### Submitting Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Test your changes** thoroughly in your environment
3. **Update documentation** if you've changed functionality
4. **Follow the existing code style**
5. **Write clear commit messages**
6. **Submit a pull request** using the template

## Development Guidelines

### Script Modifications

When modifying `update_qbittorrent_listening_port.sh`:
- Maintain backward compatibility when possible
- Add comments for complex logic
- Test with different VPN providers (PIA, ProtonVPN, etc.)
- Verify error handling works correctly

### Documentation Updates

- Keep documentation clear and concise
- Include screenshots for UI-related changes
- Update version numbers where applicable
- Test all command examples before submitting

### Version Numbering

We use semantic versioning (MAJOR.MINOR-TYPE):
- **MAJOR**: Breaking changes or major feature additions
- **MINOR**: Non-breaking improvements or bug fixes
- **TYPE**: T (tested) or U (untested)

## Testing

Before submitting changes, please test:
- Script execution in Gluetun container
- Port synchronization with qBittorrent
- Error handling (wrong credentials, network issues, etc.)
- Compatibility with different Unraid versions

## Questions?

If you have questions that aren't addressed here, feel free to:
- Open an issue with the question label
- Check existing discussions
- Review the documentation in the `docs/` folder

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers and help them learn
- Focus on what is best for the community

Thank you for contributing! 🎉
