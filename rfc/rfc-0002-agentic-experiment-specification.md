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

## Type Definitions

Fields across this schema are categorized by stability tier, which determines how strictly they are validated and how extensions are handled.

| Tier              | Description                                                                                              | Validation       |
| :---------------- | :------------------------------------------------------------------------------------------------------- | :--------------- |
| `extensible-enum` | Closed list of known values. New values allowed via `x-` prefix convention (e.g. `x-my-custom-value`).   | Pattern-enforced |
| `growing`         | Open list. Known values are documented but new values are expected and accepted without the `x-` prefix. | Documented only  |

### Shared Types

| Type                   | Kind            | Values                                                                      |
| :--------------------- | :-------------- | :-------------------------------------------------------------------------- |
| `AgentType`            | growing         | `llm`, `rl`, `scripted`, `hybrid`, `human`                                  |
| `ScoringMode`          | extensible-enum | `cumulative`, `time_weighted`, `competitive`, `threshold`                   |
| `RestartPolicy`        | extensible-enum | `never`, `on_failure`                                                       |
| `CommunicationPattern` | extensible-enum | `streaming`, `batch`, `direct`, `blackboard`                                |
| `ConditionType`        | growing         | `state`, `event`, `metric`, `artifact`, `agent_status`, `elapsed`, `custom` |
| `InjectType`           | growing         | `event`, `state`, `message`, `artifact`, `delay`                            |
| `CapabilityType`       | growing         | `shell`, `tool`, `api`, `protocol`                                          |
| `SourceType`           | growing         | `telemetry`, `local`, `api`                                                 |
| `ModelProvider`        | growing         | `anthropic`, `openai`, `deepseek`, `xai`, `google`, `mistral`               |
| `TrustLevel`           | extensible-enum | `trusted`, `untrusted`, `sandboxed`                                         |
| `LogicalOperator`      | extensible-enum | `all`, `any`, `none`, `one`                                                 |

**`LogicalOperator` semantics:**

| Value  | Meaning | Evaluates to `true` when |
| :----- | :------ | :----------------------- |
| `all`  | Every condition must pass | All conditions in `conditions` are true |
| `any`  | At least one must pass | At least one condition in `conditions` is true |
| `none` | No condition must pass | Every condition in `conditions` is false |
| `one`  | Exactly one must pass | Exactly one condition in `conditions` is true |

---

## Schema Overview

| Section       | Purpose                                                               |
| :------------ | :-------------------------------------------------------------------- |
| `environment` | Reference to RFC-0001 infrastructure                                  |
| `agents`      | Autonomous entities that interact with environment and other entities |
| `objectives`  | Success criteria and scoring                                          |
| `injects`     | Scripted events injected during execution                             |
| `runtime`     | Execution configuration: phases, throttling, state                    |

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

| Property  | Type   | Required | Description                                         | Example          |
| :-------- | :----- | :------- | :-------------------------------------------------- | :--------------- |
| `name`    | String | Yes      | Environment name (unique identifier from metadata). | `ad-range`       |
| `version` | String | No       | Version constraint.                                 | `1.0.0`, `>=1.0` |
| `display_name` | String | No       | Human-readable label | `AD Attack Range` |


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

| Property        | Type      | Required | Description                         | Example                                   |
| :-------------- | :-------- | :------- | :---------------------------------- | :---------------------------------------- |
| `display_name`  | String    | No       | Human-readable label.               | `Research Agent`                          |
| `type`          | AgentType | Yes      | Agent paradigm.                     | see [Type Definitions](#type-definitions) |
| `goal`          | String    | Yes      | Natural language objective.         | `Analyze and report findings`             |
| `model`         | Object    | No       | LLM configuration (for llm/hybrid). | See Model                                 |
| `observation`   | Object    | No       | What the agent can perceive.        | See Observation                           |
| `actions`       | Object    | No       | What the agent can do.              | See Actions                               |
| `context`       | Object    | No       | Starting position and targets.      | See Context                               |
| `resources`     | Object    | No       | Compute requirements.               | See Resources                             |
| `depends_on`    | Array     | No       | Agents that must complete first.    | `[setup-agent.lifecycle.goal_reached]`    |
| `communication` | Object    | No       | Inter-agent communication.          | See Communication                         |
| `lifecycle`     | Object    | No       | Spawn/termination conditions.       | See Lifecycle                             |
| `trust_level`   | TrustLevel | No      | Trust level of the agent            | see [Type Definitions](#type-definitions) |
| `labels`        | Object    | No       | Arbitrary key-value labels.         | `{team: red, role: recon}`                |


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

| Property     | Type          | Required | Description                   | Example                                   |
| :----------- | :------------ | :------- | :---------------------------- | :---------------------------------------- |
| `provider`   | ModelProvider | No       | Model provider.               | see [Type Definitions](#type-definitions) |
| `name`       | String        | No       | Model identifier.             | `claude-sonnet-4-20250514`                |
| `parameters` | Object        | No       | Key-value store of parameters | `{temperature: 0.7, top-p: 0.95`          |
| `max_tokens` | Integer       | No       | Maximum response tokens.      | `4096`                                    |


### Observation

What the agent can perceive. Sources reference RFC-0001 telemetry or local
agent feedback. Event formats and attributes follow RFC-0003 schema conventions.

| Property  | Type   | Required | Description                      | Example                    |
| :-------- | :----- | :------- | :------------------------------- | :------------------------- |
| `sources` | Array\<Source\>  | No       | Data sources available to agent. | See Source Types           |
| `schema`  | Object | No       | RFC-0003 schema reference.       | `{extensions: [security]}` |


#### Source Types

| Type        | Description               | Properties                      |
| :---------- | :------------------------ | :------------------------------ |
| `telemetry` | RFC-0001 telemetry stream | `ref`, `filter`                 |
| `local`     | Agent-local feedback      | `channels` (stdout, stderr, fs) |
| `api`       | Query-based data access   | `endpoints`                     |

#### Source Object

| Property    | Type       | Required | Description                         | Example                                   |
| :---------- | :--------- | :------- | :---------------------------------- | :---------------------------------------- |
| `type`      | SourceType | Yes      | Source type.                        | see [Type Definitions](#type-definitions) |
| `ref`       | String     | No       | RFC-0001 reference (for telemetry). | `telemetry.sinks.loki`                    |
| `filter`    | Object     | No       | Filter criteria.                    | `{severity: critical}`                    |
| `channels`  | Array      | No       | Local channels.                     | `[stdout, stderr]`                        |
| `endpoints` | Array      | No       | API endpoints.                      | `[query_status, list]`                    |

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

| Property  | Type           | Required | Description        | Example                                   |
| :-------- | :------------- | :------- | :----------------- | :---------------------------------------- |
| `type`    | CapabilityType | Yes      | Capability type.   | see [Type Definitions](#type-definitions) |
| `allowed` | Array          | No       | Allowed values.    | `[bash]`, `[nmap, curl]`                  |
| `denied`  | Array          | No       | Denied values.     | `[rm -rf /]`                              |
| `scopes`  | Array          | No       | Permission scopes. | `[read, write]`                           |

### Context

Where the agent operates within the RFC-0001 environment.

| Property  | Type   | Required | Description                           | Example                  |
| :-------- | :----- | :------- | :------------------------------------ | :----------------------- |
| `node`    | String | No       | Starting node (refs topology.nodes).  | `workstation-01`         |
| `targets` | Array  | No       | Target nodes (refs topology.nodes).   | `[server-01, server-02]` |
| `groups`  | Array  | No       | Target groups (refs RFC-0001 groups). | `[servers]`              |

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

| Property      | Type                 | Required | Description             | Example                                   |
| :------------ | :------------------- | :------- | :---------------------- | :---------------------------------------- |
| `pattern`     | CommunicationPattern | No       | Communication pattern.  | see [Type Definitions](#type-definitions) |
| `channels`    | Array                | No       | Named pub/sub channels. | `[findings, requests]`                    |
| `rpc_service` | String               | No       | RPC service name.       | `coordinator`                             |

### Lifecycle

Agent spawn and termination conditions.

| Property         | Type          | Required | Description                      | Example                                   |
| :--------------- | :------------ | :------- | :------------------------------- | :---------------------------------------- |
| `max_iterations` | Integer       | No       | Maximum action iterations.       | `1000`                                    |
| `timeout`        | String        | No       | Maximum runtime.                 | `1h`                                      |
| `terminate_on`   | String        | No       | Objective that terminates agent. | `goal-reached`                            |
| `parameters`     | Object        | No       | Key-value store of parameters    | `{temperature: 0.7, top-p: 0.95`          |
| `restart_policy` | RestartPolicy | No       | Behavior on failure.             | see [Type Definitions](#type-definitions) |

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
      parameters:
        temperature: 0.7
        top_p: 0.95
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

| Property | Type          | Required | Description           | Example                                   |
| :------- | :------------ | :------- | :-------------------- | :---------------------------------------- |
| `type`   | ConditionType | Yes      | Condition type.       | see [Type Definitions](#type-definitions) |
| `negate` | Boolean       | No       | Invert the condition. | `true`                                    |
| ...      | ...           | ...      | Type-specific fields. | See below                                 |

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

Set `logical` to a `LogicalOperator` value to combine multiple conditions. See [Type Definitions](#type-definitions) for the full set and semantics.

```yaml
condition:
  logical: all
  conditions:
    - type: state
      expr: "task.completed == true"
    - type: metric
      name: accuracy
      operator: gte
      value: 0.9

condition:
  logical: any
  conditions:
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

| Property       | Type       | Required | Description            | Example                                   |
| :------------- | :--------- | :------- | :--------------------- | :---------------------------------------- |
| `display_name` | String     | No       | Human-readable label.  | `External Trigger`                        |
| `description`  | String     | No       | Detailed description.  | `Simulates...`                            |
| `type`         | InjectType | Yes      | Inject type.           | see [Type Definitions](#type-definitions) |
| `target`       | String     | No       | Target node or agent.  | `server-01`, `agent-1`                    |
| `payload`      | Object     | Yes      | Type-specific payload. | See below                                 |
| `timing`       | Object     | No       | When to execute.       | See Timing                                |

### Inject Types


| Type          | Description                   | Payload Fields              |
|:--------------|:------------------------------|:----------------------------|
| `event`       | Emit event to telemetry       | `event_type`, `data`        |
| `state`       | Modify environment state      | `target`, `mutation`        |
| `message`     | Send message to agent         | `content`, `channel`        |
| `artifact`    | Place file in environment     | `path`, `content`           |
| `delay`       | Pause execution               | `duration`                  |
| `custom`      | Custom inject via evaluator   | `evaluator`, `params`       |

#### Custom Injects

For inject types not covered above, use `type: custom` with an evaluator:

```yaml
injects:
  run-custom-script:
    type: custom
    payload:
      evaluator: my_custom_inject
      params:
        command: "bash /tmp/setup.sh"
        target: server-01
```


### Timing

| Property | Type   | Required | Description                    | Example       |
| :------- | :----- | :------- | :----------------------------- | :------------ |
| `phase`  | String | No       | Phase to execute during.       | `exploration` |
| `delay`  | String | No       | Delay after trigger.           | `30s`         |
| `at`     | String | No       | Absolute time into experiment. | `10m`         |
| `after`  | String | No       | Execute after another inject.  | `inject-1`    |

> **Note:** `at` is relative to experiment start time. Use `on_enter`/`on_exit` on phases when you need an inject tied to a phase transition rather than an absolute time. For example, `timing.at: 0m` fires at the start of the experiment, while `on_enter` fires when that specific phase begins, which may be well into the experiment.

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

| Property     | Type        | Required | Description                | Example                                   |
| :----------- | :---------- | :------- | :------------------------- | :---------------------------------------- |
| `mode`       | ScoringMode | No       | Scoring mode.              | see [Type Definitions](#type-definitions) |
| `time_limit` | String      | No       | Scoring time window.       | `2h`                                      |
| `normalize`  | Boolean     | No       | Normalize scores to 0-100. | `false`                                   |

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
