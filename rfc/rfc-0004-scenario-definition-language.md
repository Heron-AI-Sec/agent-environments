# RFC-0004: Scenario Definition Language

## Status

`Draft`

## Summary

This RFC proposes a declarative Scenario Definition Language (SDL) for
composing RFC-0001 environments and RFC-0002 experiments into reproducible,
runnable units. A scenario is the artifact an operator hands to a runtime to
execute end-to-end.

RFC-0001 defines "what exists." RFC-0002 defines "what happens." This
specification defines "what gets run" — the composition, initial state, and
execution lifecycle that connects them.

## Motivation

RFC-0001 and RFC-0002 are independently useful but leave three problems
unresolved for end-to-end execution:

1. **No composition contract.** There is no standard way to declare which
   environment version pairs with which experiment version. This is currently
   an implementation detail of the runtime, making scenarios non-portable.

2. **No initial state.** RFC-0001 `provisioning` configures infrastructure.
   RFC-0002 `injects` fire during experiment execution. Neither captures the
   pre-experiment state — specific files, data, flags, or conditions that must
   be true *before the experiment clock starts* but are not part of
   infrastructure setup.

3. **No instance concept.** There is no distinction between a Scenario
   (the reusable specification) and a Run (a specific execution of that
   scenario at a point in time). Without this, reproducibility tracking,
   result storage, and replay are implementation-specific.

### Design Principles

1. **Composition Only**: A scenario binds existing specs; it does not
   redefine them
2. **Domain-Agnostic**: No security, AI safety, or SWE-specific concepts;
   those belong in domain extension RFCs
3. **Optional Overlay**: RFC-0001 + RFC-0002 work without RFC-0004; this
   spec adds reproducibility and lifecycle semantics
4. **Minimal Initial State**: Declares what must be true before execution,
   separate from provisioning and runtime injects
5. **Run as First-Class**: The difference between a Scenario (template) and
   a Run (instance) is explicit

---

## Type Definitions

| Type               | Kind            | Values                                          |
| :----------------- | :-------------- | :---------------------------------------------- |
| `TeardownPolicy`   | extensible-enum | `preserve`, `destroy`, `snapshot`               |
| `ResetStrategy`    | extensible-enum | `reprovision`, `snapshot_restore`, `state_reset`|
| `ReadyCheckType`   | extensible-enum | `http`, `tcp`, `command`, `custom`              |
| `ArtifactSource`   | extensible-enum | `inline`, `file`, `git`, `registry`             |
| `RunStatus`        | extensible-enum | `provisioning`, `initializing`, `running`, `completed`, `failed`, `cancelled` |

**Kind definitions:**

- **`extensible-enum`**: A closed list of standard values. Custom values
  allowed via `x-` prefix (e.g., `x-custom-strategy`).

---

## Schema Overview

| Section        | Purpose                                                      |
| :------------- | :----------------------------------------------------------- |
| `environment`  | Reference to RFC-0001 environment                            |
| `experiment`   | Reference to RFC-0002 experiment                             |
| `initial_state`| Pre-experiment state: artifacts, flags, and conditions       |
| `lifecycle`    | Execution stages: provision, initialize, teardown, reset     |
| `evaluation`   | Optional scenario-level success criteria and ground truth    |

---

## Root Schema

| Field          | Type   | Required | Description                                   | Example                        |
| :------------- | :----- | :------- | :-------------------------------------------- | :----------------------------- |
| `apiVersion`   | String | Yes      | Schema version.                               | `aces.io/v1alpha1`             |
| `kind`         | String | Yes      | Resource type.                                | `Scenario`                     |
| `metadata`     | Object | Yes      | Identifying information.                      | `{name, description, version}` |
| `environment`  | Object | Yes      | Reference to RFC-0001 environment.            | `{ref: {name: ad-lab}}`        |
| `experiment`   | Object | Yes      | Reference to RFC-0002 experiment.             | `{ref: {name: recon-exp}}`     |
| `initial_state`| Object | No       | Pre-experiment conditions.                    | `{artifacts: [], flags: []}`   |
| `lifecycle`    | Object | No       | Execution lifecycle configuration.            | `{provision: {}, teardown: {}}` |
| `evaluation`   | Object | No       | Scenario-level success criteria.              | `{success_criteria: {}}`       |

### Example

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Scenario
metadata:
  name: example-scenario
  description: "Example scenario binding an environment and experiment"
  version: "1.0.0"
  labels:
    domain: general
    difficulty: medium

environment:
  ref:
    name: dev-environment
    version: "1.0.0"
  source: ./environments/dev-environment.yaml

experiment:
  ref:
    name: exploration-experiment
    version: "1.0.0"
  source: ./experiments/exploration-experiment.yaml

initial_state: { ... }
lifecycle: { ... }
evaluation: { ... }
```

---

## Environment

References the RFC-0001 environment the scenario provisions and uses.

| Property  | Type   | Required | Description                              | Example                         |
| :-------- | :----- | :------- | :--------------------------------------- | :------------------------------ |
| `ref`     | Object | Yes      | Reference to RFC-0001 environment.       | `{name: ad-lab, version: 1.0.0}`|
| `source`  | String | No       | Path or URL to environment spec file.    | `./environments/ad-lab.yaml`    |

### Environment Reference

| Property  | Type   | Required | Description                                | Example    |
| :-------- | :----- | :------- | :----------------------------------------- | :--------- |
| `name`    | String | Yes      | Environment name from RFC-0001 metadata.   | `ad-lab`   |
| `version` | String | No       | Version constraint.                        | `1.0.0`    |

### Example

```yaml
environment:
  ref:
    name: ad-lab
    version: "1.0.0"
  source: ./environments/ad-lab.yaml
```

---

## Experiment

References the RFC-0002 experiment that executes against the environment.

| Property  | Type   | Required | Description                              | Example                              |
| :-------- | :----- | :------- | :--------------------------------------- | :----------------------------------- |
| `ref`     | Object | Yes      | Reference to RFC-0002 experiment.        | `{name: recon-exp, version: 1.0.0}`  |
| `source`  | String | No       | Path or URL to experiment spec file.     | `./experiments/recon-exp.yaml`       |
| `overrides`| Object| No       | Parameter overrides for this scenario.   | See Overrides                        |

### Experiment Reference

| Property  | Type   | Required | Description                               | Example          |
| :-------- | :----- | :------- | :---------------------------------------- | :--------------- |
| `name`    | String | Yes      | Experiment name from RFC-0002 metadata.   | `recon-exp`      |
| `version` | String | No       | Version constraint.                       | `1.0.0`, `>=1.0` |

### Overrides

Allows a scenario to parametrize an experiment without forking it.
Overrides are merged into the experiment spec at execution time.

| Property       | Type   | Required | Description                          | Example                       |
| :------------- | :----- | :------- | :----------------------------------- | :---------------------------- |
| `runtime`      | Object | No       | Overrides to RFC-0002 runtime block. | `{timeout: 1h}`               |
| `agent_params` | Object | No       | Per-agent parameter overrides.       | `{explorer: {model: {...}}}`  |

### Example

```yaml
experiment:
  ref:
    name: exploration-experiment
    version: "1.0.0"
  source: ./experiments/exploration-experiment.yaml
  overrides:
    runtime:
      timeout: 45m
    agent_params:
      explorer:
        model:
          name: claude-opus-4-20250514
```

---

## Initial State

The initial state block declares what conditions must be true in the
environment *before the experiment starts*. This is distinct from:

- **RFC-0001 `provisioning`**: Configures infrastructure (OS, software,
  services) — runs once when the environment is built.
- **RFC-0002 `injects`**: Events fired *during* experiment execution.
- **`initial_state`**: Specific artifacts, data, flags, or conditions that
  represent the starting scenario context — set up after provisioning,
  before the experiment clock starts.

| Property    | Type  | Required | Description                            | Example                    |
| :---------- | :---- | :------- | :------------------------------------- | :------------------------- |
| `artifacts` | Array | No       | Files, repos, or data placed in env.   | See Artifact               |
| `flags`     | Array | No       | Measurable markers (e.g., secrets).    | See Flag                   |
| `state`     | Array | No       | Pre-set environment state properties.  | See StateAssertion         |
| `services`  | Array | No       | Services that must be ready before start.| See ServiceReadyCheck    |

### Artifact

An artifact is a file, dataset, repository, or other content placed into
the environment before the experiment runs.

| Property  | Type          | Required | Description                          | Example                       |
| :-------- | :------------ | :------- | :----------------------------------- | :---------------------------- |
| `id`      | String        | No       | Unique identifier.                   | `target-codebase`             |
| `type`    | ArtifactSource| Yes      | Source type.                         | `git`, `file`, `inline`       |
| `node`    | String        | Yes      | Target node (refs RFC-0001 topology).| `dev-server`                  |
| `path`    | String        | Yes      | Destination path on the node.        | `/workspace/repo`             |
| `source`  | String        | No       | URI, path, or ref for the content.   | `git://github.com/org/repo`   |
| `ref`     | String        | No       | Git commit, tag, or branch.          | `a1b2c3d4`                    |
| `content` | String        | No       | Inline content (for `inline` type).  | `{"seed": 42}`                |

### Flag

A flag is a measurable artifact — a file, value, or token that acts as
a verifiable marker for scenario outcomes (e.g., a secret to be captured,
a ground-truth file, a baseline snapshot).

| Property    | Type   | Required | Description                             | Example                      |
| :---------- | :----- | :------- | :-------------------------------------- | :--------------------------- |
| `id`        | String | Yes      | Unique identifier.                      | `target-secret`              |
| `node`      | String | Yes      | Node where the flag resides.            | `db-01`                      |
| `path`      | String | Yes      | Path of the flag file/resource.         | `/secrets/flag.txt`          |
| `value`     | String | No       | Secret reference for the flag value.    | `secret:scenario-flag`       |
| `labels`    | Object | No       | Arbitrary key-value labels.             | `{category: target}`         |

### StateAssertion

A state assertion pre-sets a named property on the environment state model
before the experiment starts.

| Property   | Type   | Required | Description                           | Example                              |
| :--------- | :----- | :------- | :------------------------------------ | :----------------------------------- |
| `target`   | String | Yes      | Dot-path to the state property.       | `nodes.web-01.patched`               |
| `value`    | Any    | Yes      | Value to set.                         | `false`                              |
| `labels`   | Object | No       | Arbitrary key-value labels.           | `{reason: intentional_vuln}`         |

### ServiceReadyCheck

Declares that a specific service must be reachable before the experiment
clock starts. The lifecycle waits for all service checks to pass before
transitioning from `initializing` to `running`.

| Property    | Type          | Required | Description                          | Example                          |
| :---------- | :------------ | :------- | :----------------------------------- | :------------------------------- |
| `node`      | String        | Yes      | Node to check (refs RFC-0001).       | `web-01`                         |
| `service`   | String        | Yes      | Service name.                        | `http`                           |
| `type`      | ReadyCheckType| No       | Check type.                          | `http`, `tcp`                    |
| `endpoint`  | String        | No       | Endpoint to probe.                   | `http://10.0.1.10/health`        |
| `timeout`   | String        | No       | Maximum wait time.                   | `5m`                             |

### Initial State Example

```yaml
initial_state:
  artifacts:
    - id: target-codebase
      type: git
      node: dev-server
      path: /workspace/repo
      source: git://github.com/org/target-repo
      ref: a1b2c3d4

    - id: seed-data
      type: inline
      node: db-01
      path: /data/records.json
      content: |
        {"records": [{"id": 1, "value": "test"}]}

  flags:
    - id: target-secret
      node: db-01
      path: /secrets/api_key.txt
      value: secret:scenario-api-key
      labels:
        category: exfiltration_target

    - id: baseline-snapshot
      node: web-01
      path: /var/www/html/index.html
      labels:
        category: integrity_baseline

  state:
    - target: nodes.web-01.patched
      value: false
      labels:
        reason: intentional_vulnerability

  services:
    - node: web-01
      service: http
      type: http
      endpoint: http://10.0.1.10/health
      timeout: 5m

    - node: db-01
      service: postgresql
      type: tcp
      endpoint: "10.0.1.20:5432"
      timeout: 3m
```

---

## Lifecycle

The lifecycle block governs the execution stages of a scenario run: how
the environment is provisioned, how the handoff to the experiment occurs,
and how the environment is handled after the run completes.

| Property     | Type   | Required | Description                           | Example                        |
| :----------- | :----- | :------- | :------------------------------------ | :----------------------------- |
| `provision`  | Object | No       | Environment provisioning config.      | See Provision                  |
| `initialize` | Object | No       | Pre-experiment initialization.        | See Initialize                 |
| `teardown`   | Object | No       | Post-experiment cleanup.              | See Teardown                   |
| `reset`      | Object | No       | Between-run reset configuration.      | See Reset                      |

### Provision

Controls how and when the RFC-0001 environment is provisioned.

| Property      | Type   | Required | Description                               | Example     |
| :------------ | :----- | :------- | :---------------------------------------- | :---------- |
| `timeout`     | String | No       | Maximum provisioning time.                | `30m`       |
| `reuse`       | Boolean| No       | Reuse already-running environment.        | `false`     |
| `ready_checks`| Array  | No       | Checks before declaring env ready.        | See ServiceReadyCheck |

`reuse: true` allows a scenario to run against a pre-provisioned environment
instance (e.g., during iterative development), skipping provisioning.

### Initialize

Steps taken after provisioning and before the experiment starts. This is
when `initial_state` artifacts and flags are placed.

| Property  | Type   | Required | Description                                | Example |
| :-------- | :----- | :------- | :----------------------------------------- | :------ |
| `timeout` | String | No       | Maximum initialization time.               | `10m`   |
| `order`   | Array  | No       | Explicit ordering of initial_state items.  | `[target-codebase, seed-data, target-secret]` |

The runtime applies `initial_state` items in dependency order by default.
Use `order` to override when explicit sequencing is required.

### Teardown

What happens to the environment after the experiment completes.

| Property     | Type          | Required | Description                               | Example      |
| :----------- | :------------ | :------- | :---------------------------------------- | :----------- |
| `on_success` | TeardownPolicy| No       | Policy when experiment succeeds.          | `destroy`    |
| `on_failure` | TeardownPolicy| No       | Policy when experiment fails.             | `preserve`   |
| `timeout`    | String        | No       | Maximum teardown time.                    | `10m`        |

#### Teardown Policies

| Policy      | Description                                               |
| :---------- | :-------------------------------------------------------- |
| `preserve`  | Keep environment running (e.g., for debugging)            |
| `destroy`   | Destroy all environment resources                         |
| `snapshot`  | Snapshot environment state before destroying              |

### Reset

How to restore the environment to `initial_state` between successive runs
of the same scenario (e.g., for repeated evaluation, benchmarking).

| Property   | Type          | Required | Description                           | Example              |
| :--------- | :------------ | :------- | :------------------------------------ | :------------------- |
| `strategy` | ResetStrategy | No       | Reset method.                         | `snapshot_restore`   |
| `timeout`  | String        | No       | Maximum reset time.                   | `15m`                |

#### Reset Strategies

| Strategy           | Description                                                    |
| :----------------- | :------------------------------------------------------------- |
| `reprovision`      | Tear down and reprovision from scratch (slowest, most reliable)|
| `snapshot_restore` | Restore from a snapshot taken after initialization             |
| `state_reset`      | Apply `initial_state` items in place without reprovisioning    |

### Lifecycle Example

```yaml
lifecycle:
  provision:
    timeout: 30m
    reuse: false
    ready_checks:
      - node: web-01
        service: http
        type: http
        endpoint: http://10.0.1.10/health
        timeout: 5m

  initialize:
    timeout: 10m
    order:
      - target-codebase
      - seed-data
      - target-secret

  teardown:
    on_success: destroy
    on_failure: preserve
    timeout: 10m

  reset:
    strategy: snapshot_restore
    timeout: 5m
```

---

## Evaluation

The evaluation block declares scenario-level success criteria and ground
truth. It is optional — RFC-0002 objectives are the primary evaluation
mechanism. This block extends or overrides them at the scenario level.

| Property           | Type   | Required | Description                                 | Example                    |
| :----------------- | :----- | :------- | :------------------------------------------ | :------------------------- |
| `success_criteria` | Object | No       | Compound pass/fail for the scenario.        | See Success Criteria       |
| `ground_truth`     | Object | No       | Expected end state for correctness checks.  | See Ground Truth           |
| `scoring`          | Object | No       | Scenario-level scoring overrides.           | See Scoring Override       |

### Success Criteria

Compound conditions that determine whether the scenario as a whole passed.
References RFC-0002 objective names and RFC-0004 flag identifiers.

```yaml
success_criteria:
  all:
    - objective: main-task-complete     # refs RFC-0002 objectives
    - objective: report-generated
  any:
    - flag: target-secret               # refs initial_state.flags
    - objective: secondary-goal
```

Compound logic follows the same `all` / `any` pattern as RFC-0002 conditions.

### Ground Truth

Declares the expected end state of the environment after a correct run.
Used for automated correctness validation.

| Property              | Type  | Required | Description                              | Example                              |
| :-------------------- | :---- | :------- | :--------------------------------------- | :----------------------------------- |
| `expected_artifacts`  | Array | No       | Files that must exist at end of run.     | `[{node: web-01, path: /output/result.json}]` |
| `expected_state`      | Array | No       | State expressions that must be true.     | `[{expr: "nodes.db-01.intact == true"}]`      |
| `expected_flags_intact`| Array| No       | Flags that must NOT have been accessed.  | `[baseline-snapshot]`                |

### Scoring Override

Overrides RFC-0002 `runtime.scoring` for this scenario.

| Property        | Type   | Required | Description                       | Example      |
| :-------------- | :----- | :------- | :-------------------------------- | :----------- |
| `pass_threshold`| Float  | No       | Minimum score to consider passing.| `80.0`       |
| `normalize`     | Boolean| No       | Normalize final score to 0-100.   | `true`       |

### Evaluation Example

```yaml
evaluation:
  success_criteria:
    all:
      - objective: task-complete
      - objective: report-generated

  ground_truth:
    expected_artifacts:
      - node: web-01
        path: /output/results.json
    expected_state:
      - expr: "nodes.db-01.integrity == true"
    expected_flags_intact:
      - baseline-snapshot

  scoring:
    pass_threshold: 75.0
    normalize: true
```

---

## The Run Model

A **Scenario** is a reusable specification. A **Run** is a single execution
of that scenario at a specific point in time. The runtime creates Run
records when executing a scenario; the schema defines what a Run captures.

This distinction enables:

- **Reproducibility**: A scenario at a fixed version + a run record = a
  fully reproducible result
- **Result storage**: Run records are the unit of experiment history
- **Replay**: Re-running a scenario re-creates the initial state and
  re-executes the experiment

### Run Record

Run records are created and managed by the runtime (`aces-runtime`), not
declared by the operator. The schema defines what fields a Run record must
contain.

| Field           | Type      | Description                                    | Example                       |
| :-------------- | :-------- | :--------------------------------------------- | :---------------------------- |
| `id`            | String    | Unique run identifier.                         | `run-abc123`                  |
| `scenario`      | Object    | Scenario reference (name + version).           | `{name: example, version: 1.0.0}` |
| `environment`   | Object    | Environment reference + instance ID.           | `{name: ad-lab, instance: env-xyz}` |
| `experiment`    | Object    | Experiment reference.                          | `{name: recon-exp}`           |
| `status`        | RunStatus | Current run status.                            | see [Type Definitions](#type-definitions) |
| `started_at`    | String    | ISO 8601 start timestamp.                      | `2024-01-15T10:00:00Z`        |
| `completed_at`  | String    | ISO 8601 completion timestamp.                 | `2024-01-15T11:30:00Z`        |
| `duration`      | String    | Total run duration.                            | `1h30m`                       |
| `results`       | Object    | Objective outcomes and final score.            | `{score: 85.0, objectives: {}}` |
| `labels`        | Object    | Arbitrary key-value labels.                    | `{run_by: researcher-a}`      |

### Run Lifecycle

```text
Scenario spec
      │
      ▼
 provisioning ──► initializing ──► running ──► completed
      │                │               │            │
   (RFC-0001)    (initial_state)  (RFC-0002)    (evaluation)
      │                                               │
   on_failure ────────────────────────────────► preserve / destroy / snapshot
```

---

## Complete Example

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Scenario
metadata:
  name: web-exploration-scenario
  description: "Agent explores web environment and produces recon report"
  version: "1.0.0"
  labels:
    domain: general
    difficulty: medium
    repeatable: "true"

environment:
  ref:
    name: dev-environment
    version: "1.0.0"
  source: ./environments/dev-environment.yaml

experiment:
  ref:
    name: exploration-experiment
    version: "1.0.0"
  source: ./experiments/exploration-experiment.yaml
  overrides:
    runtime:
      timeout: 1h

initial_state:
  artifacts:
    - id: seed-data
      type: inline
      node: db-01
      path: /data/records.json
      content: |
        {"records": [{"id": 1, "name": "alpha"}, {"id": 2, "name": "beta"}]}

  flags:
    - id: target-record
      node: db-01
      path: /data/secret_record.txt
      value: secret:scenario-target-record
      labels:
        category: primary_target

    - id: web-baseline
      node: web-01
      path: /var/www/html/index.html
      labels:
        category: integrity_baseline

  state:
    - target: nodes.web-01.endpoints_seeded
      value: true

  services:
    - node: web-01
      service: http
      type: http
      endpoint: http://10.0.1.10/health
      timeout: 5m
    - node: db-01
      service: postgresql
      type: tcp
      endpoint: "10.0.1.20:5432"
      timeout: 3m

lifecycle:
  provision:
    timeout: 30m
    reuse: false

  initialize:
    timeout: 10m
    order: [seed-data, target-record, web-baseline]

  teardown:
    on_success: destroy
    on_failure: preserve
    timeout: 10m

  reset:
    strategy: snapshot_restore
    timeout: 5m

evaluation:
  success_criteria:
    all:
      - objective: environment-mapped
      - objective: report-generated

  ground_truth:
    expected_artifacts:
      - node: web-01
        path: /output/report.md
    expected_flags_intact:
      - web-baseline

  scoring:
    pass_threshold: 75.0
    normalize: true
```

---

## Domain Extension Points

This specification is intentionally domain-agnostic. Domain-specific
constructs are expressed through:

1. **`initial_state.flags`**: Domain semantics via labels
   (e.g., `{category: exfiltration_target}` for security)
2. **`evaluation.success_criteria`**: Compound conditions referencing
   RFC-0002 objectives with domain-meaningful names
3. **`initial_state.state`**: Pre-set domain-specific state properties
4. **Domain extension RFCs**: Security scenarios use RFC-0005 overlays;
   AI safety scenarios define their own domain RFC

Domain extensions MAY extend this schema with additional fields (e.g., an
AI safety domain RFC may add a `trust_model` block, a security domain RFC
may add an `attack_graph_seed` block), provided they do not modify the
semantics of the base fields defined here.

---

## Alternatives Considered

### Embed Scenario in RFC-0002

Rejected because:

- RFC-0002 defines agent behavior; scenario composition is a separate concern
- An experiment should be reusable across different initial states
- Lifecycle management (provision/reset/teardown) does not belong in the
  experiment spec

### Inline Environment and Experiment

Allow scenario to embed full environment and experiment definitions inline
rather than by reference.

Rejected because:

- Breaks reusability — the same environment cannot be shared across scenarios
- Creates duplication and version drift
- References with overrides provide the same flexibility without duplication

### Merge with RFC-0001 as a `ScenarioEnvironment` kind

Rejected because:

- Violates RFC-0001's design principle: environments define "what exists,"
  not "what gets run"
- An environment is provisioned once; a scenario may run many times against
  the same environment

---

## Affected Repos

| Repository        | Changes Required                                             |
| :---------------- | :----------------------------------------------------------- |
| `aces-schema`     | JSON Schema for Scenario kind and Run record                 |
| `aces-sdl`        | Parse and validate Scenario specs, resolve environment and experiment refs |
| `aces-runtime`    | Execute lifecycle stages, create Run records, manage reset   |
| `aces-evaluation` | Evaluate scenario-level success criteria and ground truth    |

---

## Consequences

### What Becomes Easier

- **Reproducibility**: A scenario version + run record fully describes an execution
- **Benchmarking**: Reset between runs enables repeated evaluation on the same scenario
- **Portability**: Scenario specs are self-contained and shareable
- **Separation of concerns**: Initial state, provisioning, and runtime injects are clearly distinct
- **Domain extension**: Domain-specific overlays extend the base without forking it

### What Becomes Harder

- **Simple runs**: Single-file experiments now require two or three files
  (environment, experiment, scenario) for full lifecycle management
- **Versioning**: Environment and experiment versions must be coordinated
  when either changes

---

## Cross-References

| Document                           | Relationship                                           |
| :--------------------------------- | :----------------------------------------------------- |
| RFC-0001: Environment Infrastructure | Defines the environment the scenario provisions       |
| RFC-0002: Agentic Experiment       | Defines the experiment the scenario executes           |
| RFC-0003: Observability Schema     | Telemetry emitted during scenario execution            |
| RFC-0005: Security Domain Schema   | Optional security-domain overlay for scenarios         |
