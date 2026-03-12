# RFC-0001: Environment Infrastructure Specification

## Status

`Draft`

## Summary

This RFC proposes a declarative YAML specification for defining reproducible
infrastructure environments. This enables seamless ingestion by orchestration
tools and execution via compatible runtimes within the Agentic Cyber Environment
System (ACES).

An environment defines "what exists" - the topology, resources, telemetry, and
connectivity that agents operate within. Experiments (RFC-0002) define "what
happens" within these environments.

## Motivation

For ACES to serve as an open reference architecture for autonomous AI agent
research, it requires a standardized, framework-agnostic language to express
environments. The specification must support:

1. Multiple instantiation backends (Docker, cloud providers, hypervisors)
2. Complex topologies with realistic network conditions
3. Observable infrastructure with telemetry collection
4. Separation of agent execution from target environments

### Design Principles

1. **Infrastructure Focus**: Environments define "what exists", not "what happens"
2. **Reusability**: The same environment can host multiple experiments
3. **Provider Agnostic**: Topology is separate from instantiation backend
4. **Observable**: Telemetry collection is configured at the infrastructure level
5. **Extensible**: Core schema supports domain-specific extensions

---

## Type Definitions

The following shared types are referenced throughout this specification.

| Type | Kind | Values |
|:-----|:-----|:-------|
| `OS` | extensible-enum | `linux`, `windows`, `macos`, `freebsd` |
| `NodeType` | extensible-enum | `host`, `container`, `router`, `switch`, `firewall` |
| `Routing` | extensible-enum | `isolated`, `nat`, `bridged` |
| `Tier` | extensible-enum | `critical`, `high`, `medium`, `low` |
| `Role` | growing | `server`, `workstation`, `router`, `database`, `web`, `domain_controller`, `gateway`, `dns_server`, `mail_server`, `file_server` |
| `Provisioner` | growing | `terraform`, `ansible`, `docker`, `proxmox`, `cloud_init` |
| `CollectionType` | growing | `syslog`, `journald`, `file`, `kubernetes_logs`, `otel_spans`, `metrics`, `events`, `windows_security`, `network_pcap` |

**Note:** Scenario-specific roles (`attacker`, `target`, `c2_server`, `redirector`, etc.)
belong in RFC-0002 (Experiment Specification), not here. Infrastructure roles describe
what a node *is*; scenario roles describe what a node *does* in a specific experiment.

**Kind definitions:**

- **`extensible-enum`**: A closed list of standard values. Custom values are allowed using the `x-` prefix (e.g., `x-myos`).
- **`growing`**: An open list where new standard values are expected to be added over time.

---

## Schema Overview

| Section          | Purpose                                                              |
|:-----------------|:---------------------------------------------------------------------|
| `topology`       | Logical structure of networks, nodes, and edges                      |
| `groups`         | Logical grouping of nodes by role, function, or deployment           |
| `resources`      | Infrastructure bindings, compute profiles, and image configuration   |
| `provisioning`   | Post-deployment configuration and automation                         |
| `agent_platform` | Where agents execute (separate from target topology)                 |
| `telemetry`      | Observability: logs, traces, metrics, storage tiers, and sinks       |
| `connectivity`   | Overlay networks, operator access, and environment connections       |

---

## Root Schema

| Field            | Type   | Required | Description                                    | Example                         |
|:-----------------|:-------|:---------|:-----------------------------------------------|:--------------------------------|
| `apiVersion`     | String | Yes      | Schema version.                                | `aces.io/v1alpha1`              |
| `kind`           | String | Yes      | Resource type.                                 | `Environment`                   |
| `metadata`       | Object | Yes      | Identifying information.                       | `{name, description, version}`  |
| `topology`       | Object | Yes      | Logical definition of networks, nodes, edges.  | `{networks: {}, nodes: {}}`     |
| `groups`         | Object | No       | Logical grouping of nodes.                     | `{servers: {...}}`              |
| `resources`      | Object | No       | Compute profiles and resource bindings.        | `{profiles: {}, bindings: {}}`  |
| `provisioning`   | Object | No       | Post-deployment configuration.                 | `{method: ansible}`             |
| `agent_platform` | Object | No       | Platform where agents execute.                 | `{type: kubernetes}`            |
| `telemetry`      | Object | No       | Observability configuration.                   | `{logging: {}, tracing: {}}`    |
| `connectivity`   | Object | No       | Network connectivity configuration.            | `{overlay: {}, connections: {}}`|

### Example

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Environment
metadata:
  name: dev-environment
  description: "Development environment for agent experiments"
  version: "1.0.0"
  labels:
    team: research
    purpose: development

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

The topology block defines the logical structure of the environment - networks,
nodes, and the connections between them.

### Networks

Networks represent broadcast domains, subnets, or switching fabrics.

Networks are defined as a map keyed by name (the unique identifier).

| Property                 | Type    | Required | Description                              | Example                     |
|:-------------------------|:--------|:---------|:-----------------------------------------|:----------------------------|
| `display_name`           | String  | No       | Human-readable label.                    | `Internal Network`          |
| `cidr`                   | String  | Yes      | IPv4/IPv6 subnet.                        | `10.0.0.0/16`               |
| `routing`                | String  | No       | Routing mode.                            | `isolated`, `nat`, `bridged`|
| `vlan_id`                | Integer | No       | VLAN identifier.                         | `100`                       |
| `secondary_cidr`         | String  | No       | Secondary CIDR (e.g., pod networking).   | `100.64.0.0/16`             |
| `private_service_access` | Array   | No       | Managed service connectivity.            | `[storage, logs]`           |
| `labels`                 | Object  | No       | Arbitrary key-value labels.              | `{zone: dmz}`               |

#### Private Service Access

Cloud-native private connectivity to managed services:
`remote_management`, `storage`, `file_storage`, `secrets`, `logs`

See [Appendix B](#appendix-b-provider-mappings) for provider-specific mappings.

#### Networks Example

```yaml
topology:
  networks:
    internal:
      display_name: "Internal Network"
      cidr: 10.0.0.0/16
      routing: nat
      private_service_access: [storage, logs]

    services:
      display_name: "Services Network"
      cidr: 10.1.0.0/24
      routing: isolated
      vlan_id: 10
      labels:
        tier: backend
```

### Nodes

Nodes represent compute instances, containers, or devices in the environment.

Nodes are defined as a map keyed by name (the unique identifier).

| Property           | Type        | Required | Description                              | Example                     |
|:-------------------|:------------|:---------|:-----------------------------------------|:----------------------------|
| `type`             | NodeType    | Yes      | Node type.                               | see [Type Definitions](#type-definitions) |
| `display_name`     | String      | No       | Human-readable label.                    | `Web Server`                |
| `hostname`         | String      | No       | Hostname as seen in the OS.              | `web-01`                    |
| `computer_name`    | String      | No       | NetBIOS/short name (Windows).            | `DC01`                      |
| `os`               | OS          | No       | Operating system.                        | see [Type Definitions](#type-definitions) |
| `os_version`       | String      | No       | OS version.                              | `22.04`, `2022`             |
| `os_distribution`  | String      | No       | Distribution (Linux).                    | `ubuntu`, `debian`, `rhel`  |
| `role`             | Role        | No       | Functional role within the environment.  | see [Type Definitions](#type-definitions) |
| `tier`             | Tier        | No       | Criticality tier for targeting/defense.  | see [Type Definitions](#type-definitions) |
| `domain`           | String      | No       | Domain membership (e.g., AD environments).| `corp.local`               |
| `groups`           | Array       | No       | Group memberships.                       | `[servers, web]`            |
| `services`         | Array       | No       | Services running on this node.           | `[http, ssh]`               |
| `network_interfaces`| Array      | Yes      | Network interface definitions.           | See NetworkInterface        |
| `provisioner`      | Provisioner | No       | Provisioning tool.                       | see [Type Definitions](#type-definitions) |
| `provisioner_id`   | String      | No       | ID within provisioner system.            | `web-01`                    |
| `owner`            | String      | No       | Responsible team or operator.            | `platform-team`             |
| `features`         | Array       | No       | Capabilities or flags.                   | `[gpu, vnc_access]`         |
| `labels`           | Object      | No       | Arbitrary key-value labels.              | `{app: nginx, env: prod}`   |
| `notes`            | String      | No       | Freeform documentation.                  | `Primary web server`        |

**Note:** The `role`, `tier`, and `domain` fields provide validated, typed alternatives
to using labels. Use these fields when you want schema validation; use `labels` for
arbitrary metadata not covered by typed fields.

#### NetworkInterface

| Property     | Type    | Required | Description                     | Example             |
|:-------------|:--------|:---------|:--------------------------------|:--------------------|
| `name`       | String  | Yes      | Interface name.                 | `eth0`              |
| `network`    | String  | Yes      | Reference to network name.      | `internal`          |
| `dhcp`       | Boolean | No       | Use DHCP.                       | `true`              |
| `ip_address` | String  | No       | Static IP address.              | `10.0.1.10/24`      |
| `hw_address` | String  | No       | MAC address.                    | `DE:AD:BE:EF:00:01` |

#### Nodes Example

```yaml
topology:
  nodes:
    web-01:
      type: host
      display_name: "Web Server"
      hostname: web-01
      os: linux
      os_distribution: ubuntu
      os_version: "22.04"
      role: web                    # Typed field (validated)
      tier: medium
      groups: [servers, web]
      services: [http, https, ssh]
      labels:
        app: nginx                 # Custom metadata via labels
      network_interfaces:
        - name: eth0
          network: internal
          ip_address: 10.0.1.10/24

    db-01:
      type: host
      display_name: "Database Server"
      hostname: db-01
      os: linux
      os_distribution: ubuntu
      os_version: "22.04"
      role: database
      tier: high
      groups: [servers, database]
      services: [postgresql, ssh]
      network_interfaces:
        - name: eth0
          network: services
          ip_address: 10.1.0.10/24

    dc01:
      type: host
      display_name: "Primary Domain Controller"
      hostname: dc01
      computer_name: DC01          # NetBIOS name
      os: windows
      os_version: "2022"
      role: domain_controller      # Infrastructure role
      tier: critical
      domain: corp.local           # AD domain membership
      groups: [domain_controllers, tier0]
      services: [ldap, kerberos, dns, smb]
      network_interfaces:
        - name: eth0
          network: domain-subnet
          ip_address: 10.0.10.10/24

    kali-01:
      type: host
      hostname: kali-01
      os: linux
      os_distribution: kali
      role: workstation            # Infrastructure role (scenario role assigned in Experiment)
      groups: [linux, operator_workstations]
      features: [vnc_access, tools_installed]
      network_interfaces:
        - name: eth0
          network: internal
          dhcp: true
```

### Edges

Edges define link-layer constraints between nodes, allowing simulation of
realistic network conditions.

| Property      | Type   | Required | Description                    | Example                     |
|:--------------|:-------|:---------|:-------------------------------|:----------------------------|
| `endpoints`   | Tuple  | Yes      | Nodes forming the edge.        | `[router-01, server-01]`    |
| `latency`     | String | No       | Simulated delay.               | `50ms`                      |
| `packet_loss` | Float  | No       | Packet loss percentage.        | `0.05`                      |
| `bandwidth`   | String | No       | Maximum bandwidth.             | `1Gbps`                     |

#### Edges Example

```yaml
topology:
  edges:
    - endpoints: [router-hq, router-branch]
      latency: 50ms
      packet_loss: 0.01
      bandwidth: 100Mbps

    - endpoints: [switch-01, workstation-01]
      bandwidth: 100Mbps
```

---

## Groups

Groups provide logical organization of nodes by function, deployment method, or
any other criteria. Groups enable bulk operations and targeting.

Groups are defined as a map keyed by name (the unique identifier).

| Property      | Type        | Required | Description                                 | Example                    |
|:--------------|:------------|:---------|:--------------------------------------------|:---------------------------|
| `display_name`| String      | No       | Human-readable label.                       | `Web Servers`              |
| `description` | String      | No       | Description.                                | `All web-facing servers`   |
| `type`        | String      | No       | Grouping strategy.                          | `functional`, `deployment`, `role-based`, `os-based`, `infrastructure` |
| `tier`        | Tier        | No       | Default criticality tier for group members. | see [Type Definitions](#type-definitions) |
| `provisioner` | Provisioner | No       | Tool that created these nodes.              | see [Type Definitions](#type-definitions) |
| `members`     | Array       | No       | Explicit list of node names.                | `[web-01, web-02]`         |
| `labels`      | Object      | No       | Arbitrary key-value labels.                 | `{env: production}`        |

### Groups Example

```yaml
groups:
  servers:
    description: "All server nodes"
    type: functional

  web:
    description: "Web servers"
    type: role-based
    members: [web-01, web-02]

  database:
    description: "Database servers"
    type: role-based
    members: [db-01]

  domain_controllers:
    description: "Active Directory domain controllers"
    type: role-based
    tier: critical

  tier0:
    description: "Tier 0 - Domain Admin level systems"
    type: infrastructure
    tier: critical
    labels:
      ad.tier: "0"

  operator_workstations:
    description: "Operator workstations (role assigned per experiment)"
    type: functional
    members: [kali-01, kali-02]

  terraform-managed:
    description: "Nodes managed by Terraform"
    type: deployment
    provisioner: terraform
```

---

## Resources

The resources block maps logical topology to physical or virtual infrastructure.
This separation allows the same topology to run on different backends.

### Profiles

Standardized compute configurations.

Profiles are defined as a map keyed by name (the unique identifier).

| Property        | Type    | Required | Description              | Example              |
|:----------------|:--------|:---------|:-------------------------|:---------------------|
| `instance_type` | String  | No       | Cloud instance type.     | `t3.medium`          |
| `cpus`          | Integer | No       | vCPU count.              | `4`                  |
| `memory`        | String  | No       | RAM allocation.          | `8Gi`                |
| `gpus`          | Integer | No       | GPU count.               | `1`                  |
| `volume`        | Object  | No       | Root volume config.      | See Volume           |

#### Volume

| Property    | Type    | Required | Description             | Example     |
|:------------|:--------|:---------|:------------------------|:------------|
| `size`      | String  | No       | Volume size.            | `100Gi`     |
| `type`      | String  | No       | Volume type.            | `gp3`, `ssd`|
| `encrypted` | Boolean | No       | Enable encryption.      | `true`      |
| `iops`      | Integer | No       | Provisioned IOPS.       | `3000`      |

### Image Filters

Defines how to select machine images for cloud deployments.

Image filters are defined as a map keyed by name (the unique identifier).

| Property      | Type    | Required | Description                    | Example                  |
|:--------------|:--------|:---------|:-------------------------------|:-------------------------|
| `owners`      | Array   | No       | Image owner account IDs.       | `[amazon, 099720109477]` |
| `filters`     | Object  | Yes      | Filter criteria.               | See below                |
| `most_recent` | Boolean | No       | Select most recent match.      | `true`                   |

#### Filter Criteria

| Property              | Type   | Description              | Example                              |
|:----------------------|:-------|:-------------------------|:-------------------------------------|
| `name`                | String | Image name pattern.      | `ubuntu/images/hvm-ssd/ubuntu-*`     |
| `virtualization-type` | String | Virtualization type.     | `hvm`                                |
| `root-device-type`    | String | Root device type.        | `ebs`                                |
| `architecture`        | String | CPU architecture.        | `x86_64`, `arm64`                    |

### Instance Policies

IAM/service account policies for instances.

Policies are defined as a map keyed by name (the unique identifier).

| Property           | Type  | Required | Description                          | Example                        |
|:-------------------|:------|:---------|:-------------------------------------|:-------------------------------|
| `capabilities`     | Array | No       | Abstract capabilities.               | `[remote_management, logs]`    |
| `managed_policies` | Array | No       | Provider-specific managed policies.  | `[AmazonSSMManagedInstanceCore]`|
| `inline_policies`  | Array | No       | Custom inline policies.              | `[{name: ..., document: ...}]` |

### Security Groups

Network security rules for nodes.

Security groups are defined as a map keyed by name (the unique identifier).

| Property      | Type   | Required | Description          | Example             |
|:--------------|:-------|:---------|:---------------------|:--------------------|
| `description` | String | No       | Description.         | `Web server access` |
| `ingress`     | Array  | No       | Inbound rules.       | See Rule            |
| `egress`      | Array  | No       | Outbound rules.      | See Rule            |

#### Rule

| Property          | Type    | Required | Description               | Example            |
|:------------------|:--------|:---------|:--------------------------|:-------------------|
| `protocol`        | String  | Yes      | Protocol.                 | `tcp`, `udp`, `-1` |
| `from_port`       | Integer | No       | Start port.               | `80`               |
| `to_port`         | Integer | No       | End port.                 | `80`               |
| `cidr_blocks`     | Array   | No       | Source/destination CIDRs. | `[10.0.0.0/16]`    |
| `security_groups` | Array   | No       | Source/dest SGs.          | `[web-sg]`         |
| `description`     | String  | No       | Rule description.         | `HTTP from VPC`    |

### Bindings

Maps nodes to profiles, images, and policies.

Bindings are defined as a map keyed by node name.

| Property          | Type   | Required | Description                     | Example                |
|:------------------|:-------|:---------|:--------------------------------|:-----------------------|
| `image`           | String | No       | Direct image URI/ID.            | `ami-0abc123`          |
| `image_filter`    | String | No       | Reference to image filter.      | `ubuntu-22.04`         |
| `profile`         | String | No       | Reference to resource profile.  | `standard`             |
| `instance_policy` | String | No       | Reference to instance policy.   | `base-policy`          |
| `security_groups` | Array  | No       | Security group references.      | `[internal, web]`      |
| `user_data`       | String | No       | Path to user data template.     | `templates/init.sh`    |

### Resources Example

```yaml
resources:
  profiles:
    standard:
      instance_type: t3.medium
      volume:
        size: 50Gi
        type: gp3
        encrypted: true

    large:
      instance_type: t3.large
      volume:
        size: 100Gi
        type: gp3
        encrypted: true

    gpu:
      instance_type: g4dn.xlarge
      gpus: 1
      volume:
        size: 100Gi

  image_filters:
    ubuntu-22.04:
      owners: [099720109477]
      most_recent: true
      filters:
        name: "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
        architecture: x86_64

  instance_policies:
    base:
      capabilities: [remote_management, logs]

  security_groups:
    internal:
      description: "Internal traffic"
      ingress:
        - protocol: "-1"
          cidr_blocks: [10.0.0.0/8]
      egress:
        - protocol: "-1"
          cidr_blocks: [0.0.0.0/0]

    web:
      description: "Web server access"
      ingress:
        - protocol: tcp
          from_port: 80
          to_port: 80
          cidr_blocks: [0.0.0.0/0]
        - protocol: tcp
          from_port: 443
          to_port: 443
          cidr_blocks: [0.0.0.0/0]

  bindings:
    web-01:
      image_filter: ubuntu-22.04
      profile: standard
      instance_policy: base
      security_groups: [internal, web]

    db-01:
      image_filter: ubuntu-22.04
      profile: large
      instance_policy: base
      security_groups: [internal]
```

---

## Provisioning

Post-deployment configuration for nodes.

| Property    | Type   | Required | Description              | Example                    |
|:------------|:-------|:---------|:-------------------------|:---------------------------|
| `method`    | String | Yes      | Provisioning method.     | See Methods                |
| `playbooks` | Object | No       | Ansible playbook defs.   | `{setup: {...}}`           |
| `templates` | Object | No       | User data templates.     | `{init: {...}}`            |

### Methods

| Method                | Description                           | Use Case                     |
|:----------------------|:--------------------------------------|:-----------------------------|
| `cloud_shell_ansible` | Ansible via cloud shell (SSM/IAP)     | Cloud instances, no SSH      |
| `ssh_ansible`         | Ansible via SSH                       | SSH-accessible nodes         |
| `cloud_init`          | Cloud-init user data only             | Simple bootstrapping         |
| `none`                | No post-deployment provisioning       | Pre-baked images             |

### Playbook

| Property     | Type   | Required | Description              | Example                    |
|:-------------|:-------|:---------|:-------------------------|:---------------------------|
| `path`       | String | Yes      | Path to playbook file.   | `ansible/setup.yml`        |
| `host_type`  | String | No       | Target OS type.          | `linux`, `windows`         |
| `groups`     | Array  | No       | Target groups.           | `[servers]`                |
| `nodes`      | Array  | No       | Target nodes.            | `[web-01]`                 |
| `extra_vars` | Object | No       | Additional variables.    | `{env: prod}`              |
| `tags`       | Array  | No       | Ansible tags to run.     | `[install, configure]`     |

### Provisioning Example

```yaml
provisioning:
  method: cloud_shell_ansible

  templates:
    linux-init:
      path: templates/linux-init.sh
      type: bash
      variables:
        install_monitoring: true

  playbooks:
    base-setup:
      path: ansible/base.yml
      host_type: linux
      groups: [servers]

    web-setup:
      path: ansible/web.yml
      host_type: linux
      groups: [web]
      extra_vars:
        nginx_version: "1.24"
```

---

## Agent Platform

Defines where agents execute. Agent execution is separated from the target
environment to enable controlled observation and action.

| Property       | Type   | Required | Description                       | Example                  |
|:---------------|:-------|:---------|:----------------------------------|:-------------------------|
| `type`         | String | Yes      | Platform type.                    | `kubernetes`, `docker`   |
| `name`         | String | Yes      | Platform identifier.              | `agent-cluster`          |
| `network`      | Object | No       | Network configuration.            | `{cidr: 172.16.0.0/16}`  |
| `orchestrator` | Object | No       | Task orchestration system.        | `{type: ray}`            |
| `storage`      | Object | No       | Shared storage for agent state.   | `{type: redis}`          |

### Network Configuration

| Property    | Type   | Required | Description                    | Example         |
|:------------|:-------|:---------|:-------------------------------|:----------------|
| `cidr`      | String | No       | Agent platform network range.  | `172.16.0.0/16` |
| `pod_cidr`  | String | No       | Pod CIDR (Kubernetes).         | `100.64.0.0/16` |
| `namespace` | String | No       | Kubernetes namespace.          | `agents`        |

### Orchestrator

| Property | Type   | Required | Description              | Example                  |
|:---------|:-------|:---------|:-------------------------|:-------------------------|
| `type`   | String | Yes      | Orchestration framework. | `ray`, `celery`, `temporal` |
| `config` | Object | No       | Framework-specific config.| `{head_service: ...}`   |

### Storage

| Property | Type   | Required | Description      | Example                 |
|:---------|:-------|:---------|:-----------------|:------------------------|
| `type`   | String | Yes      | Storage backend. | `redis`, `postgres`, `s3` |
| `url`    | String | No       | Connection URL.  | `redis://redis:6379`    |

### Agent Platform Example

```yaml
agent_platform:
  type: kubernetes
  name: agent-cluster
  network:
    cidr: 172.16.0.0/16
    pod_cidr: 100.64.0.0/16
    namespace: agents
  orchestrator:
    type: ray
    config:
      head_service: ray-head.agents.svc
      dashboard_port: 8265
  storage:
    type: redis
    url: redis://redis.agents.svc:6379
```

---

## Telemetry

Observability infrastructure for the environment. Telemetry enables agents to
observe environment state and enables experiment evaluation.

| Property            | Type   | Required | Description                         | Example                    |
|:--------------------|:-------|:---------|:------------------------------------|:---------------------------|
| `tracing`           | Object | No       | Distributed tracing config.         | `{backend: tempo}`         |
| `metrics`           | Object | No       | Metrics collection config.          | `{backend: prometheus}`    |
| `logging`           | Object | No       | Log aggregation config.             | `{backend: loki}`          |
| `collection_points` | Array  | No       | Event collection sources.           | `[{type: syslog, ...}]`    |
| `sinks`             | Object | No       | Telemetry destinations.             | `{loki: {...}}`            |
| `span_dimensions`   | Array  | No       | Custom span attributes for correlation. | `[mitre.tactic, attack_phase]` |
| `dashboards`        | Object | No       | Dashboard configurations.           | `{overview: {...}}`        |
| `schema`            | Object | No       | Reference to RFC-0003 schema.       | `{version: 1.0.0}`         |
| `storage`           | Object | No       | Storage tiers and retention.        | `{hot: {...}, warm: {...}}`|
| `agent`             | Object | No       | Telemetry agent configuration.      | `{type: alloy}`            |

### Tracing

| Property            | Type    | Required | Description                    | Example                     |
|:--------------------|:--------|:---------|:-------------------------------|:----------------------------|
| `backend`           | String  | Yes      | Tracing backend.               | `tempo`, `jaeger`, `zipkin` |
| `endpoint`          | String  | Yes      | OTLP endpoint.                 | `http://tempo:4318`         |
| `service_name`      | String  | No       | Default service name.          | `environment`               |
| `metrics_generator` | Boolean | No       | Generate metrics from traces.  | `true`                      |

### Metrics

| Property          | Type   | Required | Description              | Example                       |
|:------------------|:-------|:---------|:-------------------------|:------------------------------|
| `backend`         | String | Yes      | Metrics backend.         | `prometheus`, `mimir`         |
| `endpoint`        | String | No       | Remote write endpoint.   | `http://prometheus:9090`      |
| `scrape_interval` | String | No       | Collection interval.     | `15s`                         |
| `retention`       | String | No       | Retention period.        | `30d`                         |

### Logging

| Property        | Type   | Required | Description          | Example                     |
|:----------------|:-------|:---------|:---------------------|:----------------------------|
| `backend`       | String | Yes      | Logging backend.     | `loki`, `elasticsearch`     |
| `endpoint`      | String | No       | Ingestion endpoint.  | `http://loki:3100`          |
| `index_pattern` | String | No       | Index naming.        | `logs-*`                    |
| `retention`     | String | No       | Retention period.    | `14d`                       |

### Collection Points

Sources of telemetry data from nodes.

| Property    | Type   | Required | Description                        | Example                          |
|:------------|:-------|:---------|:-----------------------------------|:---------------------------------|
| `type`      | String | Yes      | Collection type.                   | See Types                        |
| `nodes`     | Array  | No       | Nodes to collect from.             | `[web-01, db-01]`                |
| `groups`    | Array  | No       | Groups to collect from.            | `[servers]`                      |
| `namespace` | String | No       | Kubernetes namespace.              | `default`                        |
| `event_ids` | Array  | No       | Specific event IDs (Windows).      | `[4624, 4625, 4768, 4769]`       |
| `filter`    | String | No       | Collection filter.                 | `severity >= warning`            |
| `format`    | String | No       | Event format.                      | `json`, `ocsf`, `ecs`            |

#### Collection Types

| Type              | Description                              |
|:------------------|:-----------------------------------------|
| `syslog`          | System logs                              |
| `journald`        | Systemd journal                          |
| `file`            | File-based logs                          |
| `kubernetes_logs` | Kubernetes container logs                |
| `otel_spans`      | OpenTelemetry spans                      |
| `metrics`         | Prometheus metrics                       |
| `events`          | System/application events                |
| `windows_security`| Windows Security Event Log               |
| `network_pcap`    | Network packet capture                   |

For security-focused environments, `windows_security` and `network_pcap` enable
collection of security-relevant telemetry. Windows Security events can be filtered
by Event ID (e.g., `event_ids: [4624, 4625, 4768]` for authentication events).

### Sinks

Telemetry destinations. Sinks are defined as a map keyed by name.

| Property      | Type   | Required | Description            | Example                    |
|:--------------|:-------|:---------|:-----------------------|:---------------------------|
| `type`        | String | Yes      | Sink type.             | `otlp`, `loki`, `prometheus` |
| `endpoint`    | String | Yes      | Destination endpoint.  | `http://tempo:4317`        |
| `format`      | String | No       | Output format.         | `json`, `ocsf`             |
| `credentials` | String | No       | Secret reference.      | `secret:api-key`           |
| `batch`       | Object | No       | Batching config.       | `{size: 1000, timeout: 5s}`|

### Span Dimensions

Custom span attributes enable correlation across traces.

Common infrastructure dimensions:

| Category | Dimensions |
|:---------|:-----------|
| **Service** | `service.name`, `service.namespace`, `service.version` |
| **Host** | `host.name`, `host.id`, `host.type` |
| **Deployment** | `deployment.environment`, `deployment.name` |

Scenario-specific dimensions (e.g., `mitre.tactic`, `attack_phase`, `attack_team`)
are defined in RFC-0002 experiments. When `schema.extensions` includes `security`,
additional security-related dimensions are available per RFC-0003.

### Dashboards

Dashboard configurations for visualization.

Dashboards are defined as a map keyed by name (the unique identifier).

| Property      | Type   | Required | Description                  | Example                    |
|:--------------|:-------|:---------|:-----------------------------|:---------------------------|
| `type`        | String | Yes      | Dashboard type.              | `grafana`, `kibana`        |
| `source`      | String | No       | Dashboard definition source. | `dashboards/overview.json` |
| `datasources` | Array  | No       | Required datasources.        | `[prometheus, loki, tempo]`|

### Storage Tiers

| Property    | Type   | Required | Description         | Example                  |
|:------------|:-------|:---------|:--------------------|:-------------------------|
| `type`      | String | Yes      | Storage backend.    | `local`, `s3`, `gcs`     |
| `retention` | String | Yes      | Retention period.   | `24h`, `30d`, `1y`       |
| `bucket`    | String | No       | Object storage bucket.| `telemetry-archive`    |

### Telemetry Example

```yaml
telemetry:
  tracing:
    backend: tempo
    endpoint: "http://tempo:4318"
    service_name: environment
    metrics_generator: true

  metrics:
    backend: prometheus
    endpoint: "http://prometheus:9090"
    scrape_interval: 15s
    retention: 30d

  logging:
    backend: loki
    endpoint: "http://loki:3100/loki/api/v1/push"
    retention: 14d

  agent:
    type: alloy
    version: "1.6.0"

  collection_points:
    - type: syslog
      groups: [servers]
      format: json

    - type: windows_security
      groups: [domain_controllers]
      event_ids: [4624, 4625, 4662, 4768, 4769]
      format: ocsf

    - type: network_pcap
      nodes: [core_switch]
      filter: "not port 22"

    - type: kubernetes_logs
      namespace: agents

    - type: otel_spans
      namespace: agents

  sinks:
    loki:
      type: loki
      endpoint: "http://loki:3100"

    tempo:
      type: otlp
      endpoint: "http://tempo:4317"

    prometheus:
      type: prometheus
      endpoint: "http://prometheus:9090"

  # Infrastructure span dimensions (scenario dimensions defined in RFC-0002)
  span_dimensions:
    - service.name
    - service.namespace
    - host.name
    - deployment.environment

  dashboards:
    environment-overview:
      type: grafana
      source: dashboards/overview.json
      datasources: [prometheus, loki, tempo]

    security-events:
      type: grafana
      source: dashboards/security.json
      datasources: [loki, tempo]

  schema:
    ref: "aces.io/schema/v1"
    extensions: [security]   # Enables security attributes per RFC-0003

  storage:
    hot:
      type: local
      retention: 24h
    warm:
      type: s3
      retention: 30d
      bucket: telemetry-warm
    cold:
      type: s3
      retention: 1y
      bucket: telemetry-archive
```

---

## Connectivity

Defines how environments connect to each other, how agents access targets, and
how operators access nodes.

| Property          | Type   | Required | Description                          | Example                  |
|:------------------|:-------|:---------|:-------------------------------------|:-------------------------|
| `overlay`         | Object | No       | Overlay network (VPN/mesh).          | `{type: tailscale}`      |
| `operator_access` | Object | No       | How operators access nodes.          | `{methods: [vpn, ssh]}`  |
| `connections`     | Object | No       | Environment-to-environment links.    | `{agents-to-env: {...}}` |

### Overlay Network

| Property           | Type   | Required | Description                    | Example                  |
|:-------------------|:-------|:---------|:-------------------------------|:-------------------------|
| `type`             | String | Yes      | Overlay type.                  | `tailscale`, `wireguard` |
| `auth_key`         | String | No       | Secret reference for auth.     | `secret:vpn-key`         |
| `network_name`     | String | No       | Network/tailnet name.          | `example.com`            |
| `acl_tags`         | Array  | No       | Access control tags.           | `[tag:env, tag:ops]`     |
| `advertise_routes` | Array  | No       | Routes to advertise.           | `[10.0.0.0/16]`          |

### Operator Access

| Property      | Type   | Required | Description                 | Example                  |
|:--------------|:-------|:---------|:----------------------------|:-------------------------|
| `methods`     | Array  | Yes      | Access methods (ordered).   | `[vpn, cloud_shell, ssh]`|
| `cloud_shell` | Object | No       | Cloud shell config.         | `{type: ssm}`            |
| `vpn`         | Object | No       | VPN access config.          | `{enabled: true}`        |
| `ssh`         | Object | No       | SSH config.                 | `{enabled: false}`       |

### Connections

Environment-to-environment network connections.

Connections are defined as a map keyed by name.

| Property      | Type   | Required | Description                | Example                    |
|:--------------|:-------|:---------|:---------------------------|:---------------------------|
| `type`        | String | Yes      | Connection type.           | `tailscale`, `vpc_peering` |
| `source`      | Object | Yes      | Source environment.        | `{environment: agents}`    |
| `destination` | Object | Yes      | Destination environment.   | `{environment: targets}`   |
| `policy`      | Object | No       | Traffic policy.            | `{direction: egress_only}` |

### Connectivity Example

```yaml
connectivity:
  overlay:
    type: tailscale
    auth_key: secret:tailscale-key
    network_name: example.com
    acl_tags: [tag:env, tag:operators]
    advertise_routes: [10.0.0.0/16]

  operator_access:
    methods: [vpn, cloud_shell]
    cloud_shell:
      type: ssm
      enabled: true
      session_logging: true
    vpn:
      enabled: true
      ssh: true

  connections:
    agents-to-environment:
      type: tailscale
      source:
        environment: agent-cluster
        cidr: 172.16.0.0/16
      destination:
        environment: dev-environment
        cidr: 10.0.0.0/16
      policy:
        direction: egress_only
        allowed_ports: [22, 80, 443, 5432]
```

---

## Complete Example

This example demonstrates an Active Directory lab environment. Scenario-specific
role assignments (attacker, target, etc.) are defined in RFC-0002 experiments.

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Environment
metadata:
  name: ad-lab
  description: "Active Directory lab environment"
  version: "1.0.0"
  labels:
    team: security-research

topology:
  networks:
    corp-lan:
      cidr: 10.0.0.0/16
      routing: nat
      private_service_access: [storage, logs, remote_management]

    domain-subnet:
      cidr: 10.0.10.0/24
      routing: isolated
      vlan_id: 10

  nodes:
    dc01:
      type: host
      display_name: "Primary Domain Controller"
      hostname: dc01
      computer_name: DC01
      os: windows
      os_version: "2022"
      role: domain_controller
      tier: critical
      domain: corp.local
      groups: [domain_controllers, tier0, windows]
      services: [ldap, kerberos, dns, smb]
      network_interfaces:
        - name: eth0
          network: domain-subnet
          ip_address: 10.0.10.10/24

    srv01:
      type: host
      hostname: srv01
      computer_name: SRV01
      os: windows
      os_version: "2022"
      role: file_server
      tier: high
      domain: corp.local
      groups: [member_servers, tier1, windows]
      services: [smb, winrm]
      network_interfaces:
        - name: eth0
          network: domain-subnet
          ip_address: 10.0.10.20/24

    ws01:
      type: host
      hostname: ws01
      computer_name: WS01
      os: windows
      os_version: "11"
      role: workstation
      tier: low
      domain: corp.local
      groups: [workstations, tier2, windows]
      services: [rdp, smb]
      network_interfaces:
        - name: eth0
          network: corp-lan
          dhcp: true

    kali-01:
      type: host
      hostname: kali-01
      os: linux
      os_distribution: kali
      role: workstation
      groups: [operator_workstations, linux]
      features: [vnc_access, tools_installed]
      network_interfaces:
        - name: eth0
          network: corp-lan
          dhcp: true

    ubuntu-srv-01:
      type: host
      hostname: ubuntu-srv-01
      os: linux
      os_distribution: ubuntu
      os_version: "22.04"
      role: server
      groups: [linux_servers, linux]
      services: [https, ssh]
      network_interfaces:
        - name: eth0
          network: corp-lan
          ip_address: 10.0.1.100/24

groups:
  domain_controllers:
    description: "Active Directory domain controllers"
    type: role-based
    tier: critical

  member_servers:
    description: "Domain-joined member servers"
    type: role-based

  linux_servers:
    description: "Linux servers"
    type: role-based

  workstations:
    description: "Domain-joined workstations"
    type: role-based

  operator_workstations:
    description: "Operator workstations (scenario role assigned in experiments)"
    type: functional

  tier0:
    description: "Tier 0 - Domain Admin level systems"
    type: infrastructure
    tier: critical

  tier1:
    description: "Tier 1 - Server Admin level systems"
    type: infrastructure
    tier: high

  tier2:
    description: "Tier 2 - Workstation level systems"
    type: infrastructure
    tier: low

  windows:
    description: "All Windows hosts"
    type: os-based

  linux:
    description: "All Linux hosts"
    type: os-based

resources:
  profiles:
    dc-standard:
      instance_type: t3.medium
      volume:
        size: 100Gi
        encrypted: true

    server-standard:
      instance_type: t3.small
      volume:
        size: 50Gi
        encrypted: true

    workstation:
      instance_type: t3.small
      volume:
        size: 50Gi
        encrypted: true

  image_filters:
    windows-2022:
      owners: [amazon]
      most_recent: true
      filters:
        name: "Windows_Server-2022-English-Full-Base-*"
        virtualization-type: hvm

    ubuntu-22.04:
      owners: [099720109477]
      most_recent: true
      filters:
        name: "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"

    kali-latest:
      owners: [679593333241]
      most_recent: true
      filters:
        name: "kali-linux-*"

  instance_policies:
    base:
      capabilities: [remote_management, logs]

  security_groups:
    internal:
      description: "Internal traffic"
      ingress:
        - protocol: "-1"
          cidr_blocks: [10.0.0.0/16]
      egress:
        - protocol: "-1"
          cidr_blocks: [0.0.0.0/0]

    web-server:
      description: "Web server access"
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
      image_filter: windows-2022
      profile: dc-standard
      instance_policy: base
      security_groups: [internal]

    kali-01:
      image_filter: kali-latest
      profile: workstation
      instance_policy: base
      security_groups: [internal]

    ubuntu-srv-01:
      image_filter: ubuntu-22.04
      profile: server-standard
      instance_policy: base
      security_groups: [internal, web-server]

provisioning:
  method: cloud_shell_ansible

  playbooks:
    domain-controllers:
      path: ansible/windows/dc_setup.yml
      host_type: windows
      groups: [domain_controllers]

    linux-base:
      path: ansible/linux/base.yml
      host_type: linux
      groups: [linux]

agent_platform:
  type: kubernetes
  name: agent-cluster
  network:
    cidr: 172.16.0.0/16
    namespace: aces-agents
  orchestrator:
    type: ray
    config:
      head_service: ray-head.aces-agents.svc
  storage:
    type: redis
    url: redis://redis.aces-agents.svc:6379

telemetry:
  tracing:
    backend: tempo
    endpoint: "http://tempo:4318"
    service_name: ad-lab
    metrics_generator: true

  logging:
    backend: loki
    endpoint: "http://loki:3100"
    retention: 14d

  metrics:
    backend: prometheus
    endpoint: "http://prometheus:9090"

  agent:
    type: alloy
    version: "1.6.0"

  collection_points:
    - type: windows_security
      groups: [windows]
      event_ids: [4624, 4625, 4662, 4768, 4769, 4776]
      format: ocsf

    - type: syslog
      groups: [linux]
      format: json

    - type: kubernetes_logs
      namespace: aces-agents

    - type: otel_spans
      namespace: aces-agents

  sinks:
    loki:
      type: loki
      endpoint: "http://loki:3100"

    tempo:
      type: otlp
      endpoint: "http://tempo:4317"

  # Span dimensions for correlation (experiment-specific dimensions in RFC-0002)
  span_dimensions:
    - service.name
    - service.namespace
    - host.name
    - deployment.environment

  dashboards:
    environment-overview:
      type: grafana
      source: dashboards/overview.json
      datasources: [prometheus, loki, tempo]

  schema:
    ref: "aces.io/schema/v1"
    extensions: [security]  # Enables security attributes per RFC-0003

  storage:
    hot:
      type: local
      retention: 24h
    warm:
      type: s3
      retention: 30d
      bucket: telemetry-warm

connectivity:
  overlay:
    type: tailscale
    auth_key: secret:tailscale-key
    acl_tags: [tag:env, tag:operators, tag:agents]
    advertise_routes: [10.0.0.0/16]

  operator_access:
    methods: [vpn, cloud_shell]
    cloud_shell:
      type: ssm
      enabled: true
      session_logging: true
    vpn:
      enabled: true
      ssh: true
    vnc:
      enabled: true
      nodes: [kali-01]

  connections:
    agents-to-environment:
      type: tailscale
      source:
        environment: agent-cluster
        cidr: 172.16.0.0/16
        namespace: aces-agents
      destination:
        environment: ad-lab
        cidr: 10.0.0.0/16
      policy:
        direction: egress_only
        allowed_ports: [22, 445, 389, 636, 88, 135, 139, 5985, 5986]
```

---

## Alternatives Considered

### JSON Schema Only

Rejected: YAML is more human-readable and supports comments.

### Pulumi/CDK-style Imperative

Rejected: Declarative specs are easier to version, diff, and validate.

### Combined Environment + Experiment

Rejected: Separating them enables environment reuse across experiments.

---

## Affected Repos

| Repository              | Changes Required                              |
|:------------------------|:----------------------------------------------|
| `aces-schema`           | JSON Schema for Environment kind              |
| `aces-runtime`          | Environment instantiation and management      |
| `aces-provider-aws`     | AWS-specific resource mapping                 |
| `aces-provider-gcp`     | GCP-specific resource mapping                 |
| `aces-provider-azure`   | Azure-specific resource mapping               |
| `aces-provider-docker`  | Docker/container resource mapping             |
| `aces-provisioner`      | Playbook execution                            |

---

## Consequences

### What Becomes Easier

- **Reuse**: Same environment supports multiple experiments
- **Provider flexibility**: Topology decoupled from backend
- **Team collaboration**: Infrastructure and experiment teams work independently
- **Observability**: Telemetry configured once, used by all experiments

### What Becomes Harder

- **Simple scenarios**: Requires separate environment + experiment files
- **Learning curve**: Must understand environment/experiment separation

---

## Cross-References

| Document                              | Relationship                           |
|:--------------------------------------|:---------------------------------------|
| RFC-0002: Experiment Specification    | Defines what happens in environments: scenario roles, objectives, agent coordination |
| RFC-0003: Observability Schema        | Defines telemetry semantics and attributes |
| RFC-0004: Security Domain Schema      | Attack relationship types, credential kinds, blue team roles for security scenarios |
| RFC-0005: Agent SDK (future)          | Agent implementation interfaces        |

---

## Appendix A: Active Directory Environments

Active Directory environments are a common use case. This appendix shows
conventions for expressing AD infrastructure using the schema.

### Typed Fields vs Labels

For AD environments, prefer using the typed fields for common concepts:

| Concept | Typed Field | Label Alternative |
|:--------|:------------|:------------------|
| Domain membership | `domain: corp.local` | `labels: {ad.domain: corp.local}` |
| Role | `role: domain_controller` | `labels: {ad.role: domain_controller}` |
| Criticality | `tier: critical` | `labels: {ad.tier: "0"}` |

Use typed fields when you want schema validation. Use labels for metadata not
covered by typed fields (forest, site, OU, etc.).

### AD-Specific Labels

| Label           | Description                      | Example Values                    |
|:----------------|:---------------------------------|:----------------------------------|
| `ad.forest`     | AD forest                        | `corp.local`                      |
| `ad.site`       | AD site                          | `HQ`, `Branch`                    |
| `ad.ou`         | Organizational unit              | `Servers`, `Workstations`         |
| `ad.tier`       | Administrative tier (MS model)   | `0`, `1`, `2`                     |

### AD Services

Common AD-related services for node definitions:

| Service     | Description                    |
|:------------|:-------------------------------|
| `ldap`      | LDAP directory service         |
| `kerberos`  | Kerberos authentication        |
| `dns`       | DNS (AD-integrated)            |
| `smb`       | SMB file sharing               |
| `winrm`     | Windows Remote Management      |
| `rdp`       | Remote Desktop Protocol        |

### AD Groups

Suggested group naming conventions:

| Group                  | Description                        |
|:-----------------------|:-----------------------------------|
| `domain_controllers`   | All domain controllers             |
| `member_servers`       | Domain-joined servers              |
| `workstations`         | Domain-joined workstations         |
| `tier0`                | Tier 0 (domain admin) systems      |
| `tier1`                | Tier 1 (server admin) systems      |
| `tier2`                | Tier 2 (workstation) systems       |

### AD Environment Example

This example uses typed fields (`role`, `tier`, `domain`) for validated AD concepts,
with labels for additional metadata.

```yaml
---
apiVersion: aces.io/v1alpha1
kind: Environment
metadata:
  name: ad-lab
  description: "Active Directory lab environment"
  version: "1.0.0"
  labels:
    ad.forest: corp.local

topology:
  networks:
    corp-lan:
      cidr: 10.0.0.0/16
      routing: nat

    domain-subnet:
      cidr: 10.0.10.0/24
      routing: isolated
      vlan_id: 10

  nodes:
    dc01:
      type: host
      hostname: dc01
      computer_name: DC01
      os: windows
      os_version: "2022"
      role: domain_controller    # Typed field (validated)
      tier: critical             # Typed field (validated)
      domain: corp.local         # Typed field
      groups: [domain_controllers, tier0, windows]
      services: [ldap, kerberos, dns, smb]
      labels:
        ad.site: HQ              # Additional metadata via labels
      network_interfaces:
        - name: eth0
          network: domain-subnet
          ip_address: 10.0.10.10/24

    dc02:
      type: host
      hostname: dc02
      computer_name: DC02
      os: windows
      os_version: "2022"
      role: domain_controller
      tier: critical
      domain: corp.local
      groups: [domain_controllers, tier0, windows]
      services: [ldap, kerberos, dns, smb]
      labels:
        ad.site: HQ
      network_interfaces:
        - name: eth0
          network: domain-subnet
          ip_address: 10.0.10.11/24

    srv01:
      type: host
      hostname: srv01
      computer_name: SRV01
      os: windows
      os_version: "2022"
      role: server
      tier: high
      domain: corp.local
      groups: [member_servers, tier1, windows]
      services: [smb, winrm]
      labels:
        app: file_server
        ad.ou: Servers
      network_interfaces:
        - name: eth0
          network: domain-subnet
          ip_address: 10.0.10.20/24

    ws01:
      type: host
      hostname: ws01
      computer_name: WS01
      os: windows
      os_version: "11"
      role: workstation
      tier: low
      domain: corp.local
      groups: [workstations, tier2, windows]
      services: [rdp, smb]
      labels:
        ad.ou: Workstations
      network_interfaces:
        - name: eth0
          network: corp-lan
          dhcp: true

    kali-01:
      type: host
      hostname: kali-01
      os: linux
      os_distribution: kali
      role: workstation          # Infrastructure role; scenario role in RFC-0002
      groups: [operator_workstations, linux]
      features: [vnc_access, tools_installed]
      network_interfaces:
        - name: eth0
          network: corp-lan
          dhcp: true

groups:
  domain_controllers:
    description: "Active Directory domain controllers"
    type: role-based
    tier: critical

  member_servers:
    description: "Domain-joined member servers"
    type: role-based

  workstations:
    description: "Domain-joined workstations"
    type: role-based

  operator_workstations:
    description: "Operator workstations (scenario role assigned in experiments)"
    type: functional

  tier0:
    description: "Tier 0 - Domain Admin level"
    type: infrastructure
    tier: critical

  tier1:
    description: "Tier 1 - Server Admin level"
    type: infrastructure
    tier: high

  tier2:
    description: "Tier 2 - Workstation level"
    type: infrastructure
    tier: low

  windows:
    description: "All Windows hosts"
    type: os-based

  linux:
    description: "All Linux hosts"
    type: os-based

telemetry:
  collection_points:
    - type: windows_security
      groups: [windows]
      event_ids: [4624, 4625, 4662, 4768, 4769, 4776]
      format: ocsf

    - type: syslog
      groups: [linux]
      format: json

  # Infrastructure dimensions; scenario dimensions (mitre.*, attack_*) in RFC-0002
  span_dimensions:
    - service.name
    - host.name
    - deployment.environment

  schema:
    ref: "aces.io/schema/v1"
    extensions: [security]  # Enables security attributes per RFC-0003
```

### AD Telemetry

For AD environments, use the security extension from RFC-0003 which defines:

- Active Directory attributes (`ad.domain`, `ad.object.dn`, etc.)
- Credential attributes (`credential.type`, `credential.domain`, etc.)

Scenario-specific attributes (MITRE ATT&CK: `mitre.tactic`, `mitre.technique.id`, etc.)
are defined in RFC-0002 experiments, not in the environment specification.

---

## Appendix B: Provider Mappings

### Private Service Access

| Endpoint            | AWS                    | GCP              | Azure          |
|:--------------------|:-----------------------|:-----------------|:---------------|
| `remote_management` | SSM                    | IAP              | Bastion        |
| `storage`           | S3                     | Cloud Storage    | Blob Storage   |
| `file_storage`      | EFS                    | Filestore        | Azure Files    |
| `secrets`           | Secrets Manager        | Secret Manager   | Key Vault      |
| `logs`              | CloudWatch Logs        | Cloud Logging    | Log Analytics  |

### Instance Policy Capabilities

| Capability          | AWS                            | GCP                          | Azure                         |
|:--------------------|:-------------------------------|:-----------------------------|:------------------------------|
| `remote_management` | AmazonSSMManagedInstanceCore   | roles/iap.tunnelResourceAccessor | Virtual Machine User Login |
| `logs`              | CloudWatchAgentServerPolicy    | roles/logging.logWriter      | Monitoring Metrics Publisher  |
| `storage_read`      | AmazonS3ReadOnlyAccess         | roles/storage.objectViewer   | Storage Blob Data Reader      |
