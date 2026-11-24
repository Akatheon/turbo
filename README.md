# Akatheon Turbo

Runs only the tests a pull request can affect, and signs a receipt of what ran, what was skipped and why.

Start in **shadow** mode: your full suite still runs, and the job summary shows what Akatheon Turbo would have skipped
and whether skipping it would have missed a failure. Switch a job to **enforce** when you trust what you see.

## Use

```yaml
name: tests
on:
  push:
    branches: [main]
  pull_request:

jobs:
  certificates:            # keeps the certificates of main current
    if: github.event_name == 'push'
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      # ... install your project as you do today ...
      - uses: akatheon/turbo@v1
        with:
          mode: refresh
          command: python -m pytest -n 4 tests
          license-key: ${{ secrets.AKATHEON_CI_TOKEN }}   # private repositories only

  tests:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      # ... install your project as you do today ...
      - uses: akatheon/turbo@v1
        with:
          mode: shadow       # then: enforce
          command: python -m pytest -n 4 tests
          license-key: ${{ secrets.AKATHEON_CI_TOKEN }}   # private repositories only
```

The first `refresh` on main records certificates for every test; later ones update only what each merge touched.
Recording runs each test in a fork of a process that has already set up its session, package and module fixtures, so a
fixture that builds a wheel or starts a server runs once per recording process, not once per test. When your command
uses `-n` (pytest-xdist), recording processes are told they are xdist workers, so your conftest's guards for parallel
workers still hold. A test that cannot run in a fork (one that crashes, hangs or never finishes there, as with PyTorch's
thread pools) is recorded again alone, in a process of its own.
Certificates live in GitHub's Actions cache. A pull request whose base has none (GitHub evicts cache entries unused
for 7 days) runs the full suite and says so.

## Inputs

| input | default | |
|---|---|---|
| `mode` | `shadow` | `shadow`, `enforce`, `record` or `refresh` |
| `command` | (required) | your test command, as you run it today |
| `file-mode` | | `record` and `refresh`: test files to record in one process instead of a fork per test, one per line (rarely needed: shared fixtures are set up once already) |
| `certs-dir` | `.akatheon-ci` | where certificates live on the runner |
| `base` | | override the revision the certificates describe |
| `signing-key` | | an Ed25519 seed (64 hex characters) from a secret, to sign receipts with your key |
| `license-key` | | your Akatheon Turbo key, from a secret; public repositories need none |
| `telemetry` | `on` | with a key: the run's numeric summary goes to Akatheon (below); `off` sends nothing |

Outputs: `selected`, `known` (tests with certificates) and `receipt` (the signed receipt's path).

## Requirements

- Linux x86_64 runners (checked on Ubuntu 22.04 and 24.04).
- pytest, with Python 3.12 or later in the test environment.
- `actions/checkout`'s default one-commit checkout is enough: the action fetches the commit its certificates describe
  from `origin`, and runs the full suite (saying so in the summary) if it cannot.

## Licence keys

- **Public repositories:** free, in every mode, with no key.
- **Private repositories:** a key from [turbo.akatheon.com](https://turbo.akatheon.com), stored as the secret
  `AKATHEON_CI_TOKEN`. A trial key runs `shadow`, `record` and `refresh` (a trial's `enforce` runs as `shadow`); Team and
  Growth keys run everything.
- **Without a valid key** (none, expired, another organization's, or a subscription that ended), every test runs and the
  job summary says why. The job's result is always your tests' result: Turbo never fails a build over its licence.

## What it downloads and what it sends

The action downloads one release archive from `dl.akatheon.com`, pinned by SHA-256 in `run.sh`, and refuses to run
anything that does not match. Zero source code, secrets, test names, or logs ever leave your runner (optional numeric
receipt summary can be disabled with `telemetry: off`). Certificates stay in your repository's Actions cache, and
receipts on the runner and in your job's summary.

With a valid key, and unless `telemetry` is `off`, the action makes two calls to `turbo.akatheon.com`, each authenticated
with that key (Akatheon's own credential), limited to 5 seconds and never able to fail the job. Before the tests, it checks the subscription. After them, it sends the run's
numeric summary:
- test counts and seconds;
- the commit and the receipt's SHA-256 and signature;
- GitHub's numeric repository ID, run ID and pull request number.

Without a key, nothing is sent. Model API keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`,
`GOOGLE_API_KEY`) are removed from the test processes it starts, so a run never bills a model.

## See it run

Public forks with Akatheon Turbo beside their full suites, each with demo pull requests:
[akatheon-labs/fastapi](https://github.com/akatheon-labs/fastapi) and
[akatheon-labs/pydantic-ai](https://github.com/akatheon-labs/pydantic-ai).

## Licence

Proprietary: see [LICENSE](LICENSE). You may run it in your CI during an authorized evaluation, on Akatheon's free
tier for open-source projects, or with a paid subscription. Patent pending.

Copyright (c) 2026 Beaverise Inc. ("Akatheon").
