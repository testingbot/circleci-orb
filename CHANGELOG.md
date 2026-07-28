# Changelog

All notable changes to the TestingBot orb will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `install-tunnel`, `start-tunnel` and `stop-tunnel` commands for managing
  the TestingBot Tunnel in CircleCI jobs.
- `with-tunnel` reusable job that wraps arbitrary test steps with tunnel
  setup and teardown.
- `default` executor based on `cimg/openjdk` (Java 17).
- Usage examples for both the command-based and job-based workflows.
