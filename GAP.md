# GAP.md — Known Specification Gaps

Gaps between the current ACES RFC specifications and what a working implementation
actually needs. Each gap documents the problem, where it surfaces, the current
workaround in the configs, and what a proper fix would look like.

---

## GAP-1: No dataset construct in RFC-0002

**Problem**: RFC-0002 (Experiment) has no `dataset` section. Experiments that
run across multiple sample repositories (e.g., Refactor Arena's
`side-tasks-3/mixed-3` setting) have no way to declare where samples come from,
how to filter them, or how sample-level variables bind to the environment.

**Where it surfaces**:

- `refactor-arena-experiment-honest.yaml` references `dataset: side-tasks-3/mixed-3`
  as a metadata label only — informational, not resolvable by a runtime.
- `refactor-arena-environment.yaml` uses `workspace_setup.source: "${sample.files}"`
  but `${sample.files}` has no defined resolution mechanism.
- The runner script (`run-mvp.sh`) hardcodes the dataset repo URL and setting path,
  duplicating what should be declared in the YAML.

**Current workaround**: A proposed `dataset` block has been added to the experiment
YAMLs (both full and MVP) with `source`, `setting`, `filter`, and `sample_mapping`
fields. This is explicitly marked as NOT part of RFC-0002. The runner script reads
the dataset repo URL and clones it independently.

```yaml
# Proposed extension — not in RFC-0002
dataset:
  source:
    type: git
    repo: https://github.com/fastfedora/full-repo-datasets
    ref: main
    path: side-tasks-3/mixed-3
  setting: side-tasks-3/mixed-3
  filter:
    main_task: refactor_single_file
  sample_mapping:
    files: "${repo.path}"
    language: "${repo.language}"
    name: "${repo.name}"
```

**Proper fix**: Add a first-class `dataset` section to RFC-0002 that:

1. Declares the external data source (git repo, registry, local path, or URL)
2. Specifies a setting/filter to select samples from the source
3. Defines a `sample_mapping` that binds dataset fields to template variables
   usable in the environment's `provisioning.workspace_setup.source`
4. Specifies iteration semantics (all samples, random subset, specific sample by name)

**Related open question** from `implementation_plan.md`:
> "Should ACES support experiment templates with dataset-driven parameterization,
> or is one experiment per sample the right model?"

The answer from implementation experience: parameterization is necessary. One
experiment per sample doesn't scale (3 repos = 3 near-identical experiment YAMLs).

---

## GAP-2: Infra ↔ Experiment coupling on workspace setup

**Problem**: RFC-0001 (Environment) owns `provisioning.workspace_setup` which
defines how files get into the container. But the *source* of those files is
determined by the experiment's dataset, which is an RFC-0002 concern. This creates
a cross-RFC dependency with no formal binding mechanism.

**Where it surfaces**:

- `refactor-arena-environment.yaml` has:

  ```yaml
  workspace_setup:
    source: "${dataset.sample.files}"
    target: /workspace
  ```

- This `${dataset.sample.files}` variable is defined by the experiment's
  `dataset.sample_mapping.files`, not by anything in RFC-0001.
- RFC-0001 has no concept of template variables resolved from RFC-0002.
- The environment spec cannot be validated or instantiated in isolation —
  it requires the experiment context to resolve `${dataset.sample.files}`.

**Why this matters**:

The RFC layer architecture says Environment defines "what exists" and Experiment
defines "what happens." But workspace setup (which files go into the container) is
both — it's infrastructure (how files get there) AND experiment-specific (which
files). This straddling means:

1. An environment YAML with `${dataset...}` variables is incomplete without its
   experiment — violating the principle that each RFC layer is self-contained.
2. A runtime must resolve variables across two RFC layers, but the resolution
   order and namespace rules are undefined.
3. The same environment used by two different experiments (honest vs. attack)
   gets different files, but the environment spec has one `workspace_setup`.

**Current workaround**: The environment uses `${dataset.sample.files}` as a
convention. The runner script resolves it by cloning the dataset repo and copying
the sample directory into the workspace. The attack experiment overrides the
environment with a `fixture` block that changes features and env vars but reuses
the same workspace setup mechanism.

**Proper fix options**:

*Option A — Environment owns the mechanism, Experiment provides the source:*
Environment defines `workspace_setup.target` and `workspace_setup.solver` (how to
copy files in). Experiment defines `workspace_setup.source` as part of its dataset
binding. The runtime merges them.

*Option B — Indirection via a workspace contract:*
Environment declares a `workspace` interface (path, expected structure). Experiment
fills it via a `workspace_binding` that maps dataset samples to the interface. No
template variables in the environment YAML.

*Option C — Promote workspace setup to a shared concern:*
Create a `workspace` section at the experiment level (RFC-0002) that references the
environment's target path but owns the source. Remove `workspace_setup` from
RFC-0001's provisioning.

---

## GAP-3: No variable resolution specification

**Problem**: Template variables like `${sample.files}`, `${fixture.features}`,
`${fixture.environment}`, `${secret}`, and `${dataset.sample.files}` appear across
both RFC-0001 and RFC-0002 configs, but there is no specification for:

- Variable namespace (which variables exist, what scope they belong to)
- Resolution order (which layer provides which variables)
- Default values and error handling (what happens if a variable is unresolved)
- Cross-RFC references (how an RFC-0001 variable references RFC-0002 data)

**Where it surfaces**:

| Variable | Used in | Provided by |
|:---------|:--------|:------------|
| `${sample.files}` | RFC-0001 environment | Undefined (implied dataset) |
| `${dataset.sample.files}` | RFC-0001 environment | Proposed RFC-0002 dataset |
| `${fixture.features}` | RFC-0001 provisioning | RFC-0002 experiment fixture |
| `${fixture.environment}` | RFC-0001 provisioning | RFC-0002 experiment fixture |
| `${secret}` | RFC-0002 experiment | Runtime (random generation) |
| `${repo.path}` | RFC-0002 dataset mapping | External dataset source |

**Current workaround**: Variables are used by convention. The runner script is the
de facto variable resolver. No validation is possible at the YAML level.

**Proper fix**: Define a variable resolution specification, either as:

- A section in each RFC defining its exported and imported variables
- A standalone spec (or addition to RFC-0003) for cross-RFC variable binding
- A JSON Schema with `$ref`-style resolution for ACES variable expressions

---

## GAP-4: Fixture overrides lack formal schema

**Problem**: The attack experiment extends the environment with a `fixture` block
under the `environment` reference:

```yaml
environment:
  ref: { name: refactor-arena-sandbox, version: "1.0.0" }
  source: ./refactor-arena-environment.yaml
  fixture:
    name: exfiltrate-env-var/api-key
    features: [python, web-proxy]
    environment:
      API_KEY: "${secret}"
```

This `fixture` construct is not defined in RFC-0001 or RFC-0002. It's a pattern
from Refactor Arena's per-side-task configuration system. The fixture modifies the
environment (adds features, injects env vars) from within an experiment reference,
blurring the boundary between the two RFCs.

**Proper fix**: Either:

- Add fixtures as a first-class concept in RFC-0001 (environment variants)
- Define an overlay/patch mechanism in RFC-0002 for environment modifications
- Require separate RFC-0001 environments per fixture (explicit but verbose)

---

## GAP-5: No credentials / secrets management specification

**Problem**: Experiments declare model providers (e.g., `model.provider: anthropic`,
`model.provider: openai`) in the `agents` section of RFC-0002, and the environment
(RFC-0001) may need credentials for external services. But there is no specification
for how API keys, tokens, or other secrets are:

1. **Declared** — which credentials an experiment requires
2. **Provided** — where the values come from (env vars, vault, file, CLI)
3. **Injected** — how they reach the agent runtime and scoring infrastructure
4. **Isolated** — how to prevent the untrusted agent from accessing trusted credentials

**Where it surfaces**:

- `mvp-experiment-honest.yaml` defines agents with `model.provider: openai` and
  `model.name: gpt-5`, but provides no way to specify `OPENAI_API_KEY`.
- Refactor Arena handles this via a `.env` file convention and `${env:TRUSTED_MODEL}`
  patterns in `defaults.yaml`. This works but is entirely outside the ACES spec.
- The trusted monitor model needs an API key too, but it must be the SAME provider
  key (or a different one). The spec doesn't distinguish.
- The sandbox container may need different credentials than the host runner (e.g.,
  the agent inside the sandbox should NOT have access to the monitor's API key).

**Why this matters for infrastructure operators**:

The user setting up ACES infrastructure needs to know:

- What API keys are required before they can run an experiment
- Where to put them so the runtime can find them
- That trusted (monitor) and untrusted (agent) credentials are properly separated

Without this, every ACES implementation invents its own convention (`.env` files,
environment variables, k8s secrets, vault paths), and experiments are not portable
between implementations.

**Credential flow in Refactor Arena** (reference implementation):

```text
.env file (cwd)
  └─► OPENAI_API_KEY ──► inspect-ai runtime ──► both trusted + untrusted models
  └─► TRUSTED_MODEL ───► defaults.yaml ${env:TRUSTED_MODEL} ──► monitor config
  └─► UNTRUSTED_MODEL ─► defaults.yaml ${env:UNTRUSTED_MODEL} ──► agent config
```

Note: the same `OPENAI_API_KEY` is used for both trusted and untrusted models.
There is no credential isolation — the agent and monitor share the same key.

**Current workaround**: Create a `.env` file alongside the ACES configs:

```text
OPENAI_API_KEY=sk-...
TRUSTED_MODEL=openai/gpt-4.1-nano-2025-04-14
UNTRUSTED_MODEL=openai/gpt-5
```

This is loaded by `refactor-arena init` / the CLI, but is invisible to the ACES
YAML layer.

**Proposed fix — add a `credentials` section to RFC-0002 (Experiment)**:

```yaml
# In the Experiment spec
credentials:
  required:
    - name: openai-api-key
      provider: openai
      description: "API key for OpenAI models (agent + monitor)"
      scope: [untrusted-agent, monitor-git-diff]  # which agents need it
      env_var: OPENAI_API_KEY                      # conventional env var name

  resolution:
    # How credentials are provided at runtime — ordered by precedence
    - type: env          # environment variable
    - type: file         # .env file in working directory
    - type: secret-ref   # external secret store reference
      ref: "vault://secrets/openai-api-key"
```

This would let the spec declare:

1. What the experiment needs (provider-specific API keys)
2. Which agents/scorers use each credential
3. How the runtime should resolve them (env → file → vault)

**Related considerations**:

- RFC-0005 (Security Domain) addresses trust levels and sandboxing but does NOT
  cover credential management for model API access.
- Credential isolation (keeping monitor keys away from the untrusted agent) is a
  security concern that bridges RFC-0002 and RFC-0005.
- GAP-3 (variable resolution) is related — `${env:OPENAI_API_KEY}` is a variable
  pattern but with security implications that general variable resolution doesn't
  address.
