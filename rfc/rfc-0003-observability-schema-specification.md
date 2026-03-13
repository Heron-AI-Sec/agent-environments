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

| Section        | Purpose                                                   |
|:---------------|:----------------------------------------------------------|
| `attributes`   | Standard attribute definitions and types                  |
| `taxonomy`     | Event categories and classes                              |
| `correlation`  | Patterns for linking related telemetry                    |
| `extensions`   | Domain-specific schema additions                          |

---

## Core Attributes

Core attributes appear across all telemetry types (spans, logs, metrics).

### Resource Attributes

Identify the source of telemetry.

| Attribute              | Type   | Description                          | Example                    |
|:-----------------------|:-------|:-------------------------------------|:---------------------------|
| `experiment.name`      | String | Experiment identifier                | `exploration-001`          |
| `experiment.version`   | String | Experiment version                   | `1.0.0`                    |
| `experiment.phase`     | String | Current execution phase              | `exploration`              |
| `environment.name`     | String | RFC-0001 environment name            | `dev-environment`          |
| `environment.version`  | String | Environment version                  | `1.0.0`                    |

### Agent Attributes

Identify the agent producing or triggering telemetry.

| Attribute              | Type   | Description                          | Example                    |
|:-----------------------|:-------|:-------------------------------------|:---------------------------|
| `agent.name`           | String | Agent identifier                     | `explorer-agent`           |
| `agent.type`           | String | Agent paradigm                       | `llm`, `rl`, `scripted`    |
| `agent.role`           | String | Functional role                      | `orchestrator`, `specialist`|
| `agent.instance_id`    | String | Unique instance identifier           | `explorer-agent-7f8a9b`    |

### Action Attributes

Describe agent actions.

| Attribute              | Type    | Description                          | Example                    |
|:-----------------------|:--------|:-------------------------------------|:---------------------------|
| `action.name`          | String  | Action identifier                    | `shell.execute`            |
| `action.type`          | String  | Action category                      | `shell`, `tool`, `api`     |
| `action.input`         | String  | Action input (may be truncated)      | `nmap -sV 10.0.1.0/24`     |
| `action.output`        | String  | Action output (may be truncated)     | `Host 10.0.1.10 is up...`  |
| `action.status`        | String  | Outcome status                       | `success`, `failure`, `timeout` |
| `action.duration_ms`   | Integer | Execution duration in milliseconds   | `1523`                     |
| `action.iteration`     | Integer | Action sequence number for agent     | `42`                       |

### Target Attributes

Describe what an action targeted.

| Attribute              | Type   | Description                          | Example                    |
|:-----------------------|:-------|:-------------------------------------|:---------------------------|
| `target.node`          | String | Target node name (RFC-0001)          | `web-01`                   |
| `target.group`         | String | Target group name (RFC-0001)         | `servers`                  |
| `target.network`       | String | Target network (RFC-0001)            | `internal`                 |
| `target.address`       | String | Target IP or hostname                | `10.0.1.10`                |
| `target.port`          | Integer| Target port                          | `443`                      |
| `target.service`       | String | Target service                       | `https`                    |

### Outcome Attributes

Describe results and effects.

| Attribute              | Type    | Description                          | Example                    |
|:-----------------------|:--------|:-------------------------------------|:---------------------------|
| `outcome.type`         | String  | Outcome category                     | `discovery`, `change`, `error` |
| `outcome.description`  | String  | Human-readable outcome               | `Found 3 open ports`       |
| `outcome.artifact`     | String  | Path to produced artifact            | `/output/scan.json`        |
| `outcome.objective`    | String  | Objective achieved (if any)          | `environment-mapped`       |

### Timing Attributes

| Attribute              | Type    | Description                          | Example                    |
|:-----------------------|:--------|:-------------------------------------|:---------------------------|
| `timestamp`            | String  | ISO 8601 timestamp                   | `2024-01-15T10:30:00Z`     |
| `elapsed_ms`           | Integer | Time since experiment start          | `360000`                   |
| `phase_elapsed_ms`     | Integer | Time since phase start               | `120000`                   |

---

## Taxonomy

The taxonomy defines categories and classes for events. This provides
consistent structure for different event types.

### Event Categories

Top-level groupings for events.

| Category       | Description                                    |
|:---------------|:-----------------------------------------------|
| `agent`        | Agent lifecycle and behavior events            |
| `action`       | Agent action execution events                  |
| `observation`  | Agent observation events                       |
| `environment`  | Environment state change events                |
| `objective`    | Objective evaluation events                    |
| `system`       | System/infrastructure events                   |

### Event Classes

Specific event types within categories.

#### Agent Events (`agent.*`)

| Class                  | Description                              |
|:-----------------------|:-----------------------------------------|
| `agent.spawned`        | Agent instance started                   |
| `agent.terminated`     | Agent instance stopped                   |
| `agent.iteration`      | Agent completed one reasoning cycle      |
| `agent.error`          | Agent encountered an error               |
| `agent.communication`  | Agent sent/received inter-agent message  |

#### Action Events (`action.*`)

| Class                  | Description                              |
|:-----------------------|:-----------------------------------------|
| `action.started`       | Action execution began                   |
| `action.completed`     | Action execution finished                |
| `action.failed`        | Action execution failed                  |
| `action.timeout`       | Action exceeded time limit               |

#### Observation Events (`observation.*`)

| Class                  | Description                              |
|:-----------------------|:-----------------------------------------|
| `observation.received` | Agent received observation data          |
| `observation.processed`| Agent processed observation              |
| `observation.insight`  | Agent derived insight from observation   |

#### Environment Events (`environment.*`)

| Class                  | Description                              |
|:-----------------------|:-----------------------------------------|
| `environment.state_change` | Environment state modified           |
| `environment.node_event`   | Event from environment node          |
| `environment.network_event`| Network-level event                  |
| `environment.inject`       | Inject executed                      |

#### Objective Events (`objective.*`)

| Class                  | Description                              |
|:-----------------------|:-----------------------------------------|
| `objective.achieved`   | Objective condition met                  |
| `objective.failed`     | Objective failed (penalty condition)     |
| `objective.progress`   | Progress toward objective                |
| `objective.evaluated`  | Objective condition evaluated            |

#### System Events (`system.*`)

| Class                  | Description                              |
|:-----------------------|:-----------------------------------------|
| `system.phase_started` | Experiment phase began                   |
| `system.phase_ended`   | Experiment phase completed               |
| `system.checkpoint`    | Checkpoint created                       |
| `system.error`         | System-level error                       |

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

| Attribute              | Required | Description                          |
|:-----------------------|:---------|:-------------------------------------|
| `experiment.name`      | Yes      | Experiment identifier                |
| `agent.name`           | Yes      | Agent that created the span          |
| `experiment.phase`     | Yes      | Current phase                        |

Action spans SHOULD also include:

| Attribute              | Required | Description                          |
|:-----------------------|:---------|:-------------------------------------|
| `action.name`          | Yes      | Action identifier                    |
| `action.type`          | Yes      | Action category                      |
| `action.status`        | Yes      | Outcome status                       |
| `target.*`             | No       | Target attributes if applicable      |

### Span Relationships

| Relationship   | Description                                    |
|:---------------|:-----------------------------------------------|
| `child_of`     | Span is a child of parent span                 |
| `follows_from` | Span is causally related but not a child       |
| `links`        | Span references related spans                  |

---

## Correlation

Correlation patterns link related telemetry across agents, actions, and
environment events.

### Correlation Identifiers

| Identifier             | Scope                    | Description                          |
|:-----------------------|:-------------------------|:-------------------------------------|
| `trace_id`             | Trace                    | Links all spans in a trace           |
| `span_id`              | Span                     | Unique span identifier               |
| `parent_span_id`       | Span                     | Parent span for hierarchy            |
| `experiment_id`        | Experiment               | Links all telemetry in experiment    |
| `correlation_id`       | Causal chain             | Links causally-related events        |
| `action_id`            | Action                   | Links action to its effects          |

### Correlation Patterns

#### Agent Action → Environment Effect

Link an agent action to the environment change it caused.

```text
┌─────────────────┐     correlation_id      ┌─────────────────┐
│  action.shell   │ ────────────────────────▶│ environment.    │
│    .execute     │                          │  state_change   │
└─────────────────┘                          └─────────────────┘
     agent.name: explorer                         target.node: web-01
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
     agent.name: explorer                         source: syslog
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
     agent.name: explorer                         agent.name: analyzer
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
    agent.name: explorer
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
    agent.name: explorer
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

### Security Attributes

#### MITRE ATT&CK Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `mitre.tactic`             | String | ATT&CK tactic                    | `credential-access`  |
| `mitre.tactic.id`          | String | Tactic ID                        | `TA0006`             |
| `mitre.technique.id`       | String | Technique ID                     | `T1003.006`          |
| `mitre.technique.name`     | String | Technique name                   | `DCSync`             |
| `mitre.subtechnique.id`    | String | Sub-technique ID                 | `T1003.006`          |

#### Team Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `security.team`            | String | Team assignment                  | `red`, `blue`        |
| `security.operation`       | String | Operation name                   | `credential-harvest` |
| `security.campaign`        | String | Campaign identifier              | `campaign-001`       |

#### Attack Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `attack.phase`             | String | Kill chain phase                 | `lateral-movement`   |
| `attack.vector`            | String | Attack vector                    | `phishing`, `exploit`|
| `attack.target.type`       | String | Target type                      | `credential`, `host` |

#### Defense Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `detection.rule`           | String | Detection rule that fired        | `dcsync_detected`    |
| `detection.severity`       | String | Alert severity                   | `critical`, `high`   |
| `detection.confidence`     | Float  | Detection confidence             | `0.95`               |
| `response.action`          | String | Response action taken            | `isolate`, `alert`   |

#### Credential Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `credential.type`          | String | Credential type                  | `ntlm`, `kerberos`   |
| `credential.username`      | String | Username                         | `admin`              |
| `credential.domain`        | String | Domain                           | `corp.local`         |
| `credential.source`        | String | How credential was obtained      | `lsass`, `dcsync`    |

#### Active Directory Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `ad.domain`                | String | AD domain                        | `corp.local`         |
| `ad.forest`                | String | AD forest                        | `corp.local`         |
| `ad.object.type`           | String | AD object type                   | `user`, `computer`   |
| `ad.object.dn`             | String | Distinguished name               | `CN=Admin,DC=corp`   |
| `ad.object.sid`            | String | Security identifier              | `S-1-5-21-...`       |

### Security Event Classes

#### Attack Events (`security.attack.*`)

| Class                          | Description                          |
|:-------------------------------|:-------------------------------------|
| `security.attack.reconnaissance`| Reconnaissance activity              |
| `security.attack.initial_access`| Initial access attempt               |
| `security.attack.execution`    | Code/command execution               |
| `security.attack.persistence`  | Persistence mechanism                |
| `security.attack.privilege_escalation` | Privilege escalation attempt  |
| `security.attack.credential_access` | Credential access attempt       |
| `security.attack.lateral_movement` | Lateral movement attempt         |
| `security.attack.exfiltration` | Data exfiltration attempt            |

#### Defense Events (`security.defense.*`)

| Class                          | Description                          |
|:-------------------------------|:-------------------------------------|
| `security.defense.alert`       | Alert triggered                      |
| `security.defense.detection`   | Detection rule matched               |
| `security.defense.response`    | Response action taken                |
| `security.defense.containment` | Containment action                   |
| `security.defense.investigation`| Investigation activity              |

### Security Correlation Patterns

#### Attack Chain

```text
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ security.attack │────▶│ security.attack │────▶│ security.attack │
│ .reconnaissance │     │ .credential_    │     │ .lateral_       │
│                 │     │    access       │     │    movement     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
  mitre.tactic:           mitre.tactic:           mitre.tactic:
    discovery               credential-access       lateral-movement
```

All spans share `security.campaign` and `trace_id`.

#### Attack → Detection

```text
┌─────────────────┐     correlation_id      ┌─────────────────┐
│ security.attack │ ────────────────────────▶│ security.       │
│ .credential_    │                          │   defense.alert │
│    access       │                          │                 │
└─────────────────┘                          └─────────────────┘
  agent.name: red-agent                        detection.rule: dcsync
  mitre.technique.id: T1003.006                detection.severity: critical
```

### Security Extension Example

```yaml
# Red team action span
span:
  name: action.tool.impacket
  attributes:
    # Core attributes
    agent.name: credential-agent
    action.name: secretsdump
    action.type: tool
    target.node: dc01

    # Security extension attributes
    security.team: red
    mitre.tactic: credential-access
    mitre.technique.id: T1003.006
    mitre.technique.name: DCSync
    attack.phase: credential-harvesting
    ad.domain: corp.local

# Blue team detection
event:
  class: security.defense.alert
  attributes:
    detection.rule: dcsync_detected
    detection.severity: critical
    detection.confidence: 0.98
    correlation_id: corr-123  # Links to attack

    # MITRE mapping
    mitre.technique.id: T1003.006
```

---

## Software Engineering Extension

The software engineering extension adds attributes and events for
code-related experiments.

### Software Engineering Attributes

#### Repository Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `repo.name`                | String | Repository name                  | `my-project`         |
| `repo.url`                 | String | Repository URL                   | `github.com/org/repo`|
| `repo.branch`              | String | Current branch                   | `feature/new-api`    |
| `repo.commit`              | String | Current commit SHA               | `a1b2c3d4`           |

#### Code Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `code.file`                | String | File path                        | `src/main.py`        |
| `code.function`            | String | Function name                    | `process_data`       |
| `code.line`                | Integer| Line number                      | `42`                 |
| `code.language`            | String | Programming language             | `python`             |

#### Change Attributes

| Attribute                  | Type    | Description                      | Example              |
|:---------------------------|:--------|:---------------------------------|:---------------------|
| `change.type`              | String  | Type of change                   | `add`, `modify`, `delete` |
| `change.files_count`       | Integer | Number of files changed          | `5`                  |
| `change.lines_added`       | Integer | Lines added                      | `120`                |
| `change.lines_removed`     | Integer | Lines removed                    | `45`                 |

#### Quality Attributes

| Attribute                  | Type    | Description                      | Example              |
|:---------------------------|:--------|:---------------------------------|:---------------------|
| `quality.test_coverage`    | Float   | Test coverage percentage         | `85.5`               |
| `quality.lint_errors`      | Integer | Linting errors                   | `0`                  |
| `quality.type_errors`      | Integer | Type checking errors             | `2`                  |
| `quality.security_issues`  | Integer | Security scan issues             | `0`                  |

#### CI/CD Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `ci.pipeline`              | String | Pipeline name                    | `build-and-test`     |
| `ci.job`                   | String | Job name                         | `unit-tests`         |
| `ci.status`                | String | Pipeline/job status              | `success`, `failed`  |
| `ci.duration_ms`           | Integer| Duration in milliseconds         | `45000`              |

### Software Engineering Event Classes

#### Development Events (`swe.dev.*`)

| Class                          | Description                          |
|:-------------------------------|:-------------------------------------|
| `swe.dev.file_created`         | New file created                     |
| `swe.dev.file_modified`        | File modified                        |
| `swe.dev.file_deleted`         | File deleted                         |
| `swe.dev.function_added`       | New function added                   |
| `swe.dev.refactor`             | Code refactored                      |

#### Testing Events (`swe.test.*`)

| Class                          | Description                          |
|:-------------------------------|:-------------------------------------|
| `swe.test.suite_started`       | Test suite started                   |
| `swe.test.suite_completed`     | Test suite completed                 |
| `swe.test.passed`              | Individual test passed               |
| `swe.test.failed`              | Individual test failed               |
| `swe.test.coverage_report`     | Coverage report generated            |

#### Review Events (`swe.review.*`)

| Class                          | Description                          |
|:-------------------------------|:-------------------------------------|
| `swe.review.requested`         | Review requested                     |
| `swe.review.comment`           | Review comment added                 |
| `swe.review.approved`          | Review approved                      |
| `swe.review.changes_requested` | Changes requested                    |

#### CI/CD Events (`swe.ci.*`)

| Class                          | Description                          |
|:-------------------------------|:-------------------------------------|
| `swe.ci.pipeline_started`      | Pipeline started                     |
| `swe.ci.pipeline_completed`    | Pipeline completed                   |
| `swe.ci.job_started`           | Job started                          |
| `swe.ci.job_completed`         | Job completed                        |
| `swe.ci.artifact_published`    | Artifact published                   |

---

## Format Compatibility

This schema is designed to be compatible with industry standard formats.

### OpenTelemetry

Attributes map directly to OpenTelemetry semantic conventions where
applicable. Use the `otel.*` prefix for OTel-specific attributes.

| ACES Attribute      | OTel Equivalent                |
|:--------------------|:-------------------------------|
| `agent.name`        | `service.name`                 |
| `action.duration_ms`| `duration` (span field)        |
| `target.address`    | `net.peer.name`                |
| `target.port`       | `net.peer.port`                |

### OCSF

Security extension events can be mapped to OCSF classes.

| ACES Event Class                  | OCSF Category / Class          |
|:----------------------------------|:-------------------------------|
| `security.attack.credential_access` | Identity Activity / Authentication |
| `security.defense.alert`          | Security Finding / Detection Finding |
| `environment.network_event`       | Network Activity               |

### ECS (Elastic Common Schema)

Attributes can be mapped to ECS fields.

| ACES Attribute         | ECS Equivalent              |
|:-----------------------|:----------------------------|
| `agent.name`           | `agent.name`                |
| `target.address`       | `destination.ip`            |
| `target.port`          | `destination.port`          |
| `credential.username`  | `user.name`                 |

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
    agent.name: recon-agent
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

| Repository          | Changes Required                                    |
|:--------------------|:----------------------------------------------------|
| `aces-schema`       | JSON Schema for observability schema                |
| `aces-telemetry`    | Schema validation, format conversion                |
| `aces-agent-sdk`    | Span/event emission with schema compliance          |
| `aces-evaluation`   | Schema-aware objective evaluation                   |
| `aces-dashboards`   | Pre-built dashboards using schema attributes        |

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

| Document                                | Relationship                           |
|:----------------------------------------|:---------------------------------------|
| RFC-0001: Environment Infrastructure    | Defines telemetry backends and sinks   |
| RFC-0002: Experiment Specification      | References schema for observations     |
| OpenTelemetry Semantic Conventions      | Attribute naming alignment             |
| OCSF Schema                             | Security event structure alignment     |
