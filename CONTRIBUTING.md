# Contributing

Thanks for helping improve the TestingBot orb.

## Repository layout

```
src/@orb.yml          Orb metadata (description, home/source URLs)
src/commands/         One YAML file per command
src/jobs/             One YAML file per reusable job
src/executors/        Executor definitions
src/examples/         Usage examples shown on the orb registry page
src/scripts/          Bash scripts injected into steps via <<include()>>
test/local_e2e.sh     Runs the orb in a real CircleCI job container
.circleci/            Lint/pack/review pipeline and the test-deploy pipeline
```

Component names (files in `commands/`, `jobs/`, `executors/`) must be
**snake_case** — CircleCI's `orb-tools/review` check RC010 rejects hyphens,
and the pipeline runs that check on every push.

Non-trivial shell belongs in `src/scripts/` and is pulled in with
`<<include(scripts/name.sh)>>` rather than written inline. Review check RC009
enforces this for commands longer than 64 characters, and it keeps the shell
lintable and syntax-highlighted.

## Prerequisites

- [CircleCI CLI](https://circleci.com/docs/local-cli/)
- [Docker](https://docs.docker.com/get-docker/) (for the end-to-end test)
- [ShellCheck](https://www.shellcheck.net/) and
  [bats-core](https://github.com/bats-core/bats-core) for local checks

```bash
brew install circleci shellcheck bats-core yq
```

## Local checks

Pack and validate the orb, and lint the scripts:

```bash
circleci orb pack src > orb.yml
circleci orb validate orb.yml
shellcheck src/scripts/*.sh test/local_e2e.sh
```

Run CircleCI's orb best-practice checks (the same ones the pipeline runs):

```bash
curl -fsSL -o /tmp/review.bats \
  https://raw.githubusercontent.com/CircleCI-Public/orb-tools-orb/master/src/scripts/review.bats
ORB_VAL_SOURCE_DIR=src ORB_VAL_ORB_NAME=testingbot \
ORB_VAL_MAX_COMMAND_LENGTH=64 ORB_VAL_RC_EXCLUDE="" \
  bats -T --pretty /tmp/review.bats
```

## End-to-end testing

`test/local_e2e.sh` inlines the packed orb into a config and runs it with
`circleci local execute`, so the orb is exercised inside the same container
image CircleCI uses — including `<<include>>` injection, parameter
substitution, and executor resolution. This catches things that packing and
validation cannot.

```bash
./test/local_e2e.sh install   # download the tunnel jar (no credentials needed)
./test/local_e2e.sh full      # start a real tunnel, verify the relay, stop it
./test/local_e2e.sh nocreds   # assert a clean failure when credentials are absent
```

The `full` scenario needs real credentials. Set `TB_KEY` and `TB_SECRET`, or
put a `key:secret` line in `~/.testingbot`. Credential values are redacted
from the script's output.

## Pull requests

1. Branch from `main` and make your change.
2. Run the local checks and, if you touched tunnel behaviour, the `full`
   end-to-end scenario.
3. Update `README.md` when you add or change a parameter, and add an entry to
   `CHANGELOG.md` under `[Unreleased]`.
4. Open a PR describing what changed and how you verified it.

Remember that published orb versions are immutable: renaming a command or
changing a parameter's meaning is a breaking change requiring a major version
bump, so those are worth discussing in an issue first.

## Releasing (maintainers)

Merge to `main`, then create a GitHub release tagged `vX.Y.Z`. The
`test-deploy` pipeline runs the integration test and publishes that version to
the registry. See the Publishing section of the [README](README.md) for the
one-time setup.
