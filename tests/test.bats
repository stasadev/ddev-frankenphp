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

  export INSTALL_REDIS=false
  export HOST_HTTP_PORT=
  export FRANKENPHP_WORKER=false
}

health_checks() {
  run ddev exec -s frankenphp whoami
  assert_success
  assert_output "$(whoami)"

  run ddev exec -s frankenphp bash -c 'echo $USER'
  assert_success
  assert_output "$(whoami)"

  run ddev exec -s frankenphp curl -sfI http://127.0.0.1
  assert_success
  assert_output --partial "HTTP/1.1 200"
  assert_output --partial "Server: Caddy"
  assert_output --partial "X-Powered-By: PHP/8.3"

  if [[ "${FRANKENPHP_WORKER}" == "true" ]]; then
    assert_output --partial "X-Request-Count"
    assert_output --partial "X-Worker-Uptime"
  else
    refute_output --partial "X-Request-Count"
    refute_output --partial "X-Worker-Uptime"
  fi

  run curl -sfI http://${PROJNAME}.ddev.site
  assert_success
  assert_output --partial "HTTP/1.1 200"
  assert_output --partial "Server: Caddy"
  assert_output --partial "X-Powered-By: PHP/8.3"

  if [[ "${FRANKENPHP_WORKER}" == "true" ]]; then
    assert_output --partial "X-Request-Count"
    assert_output --partial "X-Worker-Uptime"
  else
    refute_output --partial "X-Request-Count"
    refute_output --partial "X-Worker-Uptime"
  fi

  if [ "${HOST_HTTP_PORT}" != "" ]; then
    run curl -sfI http://127.0.0.1:${HOST_HTTP_PORT}
    assert_output --partial "HTTP/1.1 200"
    assert_output --partial "Server: Caddy"
    assert_output --partial "X-Powered-By: PHP/8.3"
  fi

  run curl -sfI https://${PROJNAME}.ddev.site
  assert_success
  assert_output --partial "HTTP/2 200"
  assert_output --partial "server: Caddy"
  assert_output --partial "x-powered-by: PHP/8.3"

  if [[ "${FRANKENPHP_WORKER}" == "true" ]]; then
    assert_output --partial "x-request-count"
    assert_output --partial "x-worker-uptime"
  else
    refute_output --partial "x-request-count"
    refute_output --partial "x-worker-uptime"
  fi

  run ddev exec -s frankenphp curl -sf http://127.0.0.1
  assert_success
  if [[ "${FRANKENPHP_WORKER}" == "true" ]]; then
    assert_output --partial "FrankenPHP Worker Demo"
  else
    assert_output "FrankenPHP page without worker"
  fi

  run curl -sf http://${PROJNAME}.ddev.site
  assert_success
  if [[ "${FRANKENPHP_WORKER}" == "true" ]]; then
    assert_output --partial "FrankenPHP Worker Demo"
  else
    assert_output "FrankenPHP page without worker"
  fi

  run curl -sf https://${PROJNAME}.ddev.site
  assert_success
  if [[ "${FRANKENPHP_WORKER}" == "true" ]]; then
    assert_output --partial "FrankenPHP Worker Demo"
  else
    assert_output "FrankenPHP page without worker"
  fi

  run ddev exec -s frankenphp curl -sf http://127.0.0.1:2019/config/
  assert_success
  assert_output --partial '"listen":[":80"]'
  if [[ "${FRANKENPHP_WORKER}" == "true" ]]; then
    assert_output --partial '"workers"'
    assert_output --partial '"max_execution_time":"15"'
    assert_output --partial '"memory_limit":"256M"'
  else
    refute_output --partial '"workers"'
    refute_output --partial '"max_execution_time":"15"'
    refute_output --partial '"memory_limit":"256M"'
  fi

  run ddev help php
  assert_success
  assert_output --partial "frankenphp"

  run ddev php -v
  assert_success
  assert_output --partial "PHP 8.3"

  run ddev php --ini
  assert_success
  assert_output --partial "/usr/local/etc/php/ddev.conf.d"

  run ddev php -m
  assert_success
  if [ "${INSTALL_REDIS}" = "true" ]; then
    assert_output --partial "redis"
  else
    refute_output --partial "redis"
  fi
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail

  cp "${DIR}"/tests/testdata/index-no-worker.php index.php
  assert_file_exist index.php

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

@test "worker" {
  set -eu -o pipefail

  export FRANKENPHP_WORKER=true

  cp "${DIR}"/tests/testdata/index-worker.php index.php
  assert_file_exist index.php

  cp "${DIR}"/tests/testdata/docker-compose.frankenphp_extra.yaml .ddev/docker-compose.frankenphp_extra.yaml
  assert_file_exist .ddev/docker-compose.frankenphp_extra.yaml

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

@test "wrong webserver" {
  set -eu -o pipefail

  run ddev config --webserver-type=nginx-fpm
  assert_success

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_failure
  assert_output --partial "The add-on only works with the 'generic' webserver type."
}

@test "docroot=public; customize: install redis, custom http port" {
  set -eu -o pipefail

  export INSTALL_REDIS=true
  export HOST_HTTP_PORT=8080

  run ddev config --docroot=public
  assert_success

  run ddev dotenv set .ddev/.env.frankenphp --frankenphp-php-extensions="redis" --frankenphp-host-http-port="${HOST_HTTP_PORT}"
  assert_success
  assert_file_exist .ddev/.env.frankenphp

  cp "${DIR}"/tests/testdata/index-no-worker.php public/index.php
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

  cp "${DIR}"/tests/testdata/index-no-worker.php index.php
  assert_file_exist index.php

  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
