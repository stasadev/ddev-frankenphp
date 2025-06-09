[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/stasadev/ddev-frankenphp/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/stasadev/ddev-frankenphp/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/stasadev/ddev-frankenphp)](https://github.com/stasadev/ddev-frankenphp/commits)
[![release](https://img.shields.io/github/v/release/stasadev/ddev-frankenphp)](https://github.com/stasadev/ddev-frankenphp/releases/latest)

# DDEV FrankenPHP

## Overview

[FrankenPHP](https://frankenphp.dev/) is a modern application server for PHP built on top of the [Caddy](https://caddyserver.com/) web server.

This add-on integrates FrankenPHP into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev config --webserver-type=generic
ddev add-on get stasadev/ddev-frankenphp
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

### Using a different docroot

To change the `docroot` from the default `public` directory to something else, remove the `#ddev-generated` line from the`.ddev/frankenphp/Caddyfile` and update the `root public/` line.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and ports used by FrankenPHP |
| `ddev php` | Run PHP in the FrankenPHP container |
| `ddev exec -s frankenphp -- bash` | Enter the FrankenPHP container |
| `ddev logs -s frankenphp -f` | View FrankenPHP logs |

## Caveats

- To make Xdebug available on the host, create a `.ddev/docker-compose.frankenphp_extra.yaml` file, and replace `IP_ADDRESS` with the IP from `ddev exec ping -c1 host.docker.internal`. If you're on Linux, use `host-gateway` instead of `IP_ADDRESS`:
    ```yaml
    services:
      frankenphp:
        extra_hosts:
          - "host.docker.internal:IP_ADDRESS"
    ```
- `ddev launch` doesn't work. Open the website URL directly in your browser.

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.frankenphp --frankenphp-docker-image="dunglas/frankenphp:php8.3"
ddev add-on get stasadev/ddev-frankenphp
ddev stop && ddev debug rebuild -s frankenphp && ddev start
```

Make sure to commit the `.ddev/.env.frankenphp` file to version control.

To add PHP extensions:

```bash
ddev dotenv set .ddev/.env.frankenphp --frankenphp-php-extensions="opcache xdebug"
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
