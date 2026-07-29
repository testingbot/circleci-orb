<p align="center">
  <img src="assets/logo.svg" alt="TestingBot" width="140">
</p>

<h1 align="center">TestingBot Orb for CircleCI</h1>

<p align="center">
  <a href="https://circleci.com/developer/orbs/orb/testingbot/testingbot"><img src="https://badges.circleci.com/orbs/testingbot/testingbot.svg" alt="CircleCI Orb Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="License"></a>
</p>

Run Selenium, Appium, Playwright and Cypress tests on
[TestingBot](https://testingbot.com)'s cross-browser and real device cloud
from CircleCI.

This orb manages the [TestingBot Tunnel](https://testingbot.com/support/tunnel),
which gives TestingBot's browsers and real mobile devices secure access to a
web app that is only reachable from inside your CircleCI job — an app you just
built and started on `localhost`, or a staging environment behind a firewall.
Without a tunnel, TestingBot's browsers cannot reach those hosts.

It works with any test framework that drives a browser through TestingBot,
including Selenium WebDriver, Appium, Playwright, Cypress, WebdriverIO and
Nightwatch — the tunnel carries the traffic regardless of which client you
use.

If your app is already on a public URL, you do not need this orb: point your
tests at `https://hub.testingbot.com/wd/hub` and go.

## Contents

- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Pointing your tests at the tunnel](#pointing-your-tests-at-the-tunnel)
- [Commands](#commands)
- [Jobs](#jobs)
- [Executors](#executors)
- [Running tests in parallel](#running-tests-in-parallel)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Publishing](#publishing-maintainers)

## Prerequisites

1. A [TestingBot account](https://testingbot.com). Your key and secret are in
   the [member area](https://testingbot.com/members/user/edit).
2. Add them to CircleCI as environment variables named `TB_KEY` and
   `TB_SECRET`, either under **Project Settings → Environment Variables** or in
   a [context](https://circleci.com/docs/contexts/). Never commit them.
3. Java 11 or newer on the executor (17 LTS recommended). This orb's `default`
   executor provides it; if you bring your own image, make sure a JRE is
   installed.
4. This is a partner orb, not a CircleCI-certified one, so your organization
   must allow uncertified orbs under **Organization Settings → Security**.

## Quick start

### Option A: the `with_tunnel` job

Wrap your test steps. The orb installs the tunnel, starts it, runs your steps,
and always stops the tunnel afterwards — even if your tests fail.

```yaml
version: 2.1

orbs:
  testingbot: testingbot/testingbot@1.0

workflows:
  test:
    jobs:
      - testingbot/with_tunnel:
          context: testingbot   # where TB_KEY and TB_SECRET live
          steps:
            - run: npm ci
            - run: npm start &
            - run: npm run test:e2e
```

### Option B: individual commands in your own job

Use this when you need control over the executor, caching, or step ordering.

```yaml
version: 2.1

orbs:
  testingbot: testingbot/testingbot@1.0

jobs:
  e2e-tests:
    docker:
      - image: cimg/node:20.11    # any image with Java 11+ available
    steps:
      - checkout
      - testingbot/install_tunnel
      - testingbot/start_tunnel
      - run: npm run test:e2e
      - testingbot/stop_tunnel    # runs even if the previous step failed

workflows:
  test:
    jobs:
      - e2e-tests:
          context: testingbot
```

## Pointing your tests at the tunnel

Once `start_tunnel` completes, the tunnel exposes a local Selenium relay:

```
http://localhost:4445/wd/hub
```

Point your WebDriver client at that URL and no credentials are needed in the
URL itself. You can verify it is up with:

```bash
curl http://localhost:4445/wd/hub/status
```

Alternatively, keep using the remote hub
(`https://KEY:SECRET@hub.testingbot.com/wd/hub`) — traffic to your local app is
routed through the tunnel either way. If you started the tunnel with a
`tunnel_identifier`, pass the same value in your test's `tb:options`
capabilities so TestingBot routes through the right tunnel.

## Commands

### `install_tunnel`

Downloads and extracts the TestingBot Tunnel jar. Fails with a clear message
if Java or `unzip` is missing. Skips the download if the jar is already
present, so it is safe to call twice.

| Parameter      | Type   | Default                                                    | Description                      |
| -------------- | ------ | ---------------------------------------------------------- | -------------------------------- |
| `install_dir`  | string | `~/testingbot-tunnel`                                      | Where to install the tunnel jar. |
| `download_url` | string | `https://testingbot.com/downloads/testingbot-tunnel.zip`   | Tunnel archive to download.      |

### `start_tunnel`

Starts the tunnel in the background and blocks until it reports ready (using
the tunnel's own ready-file signal). If the tunnel fails to start or times
out, the step fails and prints the tunnel log.

| Parameter           | Type           | Default                      | Description                                                              |
| ------------------- | -------------- | ---------------------------- | ------------------------------------------------------------------------ |
| `key`               | env_var_name   | `TB_KEY`                     | Name of the env var holding your TestingBot key.                          |
| `secret`            | env_var_name   | `TB_SECRET`                  | Name of the env var holding your TestingBot secret.                       |
| `tunnel_identifier` | string         | `""`                         | Names this tunnel. Required when running more than one at a time.         |
| `se_port`           | integer        | `4445`                       | Local port for the Selenium relay.                                        |
| `ready_timeout`     | integer        | `120`                        | Seconds to wait for the tunnel to become ready before failing.            |
| `extra_args`        | string         | `""`                         | Flags passed straight through to the tunnel jar, e.g. `--nobump`.         |
| `logfile`           | string         | `/tmp/testingbot-tunnel.log` | Tunnel log path. Printed automatically if startup fails.                   |
| `install_dir`       | string         | `~/testingbot-tunnel`        | Where the jar was installed.                                              |

Note that `key` and `secret` take the **name** of an environment variable, not
the value — `key: MY_TB_KEY`, not `key: abc123`. The orb passes credentials to
the tunnel through its environment, so they never appear in the process list.

### `stop_tunnel`

Shuts the tunnel down gracefully so the session is released on TestingBot's
side. Takes no parameters and uses `when: always`, so it still runs after a
failed test step. Does nothing (without failing) if no tunnel is running.

## Jobs

### `with_tunnel`

Runs your steps with a tunnel active, handling setup and teardown.

| Parameter           | Type     | Default   | Description                                             |
| ------------------- | -------- | --------- | ------------------------------------------------------- |
| `steps`             | steps    | —         | The test steps to run while the tunnel is up. Required. |
| `executor`          | executor | `default` | Executor to run on. Must provide Java 11+.              |
| `checkout`          | boolean  | `true`    | Whether to check out your code first.                   |

It also accepts `key`, `secret`, `tunnel_identifier`, `se_port`,
`ready_timeout` and `extra_args`, which are passed to `start_tunnel`.

## Executors

### `default`

A Docker executor based on `cimg/openjdk`, which has the Java runtime the
tunnel needs.

| Parameter | Type   | Default | Description                       |
| --------- | ------ | ------- | --------------------------------- |
| `tag`     | string | `17.0`  | Tag of the `cimg/openjdk` image.  |

If your tests need another runtime, use your own image with Java installed
rather than this executor.

## Running tests in parallel

When a job uses `parallelism`, each container starts its own tunnel. Give each
one a distinct `tunnel_identifier`, otherwise they collide.

Parameter values are **literal strings** — CircleCI does not expand shell
variables inside them, so `tunnel_identifier: build-$CIRCLE_NODE_INDEX` would
give every container the identical name `build-$CIRCLE_NODE_INDEX`. To build
an identifier at runtime, export `TB_TUNNEL_IDENTIFIER` via `BASH_ENV` and
leave the parameter unset:

```yaml
jobs:
  e2e-tests:
    executor: testingbot/default
    parallelism: 4
    steps:
      - checkout
      - testingbot/install_tunnel
      - run:
          name: Derive a per-container tunnel identifier
          command: |
            echo "export TB_TUNNEL_IDENTIFIER=build-${CIRCLE_BUILD_NUM}-${CIRCLE_NODE_INDEX}" >> "$BASH_ENV"
      - testingbot/start_tunnel
      - run: npm run test:e2e   # read $TB_TUNNEL_IDENTIFIER in your capabilities
      - testingbot/stop_tunnel
```

Your tests can read the same `TB_TUNNEL_IDENTIFIER` variable when building
their `tb:options` capabilities. Pipeline values such as
`<< pipeline.number >>` *are* substituted at config time, so those work
directly in the parameter.

Your TestingBot plan determines how many tunnels can run concurrently.

## Troubleshooting

**"TestingBot credentials not found"** — `TB_KEY` and `TB_SECRET` are not
visible to the job. If they are in a context, confirm the job actually
references that context, and that your org grants access to it. Note that
CircleCI does not pass secrets to builds from forked pull requests.

**"Java is required to run the TestingBot Tunnel"** — your executor has no
JRE. Use `testingbot/default`, or an image such as `cimg/openjdk:17.0`, or
install Java before calling `install_tunnel`.

**"You already have N tunnels active"** — you have hit your plan's concurrent
tunnel limit. Note that a tunnel is not always released the instant the job
ends: in testing, a tunnel remained `READY` server-side for more than ten
minutes after a clean shutdown. Back-to-back pipelines can therefore exhaust
the limit even when each job stops its tunnel properly. You can list and close
active tunnels through the API:

```bash
curl -u "$TB_KEY:$TB_SECRET" https://api.testingbot.com/v1/tunnel/list
curl -u "$TB_KEY:$TB_SECRET" -X DELETE https://api.testingbot.com/v1/tunnel/<id>
```

**Tunnel did not become ready in time** — the step prints both the tunnel's
console output and its log file, which usually name the cause. Raise
`ready_timeout` on a slow or busy runner. For more detail, add
`extra_args: --log-level debug` — but remember build logs are visible to
everyone with project read access.

**Tests cannot reach the app** — confirm your app is actually listening inside
the job before the tests run, and that your tests point at
`http://localhost:4445/wd/hub` (or pass the matching `tunnel_identifier`). For
apps using WebSockets or server-sent events, add `extra_args: --nobump`.

## Development

Install the tooling:

```bash
brew install circleci shellcheck bats-core yq
```

Pack, validate, and lint:

```bash
circleci orb pack src > orb.yml
circleci orb validate orb.yml
shellcheck src/scripts/*.sh test/local_e2e.sh
```

### End-to-end testing

`test/local_e2e.sh` runs the orb inside a real CircleCI job container via
`circleci local execute`, with the packed orb inlined into the config. This
exercises the orb itself — `<<include>>` script injection, parameter
substitution, executor resolution — rather than just the shell scripts, and
needs no published version. Requires Docker.

```bash
./test/local_e2e.sh install   # download the jar (no credentials needed)
./test/local_e2e.sh full      # start a real tunnel, check the relay, stop it
./test/local_e2e.sh nocreds   # assert a clean failure when credentials are missing
```

The `full` scenario reads `TB_KEY`/`TB_SECRET`, falling back to a `key:secret`
line in `~/.testingbot`. Credential values are redacted from its output.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the review checks the CI pipeline
runs and the conventions they enforce.

## Publishing (maintainers)

One-time setup, by an **owner** of the TestingBot organization on CircleCI
(only owners can publish production orb versions):

1. Create the GitHub repository at
   `https://github.com/testingbot/circleci-orb` and push this code. The repo
   must be public and reachable before the first publish — review check RC006
   fetches the `source_url` in `src/@orb.yml` and fails if it 404s.
2. Add the repo as a CircleCI project.
3. Claim the namespace — one per organization, and it cannot be changed:
   ```bash
   circleci namespace create testingbot --org-id <org-id>
   ```
4. Create the orb:
   ```bash
   circleci orb create testingbot/testingbot
   ```
5. Create two contexts: `orb-publishing`, holding a namespace owner's personal
   API token as `CIRCLE_TOKEN`, and `testingbot-credentials`, holding `TB_KEY`
   and `TB_SECRET` for the integration test.

To release, merge to `main` and create a GitHub release tagged `vX.Y.Z`. The
`test-deploy` pipeline runs the integration test and publishes that version.
Published versions are immutable — they cannot be edited or deleted, so
renaming a command later is a breaking change.

To get listed on [circleci.com/integrations](https://circleci.com/integrations/),
apply to the [CircleCI partner program](https://circleci.com/partners/)
referencing the published orb. There is no self-serve submission form.

## License

[MIT](LICENSE). Orbs published to the CircleCI registry are world-readable and
covered by CircleCI's
[Code Sharing Terms of Service](https://circleci.com/legal/code-sharing-terms/).
