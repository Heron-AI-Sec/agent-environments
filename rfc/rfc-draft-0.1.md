# RFC-XXXX: Agentic Cyber Range Specification

## Status

`Proposed`

## Summary

`This draft RFC proposes a declarative YAML specification for defining reproducible cyber experiment ranges. This enables seamless ingestion by aces-sdl and execution via aces-runtime within the Agentic Cyber Environment System (ACES).`

## Motivation

`For ACES to serve as an open reference architecture for autonomous AI agent research, it requires a standardized, framework-agnostic language to express scenarios. Other experiment environments have had success in specifying distributed network systems using a graph-based approach (vertices and edges) mapped to a network simulation like proxmox. ACES will ingest a declarative schema capable of supporting multiple instantiation backends (e.g., aces-provider-docker, cloud providers) and complex agentic experimentation loops via aces-experiment.`

## Proposal

`The proposed schema is divided into three layers: topology, resources, and runtime.`

### **`Topology (Logical Structure)`**

`This is a static graph declaration for the components of the model topology. This enables automated translation to infrastructure as code templates (e.g. Terraform, OpenTofu, CloudFormation scripts).`

* **`Networks (Edges):`** `Logical broadcast domains or subnets.`  
* **`Nodes (Vertices):`** `The logical representation of a host, router, or switch.`

### **`Resources (Infrastructure Bindings)`**

`Logical nodes must be mapped to physical or virtual resources. This layer separates the "what" (the topology) from the "how" (the provider instantiation), allowing the same topology to be spun up using containers, local images, or cloud VMs.`

### **`Runtime (Execution Scenarios)`**

`The runtime block defines state changes, injected events, and agent hooks that occur over the lifecycle of the experiment.`

## **`Schema Specification`**

### `Root Schema`

`The root of the YAML document defines the API version, the kind of resource, and the three core pillars of the experiment: Topology (the logical design), Resources (the infrastructure mapping), and Runtime (the execution lifecycle).`

| `Field` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `apiVersion` | `String` | `The version of the schema.` | `v1alpha1` |
| `kind` | `String` | `The type of environment.` | `CyberRange or ExperimentSpec` |
| `metadata` | `Object` | `Identifying information.` | `{name, description, version}` |
| `topology` | `Object` | `The logical definition of networks, nodes, and edges.` |  |
| `resources` | `Object` | `Hardware/virtualization requirements and resource bindings.` |  |
| `runtime` | `Object` | `The chronological phases, actions, and event triggers.` |  |

`Topology`

`The topology block defines the "what" of the environment. It outlines the structure of the network without concerning itself with how the virtualization or emulation will occur.`

#### `Networks`

`Networks represent broadcast domains, local area networks, subnets, and switching fabrics.`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `name` | `String` | `Unique identifier for the network.` | `enterprise-model` |
| `cidr` | `String` | `IPv4/IPv6 subnet.` | `10.0.0.0/24` |
| `routing` | `String` | `The routing mode.` | `{isolated, nat, bridged}` |

#### `Nodes`

`Nodes represent endpoints or edge devices, including routers, switches, and firewalls within the environment.`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `name` | `String` | `Unique identifier for the node.` | `workstation-0` |
| `type` | `String` | `Device type.` | `{host, router, switch, firewall}` |
| `interfaces` | `Array` | `List of NetworkInterface objects names for connections to declared networks.` | `[router-eth-0, router-eth-1]` |

##### `NetworkInterface Object`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `name` | `String` | `Name of the target network interface.` | `router-eth-0` |
| `type` | `Boolean` | `Flag if DHCP is on/off.` | `{True, False}` |
| `ip_address` | `String` | `Static IP address, if specified.` | `192.168.1.1/24` |
| `hw_address` | `String` | `Hardware (e.g. MAC) address.` | `DE:AD:BE:EF` |

#### 

#### `Edges`

`Edges define physical and link layer constraints between interfaces, allowing for the simulation of realistic degradation conditions for  networks.`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `endpoints` | `Tuple` | `Nodes forming each edge.` | `(router-0, workstation-0)` |
| `latency` | `String` | `Simulated delay.` | `50ms` |
| `packet_loss` | `Float` | `Percentage of dropped packets.` | `0.05` |

## 

### `Resources`

`The resources block maps the logical topology to physical or virtual realities. This separation allows the same topology to be executed on a local hypervisor, a container engine, or a public cloud.`

#### `Resource Profiles`

`Defines standardized compute to ensure reproducible performance.`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `name` | `String` | `Unique identifier.` | `standard-small-cpu` |
| `cpus` | `Integer` | `Number of vCPUs.` | `8` |
| `gpus` | `Integer` | `Number of vGPUs.` | `8` |
| `memory` | `String` | `RAM allocation.` | `32G` |
| `vram` | `String` | `VRAM allocation.` | `4096M` |

#### `Bindings`

`Maps specific nodes to OS images and compute profiles.`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `node` | `String` | `Reference to a node name in the topology.` | `workstation-0` |
| `image` | `String` | `URI or name of the OS image/container.` | `smtp-server.ova` |
| `profile` | `String` | `Reference to a defined compute profile.` | `standard-small-cpu` |

### `Runtime`

`The runtime block governs the state machine of the experiment. It is divided into sequential phases (e.g., provisioning, initialization, execution, teardown).`

#### `Phases`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `name` | `String` | `Identifier for the phase.` | `privesc-attack` |
| `dependencies` | `Array` | `Names of phases that must complete before this one starts.` | `[init-access]` |
| `duration` | `String` | `Maximum time allowance for the phase.` | `3600s` |
| `actions` | `Array` | `Ordered list of actions to execute during this phase.` | `[action-0,action-1]` |

#### `Actions`

`Actions represent discrete tasks executed against specific nodes.`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `name` | `String` | `Name of the action.` | `action-0` |
| `type` | `String` | `Type of action.` | `{execute_command, file_transfer, start_service}` |
| `target` | `String` | `The node where the action occurs.` | `workstation-0` |
| `payload` | `Object` | `The specifics of the action.` | `touch /root/file.txt` |

#### `Agents`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `id` | `String` | `Unique identifier for the agent.` | `red_team_llm_01` |
| `type` | `String` | `The operational paradigm of the agent.` | `{llm_autonomous, rl_agent, scripted_bot}` |
| `initial_node` | `String` | `Reference to a node in the topology where the agent executes or connects from.` | `workstation-0` |
| `goal` | `String` | `Natural language or programmatic objectives guiding the agent's behavior.` | `Discover internal databases and exfiltrate the 'attendees.db' file.` |
| `objectives` | `Array` | `List of AgentObjective objects.` | `[red_flag_captured]` |
| `observation_space` | `Array` | `The specific telemetry streams or environmental states the agent can perceive.` | `{stdout, network_pcap, syslog}` |
| `action_space` | `Array` | `The restricted set of interactions or commands the agent is permitted to execute.` | `{execute_shell, modify_config}` |

##### `AgentObjective Object`

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `id` | `String` | `Unique identifier for the objective.` | `red_flag_captured` |
| `condition` | `String` | `The specific environmental state that must be met to trigger the objective.` | `{file_exists:/tmp/exfil.db:attacker-node-0}` |
| `reward` | `Float` | `The numeric score, penalty, or reward applied when the condition is successfully met.` | `-10.5` |

#### **`YAML File Example (WIP)`**

### 

| `runtime:   agents:     - id: red_team_llm_01       type: llm_autonomous       initial_node: external_attacker_node       goal: "Discover internal databases and exfiltrate the 'attendees.db' file."       observation_space:         - stdout         - stderr       action_space:         - execute_shell     - id: blue_team_rl_bot       type: rl_agent       vantage_point: core_switch       goal: "Maintain uptime of HTTP services while blocking anomalous lateral movement."       observation_space:         - network_pcap         - syslog       action_space:         - modify_config  # ACLs or firewall rules   objectives:     - id: red_flag_captured       condition: "file_exists:/tmp/exfiltrated_attendees.db:external_attacker_node"       reward: 100.0     - id: blue_uptime_maintained       condition: "service_responsive:http:web_server_01"       reward: 1.0  # continuous reward per tick   phases:     - name: autonomous_engagement       duration: "3600s"       actions:         - type: start_agent_loop           target: external_attacker_node           payload:             agent_id: red_team_llm_01         - type: start_agent_loop           target: core_switch           payload:             agent_id: blue_team_rl_bot`  |
| :---- |

## Alternatives Considered

What other approaches were considered and why were they rejected?

## Affected Repos

List every repo that would need changes to implement this RFC.

## Consequences

What becomes easier or harder as a result of this change? What are the migration requirements?  
