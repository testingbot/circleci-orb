## What changed

<!-- A short description of the change and why it is needed. -->

## How it was verified

<!-- Which of these did you run? Include output for anything tunnel-related. -->

- [ ] `circleci orb pack src > orb.yml && circleci orb validate orb.yml`
- [ ] `shellcheck src/scripts/*.sh test/local_e2e.sh`
- [ ] `orb-tools` review checks (see CONTRIBUTING.md)
- [ ] `./test/local_e2e.sh full` against a real TestingBot tunnel
- [ ] Not applicable (docs-only change)

## Compatibility

- [ ] This change is backwards compatible
- [ ] This is a breaking change (renames a component, or changes a parameter's
      meaning or default) and needs a major version bump

## Checklist

- [ ] New or changed parameters are documented in `README.md`
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] Component filenames are snake_case (review check RC010)
- [ ] Non-trivial shell lives in `src/scripts/` and is `<<include>>`d (RC009)
