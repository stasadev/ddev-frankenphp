[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/stasadev/ddev-frankenphp/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/stasadev/ddev-frankenphp/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/stasadev/ddev-frankenphp)](https://github.com/stasadev/ddev-frankenphp/commits)
[![release](https://img.shields.io/github/v/release/stasadev/ddev-frankenphp)](https://github.com/stasadev/ddev-frankenphp/releases/latest)

# DDEV Frankenphp

## Overview

This add-on integrates Frankenphp into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get stasadev/ddev-frankenphp
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Frankenphp |
| `ddev logs -s frankenphp` | Check Frankenphp logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.frankenphp --frankenphp-docker-image="busybox:stable"
ddev add-on get stasadev/ddev-frankenphp
ddev restart
```

Make sure to commit the `.ddev/.env.frankenphp` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `FRANKENPHP_DOCKER_IMAGE` | `--frankenphp-docker-image` | `busybox:stable` |

## Credits

**Contributed and maintained by [@stasadev](https://github.com/stasadev)**
