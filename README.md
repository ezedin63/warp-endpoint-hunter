# WARP Endpoint Hunter

Public WARP Endpoint Hunter and Auto Config Generator for Termux / Android.

## Features

- WARP Endpoint Hunter
- WARP Auto Config Generator
- ARM64 / aarch64 support
- GitHub API based distribution
- Automatic WARP registration
- AmneziaWG endpoint scanning
- Automatic best-endpoint selection
- Automatic WireGuard / AmneziaWG config generation

## Requirements

- Android
- Termux
- ARM64 / aarch64 device
- Internet connection

## Quick Start

Run the following command in Termux:

```bash
curl -4 -fsSL \
  -H "Accept: application/vnd.github.raw+json" \
  "https://api.github.com/repos/ezedin63/warp-endpoint-hunter/contents/menu.sh" | bash
```

Then choose:

1. WARP Endpoint Hunter
2. WARP Auto Config
0. Exit

## Auto Config

The Auto Config option automatically prepares the environment, registers WARP, scans AWG endpoints, selects a suitable endpoint, and generates the final configuration.

## Security

Each user registers their own WARP account.

Private information such as PrivateKey and warpscout-account.json must never be committed to this repository.

## Important

Endpoint availability and latency can change over time and depend on the user network.

For the most representative endpoint scan, run the scanner without another VPN active.

## License

For personal and educational use. Check the licenses of third-party components used by this project.
