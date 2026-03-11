# RFC-0001: Cyber Range Specification

## Summary

This draft RFC proposes a declarative YAML specification for defining
reproducible cyber experiment ranges. This enables seamless ingestion by range
orchestration tools and execution via compatible runtimes within the Agentic
Cyber Environment System (ACES).

## Motivation

For ACES to serve as an open reference architecture for autonomous AI agent
research, it requires a standardized, framework-agnostic language to express
scenarios. Other experiment environments have had success in specifying
distributed network systems using a graph-based approach (vertices and edges)
mapped to a network simulation like proxmox. ACES will ingest a declarative
schema capable of supporting multiple instantiation backends (e.g., Docker,
cloud providers, hypervisors) and complex agentic experimentation loops.

### Design Principles

1. **Infrastructure Focus**: Ranges define "what exists", not "what happens"
2. **Reusability**: The same range can host multiple experiments
3. **Provider Agnostic**: Topology is separate from instantiation backend
4. **Observable**: Telemetry collection is configured at the infrastructure level

## Proposal

The proposed schema is divided into seven core sections:

| Section          | Purpose                                                              |
| :--------------- | :------------------------------------------------------------------- |
| `topology`       | Logical structure of networks, nodes, and edges                      |
| `groups`         | Logical grouping of nodes by role, deployment, or function           |
| `resources`      | Infrastructure bindings, compute profiles, and image configuration   |
| `provisioning`   | Post-deployment configuration and automation                         |
| `agent_platform` | Where agents execute (separate from target topology)                 |
| `telemetry`      | Observability stack: logs, traces, metrics, storage tiers, and sinks |
| `connectivity`   | Overlay networks, operator access, and environment connections       |

---

## Type Definitions

The following shared types are referenced throughout this specification.

| Type | Kind | Values |
| :--- | :--- | :----- |
| `OS` | extensible-enum | `linux`, `windows`, `macos`, `freebsd` |
| `Tier` | extensible-enum | `critical`, `high`, `medium`, `low` |
| `NodeType` | extensible-enum | `host`, `router`, `switch`, `firewall` |
| `Routing` | extensible-enum | `isolated`, `nat`, `bridged` |
| `Role` | growing | `domain_controller`, `server`, `workstation`, `attacker`, `target`, `c2_server`, `redirector` |
| `Provisioner` | growing | `terraform`, `ansible`, `docker`, `proxmox`, `cloud_init` |

**Kind definitions:**
- **`extensible-enum`**: A closed list of standard values. Custom values are allowed using the `x-` prefix (e.g., `x-myos`).
- **`growing`**: An open list where new standard values are expected to be added over time.

---

## Schema Specification

### Root Schema

The root of the YAML document defines the API version, the kind of resource,
and the infrastructure pillars.

| Field            | Type   | Required | Description                                                 | Example                              |
| :--------------- | :----- | :------- | :---------------------------------------------------------- | :----------------------------------- |
| `apiVersion`     | String | Yes      | The version of the schema.                                  | `aces.io/v1alpha1`                   |
| `kind`           | String | Yes      | The type of resource.                                       | `CyberRange`                         |
| `metadata`       | Object | Yes      | Identifying information.                                    | `{name, description, version}`       |
| `topology`       | Object | Yes      | The logical definition of networks, nodes, and edges.       | `{networks: {...}, nodes: {...}}`    |
| `groups`         | Object | No       | Logical grouping of nodes (map keyed by name).              | `{domain_controllers: {...}}`        |
| `resources`      | Object | No       | Hardware/virtualization requirements and resource bindings. | `{profiles: {...}, bindings: {...}}` |
| `provisioning`   | Object | No       | Post-deployment configuration.                              | `{method: cloud_shell_ansible}`      |
| `agent_platform` | Object | No       | Platform where agents execute.                              | `{type: kubernetes, name: ...}`      |
| `telemetry`      | Object | No       | Observability and event collection configuration.           | `{tracing: {...}, logging: {...}}`   |
| `connectivity`   | Object | No       | Network connectivity between environments.                  | `{overlay: {...}, connections: {}}` |

### Example

```yaml
---
apiVersion: aces.io/v1alpha1
kind: CyberRange
metadata:
  name: ad-attack-range
  description: "Active Directory attack simulation range"
  version: "1.0.0"
  labels:
    environment: dev
    team: red-team

topology: { ... }
groups: { ... }
resources: { ... }
provisioning: { ... }
agent_platform: { ... }
telemetry: { ... }
connectivity: { ... }
```

---

## Topology

The topology block defines the "what" of the environment. It outlines the
structure of the network without concerning itself with how the virtualization
or emulation will occur.

### Networks

Networks represent broadcast domains, local area networks, subnets, and
switching fabrics.

Networks are defined as a map keyed by name (the unique identifier).

| Property                 | Type    | Required | Description                                      | Example                        |
| :----------------------- | :------ | :------- | :----------------------------------------------- | :----------------------------- |
| `display_name`           | String  | No       | Human-readable label (not used for references).  | `Corporate LAN`                |
| `cidr`                   | String  | Yes      | IPv4/IPv6 subnet.                                | `10.0.0.0/16`                  |
| `routing`                | Routing | No       | The routing mode.                                | see [Type Definitions](#type-definitions) |
| `vlan_id`                | Integer | No       | Optional VLAN identifier.                        | `100`                          |
| `secondary_cidr`         | String  | No       | Secondary CIDR block (e.g., for pod networking). | `100.64.0.0/16`                |
| `private_service_access` | Array   | No       | Managed service connectivity (private access).   | `[remote_management, storage]` |

#### Private Service Access

For cloud deployments, private service access enables connectivity to managed
services without traversing the public internet. Supported endpoints:
`remote_management`, `storage`, `file_storage`, `secrets`, `logs`.

See [Appendix A](#appendix-a-provider-mappings) for provider-specific service mappings.

### Networks Example

```yaml
---
topology:
  networks:
    range-vpc:
      cidr: 10.0.0.0/16
      secondary_cidr: 100.64.0.0/16 # For Kubernetes pod networking
      routing: nat
      private_service_access: [remote_management, storage, file_storage]

    domain-subnet:
      cidr: 10.0.10.0/24
      routing: isolated
      vlan_id: 10
```

### Nodes

Nodes represent endpoints or edge devices, including routers, switches, and
firewalls within the environment. Nodes are defined as a map keyed by name
(the unique identifier).

| Property          | Type   | Required | Description                              | Example                                                |
| :---------------- | :----- | :------- | :--------------------------------------- | :----------------------------------------------------- |
| `type`            | NodeType    | Yes      | Device type.                             | see [Type Definitions](#type-definitions) |
| `role`            | Role        | No       | Functional role within the environment.  | see [Type Definitions](#type-definitions) |
| `computer_name`   | String      | No       | NetBIOS/hostname as seen in the OS.      | `DC01`                                    |
| `display_name`    | String      | No       | Human-readable label (not used for references). | `Primary Domain Controller`        |
| `os`              | OS          | No       | Operating system.                        | see [Type Definitions](#type-definitions) |
| `os_version`      | String      | No       | OS version.                              | `2019`, `2022`, `22.04`                   |
| `os_distribution` | String      | No       | Linux distribution (if applicable).      | `ubuntu`, `kali`, `debian`                |
| `domain`          | String      | No       | Domain membership (for AD environments). | `corp.local`                              |
| `tier`            | Tier        | No       | Criticality tier for targeting/defense.  | see [Type Definitions](#type-definitions) |
| `groups`          | Array       | No       | References to group names.               | `[ad_lab, domain_controllers, windows]`   |
| `services`        | Array       | No       | Services running on this node.           | `[ldap, kerberos, dns, smb]`              |
| `network_interfaces` | Array    | Yes      | List of NetworkInterface objects.        | `[{name: eth0, network: corp-lan}]`       |
| `provisioner`     | Provisioner | No       | Tool used to provision this node.        | see [Type Definitions](#type-definitions) |
| `provisioner_id`  | String | No       | ID within the provisioner system.        | `dc01`                                                 |
| `owner`           | String | No       | Responsible operator or team.            | `infra-team`, `red-team`                               |
| `features`        | Array  | No       | Capabilities or flags for this node.     | `[vnc_access, pre_installed_tools]`                    |
| `notes`           | String | No       | Freeform metadata or documentation.      | `Primary DC for corp.local`                            |

#### NetworkInterface Object

| Property     | Type    | Required | Description                           | Example             |
| :----------- | :------ | :------- | :------------------------------------ | :------------------ |
| `name`       | String  | Yes      | Name of the target network interface. | `eth0`              |
| `network`    | String  | Yes      | Reference to a network name.          | `domain-subnet`     |
| `dhcp`       | Boolean | No       | Flag if DHCP is on/off.               | `true`, `false`     |
| `ip_address` | String  | No       | Static IP address, if specified.      | `192.168.1.1/24`    |
| `hw_address` | String  | No       | Hardware (e.g. MAC) address.          | `DE:AD:BE:EF:00:01` |

### Nodes Example

```yaml
---
topology:
  nodes:
    dc01:
      type: host
      role: domain_controller
      computer_name: DC01
      display_name: "Primary Domain Controller"
      os: windows
      os_version: "2019"
      domain: corp.local
      tier: critical
      groups: [ad_lab, domain_controllers, windows]
      services: [ldap, kerberos, dns, smb]
      provisioner: terraform
      provisioner_id: dc01
      owner: infra-team
      network_interfaces:
        - name: eth0
          network: corp-subnet
          ip_address: 10.0.10.10/24

    kali-01:
      type: host
      role: attacker
      computer_name: kali-01
      os: linux
      os_distribution: kali
      groups: [attackers]
      features: [vnc_access, pre_installed_tools]
      network_interfaces:
        - name: eth0
          network: range-vpc
          dhcp: true
```

### Edges

Edges define physical and link layer constraints between interfaces, allowing
for the simulation of realistic degradation conditions for networks.

| Property      | Type   | Required | Description                    | Example                     |
| :------------ | :----- | :------- | :----------------------------- | :-------------------------- |
| `endpoints`   | Tuple  | Yes      | Nodes forming each edge.       | `(router-0, workstation-0)` |
| `latency`     | String | No       | Simulated delay.               | `50ms`                      |
| `packet_loss` | Float  | No       | Percentage of dropped packets. | `0.05`                      |
| `bandwidth`   | String | No       | Maximum bandwidth.             | `1Gbps`                     |

### Edges Example

```yaml
---
topology:
  edges:
    # Simulate WAN link between sites
    - endpoints: [router-hq, router-branch]
      latency: 50ms
      packet_loss: 0.01
      bandwidth: 100Mbps

    # Simulate congested LAN segment
    - endpoints: [switch-01, workstation-01]
      bandwidth: 100Mbps

    # Simulate unreliable VPN connection
    - endpoints: [vpn-gateway, remote-attacker]
      latency: 150ms
      packet_loss: 0.05
      bandwidth: 10Mbps
```

---

## Groups

Groups provide logical organization of nodes by role, deployment method, or
function. This enables bulk operations, targeting, and policy application.
Groups are defined as a map keyed by name (the unique identifier).

| Property       | Type   | Required | Description                                            | Example                                                  |
| :------------- | :----- | :------- | :----------------------------------------------------- | :------------------------------------------------------- |
| `display_name` | String | No       | Human-readable label (not used for references).        | `Domain Controllers`                                     |
| `description`  | String | No       | Human-readable description.                            | `Active Directory domain controllers`                    |
| `type`        | String | No       | Grouping strategy.                                     | `deployment`, `role-based`, `os-based`, `infrastructure` |
| `provisioner` | Provisioner | No   | Tool that created these nodes (for deployment groups). | see [Type Definitions](#type-definitions) |
| `members`     | Array  | No       | Explicit list of node names (optional).                | `[dc01, dc02]`                                           |

### Groups Example

```yaml
---
groups:
  ad_lab:
    description: "Active Directory lab hosts"
    type: deployment
    provisioner: terraform

  domain_controllers:
    description: "Active Directory domain controllers"
    type: role-based

  c2_servers:
    description: "Command & Control servers"
    type: infrastructure
    members: [sliver, mythic]

  redirectors:
    description: "C2 traffic redirectors"
    type: infrastructure
    members: [redir-01, redir-02]

  windows:
    description: "All Windows hosts"
    type: os-based

  attackers:
    description: "Offensive operator workstations"
    type: role-based
    members: [kali-01, kali-02]
```

---

## Resources

The resources block maps the logical topology to physical or virtual realities.
This separation allows the same topology to be executed on a local hypervisor,
a container engine, or a public cloud.

### Resource Profiles

Defines standardized compute configurations to ensure reproducible performance.
Profiles are defined as a map keyed by name (the unique identifier).

| Property        | Type    | Required | Description                      | Example                   |
| :-------------- | :------ | :------- | :------------------------------- | :------------------------ |
| `instance_type` | String  | No       | Cloud instance type.             | `t3.medium`, `m6i.xlarge` |
| `cpus`          | Integer | No       | Number of vCPUs (for non-cloud). | `4`                       |
| `memory`        | String  | No       | RAM allocation.                  | `8Gi`                     |
| `gpus`          | Integer | No       | Number of vGPUs.                 | `1`                       |
| `volume`        | Object  | No       | Root volume configuration.       | See Volume Object         |

#### Volume Object

| Property    | Type    | Required | Description                     | Example                  |
| :---------- | :------ | :------- | :------------------------------ | :----------------------- |
| `size`      | String  | No       | Volume size.                    | `100Gi`                  |
| `type`      | String  | No       | Volume type.                    | `gp3`, `io1`, `standard` |
| `encrypted` | Boolean | No       | Enable encryption.              | `true`                   |
| `iops`      | Integer | No       | Provisioned IOPS (for io1/io2). | `3000`                   |

### Image Filters

Defines how to select machine images for cloud deployments. This example uses
AWS AMI filters, but the pattern applies to other clouds. Image filters are
defined as a map keyed by name (the unique identifier).

| Property      | Type    | Required | Description                        | Example                  |
| :------------ | :------ | :------- | :--------------------------------- | :----------------------- |
| `owners`      | Array   | No       | Image owner account IDs.           | `[amazon, 099720109477]` |
| `filters`     | Object  | Yes      | Image filter criteria.             | See below                |
| `most_recent` | Boolean | No       | Select most recent matching image. | `true`                   |

#### Image Filter Criteria

| Property              | Type   | Description                              | Example                                   |
| :-------------------- | :----- | :--------------------------------------- | :---------------------------------------- |
| `name`                | String | Image name pattern (supports wildcards). | `Windows_Server-2019-English-Full-Base-*` |
| `virtualization-type` | String | Virtualization type.                     | `hvm`                                     |
| `root-device-type`    | String | Root device type.                        | `ebs`                                     |
| `architecture`        | String | CPU architecture.                        | `x86_64`                                  |

### Instance Policies

Defines IAM/service account policies to attach to instances. Policies are
defined as a map keyed by name (the unique identifier).

| Property           | Type   | Required | Description                                            | Example                             |
| :----------------- | :----- | :------- | :----------------------------------------------------- | :---------------------------------- |
| `capabilities`     | Array  | No       | Abstract capabilities (resolved to provider policies). | `[remote_management, metrics_logs]` |
| `managed_policies` | Array  | No       | Provider-specific managed policy ARNs/names.           | `[AmazonSSMManagedInstanceCore]`    |
| `inline_policies`  | Array  | No       | Custom inline policy documents.                        | `[{name: custom, document: {...}}]` |

#### Standard Capabilities

Abstract capabilities resolved to provider-specific policies at deploy time:
`remote_management`, `metrics_logs`, `storage_read`, `storage_full`, `secrets_read`.

See [Appendix A](#appendix-a-provider-mappings) for provider-specific policy mappings.

### Bindings

Maps specific nodes to images, compute profiles, and policies. Bindings are
defined as a map keyed by node name.

| Property          | Type   | Required | Description                               | Example                            |
| :---------------- | :----- | :------- | :---------------------------------------- | :--------------------------------- |
| `image`           | String | No       | Direct image URI or ID.                   | `ami-0abcdef1234567890`            |
| `image_filter`    | String | No       | Reference to an image filter name.        | `windows-2019-base`                |
| `profile`         | String | No       | Reference to a resource profile.          | `dc-standard`                      |
| `instance_policy` | String | No       | Reference to an instance policy.          | `range-node-base`                  |
| `security_groups` | Array  | No       | Security group references.                | `[internal-ad, management-access]` |
| `user_data`       | String | No       | Path to user data template.               | `templates/windows-dc.ps1.tpl`     |

### Security Groups

Defines network security rules for nodes. Security groups are defined as a map
keyed by name (the unique identifier).

| Property      | Type   | Required | Description                 | Example               |
| :------------ | :----- | :------- | :-------------------------- | :-------------------- |
| `description` | String | No       | Human-readable description. | `Internal AD traffic` |
| `ingress`     | Array  | No       | Inbound rules.              | See Rule Object       |
| `egress`      | Array  | No       | Outbound rules.             | See Rule Object       |

#### Security Group Rule Object

| Property          | Type    | Required | Description                         | Example                          |
| :---------------- | :------ | :------- | :---------------------------------- | :------------------------------- |
| `protocol`        | String  | Yes      | Protocol.                           | `tcp`, `udp`, `icmp`, `-1` (all) |
| `from_port`       | Integer | No       | Start port.                         | `445`                            |
| `to_port`         | Integer | No       | End port.                           | `445`                            |
| `cidr_blocks`     | Array   | No       | Source/destination CIDRs.           | `[10.0.0.0/16]`                  |
| `security_groups` | Array   | No       | Source/destination security groups. | `[agent-cluster]`                |
| `description`     | String  | No       | Rule description.                   | `SMB from VPC`                   |

### Resources Example

```yaml
---
resources:
  profiles:
    dc-standard:
      instance_type: t3.medium
      volume:
        size: 100Gi
        type: gp3
        encrypted: true

    c2-server:
      instance_type: t3.large
      volume:
        size: 100Gi
        type: gp3
        encrypted: true

    attacker-workstation:
      instance_type: t3.medium
      volume:
        size: 50Gi
        type: gp3

  image_filters:
    windows-2019-base:
      owners: [amazon]
      most_recent: true
      filters:
        name: "Windows_Server-2019-English-Full-Base-*"
        virtualization-type: hvm
        root-device-type: ebs

    ubuntu-22.04:
      owners: [099720109477] # Canonical
      most_recent: true
      filters:
        name: "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
        architecture: x86_64

    kali-latest:
      owners: [679593333241] # Kali
      most_recent: true
      filters:
        name: "kali-linux-*"

  instance_policies:
    range-node-base:
      capabilities: [remote_management, metrics_logs]
      # Provider-specific policies resolved at deploy time:
      # AWS: AmazonSSMManagedInstanceCore, CloudWatchAgentServerPolicy
      # GCP: roles/iap.tunnelResourceAccessor, roles/logging.logWriter
      # Azure: Virtual Machine User Login, Monitoring Metrics Publisher

    c2-server-policy:
      capabilities: [remote_management, storage_full]

  security_groups:
    internal-ad:
      description: "Internal AD traffic"
      ingress:
        - protocol: "-1"
          cidr_blocks: [10.0.0.0/16]
          description: "All traffic from VPC"
        - protocol: "-1"
          cidr_blocks: [172.16.0.0/16]
          description: "All traffic from agent platform"
      egress:
        - protocol: "-1"
          cidr_blocks: [0.0.0.0/0]
          description: "All outbound"

    c2-server:
      description: "C2 server access"
      ingress:
        - protocol: tcp
          from_port: 443
          to_port: 443
          cidr_blocks: [10.0.0.0/16]
        - protocol: tcp
          from_port: 80
          to_port: 80
          cidr_blocks: [10.0.0.0/16]

  bindings:
    dc01:
      image_filter: windows-2019-base
      profile: dc-standard
      instance_policy: range-node-base
      security_groups: [internal-ad]
      user_data: templates/windows-dc.ps1.tpl

    sliver:
      image_filter: ubuntu-22.04
      profile: c2-server
      instance_policy: c2-server-policy
      security_groups: [c2-server, internal-ad]
      user_data: templates/linux-c2.sh.tpl
```

---

## Provisioning

The provisioning block defines post-deployment configuration steps. This
separates the infrastructure creation (e.g., Terraform) from configuration
management (e.g., Ansible).

| Property    | Type   | Required | Description                   | Example                                            |
| :---------- | :----- | :------- | :---------------------------- | :------------------------------------------------- |
| `method`    | String | Yes      | Provisioning method.          | `cloud_shell_ansible`, `ssh_ansible`, `cloud_init` |
| `playbooks` | Object | No       | Ansible playbook definitions (map keyed by name). | `{dc-setup: {...}}`                                |
| `templates` | Object | No       | User data templates (map keyed by name).          | `{windows-bootstrap: {...}}`                       |

### Provisioning Methods

| Method                | Description                                   | Use Case                        |
| :-------------------- | :-------------------------------------------- | :------------------------------ |
| `cloud_shell_ansible` | Run Ansible via cloud shell (SSM/IAP/Bastion) | Cloud instances without SSH     |
| `ssh_ansible`         | Run Ansible via SSH                           | On-prem or SSH-accessible nodes |
| `cloud_init`          | Cloud-init user data only                     | Simple bootstrapping            |
| `none`                | No post-deployment provisioning               | Pre-baked images                |

### Playbook Object

Playbooks are defined as a map keyed by name (the unique identifier).

| Property     | Type   | Required | Description                   | Example                        |
| :----------- | :----- | :------- | :---------------------------- | :----------------------------- |
| `path`       | String | Yes      | Path to playbook file.        | `ansible/windows/dc_setup.yml` |
| `host_type`  | String | No       | Target OS type.               | `windows`, `linux`             |
| `groups`     | Array  | No       | Node groups to target.        | `[domain_controllers]`         |
| `nodes`      | Array  | No       | Specific nodes to target.     | `[dc01]`                       |
| `extra_vars` | Object | No       | Additional Ansible variables. | `{domain: corp.local}`         |
| `tags`       | Array  | No       | Ansible tags to run.          | `[install, configure]`         |

### Template Object

Templates are defined as a map keyed by name (the unique identifier).

| Property    | Type   | Required | Description            | Example                            |
| :---------- | :----- | :------- | :--------------------- | :--------------------------------- |
| `path`      | String | Yes      | Path to template file. | `templates/windows-dc.ps1.tpl`     |
| `type`      | String | Yes      | Template type.         | `powershell`, `bash`, `cloud_init` |
| `variables` | Object | No       | Template variables.    | `{join_domain: true}`              |

### Provisioning Example

```yaml
---
provisioning:
  method: cloud_shell_ansible # Uses SSM (AWS), IAP (GCP), or Bastion (Azure)

  templates:
    windows-bootstrap:
      path: templates/windows-dc.ps1.tpl
      type: powershell
      variables:
        install_cloud_agent: true # SSM agent, GCP guest agent, Azure agent
        enable_winrm: true

    linux-c2:
      path: templates/linux-c2.sh.tpl
      type: bash
      variables:
        install_docker: true

  playbooks:
    domain-controllers:
      path: ansible/windows/dc_setup.yml
      host_type: windows
      groups: [domain_controllers]
      extra_vars:
        telemetry_endpoint: "https://loki.example.com/loki/api/v1/push"

    sliver-setup:
      path: ansible/linux/sliver.yml
      host_type: linux
      nodes: [sliver]
      extra_vars:
        sliver_version: "1.5.42"
        enable_multiplayer: true

    kali-operator:
      path: ansible/linux/kali_setup.yml
      host_type: linux
      groups: [attackers]
      tags: [tools, configs]
```

---

## Agent Platform

Production deployments require agent execution to be separated from the target
topology. The agent platform defines where agents run.

| Property       | Type   | Required | Description                       | Example                              |
| :------------- | :----- | :------- | :-------------------------------- | :----------------------------------- |
| `type`         | String | Yes      | Platform type.                    | `kubernetes`, `docker`, `bare-metal` |
| `name`         | String | Yes      | Platform identifier.              | `agent-cluster`                      |
| `network`      | Object | No       | Network configuration for agents. | `{cidr: 172.16.0.0/16}`              |
| `orchestrator` | Object | No       | Task orchestration system.        | `{type: ray}`                        |
| `storage`      | Object | No       | Shared storage for agent state.   | `{type: redis, url: ...}`            |

### Network Configuration

| Property    | Type   | Required | Description                           | Example         |
| :---------- | :----- | :------- | :------------------------------------ | :-------------- |
| `cidr`      | String | No       | Agent platform network range.         | `172.16.0.0/16` |
| `pod_cidr`  | String | No       | Pod network CIDR (Kubernetes).        | `100.64.0.0/16` |
| `namespace` | String | No       | Kubernetes namespace (if applicable). | `aces-agents`   |

### Orchestrator Configuration

| Property | Type   | Required | Description                       | Example                     |
| :------- | :----- | :------- | :-------------------------------- | :-------------------------- |
| `type`   | String | Yes      | Orchestration framework.          | `ray`, `celery`, `temporal` |
| `config` | Object | No       | Framework-specific configuration. | `{head_service: ray-head}`  |

### Storage Configuration

| Property | Type   | Required | Description      | Example                              |
| :------- | :----- | :------- | :--------------- | :----------------------------------- |
| `type`   | String | Yes      | Storage backend. | `redis`, `postgres`, `s3`            |
| `url`    | String | No       | Connection URL.  | `redis://redis.aces-agents.svc:6379` |

### Agent Platform Example

```yaml
---
agent_platform:
  type: kubernetes
  name: agent-cluster
  network:
    cidr: 172.16.0.0/16
    pod_cidr: 100.64.0.0/16
    namespace: aces-agents
  orchestrator:
    type: ray
    config:
      head_service: ray-head.aces-agents.svc
      dashboard_port: 8265
  storage:
    type: redis
    url: redis://redis.aces-agents.svc:6379
```

---

## Telemetry

The telemetry block defines observability infrastructure for the range. This
includes collection, processing, storage, and visualization of logs, traces,
and metrics. Telemetry is critical for attack simulation analysis and blue
team feedback loops.

| Property            | Type   | Required | Description                                    | Example                              |
| :------------------ | :----- | :------- | :--------------------------------------------- | :----------------------------------- |
| `tracing`           | Object | No       | Distributed tracing configuration.             | `{backend: tempo, endpoint: ...}`    |
| `metrics`           | Object | No       | Metrics collection configuration.              | `{backend: prometheus}`              |
| `logging`           | Object | No       | Log aggregation configuration.                 | `{backend: loki, retention: 14d}`    |
| `collection_points` | Array  | No       | Event collection sources.                      | `[{type: windows_security, ...}]`    |
| `sinks`             | Object | No       | Telemetry destinations (map keyed by name).    | `{local-tempo: {type: otlp}}`        |
| `span_dimensions`   | Array  | No       | Custom span attributes for attack correlation. | `[mitre.tactic, attack_phase]`       |
| `storage`           | Object | No       | Storage tiers and retention.                   | `{hot: {...}, warm: {...}}`          |
| `dashboards`        | Object | No       | Dashboard configurations (map keyed by name).  | `{attack-traces: {type: grafana}}`   |
| `agent`             | Object | No       | Telemetry agent configuration.                 | `{type: alloy, version: 1.6.0}`      |

### Tracing Configuration

| Property            | Type    | Required | Description                        | Example                           |
| :------------------ | :------ | :------- | :--------------------------------- | :-------------------------------- |
| `backend`           | String  | Yes      | Tracing backend.                   | `tempo`, `jaeger`, `zipkin`       |
| `endpoint`          | String  | Yes      | OTLP endpoint for trace ingestion. | `http://tempo.observability:4318` |
| `service_name`      | String  | No       | Default service name for spans.    | `cyber-range`                     |
| `metrics_generator` | Boolean | No       | Generate RED metrics from traces.  | `true`                            |

### Metrics Configuration

| Property          | Type   | Required | Description                 | Example                                       |
| :---------------- | :----- | :------- | :-------------------------- | :-------------------------------------------- |
| `backend`         | String | Yes      | Metrics backend.            | `prometheus`, `thanos`, `mimir`, `cloudwatch` |
| `endpoint`        | String | No       | Remote write endpoint.      | `http://prometheus:9090/api/v1/write`         |
| `scrape_interval` | String | No       | Metric collection interval. | `15s`                                         |
| `retention`       | String | No       | Metrics retention period.   | `30d`                                         |

### Logging Configuration

| Property        | Type   | Required | Description             | Example                                             |
| :-------------- | :----- | :------- | :---------------------- | :-------------------------------------------------- |
| `backend`       | String | Yes      | Logging backend.        | `loki`, `opensearch`, `elasticsearch`, `cloudwatch` |
| `endpoint`      | String | No       | Log ingestion endpoint. | `http://loki-gateway:80/loki/api/v1/push`           |
| `index_pattern` | String | No       | Index naming pattern.   | `range-logs-*`                                      |
| `retention`     | String | No       | Log retention period.   | `14d`                                               |

### Collection Points

Collection points define where telemetry is gathered from nodes in the range.

| Property    | Type   | Required | Description                   | Example                          |
| :---------- | :----- | :------- | :---------------------------- | :------------------------------- |
| `type`      | String | Yes      | Type of events to collect.    | See Collection Types             |
| `nodes`     | Array  | No       | Nodes to collect from.        | `[dc01, dc02]`                   |
| `groups`    | Array  | No       | Groups to collect from.       | `[domain_controllers]`           |
| `namespace` | String | No       | Kubernetes namespace filter.  | `attack-simulation`              |
| `event_ids` | Array  | No       | Specific event IDs (Windows). | `[4624, 4625, 4662, 4768, 4769]` |
| `filter`    | String | No       | Collection filter expression. | `not port 22`                    |
| `format`    | String | No       | Event format.                 | `ocsf`, `ecs`, `raw`             |

#### Collection Types

Supported types: `windows_security`, `syslog`, `kubernetes_logs`, `network_pcap`,
`otel_spans`, `systemd_journal`.

### Sinks

Sinks define where telemetry is shipped. Multiple sinks enable fan-out
patterns for local analysis and external platform integration. Sinks are
defined as a map keyed by name (the unique identifier).

| Property      | Type   | Required | Description                | Example                            |
| :------------ | :----- | :------- | :------------------------- | :--------------------------------- |
| `type`        | String | Yes      | Sink type.                 | `otlp`, `loki`, `prometheus`, `s3` |
| `endpoint`    | String | Yes      | Destination endpoint.      | `http://tempo:4317`                |
| `format`      | String | No       | Output format.             | `ocsf`, `ecs`, `raw`               |
| `credentials` | String | No       | Secret reference for auth. | `secret:platform-api-key`          |
| `batch`       | Object | No       | Batching configuration.    | `{size: 1000, timeout: 5s}`        |

### Span Dimensions

Custom span attributes for attack correlation and metrics generation. Common
dimensions include:

- **MITRE ATT&CK**: `mitre.tactic`, `mitre.technique.id`, `mitre.technique.name`
- **Attack context**: `attack_team`, `attack_phase`, `attack_operation_id`
- **Targeting**: `attack_target_host`, `attack_target_domain`
- **Infrastructure**: `service.namespace`, `deployment.environment`

### Storage Tiers

Storage tiers (`hot`, `warm`, `cold`) define retention policies for different
data temperatures. Each tier specifies:

| Property    | Type   | Required | Description            | Example                            |
| :---------- | :----- | :------- | :--------------------- | :--------------------------------- |
| `type`      | String | Yes      | Storage backend.       | `local`, `s3`, `gcs`, `azure-blob` |
| `retention` | String | Yes      | Data retention period. | `24h`, `30d`, `1y`                 |
| `bucket`    | String | No       | Object storage bucket. | `range-telemetry-archive`          |

### Dashboards

Dashboard configurations for visualization. Dashboards are defined as a map
keyed by name (the unique identifier).

| Property      | Type   | Required | Description                  | Example                         |
| :------------ | :----- | :------- | :--------------------------- | :------------------------------ |
| `type`        | String | Yes      | Dashboard type.              | `grafana`, `kibana`             |
| `source`      | String | No       | Dashboard definition source. | `dashboards/attack-traces.json` |
| `datasources` | Array  | No       | Required datasources.        | `[prometheus, loki, tempo]`     |

### Telemetry Agent Configuration

Configuration for telemetry collection agents deployed to nodes.

| Property  | Type   | Required | Description        | Example                                           |
| :-------- | :----- | :------- | :----------------- | :------------------------------------------------ |
| `type`    | String | No       | Agent type.        | `alloy`, `fluent-bit`, `vector`, `otel-collector` |
| `version` | String | No       | Agent version.     | `1.6.0`                                           |
| `env`     | String | No       | Environment label. | `dev`, `staging`, `prod`                          |

### Telemetry Example

```yaml
---
telemetry:
  # Distributed tracing
  tracing:
    backend: tempo
    endpoint: "http://tempo.observability:4318"
    service_name: ad-range
    metrics_generator: true # Generate RED metrics from traces

  # Metrics collection
  metrics:
    backend: prometheus
    endpoint: "http://prometheus.observability:9090"
    scrape_interval: 15s
    retention: 30d

  # Log aggregation
  logging:
    backend: loki
    endpoint: "http://loki-gateway.observability:80/loki/api/v1/push"
    retention: 14d

  # Telemetry agent
  agent:
    type: alloy
    version: "1.6.0"
    env: dev

  # Collection sources
  collection_points:
    - type: windows_security
      groups: [domain_controllers]
      event_ids: [4624, 4625, 4662, 4768, 4769, 4776]
      format: ocsf

    - type: kubernetes_logs
      namespace: attack-simulation
      format: ecs

    - type: syslog
      groups: [c2_servers, attackers]
      format: ecs

    - type: otel_spans
      namespace: attack-simulation

    - type: network_pcap
      nodes: [core_switch]
      filter: "not port 22"

  # Fan-out to multiple destinations
  sinks:
    local-tempo:
      type: otlp
      endpoint: "http://tempo.observability:4317"

    local-loki:
      type: loki
      endpoint: "http://loki-gateway.observability:80"

    platform-traces:
      type: otlp
      endpoint: "https://platform.example.com/api/otel/traces"
      credentials: secret:platform-api-key
      batch:
        size: 1000
        timeout: 5s

    archive:
      type: s3
      endpoint: "s3://range-telemetry/ad-range/"
      format: ocsf

  # Attack correlation dimensions
  span_dimensions:
    - mitre.tactic
    - mitre.technique.id
    - mitre.technique.name
    - attack_team
    - attack_phase
    - attack_operation_id
    - attack_target_host
    - service.namespace
    - deployment.environment

  # Storage tiers
  storage:
    hot:
      type: local
      retention: 24h
    warm:
      type: s3
      retention: 30d
      bucket: range-telemetry-warm
    cold:
      type: s3
      retention: 1y
      bucket: range-telemetry-archive

  # Dashboards
  dashboards:
    attack-chain-traces:
      type: grafana
      source: dashboards/attack-traces.json
      datasources: [prometheus, loki, tempo]

    blue-team-analysis:
      type: grafana
      source: dashboards/blue-team.json
      datasources: [prometheus, loki]
```

---

## Connectivity

The connectivity block defines how different environments and operators access
the range. This is critical for:

1. **Agent-to-target connectivity**: Agents running in a separate platform
   accessing target nodes
2. **Operator access**: Human operators accessing private instances (no public IPs)
3. **Telemetry egress**: Shipping observability data to external systems

Many ranges deploy nodes in private subnets with no public IP addresses or SSH
access. Connectivity is provided via overlay networks (Tailscale, WireGuard)
or cloud-native solutions (AWS Systems Manager).

| Property          | Type   | Required | Description                                          | Example                            |
| :---------------- | :----- | :------- | :--------------------------------------------------- | :--------------------------------- |
| `overlay`         | Object | No       | Overlay network configuration (Tailscale/WireGuard). | `{type: tailscale, auth_key: ...}` |
| `operator_access` | Object | No       | How operators access private instances.              | `{methods: [vpn, cloud_shell]}`    |
| `connections`     | Object | No       | Environment-to-environment connections (map keyed by name). | `{agents-to-targets: {...}}` |

### VPN / Overlay Network

Overlay networks provide secure connectivity to private instances without
exposing them to the public internet.

| Property           | Type   | Required | Description                              | Example                                                   |
| :----------------- | :----- | :------- | :--------------------------------------- | :-------------------------------------------------------- |
| `type`             | String | Yes      | VPN/overlay type.                        | `tailscale`, `wireguard`, `zerotier`, `nebula`, `openvpn` |
| `auth_key`         | String | No       | Secret reference for auth key.           | `secret:vpn-auth-key`                                     |
| `network_name`     | String | No       | Network/tailnet name.                    | `example.com`                                             |
| `acl_tags`         | Array  | No       | Access control tags (provider-specific). | `[tag:range, tag:operators]`                              |
| `exit_node`        | String | No       | Exit node for internet access.           | `exit-node-01`                                            |
| `advertise_routes` | Array  | No       | Routes to advertise to the overlay.      | `[10.0.0.0/16]`                                           |
| `config`           | Object | No       | Provider-specific configuration.         | See below                                                 |

#### Provider-Specific Configuration

Each VPN provider may have additional settings in the `config` object. Example
for Tailscale:

```yaml
config:
  tailnet: example.com
  acl_tags: [tag:range, tag:operators]
  funnel: false
```

Other providers (WireGuard, Nebula, ZeroTier) follow similar patterns with
provider-specific fields.

### Operator Access

Defines how human operators access range nodes for management, red team
operations, or debugging.

| Property      | Type   | Required | Description                                     | Example                      |
| :------------ | :----- | :------- | :---------------------------------------------- | :--------------------------- |
| `methods`     | Array  | Yes      | Access methods in order of preference.          | `[vpn, cloud_shell, ssh]`    |
| `cloud_shell` | Object | No       | Cloud-managed shell access (SSM, IAP, Bastion). | `{type: ssm, enabled: true}` |
| `vpn`         | Object | No       | VPN-based operator access config.               | `{enabled: true, ssh: true}` |
| `ssh`         | Object | No       | SSH configuration (if enabled).                 | `{enabled: false}`           |
| `vnc`         | Object | No       | VNC access for GUI nodes.                       | `{enabled: true, nodes: []}` |

#### Cloud Shell Configuration

Cloud-managed shell access enables secure connections without SSH keys or open
ports. Type maps to provider services: `ssm` (AWS), `iap` (GCP), `bastion` (Azure).

| Property          | Type    | Required | Description                       | Example                 |
| :---------------- | :------ | :------- | :-------------------------------- | :---------------------- |
| `type`            | String  | Yes      | Cloud shell type.                 | `ssm`, `iap`, `bastion` |
| `enabled`         | Boolean | Yes      | Enable cloud shell access.        | `true`                  |
| `session_logging` | Boolean | No       | Log sessions to cloud storage.    | `true`                  |
| `log_destination` | String  | No       | Bucket/location for session logs. | `range-session-logs`    |

#### VPN Operator Configuration

| Property     | Type    | Required | Description                                    | Example           |
| :----------- | :------ | :------- | :--------------------------------------------- | :---------------- |
| `enabled`    | Boolean | Yes      | Enable VPN access.                             | `true`            |
| `acl_tags`   | Array   | No       | Required ACL tags for operators.               | `[tag:operators]` |
| `ssh`        | Boolean | No       | Enable VPN-native SSH (e.g., Tailscale SSH).   | `true`            |
| `web_access` | Boolean | No       | Enable web UI access (e.g., Tailscale Funnel). | `false`           |

### Connections

Environment-to-environment network connections for agent traffic and telemetry.
Connections are defined as a map keyed by name (the unique identifier).

| Property      | Type   | Required | Description                      | Example                                           |
| :------------ | :----- | :------- | :------------------------------- | :------------------------------------------------ |
| `type`        | String | Yes      | Connectivity mechanism.          | `tailscale`, `wireguard`, `vpc_peering`, `direct` |
| `source`      | Object | Yes      | Source environment details.      | `{environment: agent-cluster, cidr: ...}`         |
| `destination` | Object | Yes      | Destination environment details. | `{environment: ad-range, cidr: ...}`              |
| `policy`      | Object | No       | Traffic policies.                | `{direction: egress_only, allowed_ports: [...]}`  |

#### Source/Destination Configuration

| Property      | Type   | Required | Description                           | Example         |
| :------------ | :----- | :------- | :------------------------------------ | :-------------- |
| `environment` | String | Yes      | Environment name.                     | `agent-cluster` |
| `cidr`        | String | No       | Network range.                        | `172.16.0.0/16` |
| `namespace`   | String | No       | Kubernetes namespace (if applicable). | `aces-agents`   |

#### Policy Configuration

| Property        | Type   | Required | Description                | Example                        |
| :-------------- | :----- | :------- | :------------------------- | :----------------------------- |
| `direction`     | String | No       | Traffic direction allowed. | `egress_only`, `bidirectional` |
| `allowed_ports` | Array  | No       | Ports permitted.           | `[22, 445, 389, 636, 88, 135]` |
| `denied_ports`  | Array  | No       | Ports explicitly blocked.  | `[3389]`                       |

### Connectivity Example

```yaml
---
connectivity:
  # VPN/Overlay network for private access
  overlay:
    type: tailscale # or: wireguard, zerotier, nebula, openvpn
    auth_key: secret:vpn-auth-key
    network_name: example.com
    acl_tags: [tag:range, tag:operators, tag:agents]
    advertise_routes: [10.0.0.0/16]
    config: # Provider-specific settings
      funnel: false

  # Operator access to private instances
  operator_access:
    methods: [vpn, cloud_shell] # Prefer VPN, fallback to cloud shell

    cloud_shell:
      type: ssm # or: iap (GCP), bastion (Azure)
      enabled: true
      session_logging: true
      log_destination: range-session-logs

    vpn:
      enabled: true
      acl_tags: [tag:operators]
      ssh: true # VPN-native SSH (e.g., Tailscale SSH)

    vnc:
      enabled: true
      nodes: [kali-01] # VNC access for GUI workstations

  # Environment-to-environment connections
  connections:
    agents-to-targets:
      type: tailscale
      source:
        environment: agent-cluster
        cidr: 172.16.0.0/16
        namespace: aces-agents
      destination:
        environment: ad-range
        cidr: 10.0.0.0/16
      policy:
        direction: egress_only
        allowed_ports: [22, 445, 389, 636, 88, 135, 139, 5985, 5986]

    telemetry-ingestion:
      type: vpc_peering
      source:
        environment: ad-range
        cidr: 10.0.0.0/16
      destination:
        environment: observability
        cidr: 172.20.0.0/16
      policy:
        direction: egress_only
        allowed_ports: [4317, 4318, 3100, 9090]
```

---

## Alternatives Considered

1. **JSON Schema Only**: Rejected because YAML is more human-readable and
   supports comments.
2. **Pulumi/CDK-style Imperative**: Rejected because declarative specs are
   easier to version, diff, and validate.
3. **Combined Range + Experiment**: Rejected to enable range reuse across
   multiple experiments.
4. **Embedded Provisioning in Bindings**: Rejected to keep resource mapping
   separate from configuration management.

## Affected Repos

| Repository              | Changes Required                                                          |
| :---------------------- | :------------------------------------------------------------------------ |
| `aces-schema`           | JSON Schema and validation for CyberRange kind                            |
| `aces-runtime`          | Support for agent platform, telemetry, connectivity                       |
| `aces-provider-aws`     | Image filters, instance policies, security groups, private service access |
| `aces-provider-gcp`     | Image filters, IAM bindings, firewall rules, Private Service Connect      |
| `aces-provider-azure`   | Image filters, RBAC, NSGs, Private Link                                   |
| `aces-provider-docker`  | Resource profiles, networking                                             |
| `aces-provider-proxmox` | Resource profiles, VM templates                                           |
| `aces-provisioner`      | Ansible playbook execution via cloud shell/SSH                            |

## Consequences

### What Becomes Easier

- **Range reuse**: Same infrastructure supports multiple experiments
- **Independent versioning**: Infrastructure changes tracked separately from
  experiment changes
- **Provider flexibility**: Topology decoupled from instantiation backend
- **Team collaboration**: Infrastructure team can define ranges, research team
  defines experiments
- **Provisioning clarity**: Clear separation between infra creation and configuration

### What Becomes Harder

- **Simple scenarios**: Requires two files (range + experiment) instead of one
- **Learning curve**: Must understand range/experiment separation
- **Cloud specificity**: Some resource fields (e.g., image filters, instance
  policies) are cloud-specific (mitigated by provider abstraction)

---

## Appendix A: Provider Mappings

This appendix contains cloud provider-specific service and policy mappings.

### Provider-Specific Private Service Access

| Endpoint            | AWS                             | GCP            | Azure         |
| :------------------ | :------------------------------ | :------------- | :------------ |
| `remote_management` | SSM, SSM Messages, EC2 Messages | IAP            | Bastion       |
| `storage`           | S3                              | Cloud Storage  | Blob Storage  |
| `file_storage`      | EFS                             | Filestore      | Azure Files   |
| `secrets`           | Secrets Manager                 | Secret Manager | Key Vault     |
| `logs`              | CloudWatch Logs                 | Cloud Logging  | Log Analytics |

### Instance Policy Capabilities

| Capability          | AWS                            | GCP                                | Azure                          |
| :------------------ | :----------------------------- | :--------------------------------- | :----------------------------- |
| `remote_management` | `AmazonSSMManagedInstanceCore` | `roles/iap.tunnelResourceAccessor` | `Virtual Machine User Login`   |
| `metrics_logs`      | `CloudWatchAgentServerPolicy`  | `roles/logging.logWriter`          | `Monitoring Metrics Publisher` |
| `storage_read`      | `AmazonS3ReadOnlyAccess`       | `roles/storage.objectViewer`       | `Storage Blob Data Reader`     |
