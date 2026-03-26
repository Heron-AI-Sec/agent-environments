# RFC-0003: Observability Schema Specification

## Status

`Draft`

## Summary

This RFC proposes a schema specification for telemetry data in agentic
experiments. It defines attribute conventions, event taxonomy, and correlation
patterns that enable meaningful observation and analysis of agent behavior.

This specification is infrastructure-agnostic. RFC-0001 defines where telemetry
is collected and stored. This specification defines what the telemetry means.

## Motivation

Consistent telemetry semantics enable:

1. **Correlation**: Link agent actions to environment effects to observed events
2. **Interoperability**: Common schema across different backends and tools
3. **Analysis**: Meaningful queries and dashboards without per-experiment setup
4. **Comparison**: Cross-experiment analysis using consistent attributes

### Design Principles

1. **Schema-Only**: No infrastructure concerns; agnostic to backends and formats
2. **Extensible**: Core schema with domain-specific extensions
3. **Compatible**: Aligned with industry standards (OpenTelemetry, OCSF, ECS)
4. **Correlation-First**: Designed for linking causally-related events

---

## Schema Overview

| Section       | Purpose                                  |
| :------------ | :--------------------------------------- |
| `attributes`        | Standard attribute definitions and types          |
| `taxonomy`          | Event categories and classes                      |
| `agent_decisions`   | Structured records emitted per agent decision     |
| `correlation`       | Patterns for linking related telemetry            |
| `extensions`        | Domain-specific schema additions                  |

---

## Core Attributes

Core attributes appear across all telemetry types (spans, logs, metrics).

### Resource Attributes

Identify the source of telemetry.

| Attribute             | Type   | Description               | Example                           |
| :-------------------- | :----- | :------------------------ | :-------------------------------- |
| `experiment.name`     | String | Experiment identifier     | `exploration-001`                 |
| `experiment.version`  | String | Experiment version        | `1.0.0`                           |
| `experiment.agents`   | Object | Active agents             | `[explorer-agent, network-agent]` |
| `experiment.phase`    | String | Current execution phase   | `exploration`                     |
| `environment.name`    | String | RFC-0001 environment name | `dev-environment`                 |
| `environment.version` | String | Environment version       | `1.0.0`                           |

### Agent Attributes

Identify the agent producing or triggering telemetry.

| Attribute           | Type   | Description                | Example                      |
| :------------------ | :----- | :------------------------- | :--------------------------- |
| `agent.id`          | String | Agent identifier           | `explorer-agent`             |
| `agent.type`        | String | Agent paradigm             | `llm`, `rl`, `scripted`      |
| `agent.role`        | String | Functional role            | `orchestrator`, `specialist` |
| `agent.instance_id` | String | Unique instance identifier | `explorer-agent-7f8a9b`      |

### Action Attributes

Describe agent actions. An action is a logical unit of work (e.g. "scan_and_sort_network") that may involve multiple tool calls. Each tool call within an action produces a child span using `action.tool_call.*` attributes.

| Attribute            | Type    | Description                                                       | Example                              |
| :------------------- | :------ | :---------------------------------------------------------------- | :----------------------------------- |
| `action.id`          | String  | Unique action identifier. Used for correlation (see `action_id`). | `action-7f3a1c`                      |
| `action.name`        | String  | Human-readable action label.                                      | `scan_and_sort_network`              |
| `action.type`        | String  | Action category.                                                  | `shell`, `tool`, `api`               |
| `action.role`        | String  | Role for the action.                                              | `root`, `user`                       |
| `action.input`       | String  | Action input (may be truncated).                                  | `nmap -sV 10.0.1.0/24`               |
| `action.output`      | String  | Action output (may be truncated).                                 | `Host 10.0.1.10 is up...`            |
| `action.status`      | String  | Outcome status.                                                   | `success`, `failure`, `timeout`      |
| `action.duration_ms` | Integer | Execution duration in milliseconds.                               | `1523`                               |
| `action.iteration`   | Integer | Action sequence number for agent.                                 | `42`                                 |

#### Action Tool Call Attributes

Each tool invocation within an action produces a child span with these attributes.

| Attribute                    | Required | Description                                     |
| :--------------------------- | :------- | :---------------------------------------------- |
| `action.tool_call.id`        | Yes      | Unique identifier for this tool execution.      |
| `action.tool_call.name`      | Yes      | Tool or command invoked.                        |
| `action.tool_call.arguments` | Yes      | Parameters passed to the tool.                  |
| `action.tool_call.timestamp` | Yes      | When execution started (ISO 8601).              |
| `action.tool_call.duration_ms` | No     | How long the tool took to execute.              |
| `action.tool_call.output`    | Yes      | Raw output returned by the tool.                |
| `action.tool_call.status`    | Yes      | Execution state: `success`, `error`, `timeout`. |

### Target Attributes

Describe what an action targeted.

| Attribute        | Type    | Description                                                    | Example                           |
| :--------------- | :------ | :------------------------------------------------------------- | :-------------------------------- |
| `target.node`    | String  | Target node identifier — map key from RFC-0001 `topology.nodes`. | `web-01`                        |
| `target.group`   | String  | Target group identifier — map key from RFC-0001 `groups`.      | `servers`                         |
| `target.network` | String  | Target network (RFC-0001).                                     | `internal`                        |
| `target.address` | String  | Target IP or hostname.                                         | `10.0.1.10`                       |
| `target.port`    | Integer | Target port.                                                   | `443`                             |
| `target.service` | String  | Target service.                                                | `https`                           |
| `target.env`     | String  | Environment variables.                                         | `{PATH:/usr/local/sbin:/usr/bin}` |

### Outcome Attributes

Describe results and effects.

| Attribute             | Type   | Description                 | Example                        |
| :-------------------- | :----- | :-------------------------- | :----------------------------- |
| `outcome.type`        | String | Outcome category            | `discovery`, `change`, `error` |
| `outcome.description` | String | Human-readable outcome      | `Found 3 open ports`           |
| `outcome.artifact`    | String | Path to produced artifact   | `/output/scan.json`            |
| `outcome.objective`   | String | Objective achieved (if any) | `environment-mapped`           |

### Timing Attributes

| Attribute          | Type    | Description                 | Example                |
| :----------------- | :------ | :-------------------------- | :--------------------- |
| `timestamp`        | String  | ISO 8601 timestamp          | `2024-01-15T10:30:00Z` |
| `elapsed_ms`       | Integer | Time since experiment start | `360000`               |
| `phase_elapsed_ms` | Integer | Time since phase start      | `120000`               |

---

## Taxonomy

The taxonomy defines categories and classes for events. This provides
consistent structure for different event types.

### Event Categories

Top-level groupings for events.

| Category      | Description                         |
| :------------ | :---------------------------------- |
| `agent`       | Agent lifecycle and behavior events |
| `action`      | Agent action execution events       |
| `observation` | Agent observation events            |
| `environment` | Environment state change events     |
| `objective`   | Objective evaluation events         |
| `system`      | System/infrastructure events        |

### Event Classes

Specific event types within categories.

#### Agent Events (`agent.*`)

| Class                 | Description                             |
| :-------------------- | :-------------------------------------- |
| `agent.spawned`       | Agent instance started                  |
| `agent.terminated`    | Agent instance stopped                  |
| `agent.iteration`     | Agent completed one reasoning cycle     |
| `agent.error`         | Agent encountered an error              |
| `agent.communication` | Agent sent/received inter-agent message |

#### Action Events (`action.*`)

| Class              | Description                |
| :----------------- | :------------------------- |
| `action.started`   | Action execution began     |
| `action.completed` | Action execution finished  |
| `action.failed`    | Action execution failed    |
| `action.timeout`   | Action exceeded time limit |

#### Observation Events (`observation.*`)

| Class                   | Description                            |
| :---------------------- | :------------------------------------- |
| `observation.received`  | Agent received observation data        |
| `observation.processed` | Agent processed observation            |
| `observation.insight`   | Agent derived insight from observation |

#### Environment Events (`environment.*`)

| Class                       | Description                 |
| :-------------------------- | :-------------------------- |
| `environment.state_change`  | Environment state modified  |
| `environment.node_event`    | Event from environment node |
| `environment.network_event` | Network-level event         |
| `environment.inject`        | Inject executed             |

#### Objective Events (`objective.*`)

| Class                 | Description                          |
| :-------------------- | :----------------------------------- |
| `objective.achieved`  | Objective condition met              |
| `objective.failed`    | Objective failed (penalty condition) |
| `objective.progress`  | Progress toward objective            |
| `objective.evaluated` | Objective condition evaluated        |

#### System Events (`system.*`)

| Class                  | Description                |
| :--------------------- | :------------------------- |
| `system.phase_started` | Experiment phase began     |
| `system.phase_ended`   | Experiment phase completed |
| `system.checkpoint`    | Checkpoint created         |
| `system.error`         | System-level error         |

---

## Span Structure

Spans represent units of work with duration. They form traces that show
causal relationships.

### Span Naming Convention

```text
{category}.{class}.{detail}
```

Examples:

- `agent.iteration.reasoning`
- `action.shell.execute`
- `action.tool.nmap`
- `observation.telemetry.query`

### Standard Span Attributes

All spans SHOULD include:

| Attribute          | Required | Description                 |
| :----------------- | :------- | :-------------------------- |
| `experiment.name`  | Yes      | Experiment identifier       |
| `agent.id`       | Yes      | Agent that created the span |
| `experiment.phase` | Yes      | Current phase               |

Action spans SHOULD also include:

| Attribute       | Required | Description                     |
| :-------------- | :------- | :------------------------------ |
| `action.id`     | Yes      | Unique action identifier        |
| `action.name`   | No       | Human-readable action label     |
| `action.type`   | Yes      | Action category                 |
| `action.status` | Yes      | Outcome status                  |
| `target.*`      | No       | Target attributes if applicable |

### Span Relationships

| Relationship   | Description                              |
| :------------- | :--------------------------------------- |
| `child_of`     | Span is a child of parent span           |
| `follows_from` | Span is causally related but not a child |
| `links`        | Span references related spans            |

---

## Agent Decision Records

Agent telemetry is structured in three levels. Each level produces its own span:

```
agent.decision.*     (one reasoning cycle — what the agent decided to do)
  └── action.*       (one logical action — e.g. "scan_and_sort_network")
        └── action.tool_call.*  (one tool invocation — e.g. nmap)
        └── action.tool_call.*  (one tool invocation — e.g. sort)
```

`agent.decision.*` captures the reasoning cycle. `action.*` captures the logical action the decision triggered. `action.tool_call.*` captures each atomic tool invocation within that action.

### Agent Decision Attributes

| Attribute                          | Required | Description                                                       |
| :--------------------------------- | :------- | :---------------------------------------------------------------- |
| `agent.decision.id`                | Yes      | Unique identifier for this decision record.                       |
| `agent.decision.agent`             | Yes      | Agent that made this decision. References `agent.id` (RFC-0002). |
| `agent.decision.timestamp`         | Yes      | When the decision was made (ISO 8601).                            |
| `agent.decision.objective_ref`     | Yes      | RFC-0002 objective the agent was pursuing.                        |
| `agent.decision.environment_state` | No       | Snapshot of relevant environment state at decision time.          |
| `agent.decision.input`             | Yes      | What the agent observed before deciding.                          |
| `agent.decision.cot`               | Yes      | Chain-of-Thought reasoning steps. **How to gather this?**         |
| `agent.decision.outcome`           | No       | Result of the decision cycle: `success`, `failure`, `aborted`.   |

---

## Correlation

Correlation patterns link related telemetry across agents, actions, and
environment events.

### Correlation Identifiers

| Identifier       | Scope        | Description                       |
| :--------------- | :----------- | :-------------------------------- |
| `trace_id`       | Trace        | Links all spans in a trace        |
| `span_id`        | Span         | Unique span identifier            |
| `parent_span_id` | Span         | Parent span for hierarchy         |
| `experiment_id`  | Experiment   | Links all telemetry in experiment |
| `correlation_id` | Causal chain | Links causally-related events     |
| `action_id`      | Action       | Links action to its effects       |

### Correlation Patterns

#### Agent Action → Environment Effect

Link an agent action to the environment change it caused.

```text
┌─────────────────┐     correlation_id      ┌─────────────────┐
│  action.shell   │ ────────────────────────▶│ environment.    │
│    .execute     │                          │  state_change   │
└─────────────────┘                          └─────────────────┘
     agent.id: explorer                         target.node: web-01
     action.input: "curl..."                      outcome.type: discovery
```

Both events share the same `correlation_id`.

#### Agent Action → Telemetry Event

Link an agent action to telemetry it generated in the environment.

```text
┌─────────────────┐     action_id           ┌─────────────────┐
│  action.tool    │ ────────────────────────▶│ environment.    │
│    .nmap        │                          │   node_event    │
└─────────────────┘                          └─────────────────┘
     agent.id: explorer                         source: syslog
     target.address: 10.0.1.0/24                  event: connection_attempt
```

The `action_id` from the action span appears in the environment event.

#### Multi-Agent Correlation

Link actions across communicating agents.

```text
┌─────────────────┐     correlation_id      ┌─────────────────┐
│ agent.          │ ────────────────────────▶│ agent.          │
│  communication  │                          │  communication  │
│  (send)         │                          │  (receive)      │
└─────────────────┘                          └─────────────────┘
     agent.id: explorer                         agent.id: analyzer
     channel: findings                            channel: findings
```

#### Objective Achievement Chain

Link the action chain that led to an objective.

```text
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  action.tool    │────▶│  action.shell   │────▶│  objective.     │
│    .nmap        │     │    .execute     │     │   achieved      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                     objective: env-mapped
```

All spans share the same `trace_id`, showing the causal chain.

### Correlation Implementation

#### Using Span Context

```yaml
# Action span
span:
  name: action.tool.nmap
  trace_id: abc123
  span_id: def456
  attributes:
    agent.id: explorer
    action.name: nmap_scan
    action_id: scan-001

# Resulting environment event (log)
log:
  timestamp: 2024-01-15T10:30:00Z
  body: "Connection attempt from 10.0.1.50"
  attributes:
    trace_id: abc123          # Links to trace
    action_id: scan-001       # Links to specific action
    source.address: 10.0.1.50
    target.address: 10.0.1.10
```

#### Using Correlation IDs

```yaml
# Agent action
event:
  class: action.completed
  correlation_id: corr-789
  attributes:
    agent.id: explorer
    action.name: enumerate_hosts

# Environment effect
event:
  class: environment.state_change
  correlation_id: corr-789    # Same correlation ID
  attributes:
    target.node: web-01
    outcome.type: discovery
```

---

## Extensions

Extensions add domain-specific attributes and event classes. Extensions
are namespaced to avoid conflicts.

### Extension Structure

Extensions define:

- Additional attributes (namespaced)
- Additional event classes
- Domain-specific correlation patterns

### Declaring Extensions

```yaml
schema:
  version: "1.0.0"
  extensions:
    - name: security
      version: "1.0.0"
    - name: software_engineering
      version: "1.0.0"
```

---

## Security Extension

The security extension adds attributes and events for security-focused
experiments (red team, blue team, purple team).

**See RFC-0004: Security Domain Schema** for the complete security extension
specification, including:

- MITRE ATT&CK attributes (`mitre.tactic`, `mitre.technique.id`, etc.)
- Team attributes (`security.team`, `security.operation`, `security.campaign`)
- Attack attributes (`attack.phase`, `attack.vector`, `attack.target.type`)
- Defense attributes (`detection.rule`, `detection.severity`, `response.action`)
- Credential attributes (`credential.type`, `credential.username`, etc.)
- Active Directory attributes (`ad.domain`, `ad.forest`, `ad.object.*`)
- Security event classes (`security.attack.*`, `security.defense.*`)
- Security correlation patterns (attack chains, attack→detection linking)

RFC-0004 §16 defines these telemetry attributes as part of the unified security
domain schema, ensuring consistency between attack graph types, blue team
taxonomy, and observability semantics.

---

## Software Engineering Extension

The software engineering extension adds attributes and events for
code-related experiments.

### Software Engineering Attributes

#### Repository Attributes

| Attribute     | Type   | Description        | Example               |
| :------------ | :----- | :----------------- | :-------------------- |
| `repo.name`   | String | Repository name    | `my-project`          |
| `repo.url`    | String | Repository URL     | `github.com/org/repo` |
| `repo.branch` | String | Current branch     | `feature/new-api`     |
| `repo.commit` | String | Current commit SHA | `a1b2c3d4`            |

#### Code Attributes

| Attribute       | Type    | Description          | Example        |
| :-------------- | :------ | :------------------- | :------------- |
| `code.file`     | String  | File path            | `src/main.py`  |
| `code.function` | String  | Function name        | `process_data` |
| `code.line`     | Integer | Line number          | `42`           |
| `code.language` | String  | Programming language | `python`       |

#### Change Attributes

| Attribute              | Type    | Description             | Example                   |
| :--------------------- | :------ | :---------------------- | :------------------------ |
| `change.type`          | String  | Type of change          | `add`, `modify`, `delete` |
| `change.files_count`   | Integer | Number of files changed | `5`                       |
| `change.lines_added`   | Integer | Lines added             | `120`                     |
| `change.lines_removed` | Integer | Lines removed           | `45`                      |

#### Quality Attributes

| Attribute                 | Type    | Description              | Example |
| :------------------------ | :------ | :----------------------- | :------ |
| `quality.test_coverage`   | Float   | Test coverage percentage | `85.5`  |
| `quality.lint_errors`     | Integer | Linting errors           | `0`     |
| `quality.type_errors`     | Integer | Type checking errors     | `2`     |
| `quality.security_issues` | Integer | Security scan issues     | `0`     |

#### CI/CD Attributes

| Attribute        | Type    | Description              | Example             |
| :--------------- | :------ | :----------------------- | :------------------ |
| `ci.pipeline`    | String  | Pipeline name            | `build-and-test`    |
| `ci.job`         | String  | Job name                 | `unit-tests`        |
| `ci.status`      | String  | Pipeline/job status      | `success`, `failed` |
| `ci.duration_ms` | Integer | Duration in milliseconds | `45000`             |

### Software Engineering Event Classes

#### Development Events (`swe.dev.*`)

| Class                    | Description        |
| :----------------------- | :----------------- |
| `swe.dev.file_created`   | New file created   |
| `swe.dev.file_modified`  | File modified      |
| `swe.dev.file_deleted`   | File deleted       |
| `swe.dev.function_added` | New function added |
| `swe.dev.refactor`       | Code refactored    |

#### Testing Events (`swe.test.*`)

| Class                      | Description               |
| :------------------------- | :------------------------ |
| `swe.test.suite_started`   | Test suite started        |
| `swe.test.suite_completed` | Test suite completed      |
| `swe.test.passed`          | Individual test passed    |
| `swe.test.failed`          | Individual test failed    |
| `swe.test.coverage_report` | Coverage report generated |

#### Review Events (`swe.review.*`)

| Class                          | Description          |
| :----------------------------- | :------------------- |
| `swe.review.requested`         | Review requested     |
| `swe.review.comment`           | Review comment added |
| `swe.review.approved`          | Review approved      |
| `swe.review.changes_requested` | Changes requested    |

#### CI/CD Events (`swe.ci.*`)

| Class                       | Description        |
| :-------------------------- | :----------------- |
| `swe.ci.pipeline_started`   | Pipeline started   |
| `swe.ci.pipeline_completed` | Pipeline completed |
| `swe.ci.job_started`        | Job started        |
| `swe.ci.job_completed`      | Job completed      |
| `swe.ci.artifact_published` | Artifact published |

---

## Format Compatibility

This schema is designed to be compatible with industry standard formats.

### OpenTelemetry

Attributes map directly to OpenTelemetry semantic conventions where
applicable. Use the `otel.*` prefix for OTel-specific attributes.

| ACES Attribute       | OTel Equivalent         |
| :------------------- | :---------------------- |
| `agent.id`         | `service.name`          |
| `action.duration_ms` | `duration` (span field) |
| `target.address`     | `net.peer.name`         |
| `target.port`        | `net.peer.port`         |

### OCSF

Security extension events can be mapped to OCSF classes.

| ACES Event Class                    | OCSF Category / Class                |
| :---------------------------------- | :----------------------------------- |
| `security.attack.credential_access` | Identity Activity / Authentication   |
| `security.defense.alert`            | Security Finding / Detection Finding |
| `environment.network_event`         | Network Activity                     |

### ECS (Elastic Common Schema)

Attributes can be mapped to ECS fields.

| ACES Attribute        | ECS Equivalent     |
| :-------------------- | :----------------- |
| `agent.id`          | `agent.name`       |
| `target.address`      | `destination.ip`   |
| `target.port`         | `destination.port` |
| `credential.username` | `user.name`        |

---

## Schema Versioning

### Version Format

Schemas use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes to core attributes or event classes
- **MINOR**: New attributes or event classes (backward compatible)
- **PATCH**: Clarifications, documentation fixes

### Compatibility

Telemetry SHOULD include schema version:

```yaml
attributes:
  schema.version: "1.0.0"
  schema.extensions:
    - security:1.0.0
```

---

## Complete Example

```yaml
# Agent action span with security extension
span:
  name: action.tool.bloodhound
  trace_id: trace-abc123
  span_id: span-def456
  parent_span_id: span-parent
  start_time: 2024-01-15T10:30:00Z
  end_time: 2024-01-15T10:30:15Z

  attributes:
    # Schema version
    schema.version: "1.0.0"
    schema.extensions: ["security:1.0.0"]

    # Resource attributes
    experiment.name: purple-team-001
    experiment.version: "1.0.0"
    experiment.phase: reconnaissance
    environment.name: ad-lab

    # Agent attributes
    agent.id: recon-agent
    agent.type: llm
    agent.instance_id: recon-agent-7f8a9b

    # Action attributes
    action.name: bloodhound_collection
    action.type: tool
    action.input: "bloodhound-python -c All -d corp.local"
    action.status: success
    action.duration_ms: 15000
    action.iteration: 5

    # Target attributes
    target.node: kali-01
    target.group: domain_controllers
    target.address: 10.0.10.10

    # Outcome attributes
    outcome.type: discovery
    outcome.description: "Collected AD graph data"
    outcome.artifact: /loot/bloodhound.zip

    # Security extension
    security.team: red
    mitre.tactic: discovery
    mitre.technique.id: T1087.002
    mitre.technique.name: Domain Account
    attack.phase: reconnaissance
    ad.domain: corp.local

  # Linked events
  links:
    - trace_id: trace-xyz789
      span_id: span-detection
      relationship: triggers
```

---

## Affected Repos

| Repository        | Changes Required                             |
| :---------------- | :------------------------------------------- |
| `aces-schema`     | JSON Schema for observability schema         |
| `aces-telemetry`  | Schema validation, format conversion         |
| `aces-agent-sdk`  | Span/event emission with schema compliance   |
| `aces-evaluation` | Schema-aware objective evaluation            |
| `aces-dashboards` | Pre-built dashboards using schema attributes |

---

## Consequences

### What Becomes Easier

- **Correlation**: Standard IDs and patterns for linking events
- **Queries**: Consistent attribute names across experiments
- **Dashboards**: Reusable visualizations based on schema
- **Cross-experiment analysis**: Comparable data structures
- **Tool integration**: Compatible with OTel, OCSF, ECS ecosystems

### What Becomes Harder

- **Schema compliance**: Telemetry must follow conventions
- **Extension management**: Domains must maintain extensions
- **Version coordination**: Schema versions must align across components

---

## Cross-References

| Document                             | Relationship                                                                         |
| :----------------------------------- | :----------------------------------------------------------------------------------- |
| RFC-0001: Environment Infrastructure | Defines telemetry backends and sinks                                                 |
| RFC-0002: Experiment Specification   | References schema for observations                                                   |
| RFC-0004: Security Domain Schema     | Defines security extension attributes, event classes, and correlation patterns (§16) |
| OpenTelemetry Semantic Conventions   | Attribute naming alignment                                                           |
| OCSF Schema                          | Security event structure alignment                                                   |
