# TestingBot Orb for CircleCI

[![CircleCI Orb Version](https://badges.circleci.com/orbs/testingbot/testingbot.svg)](https://circleci.com/developer/orbs/orb/testingbot/testingbot)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

Run cross-browser and mobile app tests on [TestingBot](https://testingbot.com)
from CircleCI. This orb installs, starts and stops the
[TestingBot Tunnel](https://testingbot.com/support/tunnel), giving TestingBot's
browser and device cloud secure access to web apps running inside your
CircleCI job (localhost, staging environments behind a firewall, etc.).

## Prerequisites

1. A [TestingBot account](https://testingbot.com) — grab your key and secret
   from the [member area](https://testingbot.com/members/user/edit).
2. Add them as environment variables named `TB_KEY` and `TB_SECRET`, either in
   **Project Settings → Environment Variables** or in a
   [context](https://circleci.com/docs/contexts/).
3. The tunnel needs **Java 11+** (17 LTS recommended). The orb's `default`
   executor (`cimg/openjdk:17.0`) provides this out of the box; on your own
   image, make sure a JRE is available.

## Quick start

### Option A: the `with-tunnel` job

Wrap your test steps — the orb handles install, start, and (always) teardown:

```yaml
version: 2.1

orbs:
  testingbot: testingbot/testingbot@1.0

workflows:
  test:
    jobs:
      - testingbot/with-tunnel:
          tunnel_identifier: circleci-<< pipeline.number >>
          steps:
            - run: npm run test:e2e
```

### Option B: individual commands in your own job

```yaml
version: 2.1

orbs:
  testingbot: testingbot/testingbot@1.0

jobs:
  e2e-tests:
    executor: testingbot/default
    steps:
      - checkout
      - testingbot/install-tunnel
      - testingbot/start-tunnel
      - run: npm run test:e2e
      - testingbot/stop-tunnel
```

While the tunnel is running, point your Selenium/Appium tests at
`http://localhost:4445/wd/hub` instead of `https://hub.testingbot.com/wd/hub`
(no credentials needed in the URL when using the local relay), or keep using
the remote hub — traffic to your local app is routed through the tunnel either
way. When you set a `tunnel_identifier`, pass the same value in your test's
desired capabilities.

## Commands

### `install-tunnel`

| Parameter      | Type   | Default                                                | Description                          |
| -------------- | ------ | ------------------------------------------------------ | ------------------------------------ |
| `install_dir`  | string | `~/testingbot-tunnel`                                   | Where to install the tunnel jar.     |
| `download_url` | string | `https://testingbot.com/downloads/testingbot-tunnel.zip` | Tunnel archive to download.          |

### `start-tunnel`

| Parameter           | Type         | Default                       | Description                                                        |
| ------------------- | ------------ | ----------------------------- | ------------------------------------------------------------------ |
| `key`               | env_var_name | `TB_KEY`                      | Env var holding your TestingBot key.                               |
| `secret`            | env_var_name | `TB_SECRET`                   | Env var holding your TestingBot secret.                            |
| `tunnel_identifier` | string       | `""`                          | Named tunnel; required for parallel tunnels.                       |
| `se_port`           | integer      | `4445`                        | Local port of the tunnel's Selenium relay.                         |
| `ready_timeout`     | integer      | `120`                         | Seconds to wait for the tunnel to become ready.                    |
| `extra_args`        | string       | `""`                          | Extra flags passed to the tunnel jar, e.g. `--nobump --log-level debug`. |
| `logfile`           | string       | `/tmp/testingbot-tunnel.log`  | Tunnel log file (printed if startup fails).                        |
| `install_dir`       | string       | `~/testingbot-tunnel`         | Where the tunnel jar was installed.                                |

### `stop-tunnel`

No parameters. Gracefully shuts the tunnel down; runs even when earlier steps
failed (`when: always`), so it's safe to put at the end of any job.

## Jobs

### `with-tunnel`

Runs your `steps` with a tunnel active on the executor of your choice
(defaults to this orb's `cimg/openjdk` executor). Accepts all `start-tunnel`
parameters plus `executor`, `checkout` (default `true`) and `steps`.

## Development

```bash
circleci orb pack src > orb.yml
circleci orb validate orb.yml
shellcheck src/scripts/*.sh
```

The CI pipeline (`.circleci/config.yml`) lints, packs, reviews and
shellchecks on every push, then runs an integration test that starts a real
tunnel (requires `TB_KEY`/`TB_SECRET` in the `testingbot-credentials`
context).

## Publishing (maintainers)

One-time setup, to be done by an owner of the TestingBot org on CircleCI:

1. Push this repo to GitHub (e.g. `testingbot/circleci-orb`) and set it up as
   a CircleCI project.
2. Claim the namespace (one immutable namespace per org):
   `circleci namespace create testingbot --org-id <org-id>`
3. Create the orb: `circleci orb create testingbot/testingbot`
4. Create an `orb-publishing` context containing a personal API token
   (`CIRCLE_TOKEN`) of a namespace owner, and a `testingbot-credentials`
   context containing `TB_KEY`/`TB_SECRET` for the integration test.

Releases: merge to `main`, then create a GitHub release tagged `vX.Y.Z` —
the pipeline packs, tests and publishes that version to the
[orb registry](https://circleci.com/developer/orbs). Published versions are
immutable. To get listed on
[circleci.com/integrations](https://circleci.com/integrations/), apply to the
[CircleCI partner program](https://circleci.com/partners/) referencing the
published orb.

## License

[MIT](LICENSE). By publishing to the orb registry you agree to CircleCI's
[Code Sharing Terms of Service](https://circleci.com/legal/code-sharing-terms/).
