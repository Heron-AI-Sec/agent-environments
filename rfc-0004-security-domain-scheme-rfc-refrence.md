# RFC-0004: Security Environment Wrapper for Security-Oriented Agentic Experiments

## Status

Proposed

## Supersession

This RFC supersedes prior RFC-0004 draft iterations and is the normative
RFC-0004 direction.

The authoritative role of RFC-0004 is to define the security environment
wrapper, its minimal local schema, and the authority boundaries between
this wrapper and adjacent RFCs or external systems.

## Summary

This RFC defines a thin wrapper for describing the environment of a
security-oriented agentic experiment.

The wrapper is an integration contract. It does not replace mature
standards or platforms. Instead, it binds them together into a coherent
environment-description layer by defining:

- a canonical environment description
- a minimal local schema for entities, relationships, zones, and references
- a semantics-profile mechanism for environment graph meaning
- authority boundaries across external systems
- attachment points for behavior, telemetry, execution, tracing, backend,
  and run metadata

This RFC replaces the prior "define the full security schema here"
approach. Rather than owning every attack edge, telemetry field,
blue-team state machine, or execution artifact format, RFC-0004 now
defines only the small amount of architecture needed to describe a
security experiment environment coherently and portably.

## Decision

RFC-0004 adopts a wrapper model:

- **Adapt** BloodHound-style graph semantics for relationship identifiers
  and traversal meaning
- **Reference** MITRE ATT&CK for behavior identifiers
- **Reference** OCSF for telemetry expectations and emitted evidence
- **Reference** CALDERA and Atomic Red Team for execution content
- **Reference** CybORG or similar systems as possible environment backends
- **Reference** OpenTelemetry and LangSmith for trace artifacts
- **Reference** Inspect and MLflow for eval/run metadata
- **Exclude** runtime scoring logic, agent SDK APIs, execution internals,
  telemetry schema internals, and full blue-team workflow definitions from
  this RFC

The result is a replacement-grade RFC-0004 that is smaller, clearer, and
easier to maintain than the previous all-in-one schema draft.

## Problem Statement

Security-oriented agentic experiments need a portable way to describe the
environment in which the experiment occurs.

That environment description must capture, at minimum:

- what entities exist
- what trust, identity, and privilege relationships exist
- what zones or boundaries matter
- what attack-relevant paths are present
- what telemetry sources and classes are expected
- what external behavior or execution references are attached
- what backend, trace, or run artifacts may be linked to the environment

No single existing system solves this end-to-end. Some systems are strong
at graph semantics. Some are strong at behavior labeling. Some are strong
at telemetry representation. Some are strong at execution or evaluation.
What is missing is the thin contract that states how those pieces fit
together when the goal is to describe the environment of a security
experiment.

## Motivation

A standalone bespoke security schema duplicates mature work and creates
unnecessary maintenance burden.

A wrapper approach is preferable because it allows RFC-0004 to define only
what is not already owned elsewhere:

- the canonical environment wrapper
- the minimum local schema required for coherence
- the semantics-profile attachment point for relationships
- the authority boundary for each concern
- the attachment points for external references
- conformance rules for how those references are used

The wrapper therefore acts as a composition layer rather than a
replacement standard.

## Goals

This RFC has six goals.

First, define a canonical wrapper for security experiment environment
description.

Second, specify which concern is authoritative in which external system or
adjacent RFC.

Third, define the minimum local schema needed for a coherent environment
description.

Fourth, preserve portability across runtimes, evaluation systems, content
packages, and backends.

Fifth, replace the earlier over-broad RFC-0004 draft with a maintainable
normative contract.

Sixth, avoid reinventing mature systems that already solve their own
concerns well.

## Non-Goals

This RFC does not define:

- offensive procedures
- exploit execution logic
- runtime scoring logic
- agent planning
- blue-team workflow state machines
- telemetry field internals
- execution content internals
- tracing schema internals
- eval harness internals
- run-tracking internals
- agent SDK APIs
- a full attack-graph database
- a full local enumeration of every security edge type

Those concerns belong either to external systems or to adjacent RFCs.

## Design Principles

### 1. Thin by design

This RFC is intentionally small. Its job is to define the wrapper, not the
entire security stack.

### 2. Composition over invention

The wrapper composes existing systems instead of replacing them.

### 3. Explicit authority

Each architectural concern must have a clearly identified authoritative
source.

### 4. Strong boundaries

If a concern belongs to an adjacent RFC or external system, this RFC
references it rather than re-specifying it.

### 5. Portable environment description

The wrapper must remain usable across multiple backends and experiment
toolchains.

### 6. Local minimum, external maximum

Local types exist only where necessary to bind external authorities into
one coherent environment contract.

## Authority And Dependency Disposition

| System | What it already solves well | Adopt / Adapt / Reference / Exclude | How it interacts with the wrapper | Gap that remains |
| --- | --- | --- | --- | --- |
| BloodHound-style graph semantics | Directed privilege relationships, documented edge semantics, source/destination constraints, and traversability. See [About BloodHound Edges](https://bloodhound.specterops.io/resources/edges/overview) and [Traversable and Non-Traversable Edge Types](https://bloodhound.specterops.io/resources/edges/traversable-edges). | **Adapt** | Wrapper uses BloodHound-compatible relationship identifiers or a profiled subset for environment graph semantics. | BloodHound is not a neutral experiment-environment wrapper and does not by itself define telemetry, eval, or cross-system contracts. |
| MITRE ATT&CK | Common language for adversary tactics and techniques. See [MITRE ATT&CK](https://attack.mitre.org/). | **Reference** | Wrapper attaches ATT&CK IDs to relationships, objectives, or execution references as metadata. | ATT&CK is too coarse for typed environment relationships. |
| OCSF | Open, vendor-agnostic security event schema and schema browser for event classes, objects, and attributes. See [OCSF](https://ocsf.io/) and [OCSF Schema Browser](https://schema.ocsf.io/). | **Reference** | Wrapper declares expected telemetry sources/classes and requires emitted runtime evidence to be OCSF-aligned. | OCSF does not describe the environment graph itself. |
| CALDERA | Automated adversary emulation and automated security assessment. See [CALDERA](https://caldera.mitre.org/). | **Reference** | Wrapper can point to CALDERA adversary profiles or operations that realize parts of the declared environment scenario. | CALDERA is execution-oriented, not the authoritative environment schema. |
| Atomic Red Team | Portable ATT&CK-mapped security tests. See [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team). | **Reference** | Wrapper may point to atomics as realization examples for declared behaviors. | Not an environment-description system. |
| CybORG | Cybersecurity research environment for training and development of human and autonomous agents. See [CybORG](https://github.com/cage-challenge/CybORG). | **Reference** | Wrapper may target CybORG-like environments as one possible backend that instantiates the described environment. | CybORG is an environment framework, not the wrapper schema. |
| OpenTelemetry | Observability architecture for traces, metrics, logs, and context propagation. See [OpenTelemetry Overview](https://opentelemetry.io/docs/specs/otel/overview/). | **Reference** | Wrapper may declare trace expectations or correlation IDs, but not trace schema internals. | Does not model cyber environment structure. |
| LangSmith | Tracing, monitoring, dashboards, alerts, and trace management for LLM applications. See [LangSmith Observability](https://docs.langchain.com/langsmith/observability). | **Reference** | Wrapper may permit optional links to agent-trace artifacts for runs using LLM agents. | Not authoritative for security environment semantics. |
| Inspect | Open-source LLM evaluation framework with agents, tools, sandboxes, logs, tracing, and tool approval. See [Inspect](https://inspect.aisi.org.uk/), [Tool Approval](https://inspect.aisi.org.uk/approval.html), [Tracing](https://inspect.aisi.org.uk/tracing.html), and [Sandboxing](https://inspect.aisi.org.uk/sandboxing.html). | **Reference** | Wrapper may be consumed by Inspect-based evals as the environment contract. | Inspect is eval/runtime oriented, not a security environment schema. |
| MLflow | Experiment tracking for runs, metrics, parameters, metadata, and artifacts. See [MLflow Tracking](https://mlflow.org/docs/latest/ml/tracking/). | **Reference** | Wrapper may be stored as a run artifact or linked by run metadata. | Not an environment-description system. |

## Normative Authority Boundaries

RFC-0004 assigns authority as follows:

- **Environment graph semantics**: adapted BloodHound-style semantics via a
  declared semantics profile
- **Behavior references**: MITRE ATT&CK
- **Telemetry event representation**: OCSF
- **Execution content**: CALDERA, Atomic Red Team, or equivalent systems
- **Environment backend instantiation**: RFC-0001 infrastructure models,
  CybORG, or other compatible environments
- **Tracing**: OpenTelemetry, LangSmith, or equivalent systems
- **Experiment/run tracking**: Inspect, MLflow, or equivalent systems

RFC-0004 is authoritative only for:

- the wrapper document structure
- the minimum local schema
- semantics-profile attachment
- reference attachment rules
- conformance rules

RFC-0004 is not authoritative for:

- the full edge taxonomy itself
- telemetry field definitions
- execution implementation details
- trace schema internals
- scoring logic
- agent behavior logic

## Wrapper Model

The wrapper consists of six logical layers:

1. core environment inventory
2. relationship semantics profile
3. external behavior and execution attachments
4. telemetry and evidence expectations
5. backend attachments
6. trace and run attachments

The wrapper is declarative. It describes the environment contract for an
experiment. It does not describe runtime control flow.

## Canonical Environment Description

The wrapper MUST be able to describe:

- entities in the environment
- trust and privilege relationships between entities
- boundaries and zones in the environment
- expected telemetry sources and classes
- references to external behavior and execution artifacts
- optional backend bindings
- optional trace and run artifact links

### Minimal schema

```yaml
Environment:
  id: string
  name: string
  description: string?
  semantics_profile: SemanticsProfileRef
  entities: list[Entity]
  relationships: list[Relationship]
  zones: list[Zone]?
  objectives: list[ObjectiveRef]?
  telemetry_profiles: list[TelemetryProfileRef]?
  evidence_expectations: list[EvidenceExpectation]?
  execution_refs: list[ExecutionRef]?
  backend_refs: list[BackendRef]?
  trace_refs: list[TraceRef]?
  run_refs: list[RunRef]?

SemanticsProfileRef:
  system: "BLOODHOUND_PROFILE" | "OTHER"
  profile: string
  version: string?
  source: string?

Entity:
  id: string
  type: string
  name: string?
  zone_ref: string?
  attributes: map[string, scalar | list | object]

Zone:
  id: string
  name: string
  attributes: map[string, scalar | list | object]?

Relationship:
  id: string
  type: string
  source_ref: string
  target_ref: string
  metadata: map[string, scalar | list | object]?
  behavior_refs: list[BehaviorRef]?
  execution_refs: list[ExecutionRef]?
  telemetry_profile_refs: list[string]?

ObjectiveRef:
  id: string
  kind: "attack_path" | "detection" | "investigation" | "validation"
  description: string?
  behavior_refs: list[BehaviorRef]?
  relationship_refs: list[string]?

BehaviorRef:
  system: "ATTACK"
  id: string

ExecutionRef:
  system: "CALDERA" | "ATOMIC" | "OTHER"
  id: string
  ref: string?

TelemetryProfileRef:
  id: string
  system: "OCSF"
  classes: list[string]?
  producers: list[string]?
  notes: string?

EvidenceExpectation:
  id: string
  description: string
  telemetry_profile_ref: string?
  trace_ref: string?
  run_ref: string?

BackendRef:
  system: "CYBORG" | "OTHER"
  ref: string

TraceRef:
  system: "OTEL" | "LANGSMITH" | "OTHER"
  ref: string

RunRef:
  system: "INSPECT" | "MLFLOW" | "OTHER"
  ref: string
```

## Conformance Requirements

A conforming RFC-0004 environment document:

- MUST declare exactly one `semantics_profile`
- MUST describe entities and relationships locally
- MUST treat relationship identifiers as belonging to the declared
  semantics profile
- SHOULD use BloodHound-compatible identifiers when the declared profile
  is BloodHound-derived
- MAY define a profiled subset of BloodHound-style identifiers
- MAY define additional local identifiers only if they are namespaced and
  documented by profile
- MUST use ATT&CK only as a behavior reference, not as the authoritative
  relationship taxonomy
- MUST use OCSF only as telemetry/evidence reference authority, not as the
  environment graph schema
- MUST treat CALDERA and Atomic references as execution realizations, not
  as the canonical environment description
- MUST treat backend, trace, and run references as optional attachments,
  not as the authoritative semantics of the environment
- MUST NOT redefine scoring logic, agent APIs, telemetry internals, or
  full execution semantics inside RFC-0004

## Relationship Semantics Profile

The purpose of the semantics profile is to keep the local wrapper small
while ensuring relationship types still have stable meaning.

At minimum, a semantics profile defines:

- the set or subset of permitted relationship identifiers
- source and target constraints where relevant
- any profile-specific metadata rules
- any namespacing rules for local extensions

For most security scenarios, the default profile SHOULD be a
BloodHound-compatible profile or subset. Authors using such a profile
SHOULD align identifiers to SpecterOps' documented edge names and edge
lists, especially [About BloodHound Edges](https://bloodhound.specterops.io/resources/edges/overview)
and [Traversable and Non-Traversable Edge Types](https://bloodhound.specterops.io/resources/edges/traversable-edges).
This gives the wrapper precise attack-path semantics without forcing
RFC-0004 itself to own the full taxonomy inline.

## Scope Consolidation

This RFC uses a narrower and more maintainable scope by relocating
authority:

- attack relationship vocabulary is adapted through a declared semantics
  profile instead of being exhaustively redefined here
- ATT&CK mappings are referenced as metadata instead of becoming the core
  relationship model
- telemetry semantics are referenced through OCSF and adjacent RFCs
  instead of being restated in full here
- execution content is referenced through CALDERA, Atomic Red Team, or
  equivalent systems instead of being embedded here
- tracing and run metadata are attached through existing systems instead of
  locally re-specified
- runtime scoring and workflow logic remain outside this RFC

This is the mechanism by which RFC-0004 stays replacement-complete
without carrying unnecessary schema bulk.

## Worked Example

```yaml
Environment:
  id: env-ad-lab-01
  name: Example AD Security Lab
  description: Small environment for credential-access and lateral-movement evaluation
  semantics_profile:
    system: BLOODHOUND_PROFILE
    profile: bloodhound-compat-core
    version: "1"
    source: specterops/bloodhound-edges
  entities:
    - id: user.alice
      type: Principal
      name: Alice
      zone_ref: zone.corp
      attributes:
        domain: corp.local
    - id: host.ws01
      type: Host
      name: WS01
      zone_ref: zone.corp
      attributes:
        role: workstation
    - id: host.dc01
      type: Host
      name: DC01
      zone_ref: zone.corp
      attributes:
        role: dc
  relationships:
    - id: rel-1
      type: CanRDP
      source_ref: user.alice
      target_ref: host.ws01
      behavior_refs:
        - system: ATTACK
          id: T1021
    - id: rel-2
      type: AdminTo
      source_ref: user.alice
      target_ref: host.ws01
      behavior_refs:
        - system: ATTACK
          id: T1078
    - id: rel-3
      type: DCSync
      source_ref: user.alice
      target_ref: host.dc01
      behavior_refs:
        - system: ATTACK
          id: T1003.006
      execution_refs:
        - system: CALDERA
          id: sandcat-dcsync
  zones:
    - id: zone.corp
      name: Corp
  objectives:
    - id: obj-1
      kind: attack_path
      description: Validate whether Alice can reach credential replication against the domain controller
      relationship_refs: [rel-3]
  telemetry_profiles:
    - id: tel-1
      system: OCSF
      classes: [identity_activity, application_activity]
      notes: Expect credential-access related evidence for DCSync-like behavior
  evidence_expectations:
    - id: ev-1
      description: Runtime evidence should include OCSF-aligned identity activity linked to DCSync behavior
      telemetry_profile_ref: tel-1
  backend_refs:
    - system: CYBORG
      ref: cyborg/example-ad-lab
  trace_refs:
    - system: OTEL
      ref: otel://trace-group/example-ad-lab
  run_refs:
    - system: INSPECT
      ref: inspect://evals/example-ad-lab
```

### Example: Alice Secret On Bob, Eve Can RDP

The wrapper can express "Alice's secret is on Bob and Eve has RDP
permissions there" in two different ways depending on the intended
semantics.

If the intent is that Alice's credential material is simply present on
Bob, a local namespaced relationship can be used:

```yaml
Environment:
  id: env-secret-on-bob
  name: Alice secret on Bob, Eve can RDP
  semantics_profile:
    system: BLOODHOUND_PROFILE
    profile: bloodhound-compat-core-plus-local

  entities:
    - id: principal.alice
      type: Principal
      name: alice

    - id: principal.eve
      type: Principal
      name: eve

    - id: host.bob
      type: Host
      name: bob

    - id: credential.alice.secret
      type: Credential
      name: alice-secret
      attributes:
        kind: password

  relationships:
    - id: rel-1
      type: Authenticates
      source_ref: credential.alice.secret
      target_ref: principal.alice

    - id: rel-2
      type: local.StoredOn
      source_ref: credential.alice.secret
      target_ref: host.bob
      metadata:
        description: Alice's secret is present on Bob

    - id: rel-3
      type: CanRDP
      source_ref: principal.eve
      target_ref: host.bob
```

If the intent is specifically that Alice has a session on Bob and her
credential material is therefore recoverable there, a BloodHound-style
relationship is a better fit:

```yaml
Environment:
  id: env-session-on-bob
  name: Alice session on Bob, Eve can RDP
  semantics_profile:
    system: BLOODHOUND_PROFILE
    profile: bloodhound-compat-core

  entities:
    - id: principal.alice
      type: Principal
      name: alice

    - id: principal.eve
      type: Principal
      name: eve

    - id: host.bob
      type: Host
      name: bob

  relationships:
    - id: rel-1
      type: HasSession
      source_ref: principal.alice
      target_ref: host.bob

    - id: rel-2
      type: CanRDP
      source_ref: principal.eve
      target_ref: host.bob
```

Use `HasSession` when the presence of Alice's secret on Bob is implied by
session semantics. Use a namespaced local relationship such as
`local.StoredOn` only when the environment needs to express a generic
stored-secret fact that is not precisely captured by the selected
BloodHound-compatible profile.

## Migration Notes

If an older document or tool expected RFC-0004 to directly define the full
security schema, migrate as follows:

- keep entities and relationships in the local environment document
- move relationship meaning into a declared semantics profile
- convert ATT&CK references into metadata attachments
- convert telemetry expectations into OCSF-aligned references
- convert execution examples into CALDERA or Atomic references
- convert eval/run metadata into Inspect or MLflow references
- remove scoring logic, agent workflow state, and execution internals from
  the RFC-0004 layer

## Consequences

### What becomes easier

- keeping RFC-0004 short and maintainable
- aligning with mature external standards
- reusing the same wrapper across different backends and eval systems
- evolving execution and telemetry systems independently from the wrapper
- replacing or extending semantics profiles without rewriting the whole RFC

### What becomes harder

- a separate profile definition is required for precise relationship
  semantics
- readers must consult adjacent RFCs or external standards for deeper
  behavior, telemetry, execution, and tracing details
- teams must be disciplined about not smuggling runtime logic back into the
  wrapper

## References

- Verified against official project or vendor pages on April 2, 2026.
- BloodHound edge overview: https://bloodhound.specterops.io/resources/edges/overview
- BloodHound traversable and non-traversable edge types: https://bloodhound.specterops.io/resources/edges/traversable-edges
- MITRE ATT&CK: https://attack.mitre.org/
- OCSF homepage: https://ocsf.io/
- OCSF schema browser: https://schema.ocsf.io/
- CALDERA: https://caldera.mitre.org/
- Atomic Red Team: https://github.com/redcanaryco/atomic-red-team
- CybORG: https://github.com/cage-challenge/CybORG
- OpenTelemetry overview: https://opentelemetry.io/docs/specs/otel/overview/
- LangSmith observability docs: https://docs.langchain.com/langsmith/observability
- Inspect overview: https://inspect.aisi.org.uk/
- Inspect tool approval: https://inspect.aisi.org.uk/approval.html
- Inspect tracing: https://inspect.aisi.org.uk/tracing.html
- Inspect sandboxing: https://inspect.aisi.org.uk/sandboxing.html
- MLflow Tracking: https://mlflow.org/docs/latest/ml/tracking/
