# RFC-XXXX: Agentic Cyber Range Specification

## Status

`Proposed`

---

## Summary

This draft RFC proposes a declarative YAML specification for defining reproducible cyber experiment ranges. This enables seamless ingestion by `aces-sdl` and execution via `aces-runtime` within the Agentic Cyber Environment System (ACES).

---

## Motivation

For ACES to serve as an open reference architecture for autonomous AI agent research, it requires a standardized, framework-agnostic language to express scenarios. Other experiment environments have had success in specifying distributed network systems using a graph-based approach (vertices and edges) mapped to a network simulation like Proxmox. ACES will ingest a declarative schema capable of supporting multiple instantiation backends (e.g., `aces-provider-docker`, cloud providers) and complex agentic experimentation loops via `aces-experiment`.

---

## Proposal

The proposed schema is divided into three layers: **topology**, **resources**, and **runtime**.

### Topology (Logical Structure)

A static graph declaration for the components of the model topology. Enables automated translation to infrastructure as code templates (e.g. Terraform, OpenTofu, CloudFormation scripts).

- **Networks (Edges):** Logical broadcast domains or subnets.
- **Nodes (Vertices):** The logical representation of a host, router, or switch.

### Resources (Infrastructure Bindings)

Logical nodes must be mapped to physical or virtual resources. This layer separates the "what" (the topology) from the "how" (the provider instantiation), allowing the same topology to be spun up using containers, local images, or cloud VMs.

### Runtime (Execution Scenarios)

The runtime block defines state changes, injected events, and agent hooks that occur over the lifecycle of the experiment.

---

## Schema Specification

### Root Schema

The root of the YAML document defines the API version, the kind of resource, and the three core pillars of the experiment.

| Field | Type | Description | Example |
|---|---|---|---|
| `apiVersion` | String | The version of the schema | `v1alpha1` |
| `kind` | String | Must be `CyberRange` or `ExperimentSpec` | |
| `metadata` | Object | Identifying information | `{name, description, version}` |
| `topology` | Object | The logical definition of networks, nodes, and edges | |
| `resources` | Object | Hardware/virtualization requirements and resource bindings | |
| `runtime` | Object | The chronological phases, actions, and event triggers | |

---

### Topology

The topology block defines the "what" of the environment — the structure of the network without concerning itself with how virtualization or emulation will occur.

#### Networks

Networks represent broadcast domains, local area networks, subnets, and switching fabrics.

| Property | Type | Description |
|---|---|---|
| `name` | String | Unique identifier for the network |
| `cidr` | String | IPv4/IPv6 subnet (e.g., `10.0.0.0/24`) |
| `routing` | String | `isolated` (air-gapped), `nat` (outbound only), or `bridged` |

#### Nodes

Nodes represent endpoints or edge devices, including routers, switches, and firewalls.

| Property | Type | Description |
|---|---|---|
| `name` | String | Unique identifier for the node |
| `type` | String | Device type (e.g. `host`, `router`, `switch`, `firewall`) |
| `interfaces` | Array | List of `NetworkInterface` objects for connections to declared networks |

##### NetworkInterface Object

| Property | Type | Description |
|---|---|---|
| `name` | String | Name of the target network |
| `type` | Boolean | Flag if DHCP is on/off |
| `ip_address` | String | Static IP address, if specified |
| `hw_address` | String | Hardware (e.g. MAC) address |

#### Edges

Edges define physical and link layer constraints between interfaces, allowing simulation of realistic network degradation conditions.

| Property | Type | Description |
|---|---|---|
| `endpoints` | Array | List of node interfaces forming each edge |
| `latency` | String | Simulated delay (e.g., `50ms`) |
| `packet_loss` | Float | Percentage of dropped packets (e.g., `0.05` for 5%) |

---

### Resources

The resources block maps the logical topology to physical or virtual realities. This separation allows the same topology to be executed on a local hypervisor, a container engine, or a public cloud.

#### Resource Profiles

Defines standardized compute to ensure reproducible performance.

| Property | Type | Description |
|---|---|---|
| `name` | String | Unique identifier (e.g., `standard-small`) |
| `cpus` | Integer | Number of vCPUs |
| `gpus` | Integer | Number of vGPUs |
| `memory` | String | RAM allocation (e.g., `2048M`, `4G`) |
| `vram` | String | VRAM allocation |

#### Bindings

Maps specific nodes to OS images and compute profiles.

| Property | Type | Description |
|---|---|---|
| `node` | String | Reference to a node name in the topology |
| `image` | String | URI or name of the OS image/container |
| `profile` | String | Reference to a defined compute profile |

---

### Runtime

The runtime block governs the state machine of the experiment. It is divided into sequential phases (e.g., provisioning, initialization, execution, teardown).

#### Phases

| Property | Type | Description |
|---|---|---|
| `name` | String | Identifier for the phase (e.g., `attack_simulation`) |
| `dependencies` | Array | Names of phases that must complete before this one starts |
| `duration` | String | Maximum time allowance for the phase (e.g., `3600s`) |
| `actions` | Array | Ordered list of tasks to execute during this phase |

#### Actions

Actions represent discrete tasks executed against specific nodes.

| Property | Type | Description |
|---|---|---|
| `type` | String | Type of action (`execute_command`, `file_transfer`, `start_service`) |
| `target` | String | The node where the action occurs |
| `payload` | Object | The specifics of the action (e.g., bash command, file path) |

#### Agents

| Property | Type | Description |
|---|---|---|
| `id` | String | Unique identifier for the agent (e.g., `red_team_llm_01`) |
| `type` | String | Operational paradigm (`llm_autonomous`, `rl_agent`, `scripted_bot`) |
| `initial_node` | String | Reference to a node in the topology where the agent executes from |
| `goal` | String | Natural language or programmatic objectives guiding agent behavior |
| `objectives` | Array | List of `AgentObjective` objects |
| `observation_space` | Array | Telemetry streams the agent can perceive (e.g., `stdout`, `network_pcap`, `syslog`) |
| `action_space` | Array | Restricted set of interactions the agent is permitted to execute (e.g., `execute_shell`, `modify_config`) |

##### AgentObjective Object

| Property | Type | Description |
|---|---|---|
| `id` | String | Unique identifier for the objective (e.g., `red_flag_captured`) |
| `condition` | String | Environmental state that must be met (e.g., `file_exists:/tmp/exfil.db:attacker_node`) |
| `reward` | Float | Numeric score/reward applied when condition is met (e.g., `100.0`, `-10.5`) |

---

### YAML Example (WIP)

```yaml
runtime:

  agents:
    - id: red_team_llm_01
      type: llm_autonomous
      initial_node: external_attacker_node
      goal: "Discover internal databases and exfiltrate the 'attendees.db' file."
      observation_space:
        - stdout
        - stderr
      action_space:
        - execute_shell

    - id: blue_team_rl_bot
      type: rl_agent
      vantage_point: core_switch
      goal: "Maintain uptime of HTTP services while blocking anomalous lateral movement."
      observation_space:
        - network_pcap
        - syslog
      action_space:
        - modify_config  # ACLs or firewall rules

  objectives:
    - id: red_flag_captured
      condition: "file_exists:/tmp/exfiltrated_attendees.db:external_attacker_node"
      reward: 100.0

    - id: blue_uptime_maintained
      condition: "service_responsive:http:web_server_01"
      reward: 1.0  # continuous reward per tick

  phases:
    - name: autonomous_engagement
      duration: "3600s"
      actions:
        - type: start_agent_loop
          target: external_attacker_node
          payload:
            agent_id: red_team_llm_01

        - type: start_agent_loop
          target: core_switch
          payload:
            agent_id: blue_team_rl_bot
```

---

## Alternatives Considered

> *What other approaches were considered and why were they rejected?*

*(To be filled in)*

---

## Affected Repos

> *List every repo that would need changes to implement this RFC.*

*(To be filled in)*

---

## Consequences

> *What becomes easier or harder as a result of this change? What are the migration requirements?*

*(To be filled in)*
