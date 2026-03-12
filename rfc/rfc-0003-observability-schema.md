# RFC-0003: Observability Schema

## Summary

This RFC outlines the observability schema, which includes a standardized telemetry object designed to capture the state of a RFC-0002 experiment in a RFC-0001 environment. It defines how to capture the exact contextual state of an autonomous agent at the precise moment it makes a decision or executes a tool call.

## Motivation

To effectively replay, debug, and analyze autonomous agent behavior within reproducible cyber ranges, it is insufficient to solely log the input and output states. An agent's decisions are heavily influenced by its immediate execution environment.

This schema bridges the gap between the static, declarative infrastructure defined in the range specification (RFC-0001) and the dynamic, ephemeral state of the agent during execution.

---

### Root Schema

TODO

### EnvironmentState Object

This provides a high-level mapping back to the experiment that can be included in RFC-0001 telemetry.

| Field         | Type   | Required | Description              | Example      |
| :------------ | :----- | :------- | :----------------------- | :----------- |
| `environment` | Object | Yes      | Environment ref.         | See RFC-0002 |
| `agents`      | Array  | Yes      | A list of active agents. | See RFC-0002 |

### Agent State

The current state of an agent.

| Property           | Type   | Required | Description                                                         | Example                      |
| :----------------- | :----- | :------- | :------------------------------------------------------------------ | :--------------------------- |
| `name`             | String | Yes      | Agent name (refs agent).                                            | See RFC-0002                 |
| `platform`         | String | Yes      | Orchestration layer (refs agent_platform,name).                     | `agent-cluster`              |
| `platform_context` | String | Yes      | Execution layer.                                                    | `agent-cluster`              |
| `active_networks`  | Array  | Yes      | The logical networks the agent can access (refs topology.networks). | `[range-vpc, domain-subnet]` |
| `nodes`            | Array  | No       | The nodes where the agent is taking action (refs topology.nodes).   | `workstation-01`             |
| `node_state`       | Object | No       | Node state at the exact time of execution.                          | See NodeState Object         |

### NodeState Object

This object captures the localized, ephemeral context of an agent executing on a node.

| Field      | Type    | Required | Description                    | Example                           |
| :--------- | :------ | :------- | :----------------------------- | :-------------------------------- |
| `user`     | String  | Yes      | The active system user.        | `root`                            |
| `is_root`  | Boolean | Yes      | Flag for root privileges.      | `true`                            |
| `cwd`      | String  | Yes      | The Current Working Directory. | `/etc/cron.d`                     |
| `env_vars` | Object  | No       | Key environment variables.     | `{PATH:/usr/local/sbin:/usr/bin}` |

### PlatformContext Object

This object maps an agent to the relevant platform context.

| Property            | Type   | Required | Description                                                        | Example      |
| :------------------ | :----- | :------- | :----------------------------------------------------------------- | :----------- |
| `namespace`         | String | No       | Logical isolation boundary (refs agent_platform.network).          | `agents`     |
| `orchestrator_type` | String | Yes      | Task orchestration system (refs agent_platform.orchestrator.type). | `kubernetes` |
| `pod_id`            | String | No       | Container or pod executing the agent.                              | `worker-0`   |

---

## Alternatives Considered

### Telemetry

Telemetry specifications are already embedded in RFC-0001.

### Experiment specification.

Intermediate states are optionally captured as an extension of RFC-0002, which already specifies initial and expected end states.

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

- **Traceability**: Experiment traceability and replay from a captured state.
- **Experiment boundary enforcement**: Segregates forensic telemetry traces from environment state.

### What Becomes Harder

- **Data Capture**: Data must be captured on the agent platform in addition to the telemetry plane.
- **Extensibility**: Changes to environment specification may need to be cross-checked.

---

## Cross-References

| Document                             | Relationship                              |
| :----------------------------------- | :---------------------------------------- |
| RFC-0001: Environment Infrastructure | Defines infrastructure experiments use    |
| RFC-0003: Observability Schema       | Defines telemetry attributes and taxonomy |
| RFC-0004: Agent SDK (future)         | Agent implementation interfaces           |
| RFC-0005: Evaluation System (future) | Condition evaluator specifications        |