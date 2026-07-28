# Changelog

All notable changes to the TestingBot orb will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `install_tunnel`, `start_tunnel` and `stop_tunnel` commands for managing
  the TestingBot Tunnel in CircleCI jobs.
- `with_tunnel` reusable job that wraps arbitrary test steps with tunnel
  setup and teardown.
- `default` executor based on `cimg/openjdk` (Java 17).
- Usage examples for both the command-based and job-based workflows.
- `test/local_e2e.sh`, which runs the orb inside a real CircleCI job
  container via `circleci local execute`, including a scenario asserting a
  clean failure when credentials are missing.
- `start_tunnel` falls back to a `TB_TUNNEL_IDENTIFIER` environment variable
  when the `tunnel_identifier` parameter is empty, so callers can derive a
  per-container identifier at runtime via `BASH_ENV`. Parameter values are
  literal and cannot reference shell variables.
- On startup failure, `start_tunnel` prints the tunnel's console output in
  addition to its log file. Fatal errors such as reaching the concurrent
  tunnel limit are reported on the console before the log file is opened.
