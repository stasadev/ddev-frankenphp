[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/stasadev/ddev-frankenphp/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/stasadev/ddev-frankenphp/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/stasadev/ddev-frankenphp)](https://github.com/stasadev/ddev-frankenphp/commits)
[![release](https://img.shields.io/github/v/release/stasadev/ddev-frankenphp)](https://github.com/stasadev/ddev-frankenphp/releases/latest)

# DDEV FrankenPHP

See the blog [Using FrankenPHP with DDEV](https://ddev.com/blog/using-frankenphp-with-ddev/).

## Overview

[FrankenPHP](https://frankenphp.dev/) is a modern application server for PHP built on top of the [Caddy](https://caddyserver.com/) web server.

This add-on integrates FrankenPHP into your [DDEV](https://ddev.com/) project.

Difference from the [official quckstart](https://ddev.readthedocs.io/en/stable/users/quickstart/#generic-frankenphp):

| Feature | This Add-on | Official Quickstart |
| ------- | ----------- | ------------------- |
| **PHP Versions** | PHP 8.2, 8.3, 8.4, 8.5 | PHP 8.4 only |
| **PHP Extensions** | Builds on demand (slower, flexible) | Prebuilt (faster, limited) |
| **Configuration** | Supports custom FrankenPHP options | No custom options support |
| **Worker Mode** | ✓ Supported | ✗ Not supported |
| **Developer Tools** | `ddev xdebug`, `ddev xhprof`, `ddev xhgui` | ✗ Not available |

Note: building extensions slows down the first `ddev start`.

## Installation

```bash
ddev add-on get stasadev/ddev-frankenphp
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

### Debian Codename Detection

If you have switched to DDEV HEAD (upcoming v1.25.0+), repeat the installation to get the updated configuration in the `.ddev/.env.web` file.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View project status |
| `ddev logs -f` | View FrankenPHP logs |

## Advanced Customization

To add PHP extensions (see supported extensions [here](https://github.com/mlocati/docker-php-extension-installer?tab=readme-ov-file#supported-php-extensions)):

```bash
ddev dotenv set .ddev/.env.web --frankenphp-custom-extensions="psr solr"
ddev stop && ddev debug rebuild && ddev start
```

Make sure to commit the `.ddev/.env.web` file to version control.

---

If you want to override the default set of extensions, for example, to remove some extensions to make the first build faster:

```bash
ddev dotenv set .ddev/.env.web --frankenphp-default-extensions="gd pdo_mysql xdebug xhprof"
ddev stop && ddev debug rebuild && ddev start
```

Make sure to commit the `.ddev/.env.web` file to version control.

---

To modify the default [Caddyfile](https://github.com/php/frankenphp/blob/main/caddy/frankenphp/Caddyfile) configuration, create a file [`.ddev/docker-compose.frankenphp_extra.yaml`](./tests/testdata/docker-compose.frankenphp_extra.yaml) with the following content:

```yaml
# See all configurable variables in
# https://github.com/php/frankenphp/blob/main/caddy/frankenphp/Caddyfile
services:
  web:
    environment:
      # enable worker script
      # change some php.ini settings
      FRANKENPHP_CONFIG: |
        worker ${DDEV_DOCROOT:-.}/index.php
        php_ini {
          memory_limit 256M
          max_execution_time 15
        }
      # add a stub for Mercure module
      CADDY_SERVER_EXTRA_DIRECTIVES: |
        # mercure {
        #   ...
        # }
```

---

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `FRANKENPHP_DEBIAN_CODENAME` | `--frankenphp-debian-codename` | `bookworm` |
| `FRANKENPHP_DEFAULT_EXTENSIONS` | `--frankenphp-default-extensions` | `gd pdo_mysql pdo_pgsql xdebug xhprof zip` |
| `FRANKENPHP_CUSTOM_EXTENSIONS` | `--frankenphp-custom-extensions` | (not set) |

## Resources:

- [FrankenPHP Documentation](https://frankenphp.dev/docs/)
- [Using FrankenPHP with DDEV](https://ddev.com/blog/using-frankenphp-with-ddev/)
- [DDEV FrankenPHP Benchmark](https://github.com/stasadev/ddev-frankenphp-benchmark)

## Credits

**Contributed and maintained by [@stasadev](https://github.com/stasadev)**
