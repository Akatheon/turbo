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
```

The first `refresh` on main records certificates for every test; later ones update only what each merge touched.
Certificates live in GitHub's Actions cache. A pull request whose base has none (GitHub evicts cache entries unused
for 7 days) runs the full suite and says so.

## Inputs

| input | default | |
|---|---|---|
| `mode` | `shadow` | `shadow`, `enforce`, `record` or `refresh` |
| `command` | (required) | your test command, as you run it today |
| `file-mode` | | `record` and `refresh`: test files whose tests share an expensive fixture, one per line |
| `certs-dir` | `.akatheon-ci` | where certificates live on the runner |
| `base` | | override the revision the certificates describe |
| `signing-key` | | an Ed25519 seed (64 hex characters) from a secret, to sign receipts with your key |

Outputs: `selected`, `known` (tests with certificates) and `receipt` (the signed receipt's path).

## Requirements

- Linux x86_64 runners (checked on Ubuntu 22.04 and 24.04).
- pytest, with Python 3.12 or later in the test environment.
- `actions/checkout`'s default one-commit checkout is enough: the action fetches the commit its certificates describe
  from `origin`, and runs the full suite (saying so in the summary) if it cannot.

## What it downloads and what it sends

The action downloads one release archive from `dl.akatheon.com`, pinned by SHA-256 in `run.sh`, and refuses to run
anything that does not match. Nothing leaves the runner: certificates stay in your repository's Actions cache, and
receipts on the runner and in your job's summary. Model API keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`,
`GOOGLE_API_KEY`) are removed from the test processes it starts, so a run never bills a model.

## See it run

Public forks with Akatheon Turbo beside their full suites, each with demo pull requests:
[akatheon-labs/fastapi](https://github.com/akatheon-labs/fastapi) and
[akatheon-labs/pydantic-ai](https://github.com/akatheon-labs/pydantic-ai).

## Licence

Proprietary: see [LICENSE](LICENSE). You may run it in your CI during an authorized evaluation, on Akatheon's free
tier for open-source projects, or with a paid subscription. Patent pending.

Copyright (c) 2026 Beaverise Inc. ("Akatheon").
