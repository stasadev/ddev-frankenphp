[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/stasadev/ddev-frankenphp/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/stasadev/ddev-frankenphp/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/stasadev/ddev-frankenphp)](https://github.com/stasadev/ddev-frankenphp/commits)
[![release](https://img.shields.io/github/v/release/stasadev/ddev-frankenphp)](https://github.com/stasadev/ddev-frankenphp/releases/latest)

# DDEV FrankenPHP

## Overview

[FrankenPHP](https://frankenphp.dev/) is a modern application server for PHP built on top of the [Caddy](https://caddyserver.com/) web server.

This add-on integrates FrankenPHP into your [DDEV](https://ddev.com/) project as an extra service.

Running it as a separate service lets you install additional PHP extensions. This differs from the [official quckstart](https://ddev.readthedocs.io/en/stable/users/quickstart/#generic-frankenphp) and [another add-on](https://github.com/ochorocho/ddev-frankenphp), which bundle a static FrankenPHP build inside the `web` container.

## Installation

```bash
ddev config --webserver-type=generic
ddev add-on get stasadev/ddev-frankenphp
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and ports used by FrankenPHP |
| `ddev php` | Run PHP in the FrankenPHP container |
| `ddev exec -s frankenphp bash` | Enter the FrankenPHP container |
| `ddev logs -s frankenphp -f` | View FrankenPHP logs |

## Caveats

- To make Xdebug available on the host, create a `.ddev/docker-compose.frankenphp_extra.yaml` file:
  - For Linux and WSL2:
    ```yaml
    services:
      frankenphp:
        extra_hosts:
          - "host.docker.internal:host-gateway"
    ```
  - For other setups, replace `IP_ADDRESS` with IP from the `ddev exec ping -c1 host.docker.internal` command:
    ```yaml
    services:
      frankenphp:
        extra_hosts:
          - "host.docker.internal:IP_ADDRESS"
    ```
- `ddev xdebug` is only designed to work in the `web` container, it won't work here.
- `ddev launch` doesn't work. Open the website URL directly in your browser.

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.frankenphp --frankenphp-docker-image="dunglas/frankenphp:php8.3"
ddev add-on get stasadev/ddev-frankenphp
ddev stop && ddev debug rebuild -s frankenphp && ddev start
```

Make sure to commit the `.ddev/.env.frankenphp` file to version control.

To add PHP extensions (see supported extensions [here](https://github.com/mlocati/docker-php-extension-installer?tab=readme-ov-file#supported-php-extensions)):

```bash
ddev dotenv set .ddev/.env.frankenphp --frankenphp-php-extensions="opcache xdebug spx"
ddev add-on get stasadev/ddev-frankenphp
ddev stop && ddev debug rebuild -s frankenphp && ddev start
```

Make sure to commit the `.ddev/.env.frankenphp` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `FRANKENPHP_DOCKER_IMAGE` | `--frankenphp-docker-image` | `dunglas/frankenphp:php8.3` |
| `FRANKENPHP_PHP_EXTENSIONS` | `--frankenphp-php-extensions` | `opcache xdebug` |

## Resources:

- [FrankenPHP Documentation](https://frankenphp.dev/docs/)

## Credits

**Contributed and maintained by [@stasadev](https://github.com/stasadev)**
