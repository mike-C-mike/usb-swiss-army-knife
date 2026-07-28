# Vetted Sources v0.2.0

This sprint begins source-page vetting. The goal is to record publisher-controlled sources before enabling automatic downloads.

## Initial direct-download enabled source

- Microsoft Sysinternals Suite
  - Official source page: Microsoft Learn Sysinternals Suite page
  - Direct download: `https://download.sysinternals.com/files/SysinternalsSuite.zip`
  - Status: direct download can be enabled because it uses Microsoft's Sysinternals download host.

## Source pages recorded but not direct-download enabled by default

Examples include 7-Zip, Wireshark, Eric Zimmerman Tools, GitHub-hosted upstream projects, and vendor tools where versions, licensing, or release assets require review before automation.

## Rule

Do not enable `DownloadEnabled=Yes` for a tool unless the direct URL, license/terms, install behavior, and expected file type are understood.
