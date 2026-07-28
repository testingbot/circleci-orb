# Security Policy

## Supported versions

Orb versions published to the CircleCI registry are immutable and can never be
edited or deleted. Security fixes are therefore released as a new version.
Only the latest `1.x` release is supported — pin to a major version
(`testingbot/testingbot@1`) to receive fixes automatically.

## Reporting a vulnerability

Please report security issues privately. **Do not open a public GitHub issue**
for a vulnerability.

- Email **info@testingbot.com** (the contact listed in
  [TestingBot's security.txt](https://testingbot.com/.well-known/security.txt)).
- Alternatively, use GitHub's
  [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
  on this repository.

Please include a description of the issue, the orb version affected, and steps
to reproduce. We aim to acknowledge reports within a few business days.

## Scope

In scope: the orb source in `src/` — the tunnel lifecycle scripts, parameter
handling, and anything that could leak credentials or execute unintended code
in a user's CircleCI job.

Out of scope for this repository: vulnerabilities in the TestingBot Tunnel
itself (report those to TestingBot directly, see
[the tunnel repository](https://github.com/testingbot/Testingbot-Tunnel)),
in the TestingBot platform, or in CircleCI.

## How this orb handles your credentials

Understanding this may help you assess risk:

- Your TestingBot key and secret are read from environment variables
  (`TB_KEY` and `TB_SECRET` by default) using CircleCI's `env_var_name`
  parameter type, so the **values** never appear in your `config.yml`.
- The credentials are exported into the tunnel process's environment rather
  than passed as command-line arguments, so they do not appear in the process
  list or in `ps` output inside the job container.
- The orb never echoes the credential values. Note that if you enable the
  tunnel's own debug logging via `extra_args`, the tunnel may log
  information you would not want in a public build log — CircleCI build logs
  are visible to anyone with read access to the project.
- Store credentials in CircleCI **project environment variables** or a
  **context**, never in your committed config. Prefer a restricted context so
  only approved jobs can use them.

## A note on forked pull requests

CircleCI does not pass secrets to builds from forked pull requests by default,
and you should keep it that way. If you enable "Pass secrets to builds from
forked pull requests", anyone opening a PR can read your TestingBot
credentials.
