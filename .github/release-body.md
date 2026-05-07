Anvil is an APM-first marketplace of three packages:
`anvil-common-stable` (internal, shipped transitively),
`anvil-core-stable` (discipline), and
`anvil-orchestrator-stable` (automated inner loop).

### Install

**APM:**
```
apm marketplace add Olino3/anvil
apm install anvil-orchestrator-stable@anvil   # or anvil-core-stable@anvil
```

**Claude Code:**
```
claude /plugin marketplace add https://github.com/Olino3/anvil.git
claude /plugin install anvil-orchestrator-stable
```

**Pre-built bundles:** download the `.tar.gz` for your package
and host (`claude`, `copilot`, `cursor`, `opencode`) from the
Assets section below and extract into your project. Eight
bundles are attached per release — naming pattern
`anvil-<package-name>-<version>-<host>.tar.gz`.

Coming from v1.x? See the
[migration table](https://github.com/Olino3/anvil#upgrading-from-v1x).
