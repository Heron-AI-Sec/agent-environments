# RFC-0004: Scenario Definition Language

## Status

`Draft`

## Summary

This RFC proposes three constructs that sit above RFC-0001 and RFC-0002:

- **Scenario**: A named, versioned unit that references an RFC-0002 experiment
  and declares how it is reset between runs.
- **Run**: The record of a single execution of a scenario — its outcome,
  backend, and results.
- **Study**: A collection of scenarios and run records with associated cost,
  scoring criteria, and metadata for research reproducibility.

It also defines environment versioning semantics: what constitutes a breaking
vs. non-breaking change to an RFC-0001 environment.

RFC-0001 defines "what exists." RFC-0002 defines "what happens." This
specification defines "what was run and what it produced."

## Motivation

RFC-0001 and RFC-0002 are independently useful but leave three problems
unresolved for reproducible research:

1. **No named execution unit.** There is no versioned artifact that says
   "run this experiment and record the result under this name." This is
   currently an implementation detail of the runtime.

2. **No instance record.** There is no standard for recording what actually
   happened during a run — which backend executed it, what the outcome was,
   what it cost. Without this, reproducing or comparing results requires
   out-of-band documentation.

3. **No collection concept.** Research involves running multiple scenarios
   and comparing results. There is no construct for grouping runs into a
   named study with shared scoring criteria and cost accounting.

### Design Principles

1. **Non-redundant**: RFC-0004 does not re-specify what RFC-0001 and RFC-0002
   already own. Environment initial state belongs in RFC-0001. Experiment
   objectives and scoring belong in RFC-0002.
2. **Domain-Agnostic**: No security, AI safety, or SWE-specific concepts.
3. **Optional Overlay**: RFC-0001 + RFC-0002 are runnable without RFC-0004.
   This spec adds reproducibility and research-collection semantics.
4. **Run as First-Class**: The difference between a Scenario (specification)
   and a Run (instance) is explicit and standardized.

### On Initial State

Every variation in initial conditions — a different file, an extra server,
a different OS version, a different application config — is a new
RFC-0001 `Environment` version. RFC-0001 already specifies infrastructure
down to applications and config mechanisms. There is no principled line to
draw for "per-scenario" initial state that RFC-0001 does not already cross.

Initial state belongs in RFC-0001. RFC-0004 does not re-open that boundary.

---

## Type Definitions

| Type                   | Kind            | Values                                                       |
| :--------------------- | :-------------- | :----------------------------------------------------------- |
| `ResetStrategy`        | extensible-enum | `reprovision`, `snapshot_restore`                            |
| `RunOutcome`           | extensible-enum | `success`, `failure`, `error`, `cancelled`                   |
| `EnvironmentChangeClass` | extensible-enum | `breaking`, `additive`, `patch`                            |
| `CostUnit`             | extensible-enum | `usd`, `token`, `compute_hour`                               |

**Kind definitions:**

- **`extensible-enum`**: A closed list of standard values. Custom values
  allowed via `x-` prefix (e.g., `x-custom-outcome`).

### ResetStrategy values

| Value              | Description                                                      | Experimentally relevant?          |
| :----------------- | :--------------------------------------------------------------- | :-------------------------------- |
| `reprovision`      | Full teardown and rebuild from RFC-0001 spec                     | Yes — strongest isolation guarantee |
| `snapshot_restore` | Restore to a known snapshot taken after provisioning             | Yes — faster but snapshot-dependent |

**Note**: Reset strategy is experimentally relevant because `reprovision`
provides stronger isolation between runs than `snapshot_restore`. A study
comparing results across runs SHOULD record the strategy used. Runtime-only
concerns (timeouts, teardown policy, readiness checks) are not specified here.

### RunOutcome values

| Value       | Description                                                        |
| :---------- | :----------------------------------------------------------------- |
| `success`   | Run hit an expected stop condition (RFC-0002 objectives met)       |
| `failure`   | Run hit a failure condition or exhausted budget without succeeding |
| `error`     | Technical or runtime error prevented completion                    |
| `cancelled` | Run was manually stopped before reaching a stop condition          |

---

## Schema Overview

| Kind        | Purpose                                                             |
| :---------- | :------------------------------------------------------------------ |
| `Scenario`  | Named, versioned execution unit referencing an RFC-0002 experiment  |
| `Run`       | Record of a single scenario execution                               |
| `Study`     | Collection of scenarios and runs for research purposes              |

---

## Scenario

A Scenario is a named, versioned unit that references an RFC-0002 experiment
and declares how it is reset between successive runs.

The environment is not declared at the scenario level. It is already
specified in the RFC-0002 experiment via `environment.ref`. Declaring it
again would introduce a drift and precedence problem.

### Scenario Schema

| Field            | Type           | Required | Description                               | Example                        |
| :--------------- | :------------- | :------- | :---------------------------------------- | :----------------------------- |
| `apiVersion`     | String         | Yes      | Schema version.                           | `aces.io/v1alpha1`             |
| `kind`           | String         | Yes      | Resource type.                            | `Scenario`                     |
| `metadata`       | Object         | Yes      | Identifying information.                  | `{name, description, version}` |
| `experiment`     | Object         | Yes      | Reference to RFC-0002 experiment.         | `{ref: {name: recon-exp}}`     |
| `reset_strategy` | ResetStrategy  | No       | How to reset between runs.                | `reprovision`                  |
| `labels`         | Object         | No       | Arbitrary key-value labels.               | `{domain: security}`           |

### Experiment Reference

| Property  | Type   | Required | Description                               | Example          |
| :-------- | :----- | :------- | :---------------------------------------- | :--------------- |
| `name`    | String | Yes      | Experiment name from RFC-0002 metadata.   | `recon-exp`      |
| `version` | String | No       | Pinned version.                           | `1.0.0`          |
| `source`  | String | No       | Path or URL to experiment spec file.      | `./experiments/recon-exp.yaml` |

### Scenario Example

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Scenario
metadata:
  name: ad-recon-scenario
  description: "Agent performs Active Directory reconnaissance"
  version: "1.0.0"
  labels:
    domain: security
    difficulty: medium

experiment:
  ref:
    name: ad-recon-experiment
    version: "1.0.0"
  source: ./experiments/ad-recon.yaml

reset_strategy: reprovision
```

---

## Run

A Run is the record of a single execution of a Scenario. Run records are
created by the runtime (`aces-runtime`), not declared by operators. This
specification defines what a Run record MUST contain for reproducibility.

### Run Record Schema

| Field              | Type          | Required | Description                                      | Example                          |
| :----------------- | :------------ | :------- | :----------------------------------------------- | :------------------------------- |
| `id`               | String        | Yes      | Unique run identifier.                           | `run-abc123`                     |
| `scenario`         | Object        | Yes      | Scenario name and pinned version.                | `{name: ad-recon, version: 1.0.0}` |
| `experiment`       | Object        | Yes      | Experiment name and pinned version.              | `{name: ad-recon-exp, version: 1.0.0}` |
| `environment`      | Object        | Yes      | Environment name and pinned version.             | `{name: ad-lab, version: 1.0.0}` |
| `backend`          | Object        | Yes      | Runtime backend that executed the run.           | See Backend                      |
| `reset_strategy`   | ResetStrategy | Yes      | Strategy used for this run.                      | `reprovision`                    |
| `outcome`          | RunOutcome    | Yes      | Run outcome.                                     | `success`                        |
| `started_at`       | String        | Yes      | ISO 8601 start timestamp.                        | `2025-01-15T10:00:00Z`           |
| `completed_at`     | String        | Yes      | ISO 8601 completion timestamp.                   | `2025-01-15T11:30:00Z`           |
| `duration`         | String        | Yes      | Total run duration.                              | `1h30m`                          |
| `results`          | Object        | No       | Objective outcomes and final score from RFC-0002.| `{score: 85.0, objectives: {}}` |
| `cost`             | Object        | No       | Cost of this run.                                | See Cost                         |
| `labels`           | Object        | No       | Arbitrary key-value labels.                      | `{run_by: researcher-a}`         |

### Backend

Records which runtime and infrastructure executed the run.

| Property  | Type   | Required | Description                      | Example                |
| :-------- | :----- | :------- | :------------------------------- | :--------------------- |
| `name`    | String | Yes      | Backend identifier.              | `aces-runtime-prod`    |
| `type`    | String | Yes      | Runtime type.                    | `kubernetes`, `docker` |
| `version` | String | No       | Runtime version.                 | `0.8.1`                |
| `region`  | String | No       | Cloud region or datacenter.      | `us-east-1`            |

### Cost

Records the resource cost of executing a run.

| Property  | Type     | Required | Description                      | Example     |
| :-------- | :------- | :------- | :------------------------------- | :---------- |
| `total`   | Float    | Yes      | Total cost.                      | `4.32`      |
| `unit`    | CostUnit | Yes      | Cost unit.                       | `usd`       |
| `breakdown`| Object  | No       | Per-component cost breakdown.    | `{llm_api: 2.10, compute: 2.22}` |

### Run Record Example

```yaml
id: run-7f3a1c
scenario:
  name: ad-recon-scenario
  version: "1.0.0"
experiment:
  name: ad-recon-experiment
  version: "1.0.0"
environment:
  name: ad-lab
  version: "1.0.0"
backend:
  name: aces-runtime-prod
  type: kubernetes
  version: "0.8.1"
  region: us-east-1
reset_strategy: reprovision
outcome: success
started_at: "2025-01-15T10:00:00Z"
completed_at: "2025-01-15T11:23:00Z"
duration: 1h23m
results:
  score: 87.5
  objectives:
    environment-mapped:
      achieved: true
      reward: 50.0
    report-generated:
      achieved: true
      reward: 37.5
cost:
  total: 4.32
  unit: usd
  breakdown:
    llm_api: 2.10
    compute: 2.22
```

---

## Study

A Study is a named collection of scenarios and run records. It is the
unit of a research experiment — grouping related scenarios, specifying how
results are scored across runs, and tracking aggregate cost.

### Study Schema

| Field              | Type   | Required | Description                                      | Example                      |
| :----------------- | :----- | :------- | :----------------------------------------------- | :--------------------------- |
| `apiVersion`       | String | Yes      | Schema version.                                  | `aces.io/v1alpha1`           |
| `kind`             | String | Yes      | Resource type.                                   | `Study`                      |
| `metadata`         | Object | Yes      | Identifying information.                         | `{name, description, version}` |
| `scenarios`        | Array  | Yes      | Scenario references included in this study.      | See Scenario Reference       |
| `runs`             | Array  | No       | Run record references or inline run records.     | See Run Reference            |
| `scoring_criteria` | Object | No       | Cross-run scoring and evaluation criteria.       | See Scoring Criteria         |
| `cost`             | Object | No       | Aggregate cost across all runs in the study.     | See Study Cost               |
| `labels`           | Object | No       | Arbitrary key-value labels.                      | `{paper: arxiv-2025-001}`    |

### Scenario Reference

| Property  | Type   | Required | Description                        | Example                          |
| :-------- | :----- | :------- | :--------------------------------- | :------------------------------- |
| `name`    | String | Yes      | Scenario name.                     | `ad-recon-scenario`              |
| `version` | String | No       | Pinned scenario version.           | `1.0.0`                          |
| `source`  | String | No       | Path or URL to scenario spec file. | `./scenarios/ad-recon.yaml`      |

### Run Reference

Run records can be referenced by ID or included inline.

| Property  | Type   | Required | Description                        | Example          |
| :-------- | :----- | :------- | :--------------------------------- | :--------------- |
| `id`      | String | No       | Run record ID (external reference).| `run-7f3a1c`     |
| `source`  | String | No       | Path to run record file.           | `./runs/run-7f3a1c.yaml` |

### Scoring Criteria

Declares how runs in this study are evaluated and compared.
RFC-0002 defines per-experiment objectives and scoring. `scoring_criteria`
provides cross-run and cross-scenario evaluation for the study as a whole.

| Property    | Type   | Required | Description                                       | Example                            |
| :---------- | :----- | :------- | :------------------------------------------------ | :--------------------------------- |
| `ref`       | String | No       | Path or URL to a scoring rubric or test suite.    | `./criteria/rubric.md`             |
| `evaluator` | String | No       | Evaluator identifier for automated scoring.       | `aces.evaluators.security_control` |
| `params`    | Object | No       | Parameters passed to the evaluator.               | `{pass_threshold: 0.8}`            |
| `aggregate` | String | No       | How to aggregate scores across runs.              | `mean`, `min`, `max`, `median`     |

### Study Cost

Aggregate cost tracking across all runs in the study.

| Property    | Type     | Required | Description                          | Example     |
| :---------- | :------- | :------- | :----------------------------------- | :---------- |
| `total`     | Float    | No       | Total cost across all runs.          | `43.20`     |
| `unit`      | CostUnit | Yes      | Cost unit.                           | `usd`       |
| `per_run`   | Object   | No       | Per-run cost map (run ID → cost).    | `{run-7f3a1c: 4.32}` |

### Study Example

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Study
metadata:
  name: ad-control-evaluation-2025
  description: "Evaluating LLM agent control under AD attack conditions"
  version: "1.0.0"
  labels:
    paper: arxiv-2025-001
    authors: [researcher-a, researcher-b]

scenarios:
  - name: ad-recon-scenario
    version: "1.0.0"
    source: ./scenarios/ad-recon.yaml
  - name: ad-escalation-scenario
    version: "1.0.0"
    source: ./scenarios/ad-escalation.yaml

runs:
  - source: ./runs/run-7f3a1c.yaml
  - source: ./runs/run-9b2d4e.yaml
  - source: ./runs/run-3c8f1a.yaml

scoring_criteria:
  ref: ./criteria/control-eval-rubric.md
  evaluator: aces.evaluators.control_evaluation
  params:
    pass_threshold: 0.75
    main_task_weight: 0.6
    safety_weight: 0.4
  aggregate: mean

cost:
  total: 43.20
  unit: usd
  per_run:
    run-7f3a1c: 4.32
    run-9b2d4e: 3.98
    run-3c8f1a: 4.11
```

---

## Environment Versioning Rule

RFC-0001 environments are versioned. This section defines what constitutes
each class of version change, which matters for reproducibility: runs
against different environment versions are not directly comparable without
understanding what changed.

### Change Classes

| Class      | RFC-0001 Change Type                                      | Version Increment  | Runs comparable? |
| :--------- | :-------------------------------------------------------- | :----------------- | :--------------- |
| `breaking` | Topology change (add/remove node, network, or edge)       | Major (`X.0.0`)    | No               |
| `breaking` | OS, OS version, or OS distribution change on any node     | Major (`X.0.0`)    | No               |
| `breaking` | Application change (add/remove service or provisioner)    | Major (`X.0.0`)    | No               |
| `additive` | New group, new label, new resource profile                | Minor (`x.Y.0`)    | With caveat      |
| `additive` | New telemetry sink or collection point                    | Minor (`x.Y.0`)    | With caveat      |
| `patch`    | Config correction, documentation, non-structural fix      | Patch (`x.y.Z`)    | Yes              |

**"With caveat"**: Additive changes do not alter existing nodes or topology
but may affect what agents can observe or do. Studies SHOULD document
environment versions used. Cross-version comparison within a study requires
explicit justification.

### Environment Changelog

RFC-0001 environments SHOULD include a `changelog` in metadata describing
what changed between versions. This is not enforced by the schema but is
required for reproducible studies.

```yaml
# RFC-0001 environment metadata example
metadata:
  name: ad-lab
  version: "2.0.0"
  changelog:
    - version: "2.0.0"
      class: breaking
      description: "Added ubuntu-srv-02 node to corp-lan network"
    - version: "1.1.0"
      class: additive
      description: "Added network_pcap collection point for corp-lan"
    - version: "1.0.0"
      class: patch
      description: "Initial version"
```

### Evolving / Dynamic Ranges

Some experiments require the environment to change during execution (e.g.,
nodes joining or leaving mid-run, threat actors introduced dynamically).
RFC-0001 currently specifies static environments. Dynamic range updates
are not covered in this RFC.

**Recommendation**: Dynamic range state changes during an active run are
modeled as RFC-0002 `injects` of `type: state`. Structural topology changes
during a run (add/remove node) are a future RFC-0001 extension. A Run
record MUST capture the environment version at run start; if the environment
is mutated mid-run via injects, those injects are captured in the
RFC-0002 experiment spec and are visible in RFC-0003 telemetry.

---

## Alternatives Considered

### Include environment reference in Scenario

Rejected: RFC-0002 `experiment.environment.ref` already carries this.
A second reference at the scenario level creates drift and an unresolved
precedence problem when the two diverge.

### Include overrides in Scenario

Rejected: RFC-0002 has no parameterization mechanism. Overrides would
require either a fork of the experiment spec or a merge semantics that
is not defined. If parameterization is needed, it should be designed as
a first-class feature of RFC-0002, not worked around in RFC-0004.

### Include evaluation / ground truth in Scenario

Rejected: Evaluation is already defined per-experiment in RFC-0002
objectives and scoring. Ground truth IS the specific environment version
used in the run — it is captured in the Run record's `environment` field,
not re-specified here.

### Include initial state in Scenario

Rejected: Every meaningful variation in initial conditions (different file,
different config, different server count) is a new RFC-0001 environment
version. There is no principled line to draw for per-scenario initial state
that RFC-0001 does not already cross. Initial state belongs in RFC-0001.

### Cost in RFC-0003

Cost attributes could be placed in RFC-0003 observability telemetry.
Rejected for study-level cost: study cost is a research accounting concept,
not a telemetry event. Run-level cost in the Run record is the right
location because it is a property of the execution instance, not a
stream of telemetry events. Per-LLM-call token cost metrics can still
appear in RFC-0003 telemetry.

---

## Affected Repos

| Repository        | Changes Required                                                     |
| :---------------- | :------------------------------------------------------------------- |
| `aces-schema`     | JSON Schema for `Scenario`, `Run`, and `Study` kinds                 |
| `aces-sdl`        | Parse and validate Scenario and Study specs                          |
| `aces-runtime`    | Create Run records with outcome, backend, cost, reset_strategy       |
| `aces-evaluation` | Study-level scoring via scoring_criteria evaluators                  |

---

## Consequences

### What Becomes Easier

- **Reproducibility**: Run record pins scenario, experiment, environment,
  backend, and reset strategy — sufficient to reproduce any run
- **Cost accounting**: Studies track total and per-run cost
- **Cross-run comparison**: Study groups runs; scoring criteria defines
  how to compare them
- **Environment evolution**: Changelog + change classes make it clear when
  cross-version comparison is valid

### What Becomes Harder

- **Simple runs**: Researchers who want a run record must use a runtime that
  implements the Run schema
- **Dynamic environments**: Mid-run topology changes are not yet addressed
  in RFC-0001; this RFC defers them

---

## Cross-References

| Document                             | Relationship                                              |
| :----------------------------------- | :-------------------------------------------------------- |
| RFC-0001: Environment Infrastructure | Environment versioned and referenced by Run records       |
| RFC-0002: Agentic Experiment         | Experiment referenced by Scenario; objectives define Run results |
| RFC-0003: Observability Schema       | Telemetry emitted during runs; per-call cost metrics      |
| RFC-0005: Security Domain Schema     | Domain-specific scenario and study labels for security    |
