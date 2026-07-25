# Contributing

Contributions are welcome when they preserve the project’s core boundary:

> The repository distributes automation and metadata only. It never redistributes third-party packages or downloaded content.

## Adding a catalog item

A proposal must include:

- Official project name
- Publisher or maintainer
- Official website
- Official repository, when applicable
- Official publisher-controlled download source
- License or vendor terms
- Whether account, form, EULA, or email interaction is required
- Whether publisher hashes are available
- Whether Windows signatures are available
- Supported platforms and architectures
- Portability class
- Administrative or driver requirements
- Whether use can modify a live system
- Antivirus or policy concerns
- Recommended USB profiles
- Clear attribution text
- Why the project belongs in this toolkit

Do not submit:

- Third-party binaries
- Installer packages
- Archives
- Wordlists
- ISOs
- VM images
- Copied vendor documentation
- Unofficial mirrors
- Scraped gated downloads
- Credentials, tokens, or cookies

## Source requirements

Automated downloads must resolve to an official publisher-controlled source.

When a vendor requires interaction, use `InteractiveImport`. Do not automate around authentication, EULA acceptance, registration, rate limits, or technical access controls.

## Testing

Test changes on a disposable or controlled Windows environment.

Include:

- PowerShell version
- Windows version
- Selected mode
- Catalog item or profile
- Relevant log excerpt
- Expected behavior
- Actual behavior

## Style

Prefer:

- Clear PowerShell
- Strict error handling
- Safe defaults
- Explicit confirmation
- Idempotent behavior
- Detailed logs
- No hidden installation or execution
