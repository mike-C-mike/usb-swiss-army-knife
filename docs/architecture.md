# Architecture

USB Swiss Army Knife separates four concerns:

1. **Catalog resolution** — determine the official current package or resource.
2. **Local repository management** — download, import, extract, hash, inventory, and audit.
3. **Profile composition** — define which repository paths belong on each type of USB.
4. **Provisioning** — safely copy a selected profile to a confirmed target drive.

The public repository contains only automation and metadata. The user’s generated local repository is intentionally excluded from version control.
