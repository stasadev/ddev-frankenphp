#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=stasadev/ddev-frankenphp

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p ~/tmp
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"

  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --webserver-type=generic
  assert_success

  run ddev start -y
  assert_success
}

health_checks() {
  run ddev exec -s frankenphp curl -sfI http://127.0.0.1:8000
  assert_output --partial "HTTP/1.1 200"
  assert_output --partial "Server: Caddy"
  assert_output --partial "X-Powered-By: PHP/8.3"

  run curl -sfI http://${PROJNAME}.ddev.site
  assert_output --partial "HTTP/1.1 200"
  assert_output --partial "Server: Caddy"
  assert_output --partial "X-Powered-By: PHP/8.3"

  run curl -sfI https://${PROJNAME}.ddev.site
  assert_output --partial "HTTP/2 200"
  assert_output --partial "server: Caddy"
  assert_output --partial "x-powered-by: PHP/8.3"

  run ddev exec -s frankenphp curl -sf http://127.0.0.1:8000
  assert_output "FrankenPHP DDEV page"

  run curl -sf http://${PROJNAME}.ddev.site
  assert_output "FrankenPHP DDEV page"

  run curl -sf https://${PROJNAME}.ddev.site
  assert_output "FrankenPHP DDEV page"

  run ddev help php
  assert_success
  assert_output --partial "frankenphp"

  run ddev php -v
  assert_success
  assert_output --partial "PHP 8.3"

  run ddev php --ini
  assert_success
  assert_output --partial "/usr/local/etc/php/conf.d/ddev-xdebug.ini"
  refute_output --partial "/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
  assert_output --partial "/usr/local/etc/php/conf.d/docker-php-ext-opcache.ini"

  run ddev php -m
  assert_success
  assert_output --partial "Xdebug"
  assert_output --partial "Zend OPcache"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail

  echo '<?php echo "FrankenPHP DDEV page";' >index.php
  assert_file_exist index.php
  assert_file_not_exist public/index.php

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

@test "install from directory wrong webserver" {
  set -eu -o pipefail

  run ddev config --webserver-type=nginx-fpm
  assert_success

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_failure
  assert_output --partial "The add-on only works with the 'generic' webserver type."
}

@test "install from directory docroot=public" {
  set -eu -o pipefail

  run ddev config --docroot=public
  assert_success

  echo '<?php echo "FrankenPHP DDEV page";' >public/index.php
  assert_file_not_exist index.php
  assert_file_exist public/index.php

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail

  echo '<?php echo "FrankenPHP DDEV page";' >index.php
  assert_file_exist index.php
  assert_file_not_exist public/index.php

  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
