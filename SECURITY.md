# Security Policy

## Reporting a vulnerability

Please report vulnerabilities privately before public disclosure.

Do not include live credentials, personal data, proprietary software, restricted evidence, or active exploit details in a public issue.

For the initial alpha release, contact the maintainer through the repository’s private security-advisory feature once enabled.

## Security model

USB Swiss Army Knife:

- Downloads only over HTTPS.
- Uses allow-listed hosts for automated downloads.
- Prefers official publisher-controlled repositories and release pages.
- Records SHA-256 hashes.
- Checks Authenticode signatures where configured.
- Does not silently execute downloaded files.
- Does not silently install software.
- Requires explicit target-drive confirmation.
- Refuses the Windows system drive as a provisioning target.

## Known limitations

- A valid digital signature does not guarantee a package is safe or suitable.
- A matching hash proves consistency, not trustworthiness.
- Vendor pages and filenames may change.
- Upstream repositories and releases can be compromised.
- Some packages may trigger endpoint protection.
- Portable tools may still modify a live system.
- The builder is not a software sandbox.
- The builder is not a forensic write blocker.

Users should inspect catalog changes, review upstream release notes, and test the builder in a controlled environment.
