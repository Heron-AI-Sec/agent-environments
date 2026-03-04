# RFC-0001: Cyber Range Specification

## Summary

This draft RFC proposes a declarative YAML specification for defining reproducible cyber experiment ranges. This enables seamless ingestion by range orchestration tools and execution via compatible runtimes within the Agentic Cyber Environment System (ACES).

## Motivation

For ACES to serve as an open reference architecture for autonomous AI agent research, it requires a standardized, framework-agnostic language to express scenarios. Other experiment environments have had success in specifying distributed network systems using a graph-based approach (vertices and edges) mapped to a network simulation like proxmox. ACES will ingest a declarative schema capable of supporting multiple instantiation backends (e.g., Docker, cloud providers, hypervisors) and complex agentic experimentation loops.

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

## Schema Specification

### Root Schema

The root of the YAML document defines the API version, the kind of resource, and the infrastructure pillars.

| Field            | Type   | Required | Description                                                 | Example                              |
| :--------------- | :----- | :------- | :---------------------------------------------------------- | :----------------------------------- |
| `apiVersion`     | String | Yes      | The version of the schema.                                  | `aces.io/v1alpha1`                   |
| `kind`           | String | Yes      | The type of resource.                                       | `CyberRange`                         |
| `metadata`       | Object | Yes      | Identifying information.                                    | `{name, description, version}`       |
| `topology`       | Object | Yes      | The logical definition of networks, nodes, and edges.       | `{networks: [...], nodes: [...]}`    |
| `groups`         | Object | No       | Logical grouping of nodes.                                  | `{domain_controllers: {...}}`        |
| `resources`      | Object | No       | Hardware/virtualization requirements and resource bindings. | `{profiles: [...], bindings: [...]}` |
| `provisioning`   | Object | No       | Post-deployment configuration.                              | `{method: cloud_shell_ansible}`      |
| `agent_platform` | Object | No       | Platform where agents execute.                              | `{type: kubernetes, name: ...}`      |
| `telemetry`      | Object | No       | Observability and event collection configuration.           | `{tracing: {...}, logging: {...}}`   |
| `connectivity`   | Array  | No       | Network connectivity between environments.                  | `[{name: agents-to-targets, ...}]`   |

### Example

```yaml
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

The topology block defines the "what" of the environment. It outlines the structure of the network without concerning itself with how the virtualization or emulation will occur.

### Networks

Networks represent broadcast domains, local area networks, subnets, and switching fabrics.

| Property            | Type    | Required | Description                                      | Example                        |
| :------------------ | :------ | :------- | :----------------------------------------------- | :----------------------------- |
| `name`              | String  | Yes      | Unique identifier for the network.               | `corporate-lan`                |
| `cidr`              | String  | Yes      | IPv4/IPv6 subnet.                                | `10.0.0.0/16`                  |
| `routing`           | String  | No       | The routing mode.                                | `isolated`, `nat`, `bridged`   |
| `vlan_id`           | Integer | No       | Optional VLAN identifier.                        | `100`                          |
| `secondary_cidr`    | String  | No       | Secondary CIDR block (e.g., for pod networking). | `100.64.0.0/16`                |
| `private_endpoints` | Array   | No       | Private endpoints for cloud services.            | `[remote_management, storage]` |

#### Private Endpoints

For cloud deployments, private endpoints enable connectivity to managed services without traversing the public internet.

| Endpoint            | AWS                             | GCP            | Azure         | Description           |
| :------------------ | :------------------------------ | :------------- | :------------ | :-------------------- |
| `remote_management` | SSM, SSM Messages, EC2 Messages | IAP            | Bastion       | Remote shell access   |
| `storage`           | S3                              | Cloud Storage  | Blob Storage  | Object storage access |
| `file_storage`      | EFS                             | Filestore      | Azure Files   | Shared file systems   |
| `secrets`           | Secrets Manager                 | Secret Manager | Key Vault     | Secrets access        |
| `logs`              | CloudWatch Logs                 | Cloud Logging  | Log Analytics | Log shipping          |

### Example

```yaml
topology:
  networks:
    - name: range-vpc
      cidr: 10.0.0.0/16
      secondary_cidr: 100.64.0.0/16 # For Kubernetes pod networking
      routing: nat
      private_endpoints: [remote_management, storage, file_storage]

    - name: domain-subnet
      cidr: 10.0.10.0/24
      routing: isolated
      vlan_id: 10
```

### Nodes

Nodes represent endpoints or edge devices, including routers, switches, and firewalls within the environment.

| Property          | Type   | Required | Description                              | Example                                                |
| :---------------- | :----- | :------- | :--------------------------------------- | :----------------------------------------------------- |
| `name`            | String | Yes      | Unique identifier for the node.          | `dc01`                                                 |
| `type`            | String | Yes      | Device type.                             | `host`, `router`, `switch`, `firewall`                 |
| `role`            | String | No       | Functional role within the environment.  | `domain_controller`, `c2_server`, `attacker`, `target` |
| `computer_name`   | String | No       | NetBIOS/hostname as seen in the OS.      | `DC01`                                                 |
| `friendly_name`   | String | No       | Human-readable display name.             | `Primary Domain Controller`                            |
| `os`              | String | No       | Operating system.                        | `windows`, `linux`                                     |
| `os_version`      | String | No       | OS version.                              | `2019`, `2022`, `22.04`                                |
| `os_distribution` | String | No       | Linux distribution (if applicable).      | `ubuntu`, `kali`, `debian`                             |
| `domain`          | String | No       | Domain membership (for AD environments). | `corp.local`                                           |
| `tier`            | String | No       | Criticality tier for targeting/defense.  | `critical`, `high`, `medium`, `low`                    |
| `groups`          | Array  | No       | References to group names.               | `[ad_lab, domain_controllers, windows]`                |
| `services`        | Array  | No       | Services running on this node.           | `[ldap, kerberos, dns, smb]`                           |
| `interfaces`      | Array  | Yes      | List of NetworkInterface objects.        | `[{name: eth0, network: corp-lan}]`                    |
| `provisioner`     | String | No       | Tool used to provision this node.        | `terraform`, `ansible`, `docker`                       |
| `provisioner_id`  | String | No       | ID within the provisioner system.        | `dc01`                                                 |
| `owner`           | String | No       | Responsible operator or team.            | `infra-team`, `red-team`                               |
| `features`        | Array  | No       | Capabilities or flags for this node.     | `[vnc_access, pre_installed_tools]`                    |
| `notes`           | String | No       | Freeform metadata or documentation.      | `Primary DC for corp.local`                            |

#### Node Roles

Standard roles used in cyber ranges:

| Role                | Description                                                    |
| :------------------ | :------------------------------------------------------------- |
| `domain_controller` | Active Directory domain controller                             |
| `server`            | General-purpose server                                         |
| `workstation`       | End-user workstation                                           |
| `c2_server`         | Command & Control server (e.g., Sliver, Mythic, Cobalt Strike) |
| `attacker`          | Offensive operator workstation                                 |
| `target`            | Standalone target system                                       |
| `router`            | Network routing device                                         |
| `firewall`          | Network security device                                        |

#### NetworkInterface Object

| Property     | Type    | Required | Description                           | Example             |
| :----------- | :------ | :------- | :------------------------------------ | :------------------ |
| `name`       | String  | Yes      | Name of the target network interface. | `eth0`              |
| `network`    | String  | Yes      | Reference to a network name.          | `domain-subnet`     |
| `dhcp`       | Boolean | No       | Flag if DHCP is on/off.               | `true`, `false`     |
| `ip_address` | String  | No       | Static IP address, if specified.      | `192.168.1.1/24`    |
| `hw_address` | String  | No       | Hardware (e.g. MAC) address.          | `DE:AD:BE:EF:00:01` |

#### Example

```yaml
topology:
  nodes:
    - name: dc01
      type: host
      role: domain_controller
      computer_name: DC01
      friendly_name: "Primary Domain Controller"
      os: windows
      os_version: "2019"
      domain: corp.local
      tier: critical
      groups: [ad_lab, domain_controllers, windows]
      services: [ldap, kerberos, dns, smb]
      provisioner: terraform
      provisioner_id: dc01
      owner: infra-team
      interfaces:
        - name: eth0
          network: corp-subnet
          ip_address: 10.0.10.10/24

    - name: kali-01
      type: host
      role: attacker
      computer_name: kali-01
      os: linux
      os_distribution: kali
      groups: [attackers]
      features: [vnc_access, pre_installed_tools]
      interfaces:
        - name: eth0
          network: range-vpc
          dhcp: true
```

### Edges

Edges define physical and link layer constraints between interfaces, allowing for the simulation of realistic degradation conditions for networks.

| Property      | Type   | Required | Description                    | Example                     |
| :------------ | :----- | :------- | :----------------------------- | :-------------------------- |
| `endpoints`   | Tuple  | Yes      | Nodes forming each edge.       | `(router-0, workstation-0)` |
| `latency`     | String | No       | Simulated delay.               | `50ms`                      |
| `packet_loss` | Float  | No       | Percentage of dropped packets. | `0.05`                      |
| `bandwidth`   | String | No       | Maximum bandwidth.             | `1Gbps`                     |

#### Example

```yaml
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

Groups provide logical organization of nodes by role, deployment method, or function. This enables bulk operations, targeting, and policy application.

| Property      | Type   | Required | Description                                            | Example                                                  |
| :------------ | :----- | :------- | :----------------------------------------------------- | :------------------------------------------------------- |
| `name`        | String | Yes      | Unique identifier for the group.                       | `domain_controllers`                                     |
| `description` | String | No       | Human-readable description.                            | `Active Directory domain controllers`                    |
| `type`        | String | No       | Grouping strategy.                                     | `deployment`, `role-based`, `os-based`, `infrastructure` |
| `provisioner` | String | No       | Tool that created these nodes (for deployment groups). | `terraform`                                              |
| `members`     | Array  | No       | Explicit list of node names (optional).                | `[dc01, dc02]`                                           |

### Example

```yaml
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

The resources block maps the logical topology to physical or virtual realities. This separation allows the same topology to be executed on a local hypervisor, a container engine, or a public cloud.

### Resource Profiles

Defines standardized compute configurations to ensure reproducible performance.

| Property        | Type    | Required | Description                      | Example                   |
| :-------------- | :------ | :------- | :------------------------------- | :------------------------ |
| `name`          | String  | Yes      | Unique identifier.               | `dc-standard`             |
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

Defines how to select machine images for cloud deployments. This example uses AWS AMI filters, but the pattern applies to other clouds.

| Property      | Type    | Required | Description                        | Example                  |
| :------------ | :------ | :------- | :--------------------------------- | :----------------------- |
| `name`        | String  | Yes      | Unique identifier for this filter. | `windows-2019-base`      |
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

Defines IAM/service account policies to attach to instances.

| Property           | Type   | Required | Description                                            | Example                             |
| :----------------- | :----- | :------- | :----------------------------------------------------- | :---------------------------------- |
| `name`             | String | Yes      | Policy identifier.                                     | `range-node-base`                   |
| `capabilities`     | Array  | No       | Abstract capabilities (resolved to provider policies). | `[remote_management, metrics_logs]` |
| `managed_policies` | Array  | No       | Provider-specific managed policy ARNs/names.           | `[AmazonSSMManagedInstanceCore]`    |
| `inline_policies`  | Array  | No       | Custom inline policy documents.                        | `[{name: custom, document: {...}}]` |

#### Standard Capabilities

| Capability          | Description                            |
| :------------------ | :------------------------------------- |
| `remote_management` | Cloud shell access (SSM, IAP, Bastion) |
| `metrics_logs`      | Metrics and log shipping               |
| `storage_read`      | Read from object storage               |
| `storage_full`      | Full access to object storage          |
| `secrets_read`      | Read secrets from secret manager       |

Common managed policies for range nodes:

| Capability        | AWS                            | GCP                                | Azure                          |
| :---------------- | :----------------------------- | :--------------------------------- | :----------------------------- |
| Remote management | `AmazonSSMManagedInstanceCore` | `roles/iap.tunnelResourceAccessor` | `Virtual Machine User Login`   |
| Metrics/logs      | `CloudWatchAgentServerPolicy`  | `roles/logging.logWriter`          | `Monitoring Metrics Publisher` |
| Storage read      | `AmazonS3ReadOnlyAccess`       | `roles/storage.objectViewer`       | `Storage Blob Data Reader`     |

### Bindings

Maps specific nodes to images, compute profiles, and policies.

| Property          | Type   | Required | Description                               | Example                            |
| :---------------- | :----- | :------- | :---------------------------------------- | :--------------------------------- |
| `node`            | String | Yes      | Reference to a node name in the topology. | `dc01`                             |
| `image`           | String | No       | Direct image URI or ID.                   | `ami-0abcdef1234567890`            |
| `image_filter`    | String | No       | Reference to an image filter name.        | `windows-2019-base`                |
| `profile`         | String | No       | Reference to a resource profile.          | `dc-standard`                      |
| `instance_policy` | String | No       | Reference to an instance policy.          | `range-node-base`                  |
| `security_groups` | Array  | No       | Security group references.                | `[internal-ad, management-access]` |
| `user_data`       | String | No       | Path to user data template.               | `templates/windows-dc.ps1.tpl`     |

### Security Groups

Defines network security rules for nodes.

| Property      | Type   | Required | Description                 | Example               |
| :------------ | :----- | :------- | :-------------------------- | :-------------------- |
| `name`        | String | Yes      | Security group identifier.  | `internal-ad`         |
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

### Example

```yaml
resources:
  profiles:
    - name: dc-standard
      instance_type: t3.medium
      volume:
        size: 100Gi
        type: gp3
        encrypted: true

    - name: c2-server
      instance_type: t3.large
      volume:
        size: 100Gi
        type: gp3
        encrypted: true

    - name: attacker-workstation
      instance_type: t3.medium
      volume:
        size: 50Gi
        type: gp3

  image_filters:
    - name: windows-2019-base
      owners: [amazon]
      most_recent: true
      filters:
        name: "Windows_Server-2019-English-Full-Base-*"
        virtualization-type: hvm
        root-device-type: ebs

    - name: ubuntu-22.04
      owners: [099720109477] # Canonical
      most_recent: true
      filters:
        name: "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
        architecture: x86_64

    - name: kali-latest
      owners: [679593333241] # Kali
      most_recent: true
      filters:
        name: "kali-linux-*"

  instance_policies:
    - name: range-node-base
      capabilities: [remote_management, metrics_logs]
      # Provider-specific policies resolved at deploy time:
      # AWS: AmazonSSMManagedInstanceCore, CloudWatchAgentServerPolicy
      # GCP: roles/iap.tunnelResourceAccessor, roles/logging.logWriter
      # Azure: Virtual Machine User Login, Monitoring Metrics Publisher

    - name: c2-server-policy
      capabilities: [remote_management, storage_full]

  security_groups:
    - name: internal-ad
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

    - name: c2-server
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
    - node: dc01
      image_filter: windows-2019-base
      profile: dc-standard
      instance_policy: range-node-base
      security_groups: [internal-ad]
      user_data: templates/windows-dc.ps1.tpl

    - node: sliver
      image_filter: ubuntu-22.04
      profile: c2-server
      instance_policy: c2-server-policy
      security_groups: [c2-server, internal-ad]
      user_data: templates/linux-c2.sh.tpl
```

---

## Provisioning

The provisioning block defines post-deployment configuration steps. This separates the infrastructure creation (e.g., Terraform) from configuration management (e.g., Ansible).

| Property    | Type   | Required | Description                   | Example                                            |
| :---------- | :----- | :------- | :---------------------------- | :------------------------------------------------- |
| `method`    | String | Yes      | Provisioning method.          | `cloud_shell_ansible`, `ssh_ansible`, `cloud_init` |
| `playbooks` | Array  | No       | Ansible playbook definitions. | See Playbook Object                                |
| `templates` | Array  | No       | User data templates.          | See Template Object                                |

### Provisioning Methods

| Method                | Description                                   | Use Case                        |
| :-------------------- | :-------------------------------------------- | :------------------------------ |
| `cloud_shell_ansible` | Run Ansible via cloud shell (SSM/IAP/Bastion) | Cloud instances without SSH     |
| `ssh_ansible`         | Run Ansible via SSH                           | On-prem or SSH-accessible nodes |
| `cloud_init`          | Cloud-init user data only                     | Simple bootstrapping            |
| `none`                | No post-deployment provisioning               | Pre-baked images                |

### Playbook Object

| Property     | Type   | Required | Description                   | Example                        |
| :----------- | :----- | :------- | :---------------------------- | :----------------------------- |
| `name`       | String | Yes      | Playbook identifier.          | `dc-setup`                     |
| `path`       | String | Yes      | Path to playbook file.        | `ansible/windows/dc_setup.yml` |
| `host_type`  | String | No       | Target OS type.               | `windows`, `linux`             |
| `groups`     | Array  | No       | Node groups to target.        | `[domain_controllers]`         |
| `nodes`      | Array  | No       | Specific nodes to target.     | `[dc01]`                       |
| `extra_vars` | Object | No       | Additional Ansible variables. | `{domain: corp.local}`         |
| `tags`       | Array  | No       | Ansible tags to run.          | `[install, configure]`         |

### Template Object

| Property    | Type   | Required | Description            | Example                            |
| :---------- | :----- | :------- | :--------------------- | :--------------------------------- |
| `name`      | String | Yes      | Template identifier.   | `windows-bootstrap`                |
| `path`      | String | Yes      | Path to template file. | `templates/windows-dc.ps1.tpl`     |
| `type`      | String | Yes      | Template type.         | `powershell`, `bash`, `cloud_init` |
| `variables` | Object | No       | Template variables.    | `{join_domain: true}`              |

### Example

```yaml
provisioning:
  method: cloud_shell_ansible # Uses SSM (AWS), IAP (GCP), or Bastion (Azure)

  templates:
    - name: windows-bootstrap
      path: templates/windows-dc.ps1.tpl
      type: powershell
      variables:
        install_cloud_agent: true # SSM agent, GCP guest agent, Azure agent
        enable_winrm: true

    - name: linux-c2
      path: templates/linux-c2.sh.tpl
      type: bash
      variables:
        install_docker: true

  playbooks:
    - name: domain-controllers
      path: ansible/windows/dc_setup.yml
      host_type: windows
      groups: [domain_controllers]
      extra_vars:
        telemetry_endpoint: "https://loki.example.com/loki/api/v1/push"

    - name: sliver-setup
      path: ansible/linux/sliver.yml
      host_type: linux
      nodes: [sliver]
      extra_vars:
        sliver_version: "1.5.42"
        enable_multiplayer: true

    - name: kali-operator
      path: ansible/linux/kali_setup.yml
      host_type: linux
      groups: [attackers]
      tags: [tools, configs]
```

---

## Agent Platform

Production deployments require agent execution to be separated from the target topology. The agent platform defines where agents run.

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

### Example

```yaml
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

The telemetry block defines observability infrastructure for the range. This includes collection, processing, storage, and visualization of logs, traces, and metrics. Telemetry is critical for attack simulation analysis and blue team feedback loops.

| Property            | Type   | Required | Description                                    | Example                              |
| :------------------ | :----- | :------- | :--------------------------------------------- | :----------------------------------- |
| `tracing`           | Object | No       | Distributed tracing configuration.             | `{backend: tempo, endpoint: ...}`    |
| `metrics`           | Object | No       | Metrics collection configuration.              | `{backend: prometheus}`              |
| `logging`           | Object | No       | Log aggregation configuration.                 | `{backend: loki, retention: 14d}`    |
| `collection_points` | Array  | No       | Event collection sources.                      | `[{type: windows_security, ...}]`    |
| `sinks`             | Array  | No       | Telemetry destinations (supports fan-out).     | `[{name: local-tempo, type: otlp}]`  |
| `span_dimensions`   | Array  | No       | Custom span attributes for attack correlation. | `[mitre.tactic, attack_phase]`       |
| `storage`           | Object | No       | Storage tiers and retention.                   | `{hot: {...}, warm: {...}}`          |
| `dashboards`        | Array  | No       | Dashboard configurations.                      | `[{name: attack-traces, type: ...}]` |
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

| Type               | Description                | Typical Sources             |
| :----------------- | :------------------------- | :-------------------------- |
| `windows_security` | Windows Security Event Log | Domain controllers, servers |
| `syslog`           | Linux syslog / journald    | Linux hosts                 |
| `kubernetes_logs`  | Container stdout/stderr    | Kubernetes pods             |
| `network_pcap`     | Packet capture             | Switches, TAPs              |
| `otel_spans`       | OpenTelemetry traces       | Instrumented applications   |
| `systemd_journal`  | Systemd journal logs       | Linux hosts                 |

### Sinks

Sinks define where telemetry is shipped. Multiple sinks enable fan-out patterns for local analysis and external platform integration.

| Property      | Type   | Required | Description                | Example                            |
| :------------ | :----- | :------- | :------------------------- | :--------------------------------- |
| `name`        | String | Yes      | Sink identifier.           | `local-tempo`                      |
| `type`        | String | Yes      | Sink type.                 | `otlp`, `loki`, `prometheus`, `s3` |
| `endpoint`    | String | Yes      | Destination endpoint.      | `http://tempo:4317`                |
| `format`      | String | No       | Output format.             | `ocsf`, `ecs`, `raw`               |
| `credentials` | String | No       | Secret reference for auth. | `secret:platform-api-key`          |
| `batch`       | Object | No       | Batching configuration.    | `{size: 1000, timeout: 5s}`        |

### Span Dimensions

Span dimensions define custom attributes extracted from traces for metrics generation and correlation. These are critical for attack analysis.

| Dimension                | Description                      | Example Values                                        |
| :----------------------- | :------------------------------- | :---------------------------------------------------- |
| `mitre.tactic`           | ATT&CK tactic name.              | `credential-access`, `lateral-movement`               |
| `mitre.technique.id`     | ATT&CK technique ID.             | `T1558.003`, `T1003.006`                              |
| `mitre.technique.name`   | ATT&CK technique name.           | `Kerberoasting`, `DCSync`                             |
| `attack_team`            | Team performing the action.      | `red`, `blue`                                         |
| `attack_phase`           | Current phase of the attack.     | `reconnaissance`, `exploitation`, `post-exploitation` |
| `attack_operation_id`    | Links traces to attack campaign. | UUID                                                  |
| `attack_target_host`     | Target hostname.                 | `dc01`                                                |
| `attack_target_domain`   | Target domain.                   | `corp.local`                                          |
| `service.namespace`      | Kubernetes namespace.            | `attack-simulation`                                   |
| `deployment.environment` | Environment name.                | `dev`, `staging`, `prod`                              |

### Storage Tiers

Storage tiers define retention policies for different data temperatures.

| Property | Type   | Required | Description                   | Example     |
| :------- | :----- | :------- | :---------------------------- | :---------- |
| `hot`    | Object | No       | Fast storage for recent data. | Local SSD   |
| `warm`   | Object | No       | Cost-effective storage.       | S3 Standard |
| `cold`   | Object | No       | Archive storage.              | S3 Glacier  |

#### Storage Tier Object

| Property    | Type   | Required | Description            | Example                            |
| :---------- | :----- | :------- | :--------------------- | :--------------------------------- |
| `type`      | String | Yes      | Storage backend.       | `local`, `s3`, `gcs`, `azure-blob` |
| `retention` | String | Yes      | Data retention period. | `24h`, `30d`, `1y`                 |
| `bucket`    | String | No       | Object storage bucket. | `range-telemetry-archive`          |

### Dashboards

Dashboard configurations for visualization.

| Property      | Type   | Required | Description                  | Example                         |
| :------------ | :----- | :------- | :--------------------------- | :------------------------------ |
| `name`        | String | Yes      | Dashboard identifier.        | `attack-chain-traces`           |
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

### Example

```yaml
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
    - name: local-tempo
      type: otlp
      endpoint: "http://tempo.observability:4317"

    - name: local-loki
      type: loki
      endpoint: "http://loki-gateway.observability:80"

    - name: platform-traces
      type: otlp
      endpoint: "https://platform.example.com/api/otel/traces"
      credentials: secret:platform-api-key
      batch:
        size: 1000
        timeout: 5s

    - name: archive
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
    - name: attack-chain-traces
      type: grafana
      source: dashboards/attack-traces.json
      datasources: [prometheus, loki, tempo]

    - name: blue-team-analysis
      type: grafana
      source: dashboards/blue-team.json
      datasources: [prometheus, loki]
```

---

## Connectivity

The connectivity block defines how different environments and operators access the range. This is critical for:

1. **Agent-to-target connectivity**: Agents running in a separate platform accessing target nodes
2. **Operator access**: Human operators accessing private instances (no public IPs)
3. **Telemetry egress**: Shipping observability data to external systems

Many ranges deploy nodes in private subnets with no public IP addresses or SSH access. Connectivity is provided via overlay networks (Tailscale, WireGuard) or cloud-native solutions (AWS Systems Manager).

| Property          | Type   | Required | Description                                          | Example                            |
| :---------------- | :----- | :------- | :--------------------------------------------------- | :--------------------------------- |
| `overlay`         | Object | No       | Overlay network configuration (Tailscale/WireGuard). | `{type: tailscale, auth_key: ...}` |
| `operator_access` | Object | No       | How operators access private instances.              | `{methods: [vpn, cloud_shell]}`    |
| `connections`     | Array  | No       | Environment-to-environment connections.              | `[{name: agents-to-targets, ...}]` |

### VPN / Overlay Network

Overlay networks provide secure connectivity to private instances without exposing them to the public internet.

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

Each VPN provider may have additional settings:

**Tailscale:**

```yaml
config:
  tailnet: example.com
  acl_tags: [tag:range, tag:operators]
  funnel: false
```

**WireGuard:**

```yaml
config:
  interface: wg0
  listen_port: 51820
  private_key: secret:wg-private-key
  peers:
    - public_key: "..."
      allowed_ips: [10.0.0.0/16]
      endpoint: vpn.example.com:51820
```

**Nebula:**

```yaml
config:
  ca_cert: secret:nebula-ca
  node_cert: secret:nebula-node-cert
  lighthouse: vpn.example.com:4242
```

### Operator Access

Defines how human operators access range nodes for management, red team operations, or debugging.

| Property      | Type   | Required | Description                                     | Example                      |
| :------------ | :----- | :------- | :---------------------------------------------- | :--------------------------- |
| `methods`     | Array  | Yes      | Access methods in order of preference.          | `[vpn, cloud_shell, ssh]`    |
| `cloud_shell` | Object | No       | Cloud-managed shell access (SSM, IAP, Bastion). | `{type: ssm, enabled: true}` |
| `vpn`         | Object | No       | VPN-based operator access config.               | `{enabled: true, ssh: true}` |
| `ssh`         | Object | No       | SSH configuration (if enabled).                 | `{enabled: false}`           |
| `vnc`         | Object | No       | VNC access for GUI nodes.                       | `{enabled: true, nodes: []}` |

#### Cloud Shell Configuration

Cloud-managed shell access enables secure connections without SSH keys or open ports.

| Property          | Type    | Required | Description                       | Example                 |
| :---------------- | :------ | :------- | :-------------------------------- | :---------------------- |
| `type`            | String  | Yes      | Cloud shell type.                 | `ssm`, `iap`, `bastion` |
| `enabled`         | Boolean | Yes      | Enable cloud shell access.        | `true`                  |
| `session_logging` | Boolean | No       | Log sessions to cloud storage.    | `true`                  |
| `log_destination` | String  | No       | Bucket/location for session logs. | `range-session-logs`    |

**Provider mapping:**

| Provider | Type      | Service                         |
| :------- | :-------- | :------------------------------ |
| AWS      | `ssm`     | Systems Manager Session Manager |
| GCP      | `iap`     | Identity-Aware Proxy            |
| Azure    | `bastion` | Azure Bastion                   |

#### VPN Operator Configuration

| Property     | Type    | Required | Description                                    | Example           |
| :----------- | :------ | :------- | :--------------------------------------------- | :---------------- |
| `enabled`    | Boolean | Yes      | Enable VPN access.                             | `true`            |
| `acl_tags`   | Array   | No       | Required ACL tags for operators.               | `[tag:operators]` |
| `ssh`        | Boolean | No       | Enable VPN-native SSH (e.g., Tailscale SSH).   | `true`            |
| `web_access` | Boolean | No       | Enable web UI access (e.g., Tailscale Funnel). | `false`           |

### Connections

Environment-to-environment network connections for agent traffic and telemetry.

| Property      | Type   | Required | Description                      | Example                                           |
| :------------ | :----- | :------- | :------------------------------- | :------------------------------------------------ |
| `name`        | String | Yes      | Connection identifier.           | `agents-to-targets`                               |
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

### Example

```yaml
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
    - name: agents-to-targets
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

    - name: telemetry-ingestion
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

## Complete Example

```yaml
apiVersion: aces.io/v1alpha1
kind: CyberRange
metadata:
  name: ad-attack-range
  description: "Active Directory attack simulation range"
  version: "1.0.0"

# Logical groupings
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

  attackers:
    description: "Offensive operator workstations"
    type: role-based

  windows:
    description: "All Windows hosts"
    type: os-based

# Network topology
topology:
  networks:
    - name: range-vpc
      cidr: 10.0.0.0/16
      routing: nat
      private_endpoints: [remote_management, storage, file_storage]

    - name: corp-subnet
      cidr: 10.0.10.0/24
      routing: isolated

    - name: dmz-subnet
      cidr: 10.0.20.0/24
      routing: isolated

  nodes:
    # Domain Controllers
    - name: dc01
      type: host
      role: domain_controller
      computer_name: DC01
      friendly_name: "Primary Domain Controller"
      os: windows
      os_version: "2019"
      domain: corp.local
      tier: critical
      groups: [ad_lab, domain_controllers, windows]
      services: [ldap, kerberos, dns, smb]
      provisioner: terraform
      provisioner_id: dc01
      owner: infra-team
      interfaces:
        - name: eth0
          network: corp-subnet
          ip_address: 10.0.10.10/24

    - name: dc02
      type: host
      role: domain_controller
      computer_name: DC02
      friendly_name: "Secondary Domain Controller"
      os: windows
      os_version: "2019"
      domain: corp.local
      tier: critical
      groups: [ad_lab, domain_controllers, windows]
      services: [ldap, kerberos, dns, smb]
      interfaces:
        - name: eth0
          network: corp-subnet
          ip_address: 10.0.10.11/24

    # C2 Servers
    - name: sliver
      type: host
      role: c2_server
      computer_name: sliver
      friendly_name: "Sliver C2 Server"
      os: linux
      os_version: "22.04"
      os_distribution: ubuntu
      tier: high
      groups: [c2_servers]
      services: [sliver-server, https, nginx]
      owner: red-team
      features: [multiplayer]
      interfaces:
        - name: eth0
          network: range-vpc
          ip_address: 10.0.4.100/24

    # Attacker Workstations
    - name: kali-01
      type: host
      role: attacker
      computer_name: kali-01
      friendly_name: "Operator Workstation 1"
      os: linux
      os_distribution: kali
      tier: low
      groups: [attackers]
      owner: red-team
      features: [vnc_access, pre_installed_tools]
      notes: "Primary operator workstation"
      interfaces:
        - name: eth0
          network: range-vpc
          dhcp: true

# Resource configuration
resources:
  profiles:
    - name: dc-standard
      instance_type: t3.medium
      volume:
        size: 100Gi
        type: gp3
        encrypted: true

    - name: c2-server
      instance_type: t3.large
      volume:
        size: 100Gi
        type: gp3
        encrypted: true

  image_filters:
    - name: windows-2019-base
      owners: [amazon]
      most_recent: true
      filters:
        name: "Windows_Server-2019-English-Full-Base-*"

    - name: ubuntu-22.04
      owners: [099720109477]
      most_recent: true
      filters:
        name: "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

    - name: kali-latest
      owners: [679593333241]
      most_recent: true
      filters:
        name: "kali-linux-*"

  instance_policies:
    - name: range-node-base
      capabilities: [remote_management, metrics_logs]

  security_groups:
    - name: internal-ad
      description: "Internal AD traffic"
      ingress:
        - protocol: "-1"
          cidr_blocks: [10.0.0.0/16, 172.16.0.0/16]

  bindings:
    - node: dc01
      image_filter: windows-2019-base
      profile: dc-standard
      instance_policy: range-node-base
      security_groups: [internal-ad]

    - node: dc02
      image_filter: windows-2019-base
      profile: dc-standard
      instance_policy: range-node-base
      security_groups: [internal-ad]

    - node: sliver
      image_filter: ubuntu-22.04
      profile: c2-server
      instance_policy: range-node-base
      security_groups: [internal-ad]

    - node: kali-01
      image_filter: kali-latest
      profile: dc-standard
      instance_policy: range-node-base

# Post-deployment provisioning
provisioning:
  method: cloud_shell_ansible

  playbooks:
    - name: dc-setup
      path: ansible/windows/dc_setup.yml
      host_type: windows
      groups: [domain_controllers]

    - name: sliver-setup
      path: ansible/linux/sliver.yml
      host_type: linux
      nodes: [sliver]
      extra_vars:
        sliver_version: "1.5.42"

# Agent execution platform
agent_platform:
  type: kubernetes
  name: agent-cluster
  network:
    cidr: 172.16.0.0/16
    pod_cidr: 100.64.0.0/16
    namespace: aces-agents
  orchestrator:
    type: ray
  storage:
    type: redis
    url: redis://redis.aces-agents.svc:6379

# Observability infrastructure
telemetry:
  tracing:
    backend: tempo
    endpoint: "http://tempo.observability:4318"
    metrics_generator: true

  metrics:
    backend: prometheus
    endpoint: "http://prometheus.observability:9090"
    retention: 30d

  logging:
    backend: loki
    endpoint: "http://loki-gateway.observability:80"
    retention: 14d

  agent:
    type: alloy
    version: "1.6.0"

  collection_points:
    - type: windows_security
      groups: [domain_controllers]
      event_ids: [4624, 4625, 4662, 4768, 4769]
      format: ocsf

    - type: kubernetes_logs
      namespace: attack-simulation

    - type: otel_spans
      namespace: attack-simulation

  sinks:
    - name: local-tempo
      type: otlp
      endpoint: "http://tempo.observability:4317"

    - name: platform-traces
      type: otlp
      endpoint: "https://platform.example.com/api/otel/traces"
      credentials: secret:platform-api-key

  span_dimensions:
    - mitre.tactic
    - mitre.technique.id
    - attack_team
    - attack_phase
    - attack_operation_id
    - service.namespace

  storage:
    hot:
      type: local
      retention: 24h
    warm:
      type: s3
      retention: 30d
      bucket: range-telemetry

# Network connectivity
connectivity:
  overlay:
    type: tailscale
    auth_key: secret:vpn-auth-key
    network_name: example.com
    acl_tags: [tag:range, tag:operators, tag:agents]
    advertise_routes: [10.0.0.0/16]

  operator_access:
    methods: [vpn, cloud_shell]
    cloud_shell:
      type: ssm # or: iap, bastion
      enabled: true
      session_logging: true
    vpn:
      enabled: true
      ssh: true

  connections:
    - name: agents-to-targets
      type: tailscale
      source:
        environment: agent-cluster
        cidr: 172.16.0.0/16
      destination:
        environment: ad-attack-range
        cidr: 10.0.0.0/16
      policy:
        direction: egress_only
```

---

## Alternatives Considered

1. **JSON Schema Only**: Rejected because YAML is more human-readable and supports comments.
2. **Pulumi/CDK-style Imperative**: Rejected because declarative specs are easier to version, diff, and validate.
3. **Combined Range + Experiment**: Rejected to enable range reuse across multiple experiments (see RFC-0002).
4. **Embedded Provisioning in Bindings**: Rejected to keep resource mapping separate from configuration management.

## Affected Repos

| Repository              | Changes Required                                                     |
| :---------------------- | :------------------------------------------------------------------- |
| `aces-schema`           | JSON Schema and validation for CyberRange kind                       |
| `aces-runtime`          | Support for agent platform, telemetry, connectivity                  |
| `aces-provider-aws`     | Image filters, instance policies, security groups, private endpoints |
| `aces-provider-gcp`     | Image filters, IAM bindings, firewall rules, Private Service Connect |
| `aces-provider-azure`   | Image filters, RBAC, NSGs, Private Link                              |
| `aces-provider-docker`  | Resource profiles, networking                                        |
| `aces-provider-proxmox` | Resource profiles, VM templates                                      |
| `aces-provisioner`      | Ansible playbook execution via cloud shell/SSH                       |

## Consequences

### What Becomes Easier

- **Range reuse**: Same infrastructure supports multiple experiments
- **Independent versioning**: Infrastructure changes tracked separately from experiment changes
- **Provider flexibility**: Topology decoupled from instantiation backend
- **Team collaboration**: Infrastructure team can define ranges, research team defines experiments
- **Provisioning clarity**: Clear separation between infra creation and configuration

### What Becomes Harder

- **Simple scenarios**: Requires two files (range + experiment) instead of one
- **Learning curve**: Must understand range/experiment separation
- **Cloud specificity**: Some resource fields (e.g., image filters, instance policies) are cloud-specific (mitigated by provider abstraction)

---

## Cross-References

| Document                           | Relationship                                                                             |
| ---------------------------------- | ---------------------------------------------------------------------------------------- |
| RFC-0002: Experiment Specification | Defines agents, objectives, detection rules, and runtime that execute against this range |
