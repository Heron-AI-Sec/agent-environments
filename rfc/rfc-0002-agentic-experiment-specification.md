# RFC-0002: Agentic Experiment Specification

## Status

`Draft`

## Summary

This RFC proposes a declarative YAML specification for defining autonomous agent
experiments. Experiments execute against infrastructure defined by RFC-0001,
which provides the environment (topology, telemetry, agent platform). This
specification defines what agents exist, what they can observe and do, and how
success is measured.

RFC-0001 defines "what exists." This specification defines "what happens."

## Motivation

A standardized experiment specification enables:

1. **Reproducibility**: Experiments can be shared, versioned, and re-run
2. **Composability**: Agents from different sources can be combined
3. **Evaluation**: Consistent objective and scoring structures
4. **Tooling**: Common runtimes, dashboards, and analysis tools

### Design Principles

1. **Environment Independence**: Experiments reference environments, don't embed them
2. **Agent-Centric**: Primary focus on agent behavior and coordination
3. **Observable**: Agent actions produce telemetry via RFC-0001 infrastructure
4. **Measurable**: Experiments define concrete success criteria

---

## Schema Overview

| Section       | Purpose                                            |
| :------------ | :------------------------------------------------- |
| `environment` | Reference to RFC-0001 infrastructure               |
| `agents`      | Autonomous entities that interact with environment |
| `objectives`  | Success criteria and scoring                       |
| `injects`     | Scripted events injected during execution          |
| `runtime`     | Execution configuration: phases, throttling, state |

---

## Root Schema

| Field         | Type   | Required | Description                            | Example                        |
| :------------ | :----- | :------- | :------------------------------------- | :----------------------------- |
| `apiVersion`  | String | Yes      | Schema version.                        | `aces.io/v1alpha1`             |
| `kind`        | String | Yes      | Resource type.                         | `Experiment`                   |
| `metadata`    | Object | Yes      | Identifying information.               | `{name, description, version}` |
| `environment` | Object | Yes      | Reference to RFC-0001 environment.     | `{ref: {name: ...}}`           |
| `agents`      | Object | Yes      | Agent definitions (map keyed by name). | `{agent-1: {...}}`             |
| `objectives`  | Object | No       | Success criteria (map keyed by name).  | `{goal-1: {...}}`              |
| `injects`     | Object | No       | Scripted events (map keyed by name).   | `{event-1: {...}}`             |
| `runtime`     | Object | No       | Execution configuration.               | `{timeout: 4h, phases: {}}`    |

### Example

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Experiment
metadata:
  name: example-experiment
  description: "Example agentic experiment"
  version: "1.0.0"
  labels:
    domain: security

environment:
  ref:
    name: my-range
    version: "1.0.0"

agents:
  agent-1:
    type: llm
    goal: "Accomplish the task."
    # ...

objectives:
  success:
    condition: { ... }
    reward: 100.0

runtime:
  timeout: 2h
```

---

## Environment

References an RFC-0001 environment that the experiment executes against.

| Property | Type   | Required | Description                        | Example                     |
| :------- | :----- | :------- | :--------------------------------- | :-------------------------- |
| `ref`    | Object | Yes      | Reference to environment instance. | `{name: ..., version: ...}` |
| `source` | String | No       | Path or URL to environment spec.   | `./environments/range.yaml` |

### Environment Reference

| Property  | Type   | Required | Description                       | Example          |
| :-------- | :----- | :------- | :-------------------------------- | :--------------- |
| `name`    | String | Yes      | Environment name (from metadata). | `ad-range`       |
| `version` | String | No       | Version constraint.               | `1.0.0`, `>=1.0` |

### Integration with RFC-0001

The experiment uses the following from the referenced environment:

| RFC-0001 Section    | Experiment Usage                     |
| :------------------ | :----------------------------------- |
| `topology.nodes`    | Agent starting positions and targets |
| `topology.networks` | Network context for agent actions    |
| `groups`            | Bulk targeting via group references  |
| `agent_platform`    | Where agents execute                 |
| `telemetry`         | Observation sources for agents       |
| `connectivity`      | Agent-to-target network paths        |

### Example

```yaml
environment:
  ref:
    name: ad-attack-range
    version: "1.0.0"
  source: ./environments/ad-range.yaml
```

---

## Agents

Agents are autonomous entities that interact with the environment to achieve
goals. They execute on the `agent_platform` defined in RFC-0001.

Agents are defined as a map keyed by name (the unique identifier).

| Property        | Type   | Required | Description                         | Example                                    |
| :-------------- | :----- | :------- | :---------------------------------- | :----------------------------------------- |
| `display_name`  | String | No       | Human-readable label.               | `Research Agent`                           |
| `type`          | String | Yes      | Agent paradigm.                     | `llm`, `rl`, `scripted`, `hybrid`, `human` |
| `goal`          | String | Yes      | Natural language objective.         | `Analyze and report findings`              |
| `model`         | Object | No       | LLM configuration (for llm/hybrid). | See Model                                  |
| `observation`   | Object | No       | What the agent can perceive.        | See Observation                            |
| `actions`       | Object | No       | What the agent can do.              | See Actions                                |
| `context`       | Object | No       | Starting position and targets.      | See Context                                |
| `resources`     | Object | No       | Compute requirements.               | See Resources                              |
| `depends_on`    | Array  | No       | Agents that must complete first.    | `[setup-agent]`                            |
| `communication` | Object | No       | Inter-agent communication.          | See Communication                          |
| `lifecycle`     | Object | No       | Spawn/termination conditions.       | See Lifecycle                              |
| `labels`        | Object | No       | Arbitrary key-value labels.         | `{team: red, role: recon}`                 |

### Agent Types

| Type       | Description                                       |
| :--------- | :------------------------------------------------ |
| `llm`      | LLM-driven agent with tool use                    |
| `rl`       | Reinforcement learning agent with trained policy  |
| `scripted` | Deterministic playbook execution                  |
| `hybrid`   | Combination (e.g., LLM reasoning + RL components) |
| `human`    | Human-in-the-loop participant                     |

### Model

LLM configuration for `llm` and `hybrid` agents.

| Property      | Type    | Required | Description              | Example                    |
| :------------ | :------ | :------- | :----------------------- | :------------------------- |
| `provider`    | String  | No       | Model provider.          | `anthropic`, `openai`      |
| `name`        | String  | No       | Model identifier.        | `claude-sonnet-4-20250514` |
| `temperature` | Float   | No       | Sampling temperature.    | `0.7`                      |
| `max_tokens`  | Integer | No       | Maximum response tokens. | `4096`                     |

### Observation

What the agent can perceive. Sources reference RFC-0001 telemetry or local
agent feedback. Event formats and attributes follow RFC-0003 schema conventions.

| Property  | Type   | Required | Description                      | Example                    |
| :-------- | :----- | :------- | :------------------------------- | :------------------------- |
| `sources` | Array  | No       | Data sources available to agent. | See Source Types           |
| `schema`  | Object | No       | RFC-0003 schema reference.       | `{extensions: [security]}` |

#### Source Types

| Type        | Description               | Properties                      |
| :---------- | :------------------------ | :------------------------------ |
| `telemetry` | RFC-0001 telemetry stream | `ref`, `filter`                 |
| `local`     | Agent-local feedback      | `channels` (stdout, stderr, fs) |
| `api`       | Query-based data access   | `endpoints`                     |

#### Source Object

| Property    | Type   | Required | Description                         | Example                     |
| :---------- | :----- | :------- | :---------------------------------- | :-------------------------- |
| `type`      | String | Yes      | Source type.                        | `telemetry`, `local`, `api` |
| `ref`       | String | No       | RFC-0001 reference (for telemetry). | `telemetry.sinks.loki`      |
| `filter`    | Object | No       | Filter criteria.                    | `{severity: critical}`      |
| `channels`  | Array  | No       | Local channels.                     | `[stdout, stderr]`          |
| `endpoints` | Array  | No       | API endpoints.                      | `[query_status, list]`      |

### Actions

What the agent can do.

| Property       | Type  | Required | Description             | Example              |
| :------------- | :---- | :------- | :---------------------- | :------------------- |
| `capabilities` | Array | No       | Available action types. | See Capability Types |

#### Capability Types

| Type       | Description                  | Properties          |
| :--------- | :--------------------------- | :------------------ |
| `shell`    | Shell command execution      | `allowed`, `denied` |
| `tool`     | Tool invocation              | `allowed`           |
| `api`      | API calls                    | `allowed`, `scopes` |
| `protocol` | Network protocol interaction | `allowed`           |

#### Capability Object

| Property  | Type   | Required | Description        | Example                  |
| :-------- | :----- | :------- | :----------------- | :----------------------- |
| `type`    | String | Yes      | Capability type.   | `shell`, `tool`, `api`   |
| `allowed` | Array  | No       | Allowed values.    | `[bash]`, `[nmap, curl]` |
| `denied`  | Array  | No       | Denied values.     | `[rm -rf /]`             |
| `scopes`  | Array  | No       | Permission scopes. | `[read, write]`          |

### Context

Where the agent operates within the RFC-0001 environment.

| Property  | Type   | Required | Description                           | Example                  |
| :-------- | :----- | :------- | :------------------------------------ | :----------------------- |
| `node`    | String | No       | Starting node (refs topology.nodes).  | `workstation-01`         |
| `targets` | Array  | No       | Target nodes (refs topology.nodes).   | `[server-01, server-02]` |
| `groups`  | Array  | No       | Target groups (refs RFC-0001 groups). | `[servers]`              |

### State

The current state of the agent within the RFC-0001 environment.

| Property          | Type   | Required | Description                                     | Example                      |
| :---------------- | :----- | :------- | :---------------------------------------------- | :--------------------------- |
| `node`            | String | No       | Current node (refs topology.nodes).             | `workstation-01`             |
| `active_networks` | Array  | Yes      | The logical networks the agent can access.      | `[range-vpc, domain-subnet]` |
| `node_state`      | Object | Yes      | Ephemeral state at the exact time of execution. | See NodeState Object         |

### NodeState Object

This object captures the localized, ephemeral operating system context.

| Field      | Type    | Required | Description                    | Example                                |
| :--------- | :------ | :------- | :----------------------------- | :------------------------------------- |
| `user`     | String  | Yes      | The active system user.        | `root`                                 |
| `is_root`  | Boolean | Yes      | Flag for root privileges.      | `true`                                 |
| `cwd`      | String  | Yes      | The Current Working Directory. | `/etc/cron.d`                          |
| `env_vars` | Object  | No       | Key environment variables.     | `{"PATH": "/usr/local/sbin:/usr/bin"}` |

### Resources

Compute resources for agent execution on RFC-0001 `agent_platform`.

| Property  | Type    | Required | Description                               | Example     |
| :-------- | :------ | :------- | :---------------------------------------- | :---------- |
| `cpu`     | String  | No       | CPU allocation.                           | `500m`, `2` |
| `memory`  | String  | No       | Memory allocation.                        | `512Mi`     |
| `gpu`     | Integer | No       | GPU count.                                | `1`         |
| `profile` | String  | No       | Reference to RFC-0001 resources.profiles. | `gpu-large` |

### Communication

Inter-agent communication. Uses RFC-0001 `agent_platform.orchestrator` and
`agent_platform.storage`.

| Property      | Type   | Required | Description             | Example                                      |
| :------------ | :----- | :------- | :---------------------- | :------------------------------------------- |
| `pattern`     | String | No       | Communication pattern.  | `streaming`, `batch`, `direct`, `blackboard` |
| `channels`    | Array  | No       | Named pub/sub channels. | `[findings, requests]`                       |
| `rpc_service` | String | No       | RPC service name.       | `coordinator`                                |

### Lifecycle

Agent spawn and termination conditions.

| Property         | Type    | Required | Description                      | Example               |
| :--------------- | :------ | :------- | :------------------------------- | :-------------------- |
| `max_iterations` | Integer | No       | Maximum action iterations.       | `1000`                |
| `timeout`        | String  | No       | Maximum runtime.                 | `1h`                  |
| `terminate_on`   | String  | No       | Objective that terminates agent. | `goal-reached`        |
| `restart_policy` | String  | No       | Behavior on failure.             | `never`, `on_failure` |

### Agents Example

```yaml
agents:
  explorer:
    display_name: "Explorer Agent"
    type: llm
    goal: "Map the environment and identify interesting targets."
    labels:
      team: red
      phase: recon
    model:
      provider: anthropic
      name: claude-sonnet-4-20250514
    observation:
      sources:
        - type: local
          channels: [stdout, stderr]
    actions:
      capabilities:
        - type: shell
          allowed: [bash]
        - type: tool
          allowed: [nmap, curl]
    context:
      node: attacker-01
      groups: [servers]
    resources:
      cpu: "500m"
      memory: "1Gi"
    lifecycle:
      timeout: 30m

  analyzer:
    display_name: "Analyzer Agent"
    type: llm
    goal: "Analyze collected data and identify patterns."
    depends_on: [explorer]
    observation:
      sources:
        - type: telemetry
          ref: telemetry.sinks.loki
          filter:
            severity: [high, critical]
        - type: local
          channels: [stdout]
    actions:
      capabilities:
        - type: api
          allowed: [query_logs, create_report]
          scopes: [read]
    resources:
      cpu: "1"
      memory: "2Gi"
    communication:
      pattern: direct
      rpc_service: coordinator
```

---

## Objectives

Objectives define success criteria with associated scoring. They are evaluated
against agent actions and environment state.

Objectives are defined as a map keyed by name (the unique identifier).

| Property       | Type   | Required | Description                 | Example                             |
| :------------- | :----- | :------- | :-------------------------- | :---------------------------------- |
| `display_name` | String | No       | Human-readable label.       | `Goal Achieved`                     |
| `description`  | String | No       | Detailed description.       | `Successfully completed...`         |
| `condition`    | Object | Yes      | Trigger condition.          | See Conditions                      |
| `reward`       | Float  | No       | Score when achieved.        | `100.0`                             |
| `penalty`      | Float  | No       | Score deduction.            | `-50.0`                             |
| `time_bonus`   | Object | No       | Bonus for fast completion.  | `{within: 1h, bonus: 25.0}`         |
| `labels`       | Object | No       | Arbitrary key-value labels. | `{team: blue, category: detection}` |

### Conditions

Conditions define when an objective is achieved.

| Property | Type    | Required | Description           | Example             |
| :------- | :------ | :------- | :-------------------- | :------------------ |
| `type`   | String  | Yes      | Condition type.       | See Condition Types |
| `negate` | Boolean | No       | Invert the condition. | `true`              |
| ...      | ...     | ...      | Type-specific fields. | See below           |

#### Condition Types

| Type           | Description                          | Fields                      |
| :------------- | :----------------------------------- | :-------------------------- |
| `state`        | Environment state matches expression | `expr`                      |
| `event`        | Specific event occurred              | `event_type`, `filter`      |
| `metric`       | Metric crosses threshold             | `name`, `operator`, `value` |
| `artifact`     | File/artifact exists                 | `path`                      |
| `agent_status` | Agent reached status                 | `agent`, `status`           |
| `elapsed`      | Time elapsed                         | `duration`                  |
| `custom`       | Custom evaluator                     | `evaluator`, `params`       |

#### Condition Examples

```yaml
# State condition
condition:
  type: state
  expr: "nodes.server-01.compromised == true"

# Event condition
condition:
  type: event
  event_type: alert.created
  filter:
    severity: critical

# Metric condition
condition:
  type: metric
  name: success_rate
  operator: gte
  value: 0.95

# Artifact condition
condition:
  type: artifact
  path: /output/results.json
```

#### Compound Conditions

Use `all` (AND) or `any` (OR) for compound logic:

```yaml
condition:
  all:
    - type: state
      expr: "task.completed == true"
    - type: metric
      name: accuracy
      operator: gte
      value: 0.9

condition:
  any:
    - type: event
      event_type: goal_a
    - type: event
      event_type: goal_b
```

### Objectives Example

```yaml
objectives:
  task-complete:
    display_name: "Task Completed"
    description: "Agent successfully completed the assigned task."
    condition:
      type: state
      expr: "task.status == 'completed'"
    reward: 100.0
    time_bonus:
      within: 1h
      bonus: 25.0

  high-quality:
    display_name: "High Quality Result"
    condition:
      all:
        - type: artifact
          path: /output/results.json
        - type: metric
          name: quality_score
          operator: gte
          value: 0.9
    reward: 50.0

  failure-penalty:
    display_name: "Critical Failure"
    condition:
      type: event
      event_type: critical_error
    penalty: -100.0
```

---

## Injects

Injects are scripted events injected during experiment execution. They provide
stimuli, simulate external events, or set up specific conditions.

Injects are defined as a map keyed by name (the unique identifier).

| Property       | Type   | Required | Description            | Example                |
| :------------- | :----- | :------- | :--------------------- | :--------------------- |
| `display_name` | String | No       | Human-readable label.  | `External Trigger`     |
| `description`  | String | No       | Detailed description.  | `Simulates...`         |
| `type`         | String | Yes      | Inject type.           | See Inject Types       |
| `target`       | String | No       | Target node or agent.  | `server-01`, `agent-1` |
| `payload`      | Object | Yes      | Type-specific payload. | See below              |
| `timing`       | Object | No       | When to execute.       | See Timing             |

### Inject Types

| Type       | Description               | Payload Fields       |
| :--------- | :------------------------ | :------------------- |
| `event`    | Emit event to telemetry   | `event_type`, `data` |
| `state`    | Modify environment state  | `target`, `mutation` |
| `message`  | Send message to agent     | `content`, `channel` |
| `artifact` | Place file in environment | `path`, `content`    |
| `delay`    | Pause execution           | `duration`           |

### Timing

| Property | Type   | Required | Description                    | Example       |
| :------- | :----- | :------- | :----------------------------- | :------------ |
| `phase`  | String | No       | Phase to execute during.       | `exploration` |
| `delay`  | String | No       | Delay after trigger.           | `30s`         |
| `at`     | String | No       | Absolute time into experiment. | `10m`         |
| `after`  | String | No       | Execute after another inject.  | `inject-1`    |

### Injects Example

```yaml
injects:
  trigger-event:
    display_name: "External Trigger"
    type: event
    payload:
      event_type: external_update
      data:
        message: "New data available"
    timing:
      phase: execution
      delay: 5m

  setup-artifact:
    display_name: "Setup Test Data"
    type: artifact
    target: server-01
    payload:
      path: /data/input.json
      content: '{"test": true}'
    timing:
      phase: setup

  notify-agent:
    display_name: "Notify Analyzer"
    type: message
    target: analyzer
    payload:
      content: "Begin analysis"
      channel: commands
    timing:
      after: trigger-event
```

---

## Runtime

Runtime configuration controls experiment execution.

| Property      | Type   | Required | Description                  | Example         |
| :------------ | :----- | :------- | :--------------------------- | :-------------- |
| `timeout`     | String | No       | Maximum experiment duration. | `4h`            |
| `phases`      | Object | No       | Sequential execution phases. | See Phases      |
| `throttling`  | Object | No       | Rate limiting.               | See Throttling  |
| `checkpoints` | Object | No       | State persistence.           | See Checkpoints |
| `scoring`     | Object | No       | Scoring configuration.       | See Scoring     |

### Phases

Phases define sequential stages of the experiment.

Phases are defined as a map keyed by name (the unique identifier).

| Property       | Type   | Required | Description                        | Example             |
| :------------- | :----- | :------- | :--------------------------------- | :------------------ |
| `display_name` | String | No       | Human-readable label.              | `Setup Phase`       |
| `duration`     | String | No       | Maximum phase duration.            | `30m`               |
| `depends_on`   | Array  | No       | Phases that must complete first.   | `[setup]`           |
| `start_agents` | Array  | No       | Agents to start.                   | `[explorer]`        |
| `stop_agents`  | Array  | No       | Agents to stop.                    | `[setup-agent]`     |
| `wait_for`     | String | No       | Objective to wait for.             | `milestone-reached` |
| `on_enter`     | Array  | No       | Injects to trigger on phase start. | `[setup-inject]`    |
| `on_exit`      | Array  | No       | Injects to trigger on phase end.   | `[cleanup]`         |

### Throttling

| Property                | Type    | Required | Description                   | Example |
| :---------------------- | :------ | :------- | :---------------------------- | :------ |
| `max_concurrent_agents` | Integer | No       | Maximum parallel agents.      | `10`    |
| `llm_calls_per_minute`  | Integer | No       | LLM API rate limit per agent. | `30`    |
| `actions_per_minute`    | Integer | No       | Agent actions per minute.     | `60`    |

### Checkpoints

| Property       | Type    | Required | Description                      | Example |
| :------------- | :------ | :------- | :------------------------------- | :------ |
| `enabled`      | Boolean | No       | Enable checkpointing.            | `true`  |
| `interval`     | String  | No       | Automatic checkpoint interval.   | `15m`   |
| `on_phase_end` | Boolean | No       | Checkpoint at phase transitions. | `true`  |
| `retention`    | Integer | No       | Checkpoints to retain.           | `5`     |

### Scoring

| Property     | Type    | Required | Description                | Example   |
| :----------- | :------ | :------- | :------------------------- | :-------- |
| `mode`       | String  | No       | Scoring mode.              | See Modes |
| `time_limit` | String  | No       | Scoring time window.       | `2h`      |
| `normalize`  | Boolean | No       | Normalize scores to 0-100. | `false`   |

#### Scoring Modes

| Mode            | Description                        |
| :-------------- | :--------------------------------- |
| `cumulative`    | Sum all achieved objective rewards |
| `time_weighted` | Rewards decrease over time         |
| `competitive`   | Multi-team zero-sum scoring        |
| `threshold`     | Pass/fail based on minimum score   |

### Runtime Example

```yaml
runtime:
  timeout: 4h

  throttling:
    max_concurrent_agents: 10
    llm_calls_per_minute: 30

  checkpoints:
    enabled: true
    interval: 15m
    on_phase_end: true

  scoring:
    mode: cumulative

  phases:
    setup:
      display_name: "Setup"
      duration: 60s
      on_enter: [setup-artifact]

    exploration:
      display_name: "Exploration"
      depends_on: [setup]
      duration: 30m
      start_agents: [explorer]
      wait_for: environment-mapped

    execution:
      display_name: "Execution"
      depends_on: [exploration]
      duration: 2h
      start_agents: [executor]
      stop_agents: [explorer]

    analysis:
      display_name: "Analysis"
      depends_on: [execution]
      duration: 30m
      start_agents: [analyzer]
```

---

## Complete Example

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Experiment
metadata:
  name: exploration-experiment
  description: "Agent explores environment and achieves objectives"
  version: "1.0.0"
  labels:
    domain: general

environment:
  ref:
    name: test-range
    version: "1.0.0"
  source: ./environments/test-range.yaml

agents:
  explorer:
    display_name: "Explorer Agent"
    type: llm
    goal: "Explore the environment and identify all server endpoints."
    model:
      provider: anthropic
      name: claude-sonnet-4-20250514
    observation:
      sources:
        - type: local
          channels: [stdout, stderr]
    actions:
      capabilities:
        - type: shell
          allowed: [bash]
        - type: tool
          allowed: [nmap, curl, dig]
    context:
      node: workstation-01
      groups: [servers]
    resources:
      cpu: "500m"
      memory: "1Gi"
    lifecycle:
      timeout: 30m
      max_iterations: 500

  analyzer:
    display_name: "Analyzer Agent"
    type: llm
    goal: "Analyze exploration results and create a comprehensive report."
    depends_on: [explorer]
    model:
      provider: anthropic
      name: claude-sonnet-4-20250514
    observation:
      sources:
        - type: telemetry
          ref: telemetry.sinks.loki
        - type: local
          channels: [stdout]
    actions:
      capabilities:
        - type: api
          allowed: [query_logs, write_report]
    resources:
      cpu: "1"
      memory: "2Gi"
    communication:
      pattern: streaming
      channels: [findings]

objectives:
  environment-mapped:
    display_name: "Environment Mapped"
    description: "All server endpoints discovered."
    condition:
      type: metric
      name: endpoints_discovered
      operator: gte
      value: 10
    reward: 50.0

  report-generated:
    display_name: "Report Generated"
    condition:
      type: artifact
      path: /output/report.md
    reward: 50.0
    time_bonus:
      within: 1h
      bonus: 25.0

  complete:
    display_name: "Full Success"
    condition:
      all:
        - type: state
          expr: "objectives.environment-mapped.achieved"
        - type: state
          expr: "objectives.report-generated.achieved"
    reward: 100.0

injects:
  mid-experiment-event:
    display_name: "New Data Available"
    type: event
    payload:
      event_type: data_update
      data:
        source: external
        message: "Additional endpoints added"
    timing:
      phase: exploration
      delay: 15m

runtime:
  timeout: 2h

  throttling:
    max_concurrent_agents: 5
    llm_calls_per_minute: 30

  checkpoints:
    enabled: true
    on_phase_end: true

  scoring:
    mode: cumulative

  phases:
    setup:
      display_name: "Setup"
      duration: 30s

    exploration:
      display_name: "Exploration"
      depends_on: [setup]
      duration: 45m
      start_agents: [explorer]
      wait_for: environment-mapped

    analysis:
      display_name: "Analysis"
      depends_on: [exploration]
      duration: 30m
      start_agents: [analyzer]
      stop_agents: [explorer]
```

---

## Domain-Specific Usage

This specification is domain-agnostic. Domain-specific semantics are expressed
through:

1. **Labels**: Arbitrary key-value pairs on agents and objectives
2. **Custom condition types**: Domain evaluators via `type: custom`
3. **Naming conventions**: Meaningful names that reflect domain concepts

### Example: Security Domain

```yaml
agents:
  recon:
    labels:
      team: red
      mitre_tactic: discovery
      mitre_techniques: "T1087,T1069"
    # ...

objectives:
  credential-captured:
    labels:
      team: red
      mitre_technique: T1003
    condition:
      type: custom
      evaluator: security.credential_captured
      params:
        target: any
        identity: admin
```

### Example: Software Engineering Domain

```yaml
agents:
  developer:
    labels:
      role: developer
      languages: "python,typescript"
    # ...

objectives:
  tests-pass:
    labels:
      category: quality
    condition:
      type: custom
      evaluator: swe.tests_pass
      params:
        coverage_min: 80
```

---

## Alternatives Considered

### Embedded Domain Semantics

Rejected because:

- Forces domain concepts on unrelated experiments
- Harder to extend to new domains
- Labels + custom conditions provide equivalent expressiveness

### Separate Specs Per Domain

Rejected because:

- Duplicates core agent/objective/runtime concepts
- Harder to build shared tooling
- This spec can be extended, not forked

---

## Affected Repos

| Repository        | Changes Required                            |
| :---------------- | :------------------------------------------ |
| `aces-schema`     | JSON Schema for Experiment kind             |
| `aces-experiment` | Parse and validate experiments              |
| `aces-runtime`    | Execute experiments, manage agent lifecycle |
| `aces-evaluation` | Evaluate conditions, compute scores         |
| `aces-agent-sdk`  | Agent interfaces for observation/action     |

---

## Consequences

### What Becomes Easier

- **Cross-domain use**: Same spec for security, SWE, research, etc.
- **Tooling**: Single runtime, dashboard, analysis pipeline
- **Learning**: One spec to learn
- **Extension**: Labels and custom conditions, no schema changes

### What Becomes Harder

- **Domain validation**: Domain rules must be in evaluators, not schema
- **Discoverability**: Domain semantics less visible than explicit fields

---

## Cross-References

| Document                             | Relationship                              |
| :----------------------------------- | :---------------------------------------- |
| RFC-0001: Environment Infrastructure | Defines infrastructure experiments use    |
| RFC-0003: Observability Schema       | Defines telemetry attributes and taxonomy |
| RFC-0004: Agent SDK (future)         | Agent implementation interfaces           |
| RFC-0005: Evaluation System (future) | Condition evaluator specifications        |
