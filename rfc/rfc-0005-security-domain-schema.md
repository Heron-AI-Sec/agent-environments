# RFC-0005: Security Domain Schema

## Status

Proposed

## Summary

Propose a foundational attack relationship taxonomy for aces-schema that
models exploitable relationships between entities in cybersecurity
scenarios. The taxonomy is derived from BloodHound-compatible edge types
validated in production in Dreadnode Ares, covering Active Directory,
ADCS, Kerberos, Azure/Entra ID, AWS IAM, and GCP IAM domains.

It defines the core schema types needed for scenario specifications to
express attack graphs and defensive investigations:

**Red Team (Offensive):**

- **12 node types** (Host, Principal, Credential, GPO, etc.)
- **65 edge types** grouped by domain (AD ACL, Kerberos, ADCS, Cloud)
- **10 edge classifications** for behavioral categorization
- **9 credential kinds** with crackability/authentication semantics
- **21 enumeration techniques** with per-node/global metadata
- **Edge metadata** including conditions, severity, and ATT&CK mappings

**Blue Team (Defensive):**

- **4 blue team roles** (Orchestrator, Triage, Threat Hunter, Lateral Analyst)
- **5 blue team task types** for investigation workflow
- **~40 detection techniques** mapped to MITRE ATT&CK
- **6-level evidence classification** (Pyramid of Pain)
- **Investigation state model** with timeline, lateral movement graph, and escalation

The RFC specifies how this taxonomy integrates with aces-agent-sdk
observation/action spaces for both red and blue team agents.

## Motivation

ACES scenarios must express attack paths — the exploitable relationships
between entities that agents navigate during exercises. Without a
standardized taxonomy of these relationships, scenario authors will invent
ad-hoc edge types, making scenarios structurally incomparable across
environments. This directly undermines ACES' core value proposition.

### ACES Layer Alignment

This taxonomy lives in **aces-schema** (Specification layer). It defines
the types that:

- **aces-sdl** parses and validates (Specification layer)
- **aces-runtime** uses for scoring and state management (Runtime layer)
- **aces-agent-sdk** exposes in observation/action spaces (Instantiation
  layer)
- **aces-experiment** references for reproducibility controls
  (Experimentation layer)

The taxonomy is specification-layer infrastructure. Runtime telemetry
uses OCSF (ADR-0008). When an agent exploits an edge, the runtime emits
OCSF events; the edge type itself is an ACES-native concept.

### Why This Decision Matters

The attack relationship taxonomy is the single most consequential schema
design decision for cybersecurity evaluation scenarios. It determines:

1. **What attack paths scenarios can express.** Missing edge types mean
   entire attack classes are unrepresentable.
2. **Whether results are comparable across backends.** If different
   content packages use different edge types for the same attack, scoring
   is meaningless.
3. **Whether the community adopts the standard.** BloodHound's taxonomy
   is the de facto industry standard for AD attack graphs. Compatibility
   with it lowers the adoption barrier.

Dreadnode Ares has validated this taxonomy across thousands of generated
trajectories on synthetic AD environments ranging from 10 to 10,000+
hosts. The taxonomy has been refined through production use to distinguish
exploitable edges from structural relationships and to model credential
chains, delegation attacks, and ADCS escalation paths.

## Proposal

### 1. Node Types

Define a `NodeType` enum in aces-schema representing the entity types
that participate in attack graphs.

| Node Type | Description | Domain |
|-----------|-------------|--------|
| `Host` | A computer/server in the network | Core |
| `Principal` | A security principal (user, group, computer account, service account) | Core |
| `Credential` | A credential artifact (password, hash, ticket, key) | Core |
| `Service` | A network service running on a host | Core |
| `Subnet` | A network segment (CIDR block) | Core |
| `Domain` | An AD domain or cloud account boundary | Core |
| `Share` | A network file share | AD |
| `Artifact` | A lootable file (config, script, backup, credentials file) | Core |
| `GPO` | A Group Policy Object | AD |
| `Certificate` | A digital certificate | AD/ADCS |
| `CertificateTemplate` | An ADCS certificate template | AD/ADCS |
| `CertificateAuthority` | An ADCS certificate authority server | AD/ADCS |

### 2. Edge Types (Attack Relationships)

Edges are typed, directed relationships between nodes. Each edge type
belongs to a domain category and carries metadata about exploitation
conditions and severity.

#### 2.1 Core Structural Relationships

These are non-exploitable edges that define identity and containment
structure. They are used for transitive access computation (e.g., group
membership closure) but are not themselves attack actions.

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `MemberOf` | Principal → Principal (group) | Group membership |
| `Contains` | Domain/OU → Principal/Host | Containment hierarchy |
| `HasCredential` | Principal → Credential | Credential ownership |
| `Authenticates` | Credential → Principal | Credential grants access to principal |

#### 2.2 Active Directory — Local Privileges

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `AdminTo` | Principal → Host | Local admin on target host |
| `CanPSRemote` | Principal → Host | PowerShell remoting access |
| `CanRDP` | Principal → Host | Remote Desktop access |
| `ExecuteDCOM` | Principal → Host | DCOM execution rights |
| `HasSession` | Principal → Host | Active logon session on target host (implies credential exposure on dst) |
| `SQLAdmin` | Principal → Host | SQL Server admin access |

**Note on `HasSession`**: The edge direction is Principal → Host, representing
"this principal has an active session on this host." From an attacker's
perspective, compromising the host exposes the principal's credentials. The
semantic is "credential material for src is recoverable from dst."

#### 2.3 Active Directory — ACL Abuse

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `GenericAll` | Principal → Any | Full control over target object |
| `GenericWrite` | Principal → Any | Write any attribute on target |
| `WriteOwner` | Principal → Any | Can take ownership of target |
| `WriteDacl` | Principal → Any | Can modify target's DACL |
| `ForceChangePassword` | Principal → Principal | Reset target's password without knowing current |
| `AddMember` | Principal → Group | Can add members to target group |
| `AllExtendedRights` | Principal → Any | All extended rights on target |
| `Owns` | Principal → Any | Object ownership |
| `AddSelf` | Principal → Group | Can add self to target group |
| `AddAllowedToAct` | Principal → Host | Can configure RBCD on target |
| `ReadLAPSPassword` | Principal → Host | Can read LAPS password |
| `ReadGMSAPassword` | Principal → Principal | Can read gMSA password |

#### 2.4 Active Directory — Kerberos

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `HasSPNConfigured` | Principal → (property) | Kerberoastable — has a Service Principal Name configured |
| `DontReqPreAuth` | Principal → (property) | Kerberos preauthentication not required (vulnerable to AS-REP roasting) |
| `AllowedToDelegate` | Principal → Principal | Constrained delegation target |
| `AllowedToAct` | Principal → Host | Resource-based constrained delegation |
| `UnconstrainedDelegation` | Principal → (property) | Unconstrained delegation enabled |

#### 2.5 Active Directory — Domain Replication

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `GetChanges` | Principal → Domain | DS-Replication-Get-Changes right |
| `GetChangesAll` | Principal → Domain | DS-Replication-Get-Changes-All right |
| `DCSync` | Principal → Domain | Composite: GetChanges + GetChangesAll (can replicate all credentials) |

#### 2.6 Active Directory — ADCS (Certificate Services)

ADCS escalation paths follow the ESC numbering from SpecterOps research.
Some ESC types have sub-variants (a/b) representing distinct exploitation
conditions. The schema includes both the base types (used by the
trajectory engine for coarse-grained matching) and the specific variants
(used by manifest generation for precise vulnerability modeling).

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `ADCSESC1` | Principal → CertificateTemplate | ESC1: Enrollee supplies subject + client auth |
| `ADCSESC2` | Principal → CertificateTemplate | ESC2: Enrollee supplies subject via template flag |
| `ADCSESC3` | Principal → CertificateTemplate | ESC3: Enrollment agent template abuse |
| `ADCSESC4` | Principal → CertificateTemplate | ESC4: Vulnerable template ACL |
| `ADCSESC5` | Principal → CertificateTemplate | ESC5: Vulnerable PKI object ACL |
| `ADCSESC6` | Principal → CertificateAuthority | ESC6: EDITF_ATTRIBUTESUBJECTALTNAME2 on CA (base) |
| `ADCSESC6a` | Principal → CertificateAuthority | ESC6a: EDITF_ATTRIBUTESUBJECTALTNAME2 variant |
| `ADCSESC6b` | Principal → CertificateAuthority | ESC6b: EDITF_ATTRIBUTESUBJECTALTNAME2 variant |
| `ADCSESC7` | Principal → CertificateAuthority | ESC7: Vulnerable CA ACL (ManageCA / ManageCertificates) |
| `ADCSESC8` | Principal → CertificateAuthority | ESC8: NTLM relay to AD CS HTTP enrollment |
| `ADCSESC9` | Principal → CertificateTemplate | ESC9: No security extension (base) |
| `ADCSESC9a` | Principal → CertificateTemplate | ESC9a: No security extension + GenericWrite |
| `ADCSESC9b` | Principal → CertificateTemplate | ESC9b: No security extension variant |
| `ADCSESC10` | Principal → CertificateTemplate | ESC10: Subject alternative name weak mapping (base) |
| `ADCSESC10a` | Principal → CertificateTemplate | ESC10a: SAN weak mapping variant |
| `ADCSESC10b` | Principal → CertificateTemplate | ESC10b: SAN weak mapping variant |
| `ADCSESC11` | Principal → CertificateAuthority | ESC11: NTLM relay to ICPR RPC endpoint |
| `ADCSESC13` | Principal → CertificateTemplate | ESC13: Issuance policy with OID group link |
| `CanRequest` | Principal → CertificateTemplate | Can enroll in certificate template |
| `HasCertificate` | Principal → Certificate | Possesses a certificate |

#### 2.7 Active Directory — GPO Abuse

Group Policy Objects are frequently misconfigured with write permissions
that enable privilege escalation. These edges model both structural links
and abusable permissions.

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `GPLink` | GPO → OU/Domain | Group Policy link (structural) |
| `GPOAbuse` | Principal → GPO | Can modify GPO (WriteProperty, WriteDacl, GenericWrite) |
| `GPOImmediateTask` | Principal → GPO | Can create immediate scheduled task via GPO |

**GPO Attack Chain**: When a principal has `GPOAbuse` on a GPO that is
linked to computers (especially Domain Controllers), they can add
immediate scheduled tasks that execute as SYSTEM. This is a fast path
to Domain Admin.

#### 2.8 Active Directory — MSSQL

SQL Server attacks are common lateral movement and privilege escalation
vectors in enterprise environments.

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `SQLAdmin` | Principal → Host | SQL Server admin access (sysadmin role) |
| `MSSQLImpersonation` | Principal → Principal | Can impersonate another SQL login (EXECUTE AS) |
| `MSSQLLinkedServer` | Host → Host | SQL Server linked server relationship |
| `MSSQLXpCmdShell` | Principal → Host | Can execute xp_cmdshell (OS command execution) |

**MSSQL Attack Chain**: Compromise SQL login → impersonate sa → enable
xp_cmdshell → OS command execution as SQL service account → often has
SeImpersonatePrivilege → SYSTEM via potato exploit.

#### 2.9 Active Directory — gMSA

Group Managed Service Accounts have passwords managed by Active Directory.
Accounts with read access to `msDS-ManagedPassword` can retrieve the
NTLM hash without cracking.

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `ReadGMSAPassword` | Principal → Principal | Can read gMSA password (msDS-ManagedPassword) |

gMSA accounts often have elevated privileges (service accounts for SQL
Server, scheduled tasks, etc.), making this edge type high-value.

#### 2.10 Active Directory — AdminSDHolder

AdminSDHolder is a special AD container that propagates ACEs to protected
groups (Domain Admins, Enterprise Admins, etc.) every 60 minutes via
SDProp. Write access enables persistent backdoors.

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `AdminSDHolderWritable` | Principal → Domain | Can write to AdminSDHolder (persistent backdoor) |

#### 2.11 Active Directory — Trust Relationships

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `TrustedBy` | Domain → Domain | Domain trust relationship |
| `ParentOf` | Domain → Domain | Parent-child domain relationship |
| `CrossForestTrust` | Domain → Domain | Cross-forest trust (external) |

#### 2.12 Credential Chain

These edges model the lifecycle of credential acquisition, cracking, and
use. They enable multi-step attack chains where an agent must first
acquire a hash, then crack it, then use the password.

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `HasCredential` | Principal → Credential | (see §2.1) |
| `CanCrack` | Credential (hash) → Credential (password) | Hash is crackable (weak password) |
| `Authenticates` | Credential → Principal | (see §2.1) |
| `DerivedFrom` | Credential → Credential | Credential chain lineage (e.g., cracked from hash) |

**Attack Chain Tracking**: Each credential carries lineage metadata:

- `parent_id`: ID of the credential/hash that enabled this discovery
- `attack_step`: Position in the attack chain (0 = initial access)
- `source`: Tool/method that discovered this credential

This enables attack path reconstruction for scoring and reporting.

**Roasting Workflow**: Property edges (`HasSPNConfigured`, `DontReqPreAuth`)
enable enumeration techniques (`KERBEROAST`, `ASREP_ROAST`). These techniques
produce `roasted_hash` credentials at runtime. `CanCrack` edges linking
roasted hashes to passwords may be:

1. **Static**: Defined in the scenario manifest (the hash is known to be weak)
2. **Dynamic**: Generated at runtime when the agent successfully cracks a hash

This distinction has implications for aces-runtime: static edges are part of
the scenario specification, while dynamic edges are state changes during
execution. Both use the same `CanCrack` edge type.

#### 2.13 Local Privilege Escalation

Edges representing local privilege escalation on compromised hosts.

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `SeImpersonate` | Principal → Host | Has SeImpersonatePrivilege (potato exploits) |
| `LocalAdmin` | Principal → Host | Local administrator access |
| `ServiceAccount` | Principal → Service | Service account relationship |

**SeImpersonate Attack Chain**: Service accounts (IIS, SQL, etc.) often
have SeImpersonatePrivilege. Potato-style exploits (PrintSpoofer,
GodPotato, SweetPotato) abuse this to escalate to SYSTEM.

#### 2.14 Azure / Entra ID

**Note**: This is a minimal MVP set. BloodHound defines additional Azure
edges (AZContributor, AZKeyVaultContributor, AZAddOwner, AZAddSecret,
AZAutomationContributor, etc.). A future RFC will expand Azure/Entra
coverage. The inclusion criteria for this RFC is "edges validated in
Ares trajectory generation."

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `AZMemberOf` | AZ Principal → AZ Group | Azure group membership |
| `AZGlobalAdmin` | AZ Principal → AZ Tenant | Global Administrator role |
| `AZPrivilegedAuthAdmin` | AZ Principal → AZ Tenant | Privileged Authentication Administrator |
| `AZOwns` | AZ Principal → AZ Object | Object ownership in Entra ID |
| `AZAddMembers` | AZ Principal → AZ Group | Can add members to Azure group |

#### 2.15 AWS IAM

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `AWSAssumeRole` | AWS Principal → AWS Role | Can assume IAM role |
| `AWSHasPolicy` | AWS Principal → AWS Policy | IAM policy attachment |
| `AWSS3Access` | AWS Principal → AWS S3 Bucket | S3 bucket access |
| `AWSEC2Access` | AWS Principal → AWS EC2 Instance | EC2 instance access |

#### 2.16 GCP IAM

| Edge Type | Source → Target | Description |
|-----------|----------------|-------------|
| `GCPHasRole` | GCP Principal → GCP Resource | IAM role binding |
| `GCPImpersonate` | GCP Principal → GCP Service Account | Service account impersonation |
| `GCPGCSAccess` | GCP Principal → GCP GCS Bucket | Cloud Storage access |

### 3. Edge Metadata

Every edge carries metadata beyond its type:

```yaml
EdgeConditions:
  requires_auth: bool       # Must have valid credentials
  requires_session: bool    # Must have active session on source host
  requires_cred_type: str?  # Specific credential type needed (e.g., "kerberos_tgt")

EdgeSeverity: enum
  info | low | medium | high | critical

EdgeMeta:
  spn: list[str]            # Service Principal Names (for delegation edges)
```

### 4. Credential Types

| Kind | Description | Use |
|------|-------------|-----|
| `password` | Plaintext password | Direct authentication |
| `ntlm_hash` | NTLM hash | Pass-the-hash |
| `kerberos_tgt` | Kerberos TGT | Pass-the-ticket |
| `kerberos_tgs` | Kerberos TGS | Service ticket |
| `roasted_hash` | AS-REP or TGS-REP roasted hash | Crack-only (no direct auth) |
| `ssh_key` | SSH private key | SSH authentication |
| `api_key` | API key | Cloud/service API access |
| `token` | Bearer/session token | Token-based auth |
| `certificate` | X.509 certificate | Certificate-based auth |

Each credential has a `CredentialPolicy`:

```yaml
CredentialPolicy:
  weak: bool      # Crackable by dictionary attack
  reused: bool    # Same password used elsewhere
  expires: bool   # Has expiration
  managed: bool   # Machine-managed (gMSA, etc.)
  rotated: bool   # Subject to rotation policy
```

### 5. Supporting Enumerations

#### Principal Types

`user` | `group` | `computer` | `service`

#### Host Roles

`dc` (Domain Controller) | `file` (File Server) | `sql` (SQL Server) |
`web` (Web Server) | `workstation` | `ci` (CI/CD) | `vpn` | `mail` |
`ca` (Certificate Authority) | `generic`

#### Exposure Profiles

`internal` | `dmz` | `external`

#### Authentication Methods

`none` | `ntlm` | `kerberos` | `basic` | `bearer` | `certificate` |
`ssh_key`

### 6. Enumeration Technique Types

These represent reconnaissance actions an agent can take to discover
nodes and edges. They are not attack relationships but are part of the
scenario action space.

| Category | Techniques |
|----------|-----------|
| Network | `ping_sweep`, `port_scan`, `service_enum`, `dns_enum` |
| SMB | `smb_enum`, `share_enum`, `file_enum`, `share_spider` |
| LDAP/AD | `ldap_users`, `ldap_groups`, `ldap_computers`, `ldap_self_groups`, `ldap_kerberoastable`, `ldap_asrep_roastable`, `ldap_admin_count`, `ldap_trusts`, `ldap_gmsa`, `ldap_adminsd_holder` |
| Kerberos | `kerberoast`, `asrep_roast`, `find_delegation` |
| ADCS | `adcs_enum`, `adcs_vulnerable_templates` |
| Database | `mssql_enum`, `mssql_links`, `mssql_impersonation_check` |
| BloodHound | `bloodhound_collect`, `bloodhound_paths`, `bloodhound_acl_paths` |
| GPO | `gpo_enum`, `gpo_permissions` |

#### Enumeration Technique Metadata

Each technique carries metadata that determines when it can be offered
to an agent and what resources it requires:

```yaml
EnumTechnique:
  type: EnumTechniqueType
  per_node: bool          # True = applies to specific owned principal/host
                          # False = domain-wide query
  required_ports: set[int]  # Ports that must be open on target
  requires_auth: bool     # Needs valid credentials to execute
```

| Technique | per_node | required_ports | requires_auth |
|-----------|----------|----------------|---------------|
| `ping_sweep` | false | — | false |
| `port_scan` | true | — | false |
| `ldap_users` | false | 389, 636 | true |
| `ldap_self_groups` | true | 389, 636 | true |
| `kerberoast` | false | 88 | true |
| `mssql_enum` | true | 1433 | true |

*Table shows representative examples. Full metadata for all 21 techniques
will be defined in aces-schema.*

**Per-node vs Global**: Global techniques (e.g., `ldap_users`) query the
entire domain and return all visible results. Per-node techniques (e.g.,
`ldap_self_groups`, `port_scan`) operate on a specific target and require
the agent to specify which principal/host to enumerate.

### 7. OCSF Mapping

ACES uses OCSF as the exercise telemetry contract (ADR-0008). This
taxonomy maps to OCSF as follows:

#### Direct Mappings (OCSF has equivalent concepts)

| Proposed Type | OCSF Class/Object | Notes |
|--------------|-------------------|-------|
| `Host` | `Device` object | Map hostname, IP, OS. Add role, exposure_profile as extensions. |
| `Service` | `Service` object | Good alignment on port, proto, product, version. |
| `Principal` (user) | `User` object | Map SAM, UPN, SID. |
| `Principal` (group) | `Group` object | Map SAM, SID. |
| `Credential` | `Digital Signature` or custom | Partial. OCSF doesn't model credential artifacts as first-class objects. |
| `Software` | `Software` object | Good alignment on vendor, version, CVEs. |
| Enumeration results | `Discovery` category [5] | Port scans → Device Inventory [5001]. User queries → User Inventory [5003]. |
| Authentication events | `Authentication` [3002] | Agent login attempts map directly. |
| Network scans | `Network Activity` [4001] | Nmap scans map to Network Activity events. |

#### Gap: Attack Relationships

**OCSF models events (things that happened), not potential relationships
(things that could be exploited).** This is the fundamental gap.

OCSF has no concept of:

- A typed edge between two entities representing an exploitable path
- An attack graph as a first-class data structure
- Edge conditions, severity, or activation requirements
- Credential chains (acquire → crack → authenticate)

The closest OCSF constructs are:

- `Vulnerability Finding` [2002] — could model individual
  misconfigurations (e.g., "this user has GenericAll on Domain Admins")
  but loses the graph structure
- `Detection Finding` [2004] — could model detected exploitation
  attempts but is post-hoc, not declarative

**Recommendation:** Define attack relationships as an ACES-specific
schema domain that references OCSF objects (Device, User, Group) but does
not attempt to model the graph within OCSF's event-centric framework. The
OCSF integration point is at the telemetry layer: when an agent exploits
an edge, the runtime emits OCSF events describing the action. The
scenario specification uses ACES-native types to define the attack graph.

This is consistent with ADR-0008's intent: OCSF is the *telemetry*
lingua franca, not the *specification* lingua franca.

### 8. Vulnerability Queue Prioritization

When agents discover exploitable edges, they are queued for exploitation
based on priority. The priority system enables autonomous agents to make
rational decisions about which attack paths to pursue first.

#### 8.1 Priority Tiers

Vulnerabilities are assigned to priority tiers (lower number = higher
priority):

| Tier | Priority | Vulnerability Types | Rationale |
|------|----------|---------------------|-----------|
| 1 | 1-2 | `ADCS_ESC1`, `ADCS_ESC4` | Direct certificate abuse → instant DA |
| 2 | 3 | `ADCS_ESC8` | Requires relay setup but reliable DA path |
| 3 | 4-6 | `constrained_delegation`, `unconstrained_delegation`, `rbcd` | High confidence when credentials available |
| 4 | 7-8 | `krbtgt_hash`, `domain_admin_hash` | Instant DA if obtained |
| 5 | 9 | `acl_abuse` | Requires multi-step chains |
| 6 | 10-11 | `mssql_impersonation`, `mssql_linked`, `mssql_xp_cmdshell` | Lateral movement, may chain to DA |
| 7 | 12-15 | `gpo_abuse`, `laps_abuse`, `dcsync`, `shadow_credentials` | Various privilege escalation |
| 8 | 16-21 | `gmsa_readable`, `genericall_domain_admins`, `kerberoast`, `asreproast` | Targeted credential attacks |
| 9 | 22+ | `smb_relay_target`, `adminsd_holder_writable`, `password_spray` | Lower priority or requires setup |

#### 8.2 Dynamic Priority Adjustment

Priorities are recalculated at dequeue time based on current state:

- **Constrained delegation with credentials**: If the agent has cracked
  credentials for the delegation account AND the target SPN is a DC
  service (cifs/, ldap/, host/, gc/), priority boosts from 4 → 2.
- **MSSQL with sysadmin confirmed**: If `can_impersonate_sa` or
  `is_sysadmin` is confirmed, priority boosts to 3.

This prevents the agent from attempting exploits it cannot complete and
prioritizes high-confidence attack paths.

#### 8.3 Prerequisite Checking

Some vulnerabilities require prerequisites before exploitation:

| Vulnerability Type | Prerequisite |
|--------------------|--------------|
| `constrained_delegation` | Cleartext password for the account (hash not sufficient) |
| `dcsync` | GetChanges + GetChangesAll rights (composite) |
| `adcs_esc8` | ntlmrelayx listener running before coercion |

Vulnerabilities failing prerequisite checks are deferred until conditions
are met.

### 9. Edge Classification

Edge types are grouped into **behavioral classifications** for use in
pathfinding, scoring, and strategy computation. These classifications
are orthogonal to the domain organization in §2.X:

- **§2.X (Domain Organization)**: Where edge types logically belong
  (AD ACL, Kerberos, ADCS, etc.) — useful for documentation and tooling.
- **§9 (Behavioral Classification)**: How the trajectory engine and
  scoring system treat edges — useful for runtime behavior.

For example, `ReadLAPSPassword` appears in §2.3 (AD ACL Abuse) because
it's an ACL-based permission, but it's classified as `CREDENTIAL` in §9
because it results in credential acquisition.

| Classification | Edge Types | Use |
|----------------|------------|-----|
| `STRUCTURAL` | MemberOf, Contains, HasCredential, Authenticates, DerivedFrom, ParentOf | Non-exploitable; used for transitive access computation (group membership closure) |
| `PROPERTY` | HasSPNConfigured, DontReqPreAuth, UnconstrainedDelegation, SeImpersonate | Node properties exposed as edges; handled by enumeration, not exploitation |
| `CREDENTIAL` | HasCredential, CanCrack, Authenticates, ReadLAPSPassword, ReadGMSAPassword | Credential acquisition or use |
| `ACL` | GenericAll, GenericWrite, WriteOwner, WriteDacl, ForceChangePassword, AddMember, AllExtendedRights, Owns, AddSelf, AddAllowedToAct, AdminSDHolderWritable | ACL-based abuse |
| `HOST_TARGETING` | AdminTo, CanRDP, CanPSRemote, ExecuteDCOM, HasSession, SQLAdmin, LocalAdmin | Target hosts for compromise |
| `MSSQL` | MSSQLImpersonation, MSSQLLinkedServer, MSSQLXpCmdShell | SQL Server exploitation |
| `GPO` | GPLink, GPOAbuse, GPOImmediateTask | Group Policy abuse |
| `DELEGATION` | AllowedToDelegate, AllowedToAct, UnconstrainedDelegation | Kerberos delegation attacks |
| `ADCS` | ADCSESC1-13, CanRequest, HasCertificate | Certificate services escalation |
| `CLOUD` | AZ*, AWS*, GCP* edges | Cloud provider edges |

These classifications enable:

- **Scoring weights**: Different severity for credential vs ACL edges
- **Strategy computation**: Prioritize HOST_TARGETING over STRUCTURAL
- **Frontier filtering**: Exclude PROPERTY edges from exploitation
- **Path analysis**: Count credential hops vs lateral movement hops

### 10. Default Edge Severities

Each edge type has a default severity for scoring. Scenario authors can
override these per-edge, but defaults provide consistent baseline
scoring.

| Severity | Edge Types | Rationale |
|----------|------------|-----------|
| `critical` | DCSync, AZGlobalAdmin | Direct domain/tenant compromise |
| `high` | AdminTo, GenericAll, WriteDacl, WriteOwner, AllExtendedRights, Owns, GetChanges, GetChangesAll, ADCSESC1, ADCSESC4, AZPrivilegedAuthAdmin | Significant privilege escalation |
| `medium` | CanPSRemote, CanRDP, ExecuteDCOM, SQLAdmin, ForceChangePassword, AddMember, GenericWrite, AddAllowedToAct, ReadLAPSPassword, ReadGMSAPassword, AllowedToDelegate, AllowedToAct, CanCrack, ADCSESC3, AWSAssumeRole, GCPImpersonate | Lateral movement / credential access |
| `low` | HasSession, AddSelf, HasSPNConfigured, DontReqPreAuth, UnconstrainedDelegation | Reconnaissance value |
| `info` | MemberOf, Contains, HasCredential, Authenticates, GPLink, TrustedBy, CanRequest, HasCertificate, AZMemberOf, AWSHasPolicy, GCPHasRole | Structural relationships |

### 11. Extension Mechanism

New domains are added as extension modules that introduce new edge types,
node types, and metadata without modifying the core schema.

#### Example: OT/ICS Extension (Future)

```yaml
# New node types (protobuf enum range 200-249)
NodeType += PLCController | HMIStation | RTU | Historian

# New edge types (protobuf enum range 200-299)
EdgeType += ModbusAccess | DNP3Access | OPCUABrowse | FirmwareUpdate
            | PhysicalAccess | SerialConnection

# New metadata
OTEdgeMeta:
  protocol: modbus | dnp3 | opcua | bacnet
  safety_impact: none | degraded | unsafe
```

#### Example: Wireless Extension (Future)

```yaml
# New node types
NodeType += AccessPoint | WirelessClient

# New edge types (protobuf enum range 300-399)
EdgeType += WPAHandshake | EvilTwin | Deauth | RogueAP
```

The extension pattern: new enums extend the base enums (union), new
metadata types are optional fields on the edge, and new node types
register in the NodeType enum. No existing types are modified.

### 12. Agent SDK Integration

This taxonomy directly shapes the aces-agent-sdk `gymnasium.Env` interface
(ARCHITECTURE.md Boundary 4). The mapping:

#### Observation Space

Discovered edges are exposed as typed tuples in the observation:

```python
# Observation includes discovered attack graph
observation = {
    "edges": [
        {"src": "user-123", "dst": "host-456", "type": "AdminTo", "severity": "high"},
        {"src": "user-123", "dst": "group-789", "type": "MemberOf", "severity": "info"},
    ],
    "credentials": [
        {"id": "cred-001", "kind": "ntlm_hash", "owner": "user-123"},
    ],
    "owned_principals": ["user-123"],
    "compromised_hosts": [],
}
```

#### Action Space

Agent actions map to enumeration techniques (§6) and edge exploitation:

```python
# Enumeration action — discover new edges/nodes
action = {
    "type": "enumerate",
    "technique": "ldap_kerberoastable",  # EnumTechniqueType
    "target": None,  # Global technique, no target needed
}

# Exploitation action — traverse an edge
action = {
    "type": "exploit",
    "edge_id": "edge-abc",  # Reference to discovered edge
    "credential_id": "cred-001",  # Credential to use (if required)
}
```

#### Classification-Based Action Filtering

Edge classifications (§9) enable action space filtering:

- `STRUCTURAL` edges are never directly exploitable (MemberOf, Contains)
- `PROPERTY` edges are handled via enumeration, not exploitation
- `CREDENTIAL`, `ACL`, `HOST_TARGETING`, `MSSQL`, `GPO`, `DELEGATION`, `ADCS` edges are exploitable

The runtime uses classification to determine valid actions per state.

#### Vulnerability Queue Integration

When agents discover exploitable edges, they are queued as vulnerabilities
with priority-based ordering (§8). The action space exposes:

```python
# Queue a discovered vulnerability for exploitation
action = {
    "type": "queue_vulnerability",
    "vuln_type": "constrained_delegation",
    "target": "svc_backup",
    "details": {
        "account_name": "svc_backup",
        "target_spn": "cifs/DC01.contoso.local",
        "has_credentials": True,
    },
}

# Get next priority vulnerability to exploit
action = {
    "type": "get_next_vulnerability",
}
# Returns highest priority vuln that passes prerequisite checks
```

This enables multi-agent coordination where discovery agents queue
vulnerabilities and exploitation agents consume them based on priority.

#### Scoring Integration

Default severities (§9) enable backend-agnostic scoring:

```python
# Scoring weights can combine severity + classification
score_weights = {
    ("critical", "credential"): 100,
    ("high", "host_targeting"): 50,
    ("high", "acl"): 40,
    ("medium", "credential"): 25,
    # ...
}
```

Scenario authors can override defaults per-edge for custom scoring.

### 13. Blue Team Taxonomy

ACES scenarios support both red team (offensive) and blue team (defensive)
agents. This section defines the schema types for defensive operations,
enabling autonomous SOC investigation, threat hunting, and incident
response.

#### 13.1 Blue Team Roles

Blue team agents operate in specialized roles with distinct responsibilities
and tool access. This parallels the red team multi-agent architecture but
focuses on detection and investigation.

| Role | Description | Primary Tools |
|------|-------------|---------------|
| `ORCHESTRATOR` | Coordinates multi-agent investigation workflow | Task dispatch, result aggregation |
| `TRIAGE` | Initial alert assessment and severity determination | Alert parsing, quick queries, escalation decisions |
| `THREAT_HUNTER` | Deep threat hunting and technique detection | Detection queries, MITRE mapping, evidence collection |
| `LATERAL_ANALYST` | Lateral movement scope analysis | Connection graphing, pivot tracking, containment recommendations |

**Why Blue Team Roles are Schema-Defined (Red Team Roles are Not)**

Blue team roles are defined in aces-schema; red team roles (RECON,
CREDENTIAL_ACCESS, PRIVESC, LATERAL, etc. — see Open Question #6) are
deferred to runtime. This asymmetry is intentional:

1. **Blue team roles map to standardized SOC workflows.** Triage →
   Investigation → Escalation is a universal pattern across security
   operations. Role definitions affect observation/action space partitioning
   and scoring, making them specification-layer concerns.

2. **Red team roles are orchestration strategies.** Whether an agent uses
   RECON/PRIVESC/LATERAL decomposition vs. monolithic execution is a
   runtime optimization, not a scenario property. Different agent
   implementations may use different role structures for the same scenario.

3. **Blue team scoring depends on role performance.** Detection rate per
   role (did TRIAGE correctly escalate?), time-to-detect per stage, and
   evidence pyramid level are role-specific metrics. These metrics require
   schema-level role definitions to be portable across implementations.

4. **Red team scoring is goal-based, not role-based.** Red team success is
   measured by attack path completion, stealth, and efficiency — not by
   which internal agent handled which step.

If future experience demonstrates that red team role standardization improves
interoperability, a subsequent RFC can promote red team roles to schema level.

#### 13.2 Blue Team Task Types

| Task Type | Description | Assigned To |
|-----------|-------------|-------------|
| `TRIAGE_ALERT` | Initial alert triage and severity assessment | TRIAGE |
| `THREAT_HUNT` | Hunt for specific technique or indicator | THREAT_HUNTER |
| `LATERAL_ANALYSIS` | Analyze lateral movement scope from a host | LATERAL_ANALYST |
| `USER_INVESTIGATION` | Deep investigation of a specific user | THREAT_HUNTER |
| `HOST_INVESTIGATION` | Deep investigation of a specific host | THREAT_HUNTER |

#### 13.3 Investigation State Model

Defensive agents maintain investigation state that tracks progress through
a structured workflow:

```yaml
InvestigationState:
  # Core tracking
  alert_id: str
  stage: InvestigationStage        # triage → causation → lateral → synthesis
  escalated: bool
  escalation_reason: str?

  # Evidence collection (Pyramid of Pain levels 1-6)
  evidence: list[Evidence]
  timeline: list[TimelineEvent]

  # MITRE mapping
  techniques_identified: set[str]  # T1003, T1558, etc.
  tactics_identified: set[str]     # TA0006, TA0008, etc.

  # Lateral movement graph
  lateral_connections: list[LateralConnection]
  investigated_hosts: set[str]
  pending_hosts: set[str]

  # Query management
  queued_pivot_queries: list[Query]
  queued_chain_queries: list[Query]

  # Recommendations
  recommendations: list[str]
```

**Investigation Stages:**

| Stage | Description | Exit Criteria |
|-------|-------------|---------------|
| `TRIAGE` | Initial alert assessment | Severity determined, key IOCs extracted |
| `CAUSATION` | Root cause analysis | Attack technique identified, initial evidence collected |
| `LATERAL` | Scope determination | All affected hosts/users identified |
| `SYNTHESIS` | Final analysis | Attack synopsis written, recommendations generated |

#### 13.4 Evidence Classification (Pyramid of Pain)

Evidence is classified using David Bianco's Pyramid of Pain, which ranks
indicators by how difficult they are for attackers to change:

| Level | Category | Description | Examples |
|-------|----------|-------------|----------|
| 1 | Hash Values | File hashes (trivial for attacker to change) | MD5, SHA256 of malware |
| 2 | IP Addresses | Network indicators | C2 server IPs |
| 3 | Domain Names | DNS-based indicators | Phishing domains |
| 4 | Network/Host Artifacts | Behavioral patterns on network/host | Registry keys, file paths, user agents |
| 5 | Tools | Attacker tooling signatures | Mimikatz, Cobalt Strike, Impacket |
| 6 | TTPs | Tactics, Techniques, Procedures | MITRE ATT&CK mappings |

**Goal**: Defensive agents should climb the pyramid toward TTPs, as these
are the hardest for attackers to change and provide the most durable
detection value.

```yaml
Evidence:
  id: str
  level: PyramidLevel             # 1-6
  category: str                   # "hash", "ip", "domain", "artifact", "tool", "ttp"
  value: str                      # The actual indicator
  confidence: float               # 0.0-1.0
  source_query_id: str?           # Query that discovered this evidence
  mitre_technique: str?           # T-code if applicable
  validated: bool                 # Has this evidence been corroborated?
  timestamp: datetime
```

#### 13.5 Detection Technique Types

These represent detection queries that blue team agents can execute.
They are the defensive counterpart to red team enumeration techniques (§6).

| Category | Techniques | MITRE Coverage |
|----------|-----------|----------------|
| **Credential Theft** | `detect_secretsdump`, `detect_dcsync`, `detect_kerberoasting`, `detect_asrep_roasting`, `detect_brute_force`, `detect_lsa_secrets_access` | T1003, T1558, T1110 |
| **Lateral Movement** | `detect_lateral_movement`, `detect_pass_the_hash`, `detect_smb_file_access` | T1021, T1550 |
| **Impacket Tools** | `detect_impacket_wmiexec`, `detect_impacket_psexec`, `detect_impacket_smbexec`, `detect_impacket_atexec`, `detect_impacket_dcomexec`, `detect_impacket_secretsdump`, `detect_impacket_ntlmrelayx`, `detect_impacket_smbclient` | T1021, T1003 |
| **ADCS Attacks** | `detect_adcs_exploitation`, `detect_esc1_attack`, `detect_esc4_attack`, `detect_esc8_attack`, `detect_certificate_authentication` | T1649 |
| **Kerberos Attacks** | `detect_delegation_abuse`, `detect_s4u_delegation`, `detect_golden_ticket` | T1558 |
| **BloodHound** | `detect_bloodhound_collection`, `detect_bloodhound_domain_enum`, `detect_bloodhound_acl_enum`, `detect_bloodhound_session_enum`, `detect_bloodhound_gpo_enum`, `detect_bloodhound_computer_enum` | T1087, T1069 |
| **Reconnaissance** | `detect_port_scanning`, `detect_user_enumeration`, `detect_share_enumeration` | T1046, T1087, T1135 |
| **Execution** | `detect_suspicious_execution`, `detect_certipy_enumeration`, `detect_remote_registry_start` | T1059 |

**Detection Technique Metadata:**

```yaml
DetectionTechnique:
  type: DetectionTechniqueType
  mitre_technique_id: str         # Primary ATT&CK technique
  mitre_subtechnique_id: str?     # Sub-technique if applicable
  windows_event_ids: list[int]    # Relevant Windows Security event IDs
  default_time_window: duration   # Recommended lookback period
  requires_host_context: bool     # Needs specific hostname to query
  log_source: str                 # e.g., "windows-security", "sysmon"
```

| Technique | Event IDs | Time Window | Host Context |
|-----------|-----------|-------------|--------------|
| `detect_dcsync` | 4662 | 1h | false |
| `detect_kerberoasting` | 4769 | 1h | false |
| `detect_pass_the_hash` | 4624, 4625 | 1h | true |
| `detect_lateral_movement` | 4624, 4648 | 1h | true |
| `detect_golden_ticket` | 4768, 4769 | 24h | false |

#### 13.6 Lateral Connection Types

When analyzing lateral movement scope, defensive agents track connection
types between hosts:

| Connection Type | Description | Detection Method |
|-----------------|-------------|------------------|
| `SMB` | SMB/CIFS file sharing | Event 5140, 5145 |
| `RDP` | Remote Desktop Protocol | Event 4624 (Type 10) |
| `WMI` | Windows Management Instrumentation | Event 4624 (Type 3) + WMI process |
| `PSEXEC` | PsExec-style remote execution | Event 4624 + service creation |
| `SSH` | Secure Shell | Auth logs |
| `WINRM` | Windows Remote Management | Event 4624 (Type 3) + WinRM |
| `DCOM` | Distributed COM | Event 4624 (Type 3) + DCOM |

```yaml
LateralConnection:
  source_host: str
  target_host: str
  connection_type: LateralConnectionType
  timestamp: datetime
  source_user: str?
  evidence_ids: list[str]         # Evidence supporting this connection
```

#### 13.7 Alert Correlation

Defensive agents correlate alerts to identify related activity:

```yaml
AlertCorrelation:
  primary_alert_id: str
  correlated_alerts: list[str]
  correlation_type: CorrelationType
  shared_indicators: list[str]    # Common hosts, users, techniques

CorrelationType: enum
  same_host | same_user | same_technique | same_timeframe | same_campaign
```

#### 13.8 Blue Team Agent SDK Integration

The aces-agent-sdk exposes defensive capabilities through the same
`gymnasium.Env` interface used for red team agents.

**Observation Space (Blue Team):**

```python
observation = {
    # Current investigation state
    "investigation": {
        "alert_id": "alert-123",
        "stage": "causation",
        "escalated": False,
        "techniques_identified": ["T1003.006", "T1558.003"],
    },

    # Collected evidence by pyramid level
    "evidence": [
        {"id": "ev-001", "level": 5, "category": "tool", "value": "mimikatz", "confidence": 0.95},
        {"id": "ev-002", "level": 6, "category": "ttp", "value": "T1003.006", "confidence": 0.90},
    ],

    # Timeline of events
    "timeline": [
        {"timestamp": "2024-01-15T10:30:00Z", "event": "DCSync replication detected", "host": "DC01"},
    ],

    # Lateral movement graph
    "lateral_graph": {
        "connections": [
            {"src": "WS01", "dst": "DC01", "type": "SMB", "user": "admin"},
        ],
        "investigated_hosts": ["WS01"],
        "pending_hosts": ["DC01", "FS01"],
    },

    # Queued queries for execution
    "queued_queries": [
        {"type": "pivot", "target_host": "DC01", "technique": "detect_dcsync"},
    ],
}
```

**Action Space (Blue Team):**

```python
# Execute a detection query
action = {
    "type": "detect",
    "technique": "detect_kerberoasting",
    "target_host": None,  # Domain-wide query
    "time_window": "1h",
}

# Record evidence
action = {
    "type": "record_evidence",
    "level": 6,  # TTP
    "category": "ttp",
    "value": "T1558.003",
    "confidence": 0.9,
    "mitre_technique": "T1558.003",
}

# Add timeline event
action = {
    "type": "add_timeline_event",
    "timestamp": "2024-01-15T10:30:00Z",
    "event": "Kerberoasting activity detected",
    "host": "DC01",
    "mitre_technique": "T1558.003",
}

# Track lateral connection
action = {
    "type": "record_lateral_connection",
    "source_host": "WS01",
    "target_host": "DC01",
    "connection_type": "SMB",
    "source_user": "admin",
}

# Transition investigation stage
action = {
    "type": "transition_stage",
    "new_stage": "lateral",
}

# Escalate investigation
action = {
    "type": "escalate",
    "severity": "critical",
    "reason": "Active DCSync attack in progress",
}

# Complete investigation
action = {
    "type": "complete_investigation",
    "attack_synopsis": "Attacker compromised WS01, moved to DC01 via SMB...",
    "recommendations": ["Reset krbtgt password", "Isolate WS01", ...],
}
```

**Multi-Agent Coordination (Blue Team):**

```python
# Orchestrator dispatches task to worker
action = {
    "type": "dispatch_task",
    "task_type": "THREAT_HUNT",
    "target_role": "THREAT_HUNTER",
    "parameters": {
        "technique": "T1558.003",
        "hosts": ["DC01", "DC02"],
    },
}

# Worker reports completion
action = {
    "type": "task_complete",
    "task_id": "task-456",
    "findings": {
        "techniques_found": ["T1558.003"],
        "evidence_ids": ["ev-001", "ev-002"],
        "severity": "high",
    },
}
```

#### 13.9 Red vs Blue Scenario Modes

ACES scenarios can run in three modes:

| Mode | Description | Agent Types |
|------|-------------|-------------|
| `RED_ONLY` | Attack simulation without defenders | Red team agents only |
| `BLUE_ONLY` | Detection/response exercise with simulated attacks | Blue team agents only |
| `PURPLE` | Adversarial mode with competing red and blue agents | Both agent types |

In `PURPLE` mode, red team actions generate telemetry that blue team
agents must detect. The scoring function evaluates both:

- **Red team**: Attack path completion, stealth, efficiency
- **Blue team**: Detection rate, time-to-detect, escalation accuracy

### 14. Concrete Examples

#### JSON Schema (candidate format)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ACES Attack Relationship",
  "$defs": {
    "NodeType": {
      "type": "string",
      "enum": [
        "Host", "Principal", "Credential", "Service", "Subnet",
        "Domain", "Share", "Artifact", "GPO", "Certificate",
        "CertificateTemplate", "CertificateAuthority"
      ]
    },
    "EdgeType": {
      "type": "string",
      "enum": [
        "MemberOf", "Contains", "HasCredential", "Authenticates", "DerivedFrom",
        "AdminTo", "CanPSRemote", "CanRDP", "ExecuteDCOM", "HasSession",
        "SQLAdmin", "LocalAdmin", "SeImpersonate", "ServiceAccount",
        "GenericAll", "GenericWrite", "WriteOwner",
        "WriteDacl", "ForceChangePassword", "AddMember",
        "AllExtendedRights", "Owns", "AddSelf", "AddAllowedToAct",
        "ReadLAPSPassword", "ReadGMSAPassword", "AdminSDHolderWritable",
        "HasSPNConfigured", "DontReqPreAuth", "AllowedToDelegate", "AllowedToAct",
        "UnconstrainedDelegation", "GetChanges", "GetChangesAll",
        "DCSync", "GPLink", "GPOAbuse", "GPOImmediateTask",
        "MSSQLImpersonation", "MSSQLLinkedServer", "MSSQLXpCmdShell",
        "ADCSESC1", "ADCSESC2", "ADCSESC3", "ADCSESC4",
        "ADCSESC5", "ADCSESC6", "ADCSESC6a", "ADCSESC6b", "ADCSESC7",
        "ADCSESC8", "ADCSESC9", "ADCSESC9a", "ADCSESC9b", "ADCSESC10",
        "ADCSESC10a", "ADCSESC10b", "ADCSESC11", "ADCSESC13",
        "CanRequest", "HasCertificate", "CanCrack",
        "TrustedBy", "ParentOf", "CrossForestTrust",
        "AZMemberOf", "AZGlobalAdmin", "AZPrivilegedAuthAdmin",
        "AZOwns", "AZAddMembers",
        "AWSAssumeRole", "AWSHasPolicy", "AWSS3Access", "AWSEC2Access",
        "GCPHasRole", "GCPImpersonate", "GCPGCSAccess"
      ]
    },
    "EdgeSeverity": {
      "type": "string",
      "enum": ["info", "low", "medium", "high", "critical"]
    },
    "EdgeClassification": {
      "type": "string",
      "enum": [
        "structural", "property", "credential", "acl",
        "host_targeting", "mssql", "gpo", "delegation", "adcs", "cloud"
      ]
    },
    "EdgeConditions": {
      "type": "object",
      "properties": {
        "requires_auth": { "type": "boolean", "default": false },
        "requires_session": { "type": "boolean", "default": false },
        "requires_cred_type": { "type": ["string", "null"], "default": null }
      },
      "additionalProperties": false
    },
    "EdgeMeta": {
      "type": "object",
      "properties": {
        "spn": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Service Principal Names (for delegation edges)"
        },
        "mitre_technique_id": {
          "type": ["string", "null"],
          "description": "Optional ATT&CK technique ID (e.g., T1558)"
        }
      },
      "additionalProperties": false
    },
    "AttackRelationship": {
      "type": "object",
      "required": ["edge_id", "type", "src", "dst"],
      "properties": {
        "edge_id": { "type": "string", "format": "uuid" },
        "type": { "$ref": "#/$defs/EdgeType" },
        "src": { "type": "string", "description": "Source entity ID" },
        "dst": { "type": "string", "description": "Target entity ID" },
        "src_type": { "$ref": "#/$defs/NodeType" },
        "dst_type": { "$ref": "#/$defs/NodeType" },
        "conditions": { "$ref": "#/$defs/EdgeConditions" },
        "severity": { "$ref": "#/$defs/EdgeSeverity" },
        "classification": { "$ref": "#/$defs/EdgeClassification" },
        "meta": { "$ref": "#/$defs/EdgeMeta" }
      },
      "additionalProperties": false
    },

    "BlueRole": {
      "type": "string",
      "enum": ["orchestrator", "triage", "threat_hunter", "lateral_analyst"]
    },
    "BlueTaskType": {
      "type": "string",
      "enum": ["triage_alert", "threat_hunt", "lateral_analysis", "user_investigation", "host_investigation"]
    },
    "InvestigationStage": {
      "type": "string",
      "enum": ["triage", "causation", "lateral", "synthesis"]
    },
    "PyramidLevel": {
      "type": "integer",
      "minimum": 1,
      "maximum": 6,
      "description": "Pyramid of Pain level (1=hashes, 6=TTPs)"
    },
    "LateralConnectionType": {
      "type": "string",
      "enum": ["smb", "rdp", "wmi", "psexec", "ssh", "winrm", "dcom"]
    },
    "DetectionTechniqueType": {
      "type": "string",
      "enum": [
        "detect_secretsdump", "detect_dcsync", "detect_kerberoasting",
        "detect_asrep_roasting", "detect_brute_force", "detect_lsa_secrets_access",
        "detect_lateral_movement", "detect_pass_the_hash", "detect_smb_file_access",
        "detect_impacket_wmiexec", "detect_impacket_psexec", "detect_impacket_smbexec",
        "detect_impacket_atexec", "detect_impacket_dcomexec", "detect_impacket_secretsdump",
        "detect_impacket_ntlmrelayx", "detect_impacket_smbclient",
        "detect_adcs_exploitation", "detect_esc1_attack", "detect_esc4_attack",
        "detect_esc8_attack", "detect_certificate_authentication",
        "detect_delegation_abuse", "detect_s4u_delegation", "detect_golden_ticket",
        "detect_bloodhound_collection", "detect_bloodhound_domain_enum",
        "detect_bloodhound_acl_enum", "detect_bloodhound_session_enum",
        "detect_bloodhound_gpo_enum", "detect_bloodhound_computer_enum",
        "detect_port_scanning", "detect_user_enumeration", "detect_share_enumeration",
        "detect_suspicious_execution", "detect_certipy_enumeration",
        "detect_remote_registry_start"
      ]
    },
    "Evidence": {
      "type": "object",
      "required": ["id", "level", "category", "value"],
      "properties": {
        "id": { "type": "string", "format": "uuid" },
        "level": { "$ref": "#/$defs/PyramidLevel" },
        "category": {
          "type": "string",
          "enum": ["hash", "ip", "domain", "artifact", "tool", "ttp"]
        },
        "value": { "type": "string" },
        "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
        "source_query_id": { "type": ["string", "null"] },
        "mitre_technique": { "type": ["string", "null"] },
        "validated": { "type": "boolean", "default": false },
        "timestamp": { "type": "string", "format": "date-time" }
      }
    },
    "TimelineEvent": {
      "type": "object",
      "required": ["timestamp", "event"],
      "properties": {
        "timestamp": { "type": "string", "format": "date-time" },
        "event": { "type": "string" },
        "host": { "type": ["string", "null"] },
        "user": { "type": ["string", "null"] },
        "mitre_technique": { "type": ["string", "null"] }
      }
    },
    "LateralConnection": {
      "type": "object",
      "required": ["source_host", "target_host", "connection_type", "timestamp"],
      "properties": {
        "source_host": { "type": "string" },
        "target_host": { "type": "string" },
        "connection_type": { "$ref": "#/$defs/LateralConnectionType" },
        "timestamp": { "type": "string", "format": "date-time" },
        "source_user": { "type": ["string", "null"] },
        "evidence_ids": {
          "type": "array",
          "items": { "type": "string" }
        }
      }
    },
    "InvestigationState": {
      "type": "object",
      "required": ["alert_id", "stage"],
      "properties": {
        "alert_id": { "type": "string" },
        "stage": { "$ref": "#/$defs/InvestigationStage" },
        "escalated": { "type": "boolean", "default": false },
        "escalation_reason": { "type": ["string", "null"] },
        "evidence": {
          "type": "array",
          "items": { "$ref": "#/$defs/Evidence" }
        },
        "timeline": {
          "type": "array",
          "items": { "$ref": "#/$defs/TimelineEvent" }
        },
        "techniques_identified": {
          "type": "array",
          "items": { "type": "string" }
        },
        "lateral_connections": {
          "type": "array",
          "items": { "$ref": "#/$defs/LateralConnection" }
        },
        "investigated_hosts": {
          "type": "array",
          "items": { "type": "string" }
        },
        "pending_hosts": {
          "type": "array",
          "items": { "type": "string" }
        },
        "recommendations": {
          "type": "array",
          "items": { "type": "string" }
        }
      }
    },
    "ScenarioMode": {
      "type": "string",
      "enum": ["red_only", "blue_only", "purple"]
    }
  }
}
```

#### Protobuf (candidate format)

```protobuf
syntax = "proto3";
package aces.schema.v1;

enum NodeType {
  NODE_TYPE_UNSPECIFIED = 0;
  HOST = 1;
  PRINCIPAL = 2;
  CREDENTIAL = 3;
  SERVICE = 4;
  SUBNET = 5;
  DOMAIN = 6;
  SHARE = 7;
  ARTIFACT = 8;
  GPO = 9;
  CERTIFICATE = 10;
  CERTIFICATE_TEMPLATE = 11;
  CERTIFICATE_AUTHORITY = 12;
  // Reserved 100-199 for extensions
}

enum EdgeType {
  EDGE_TYPE_UNSPECIFIED = 0;

  // --- Core Structural (1-9) ---
  // Non-exploitable edges used for transitive access computation
  MEMBER_OF = 1;
  CONTAINS = 2;
  HAS_CREDENTIAL = 3;
  AUTHENTICATES = 4;

  // --- AD Local Privileges (10-19) ---
  ADMIN_TO = 10;
  CAN_PS_REMOTE = 11;
  CAN_RDP = 12;
  EXECUTE_DCOM = 13;
  HAS_SESSION = 14;
  SQL_ADMIN = 15;

  // --- AD ACL Abuse (20-39) ---
  GENERIC_ALL = 20;
  GENERIC_WRITE = 21;
  WRITE_OWNER = 22;
  WRITE_DACL = 23;
  FORCE_CHANGE_PASSWORD = 24;
  ADD_MEMBER = 25;
  ALL_EXTENDED_RIGHTS = 26;
  OWNS = 27;
  ADD_SELF = 28;
  ADD_ALLOWED_TO_ACT = 29;
  READ_LAPS_PASSWORD = 30;
  READ_GMSA_PASSWORD = 31;

  // --- AD Kerberos (40-49) ---
  HAS_SPN_CONFIGURED = 40;
  DONT_REQ_PREAUTH = 41;
  ALLOWED_TO_DELEGATE = 42;
  ALLOWED_TO_ACT = 43;
  UNCONSTRAINED_DELEGATION = 44;

  // --- Domain Replication (50-59) ---
  GET_CHANGES = 50;
  GET_CHANGES_ALL = 51;
  DC_SYNC = 52;

  // --- ADCS (60-89) ---
  ADCS_ESC1 = 60;
  ADCS_ESC2 = 61;
  ADCS_ESC3 = 62;
  ADCS_ESC4 = 63;
  ADCS_ESC5 = 64;
  ADCS_ESC6 = 65;
  ADCS_ESC6A = 66;
  ADCS_ESC6B = 67;
  ADCS_ESC7 = 68;
  ADCS_ESC8 = 69;
  ADCS_ESC9 = 70;
  ADCS_ESC9A = 71;
  ADCS_ESC9B = 72;
  ADCS_ESC10 = 73;
  ADCS_ESC10A = 74;
  ADCS_ESC10B = 75;
  ADCS_ESC11 = 76;
  ADCS_ESC13 = 77;
  CAN_REQUEST = 78;
  HAS_CERTIFICATE = 79;

  // --- Credential Chain (80-89) ---
  CAN_CRACK = 80;

  // --- AD GPO Abuse (85-89) ---
  GP_LINK = 85;
  GPO_ABUSE = 86;
  GPO_IMMEDIATE_TASK = 87;

  // --- AD Trust/Other (90-99) ---
  TRUSTED_BY = 90;
  PARENT_OF = 91;
  CROSS_FOREST_TRUST = 92;
  ADMIN_SD_HOLDER_WRITABLE = 93;

  // --- MSSQL (130-139) ---
  MSSQL_IMPERSONATION = 130;
  MSSQL_LINKED_SERVER = 131;
  MSSQL_XP_CMDSHELL = 132;

  // --- Local Privilege Escalation (140-149) ---
  SE_IMPERSONATE = 140;
  LOCAL_ADMIN = 141;
  SERVICE_ACCOUNT = 142;

  // --- Credential Chain (150-159) ---
  DERIVED_FROM = 150;

  // --- Azure / Entra ID (100-109) ---
  AZ_MEMBER_OF = 100;
  AZ_GLOBAL_ADMIN = 101;
  AZ_PRIVILEGED_AUTH_ADMIN = 102;
  AZ_OWNS = 103;
  AZ_ADD_MEMBERS = 104;

  // --- AWS IAM (110-119) ---
  AWS_ASSUME_ROLE = 110;
  AWS_HAS_POLICY = 111;
  AWS_S3_ACCESS = 112;
  AWS_EC2_ACCESS = 113;

  // --- GCP IAM (120-129) ---
  GCP_HAS_ROLE = 120;
  GCP_IMPERSONATE = 121;
  GCP_GCS_ACCESS = 122;

  // --- Reserved Ranges for Extensions ---
  // 200-299: OT/ICS (Modbus, DNP3, OPC-UA)
  // 300-399: Wireless (WiFi, Bluetooth, Zigbee)
  // 400-499: Additional Cloud (Oracle, Alibaba)
  // 500-599: Container/Kubernetes
  // 1000+: User-defined / scenario-specific
}

enum EdgeSeverity {
  EDGE_SEVERITY_UNSPECIFIED = 0;
  INFO = 1;
  LOW = 2;
  MEDIUM = 3;
  HIGH = 4;
  CRITICAL = 5;
}

enum EdgeClassification {
  EDGE_CLASSIFICATION_UNSPECIFIED = 0;
  STRUCTURAL = 1;
  PROPERTY = 2;
  CREDENTIAL = 3;
  ACL = 4;
  HOST_TARGETING = 5;
  MSSQL = 6;
  GPO = 7;
  DELEGATION = 8;
  ADCS = 9;
  CLOUD = 10;
}

enum CredentialKind {
  CREDENTIAL_KIND_UNSPECIFIED = 0;
  PASSWORD = 1;
  NTLM_HASH = 2;
  KERBEROS_TGT = 3;
  KERBEROS_TGS = 4;
  ROASTED_HASH = 5;
  SSH_KEY = 6;
  API_KEY = 7;
  TOKEN = 8;
  X509_CERTIFICATE = 9;  // Distinct from CERTIFICATE node type
}

enum EnumTechniqueType {
  ENUM_TECHNIQUE_TYPE_UNSPECIFIED = 0;
  // Network
  PING_SWEEP = 1;
  PORT_SCAN = 2;
  SERVICE_ENUM = 3;
  DNS_ENUM = 4;
  // SMB
  SMB_ENUM = 10;
  SHARE_ENUM = 11;
  FILE_ENUM = 12;
  SHARE_SPIDER = 13;
  // LDAP/AD
  LDAP_USERS = 20;
  LDAP_GROUPS = 21;
  LDAP_COMPUTERS = 22;
  LDAP_SELF_GROUPS = 23;
  LDAP_KERBEROASTABLE = 24;
  LDAP_ASREP_ROASTABLE = 25;
  LDAP_ADMIN_COUNT = 26;
  LDAP_TRUSTS = 27;
  LDAP_GMSA = 28;
  LDAP_ADMINSD_HOLDER = 29;
  // Kerberos
  KERBEROAST = 30;
  ASREP_ROAST = 31;
  FIND_DELEGATION = 32;
  // ADCS
  ADCS_ENUM = 40;
  ADCS_VULNERABLE_TEMPLATES = 41;
  // Database
  MSSQL_ENUM = 50;
  MSSQL_LINKS = 51;
  MSSQL_IMPERSONATION_CHECK = 52;
  // BloodHound
  BLOODHOUND_COLLECT = 60;
  BLOODHOUND_PATHS = 61;
  BLOODHOUND_ACL_PATHS = 62;
  // GPO
  GPO_ENUM = 70;
  GPO_PERMISSIONS = 71;
}

message EdgeConditions {
  bool requires_auth = 1;
  bool requires_session = 2;
  optional string requires_cred_type = 3;
}

message EdgeMeta {
  repeated string spn = 1;  // Service Principal Names (for delegation edges)
  optional string mitre_technique_id = 2;  // ATT&CK technique ID (e.g., T1558)
}

message AttackRelationship {
  string edge_id = 1;
  EdgeType type = 2;
  string src = 3;
  string dst = 4;
  NodeType src_type = 5;
  NodeType dst_type = 6;
  EdgeConditions conditions = 7;
  EdgeSeverity severity = 8;
  // classification is derivable from type but included for convenience
  EdgeClassification classification = 9;
  EdgeMeta meta = 10;
}

// ============================================================================
// Blue Team Types
// ============================================================================

enum BlueRole {
  BLUE_ROLE_UNSPECIFIED = 0;
  ORCHESTRATOR = 1;
  TRIAGE = 2;
  THREAT_HUNTER = 3;
  LATERAL_ANALYST = 4;
}

enum BlueTaskType {
  BLUE_TASK_TYPE_UNSPECIFIED = 0;
  TRIAGE_ALERT = 1;
  THREAT_HUNT = 2;
  LATERAL_ANALYSIS = 3;
  USER_INVESTIGATION = 4;
  HOST_INVESTIGATION = 5;
}

enum InvestigationStage {
  INVESTIGATION_STAGE_UNSPECIFIED = 0;
  STAGE_TRIAGE = 1;
  STAGE_CAUSATION = 2;
  STAGE_LATERAL = 3;
  STAGE_SYNTHESIS = 4;
}

enum PyramidLevel {
  PYRAMID_LEVEL_UNSPECIFIED = 0;
  HASH_VALUES = 1;
  IP_ADDRESSES = 2;
  DOMAIN_NAMES = 3;
  NETWORK_HOST_ARTIFACTS = 4;
  TOOLS = 5;
  TTPS = 6;
}

enum LateralConnectionType {
  LATERAL_CONNECTION_TYPE_UNSPECIFIED = 0;
  LATERAL_SMB = 1;
  LATERAL_RDP = 2;
  LATERAL_WMI = 3;
  LATERAL_PSEXEC = 4;
  LATERAL_SSH = 5;
  LATERAL_WINRM = 6;
  LATERAL_DCOM = 7;
}

enum DetectionTechniqueType {
  DETECTION_TECHNIQUE_TYPE_UNSPECIFIED = 0;

  // Credential Theft (1-19)
  DETECT_SECRETSDUMP = 1;
  DETECT_DCSYNC = 2;
  DETECT_KERBEROASTING = 3;
  DETECT_ASREP_ROASTING = 4;
  DETECT_BRUTE_FORCE = 5;
  DETECT_LSA_SECRETS_ACCESS = 6;

  // Lateral Movement (20-29)
  DETECT_LATERAL_MOVEMENT = 20;
  DETECT_PASS_THE_HASH = 21;
  DETECT_SMB_FILE_ACCESS = 22;

  // Impacket Tools (30-49)
  DETECT_IMPACKET_WMIEXEC = 30;
  DETECT_IMPACKET_PSEXEC = 31;
  DETECT_IMPACKET_SMBEXEC = 32;
  DETECT_IMPACKET_ATEXEC = 33;
  DETECT_IMPACKET_DCOMEXEC = 34;
  DETECT_IMPACKET_SECRETSDUMP = 35;
  DETECT_IMPACKET_NTLMRELAYX = 36;
  DETECT_IMPACKET_SMBCLIENT = 37;

  // ADCS Attacks (50-59)
  DETECT_ADCS_EXPLOITATION = 50;
  DETECT_ESC1_ATTACK = 51;
  DETECT_ESC4_ATTACK = 52;
  DETECT_ESC8_ATTACK = 53;
  DETECT_CERTIFICATE_AUTHENTICATION = 54;

  // Kerberos Attacks (60-69)
  DETECT_DELEGATION_ABUSE = 60;
  DETECT_S4U_DELEGATION = 61;
  DETECT_GOLDEN_TICKET = 62;

  // BloodHound (70-79)
  DETECT_BLOODHOUND_COLLECTION = 70;
  DETECT_BLOODHOUND_DOMAIN_ENUM = 71;
  DETECT_BLOODHOUND_ACL_ENUM = 72;
  DETECT_BLOODHOUND_SESSION_ENUM = 73;
  DETECT_BLOODHOUND_GPO_ENUM = 74;
  DETECT_BLOODHOUND_COMPUTER_ENUM = 75;

  // Reconnaissance (80-89)
  DETECT_PORT_SCANNING = 80;
  DETECT_USER_ENUMERATION = 81;
  DETECT_SHARE_ENUMERATION = 82;

  // Execution (90-99)
  DETECT_SUSPICIOUS_EXECUTION = 90;
  DETECT_CERTIPY_ENUMERATION = 91;
  DETECT_REMOTE_REGISTRY_START = 92;
}

enum ScenarioMode {
  SCENARIO_MODE_UNSPECIFIED = 0;
  RED_ONLY = 1;
  BLUE_ONLY = 2;
  PURPLE = 3;
}

message Evidence {
  string id = 1;
  PyramidLevel level = 2;
  string category = 3;  // "hash", "ip", "domain", "artifact", "tool", "ttp"
  string value = 4;
  float confidence = 5;  // 0.0-1.0
  optional string source_query_id = 6;
  optional string mitre_technique = 7;
  bool validated = 8;
  google.protobuf.Timestamp timestamp = 9;
}

message TimelineEvent {
  google.protobuf.Timestamp timestamp = 1;
  string event = 2;
  optional string host = 3;
  optional string user = 4;
  optional string mitre_technique = 5;
}

message LateralConnection {
  string source_host = 1;
  string target_host = 2;
  LateralConnectionType connection_type = 3;
  google.protobuf.Timestamp timestamp = 4;
  optional string source_user = 5;
  repeated string evidence_ids = 6;
}

message InvestigationState {
  string alert_id = 1;
  InvestigationStage stage = 2;
  bool escalated = 3;
  optional string escalation_reason = 4;
  repeated Evidence evidence = 5;
  repeated TimelineEvent timeline = 6;
  repeated string techniques_identified = 7;
  repeated string tactics_identified = 8;
  repeated LateralConnection lateral_connections = 9;
  repeated string investigated_hosts = 10;
  repeated string pending_hosts = 11;
  repeated string recommendations = 12;
}

message BlueTask {
  string task_id = 1;
  BlueTaskType task_type = 2;
  BlueRole assigned_role = 3;
  map<string, string> parameters = 4;
  optional string result = 5;
}
```

### 14.1 Schema Definition Format

This RFC provides examples in both JSON Schema and Protocol Buffers to
illustrate the taxonomy structure. The choice of canonical schema format
is addressed in **ADR-0022: Schema Definition Format**.

**Key points from ADR-0022:**

- Protocol Buffers is the canonical schema definition format.
- JSON Schema is derived from protobuf for validation tooling and documentation.
- Reserved enum ranges enable extensions without modifying core types.
- prost generates Rust types; Python protobuf generates Python types.

The examples in §14 are illustrative. Implementers should reference
ADR-0022 for authoritative guidance on schema packaging and code
generation.

### 15. Verification Tier Mapping

ADR-0002 establishes a four-tier verification model. This section maps
RFC-0001 types to the appropriate verification tier.

| RFC Type | Verification Tier | Rationale |
|----------|-------------------|-----------|
| Edge type enums | Tier 1 (Static) | Syntax validation — is the edge type a valid enum value? |
| Node type enums | Tier 1 (Static) | Syntax validation — is the node type a valid enum value? |
| Edge source/target types | Tier 1 (Static) | Type checking — does `AdminTo` connect Principal → Host? |
| `EdgeConditions.requires_cred_type` | Tier 2 (Semantic) | Logical validation — does the referenced credential type exist in the scenario? |
| Credential chains (HasCredential → CanCrack → Authenticates) | Tier 2 (Semantic) | Formal verification — is the chain well-formed and complete? |
| Detection technique coverage | Tier 2 (Semantic) | Formal verification — do detection techniques cover all attack edges in the scenario? |
| Attack path reachability | Tier 2 (Semantic) | Logical validation — is the goal state reachable from initial access? |
| Backend edge support | Tier 3 (Capability) | Infrastructure validation — can the provider instantiate this edge type? |
| Enumeration technique availability | Tier 3 (Capability) | Infrastructure validation — does the backend support `kerberoast`? |
| Purple mode telemetry fidelity | Tier 4 (Constraint) | Experimental validation — does the environment generate detectable events for blue team? |
| Evidence collection requirements | Tier 4 (Constraint) | Experimental validation — can the environment produce required evidence types? |

**Tier 1 (Static)** validation is performed by aces-sdl during parsing.
Invalid edge types, malformed references, and type mismatches are caught
before runtime.

**Tier 2 (Semantic)** validation uses formal methods to verify
logical properties. This includes coverage analysis (do detections cover
attacks?) and reachability proofs (can the agent reach the goal?).

**Tier 3 (Capability)** validation is performed by provider `DryRun()` APIs.
Providers report which edge types and techniques they can instantiate.
Scenarios requiring unsupported edges fail capability validation.

**Tier 4 (Constraint)** validation occurs at experiment time. The
aces-experiment layer verifies that the instantiated environment meets
research constraints (e.g., telemetry fidelity for purple mode evaluation).

## Alternatives Considered

### MITRE ATT&CK Technique IDs

ATT&CK operates at a higher abstraction level (tactics and techniques)
than attack graph edges. A single ATT&CK technique (e.g., T1558
Kerberoasting) maps to multiple ACES constructs (the `HasSPNConfigured`
edge, the `kerberoast` enumeration technique, and the `CanCrack` +
`Authenticates` credential chain). ATT&CK is useful for categorizing
scenarios but too coarse for graph-level specification. The two are
complementary — ACES edges could carry ATT&CK annotations.

### Raw BloodHound JSON

BloodHound's JSON export format contains the graph data but is
BloodHound-specific, not schema-independent. It includes UI metadata,
lacks formal versioning, and cannot express non-AD domains (cloud, OT).
However, BloodHound's *naming conventions* for edge types are the
industry standard and this RFC adopts them.

### Building from Scratch

Designing a new taxonomy without reference to existing work would waste
the validation that Ares' taxonomy has undergone. The proposed taxonomy
has been tested across thousands of trajectories on networks from 10 to
10,000+ hosts. Starting fresh risks missing edge cases (literal and
figurative) that production use has already surfaced.

## Affected Repos

| Repo | Change | Priority |
|------|--------|----------|
| **aces-schema** | Add EdgeType, NodeType, CredentialKind enums. Add AttackRelationship, EdgeConditions, EdgeMeta types. Add Credential, CredentialPolicy types. Add enumeration technique taxonomy. **Add BlueRole, BlueTaskType, InvestigationStage, DetectionTechniqueType enums. Add Evidence, InvestigationState, LateralConnection types.** | Critical — this is the primary deliverable |
| **aces-sdl** | Parser support for edge type declarations in scenario files. Support for ScenarioMode (red_only, blue_only, purple). | After schema ships |
| **aces-stdlib** | Reference scenarios using the taxonomy (e.g., Kerberoasting path, ADCS ESC1 path, DCSync path). **Add purple team scenarios with detection objectives.** | After SDL support |
| **aces-runtime** | Scoring engine must understand edge types for path-based assessment. **Add blue team scoring for detection rate, time-to-detect, evidence pyramid level.** | After schema ships |
| **aces-agent-sdk** | Action space includes edge exploitation; observation space includes discovered edges. **Add blue team observation/action space: detection techniques, evidence collection, investigation state.** | After runtime support |
| **aces-experiment** | Blue team evaluation harness types for detection metrics, time-to-detect measurement, and pyramid-level evidence scoring. Purple mode experiment protocols. | After agent-sdk support |
| **aces-cli** | Commands for purple mode scenario execution, blue/red team switching, and investigation state inspection. | After runtime support |

## Consequences

### What Becomes Easier

**Red Team:**

- Scenario authors can express AD attack paths using industry-standard
  terminology.
- Attack graphs are structurally comparable across backends and content
  generators (simulation, Docker, VMs, cloud).
- Scoring can reference specific edge types and paths.
- Community contributions to aces-stdlib can build on a shared vocabulary.
- Integration with BloodHound tooling is straightforward (same edge type
  names).

**Blue Team:**

- Detection coverage analysis becomes tractable — enumerate which attack
  techniques have corresponding detection techniques.
- Investigation state is standardized — agents from different providers
  produce comparable evidence artifacts.
- Pyramid of Pain classification provides consistent evidence quality
  metrics across scenarios.
- Purple team scenarios can be scored on both attack success and detection
  effectiveness using the same schema primitives.

### What Becomes Harder

- Adding a new edge type requires a schema minor version bump. This is by
  design — the taxonomy is a controlled vocabulary, not a free-form
  string.
- Non-AD domains (cloud, OT) must map their concepts to the extension
  pattern. The initial cloud types (AWS, GCP, Azure) demonstrate this is
  feasible but each new domain requires design work.
- Blue team detection techniques must be kept in sync with red team attack
  edges — adding a new attack type without corresponding detection
  technique creates a coverage gap.
- Purple mode requires careful telemetry design to ensure red team actions
  generate detectable signals without being trivially easy to find.

### Migration Requirements

None. This is a greenfield addition to an unreleased schema. No backward
compatibility concerns.

### Open Questions for Discussion

1. **Should edge types carry ATT&CK annotations?** Could add an optional
   `mitre_technique_id` field to AttackRelationship. This would enable
   ATT&CK-based reporting and filtering without changing the core
   taxonomy. **Recommendation**: Yes, as optional metadata. ATT&CK IDs
   are stable and widely recognized.

2. **Should enumeration techniques be part of aces-schema or
   aces-stdlib?** They define the agent's action space but are more
   operational than structural. **Recommendation**: aces-schema. The
   enumeration technique enum is part of the agent action space contract
   (aces-agent-sdk depends on it). Content in aces-stdlib can reference
   these techniques, but the types belong in schema.

3. **How should the schema handle composite edges?** DCSync is
   semantically GetChanges + GetChangesAll. Should the schema model this
   composition explicitly or treat DCSync as atomic?
   **Recommendation**: Atomic with optional composition metadata. DCSync
   is the attackable primitive from the agent's perspective. The
   constituent rights (GetChanges, GetChangesAll) exist as separate
   edges for scenarios that want fine-grained modeling. Add an optional
   `composition` field for tooling that wants to display relationships:

   ```yaml
   EdgeComposition:
     requires: list[EdgeType]  # e.g., [GetChanges, GetChangesAll]
     mode: "all" | "any"       # all = AND, any = OR
   ```

   This is metadata for display/analysis, not runtime semantics.

4. **Should credential chains be first-class in the schema?** The
   HasCredential → CanCrack → Authenticates chain is a recurring pattern.
   Should the schema define a `CredentialChain` type?
   **Recommendation**: No. The chain is expressible as a sequence of
   edges. A first-class type would add complexity without enabling new
   scenarios. Scoring can recognize the pattern via edge classification
   (CREDENTIAL edges).

5. **Should the vulnerability queue be part of the schema or runtime?**
   The priority-based vulnerability queue (§8) is a runtime concept but
   needs schema support for `VulnerabilityInfo` types.
   **Recommendation**: Schema defines `VulnerabilityInfo` as a type that
   references edge types. The queue itself is a runtime data structure,
   but the vocabulary of vulnerability types should be in the schema.

6. **How should multi-agent coordination be modeled?** In ares, different
   agent roles (RECON, CREDENTIAL_ACCESS, PRIVESC, LATERAL, etc.) have
   different tool access and responsibilities. Should the schema define
   agent role types?
   **Recommendation**: Out of scope for this RFC. Agent roles are an
   orchestration concern for aces-runtime, not a specification concern
   for aces-schema. However, the enumeration technique taxonomy (§6)
   implicitly maps to agent capabilities.

7. **Should the schema support attack chain lineage tracking?** Ares
   tracks `parent_id` and `attack_step` on credentials to reconstruct
   attack paths. Should this be standardized?
   **Recommendation**: Yes, as optional metadata on Credential. The
   `DerivedFrom` edge (§2.12) provides graph-based lineage, while
   `attack_step` provides a linear position in the chain. Both are
   useful for scoring and reporting.

8. **How should blue team scoring work?** Red team scoring focuses on
   attack path completion. Blue team needs different metrics.
   **Recommendation**: Blue team scoring should include:
   - **Detection rate**: Percentage of red team actions detected
   - **Time-to-detect (TTD)**: Latency from attack to alert
   - **Pyramid elevation**: Average evidence level (1-6) achieved
   - **Investigation completeness**: Did the agent reach synthesis stage?
   - **False positive rate**: Incorrect escalations
   - **Scope accuracy**: Did the agent identify all affected hosts/users?

9. **How should purple mode telemetry work?** In purple scenarios, red
   team actions must generate detectable telemetry for blue team agents.
   **Recommendation**: Red team edge traversals emit OCSF events (per
   ADR-0008) that blue team agents query via Loki/Prometheus. The
   runtime should support configurable noise levels (baseline activity)
   and stealth modifiers (attacker OPSEC). This enables evaluation of
   both attack execution and detection capabilities.

10. **Should detection techniques have coverage metadata?** Each detection
    technique maps to MITRE ATT&CK techniques. Should this mapping be
    explicit in the schema?
    **Recommendation**: Yes. Add `mitre_technique_ids: list[str]` to
    `DetectionTechniqueType` metadata. This enables coverage analysis
    (which techniques can we detect?) and gap identification.

### 16. Telemetry Attributes (Security Extension)

This section defines telemetry attributes for security-focused experiments. These
attributes extend the core observability schema (RFC-0003) with security-specific
context for red team, blue team, and purple team scenarios.

When an environment declares `schema.extensions: [security]` (RFC-0001), these
attributes become available for spans, logs, and events.

#### 16.1 MITRE ATT&CK Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `mitre.tactic`             | String | ATT&CK tactic                    | `credential-access`  |
| `mitre.tactic.id`          | String | Tactic ID                        | `TA0006`             |
| `mitre.technique.id`       | String | Technique ID                     | `T1003.006`          |
| `mitre.technique.name`     | String | Technique name                   | `DCSync`             |
| `mitre.subtechnique.id`    | String | Sub-technique ID                 | `T1003.006`          |

#### 16.2 Team Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `security.team`            | String | Team assignment                  | `red`, `blue`        |
| `security.operation`       | String | Operation name                   | `credential-harvest` |
| `security.campaign`        | String | Campaign identifier              | `campaign-001`       |

#### 16.3 Attack Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `attack.phase`             | String | Kill chain phase                 | `lateral-movement`   |
| `attack.vector`            | String | Attack vector                    | `phishing`, `exploit`|
| `attack.target.type`       | String | Target type                      | `credential`, `host` |

#### 16.4 Defense Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `detection.rule`           | String | Detection rule that fired        | `dcsync_detected`    |
| `detection.severity`       | String | Alert severity                   | `critical`, `high`   |
| `detection.confidence`     | Float  | Detection confidence             | `0.95`               |
| `response.action`          | String | Response action taken            | `isolate`, `alert`   |

#### 16.5 Credential Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `credential.type`          | String | Credential type                  | `ntlm`, `kerberos`   |
| `credential.username`      | String | Username                         | `admin`              |
| `credential.domain`        | String | Domain                           | `corp.local`         |
| `credential.source`        | String | How credential was obtained      | `lsass`, `dcsync`    |

#### 16.6 Active Directory Attributes

| Attribute                  | Type   | Description                      | Example              |
|:---------------------------|:-------|:---------------------------------|:---------------------|
| `ad.domain`                | String | AD domain                        | `corp.local`         |
| `ad.forest`                | String | AD forest                        | `corp.local`         |
| `ad.object.type`           | String | AD object type                   | `user`, `computer`   |
| `ad.object.dn`             | String | Distinguished name               | `CN=Admin,DC=corp`   |
| `ad.object.sid`            | String | Security identifier              | `S-1-5-21-...`       |

#### 16.7 Security Event Classes

These event classes extend the taxonomy defined in RFC-0003.

**Attack Events (`security.attack.*`):**

| Class                               | Description                          |
|:------------------------------------|:-------------------------------------|
| `security.attack.reconnaissance`    | Reconnaissance activity              |
| `security.attack.initial_access`    | Initial access attempt               |
| `security.attack.execution`         | Code/command execution               |
| `security.attack.persistence`       | Persistence mechanism                |
| `security.attack.privilege_escalation` | Privilege escalation attempt      |
| `security.attack.credential_access` | Credential access attempt            |
| `security.attack.lateral_movement`  | Lateral movement attempt             |
| `security.attack.exfiltration`      | Data exfiltration attempt            |

**Defense Events (`security.defense.*`):**

| Class                               | Description                          |
|:------------------------------------|:-------------------------------------|
| `security.defense.alert`            | Alert triggered                      |
| `security.defense.detection`        | Detection rule matched               |
| `security.defense.response`         | Response action taken                |
| `security.defense.containment`      | Containment action                   |
| `security.defense.investigation`    | Investigation activity               |

#### 16.8 Security Correlation Patterns

**Attack Chain:**

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

**Attack → Detection:**

```text
┌─────────────────┐     correlation_id      ┌─────────────────┐
│ security.attack │ ────────────────────────▶│ security.       │
│ .credential_    │                          │   defense.alert │
│    access       │                          │                 │
└─────────────────┘                          └─────────────────┘
  agent.name: red-agent                        detection.rule: dcsync
  mitre.technique.id: T1003.006                detection.severity: critical
```

#### 16.9 Telemetry Example

```yaml
# Red team action span
span:
  name: action.tool.impacket
  attributes:
    # Core attributes (RFC-0003)
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

### 17. Defensive Control Evaluation

ACES scenarios that include defensive controls need a portable way to
describe what controls are present, what they are expected to detect or
block, and how their effectiveness is measured across runs. This section
defines the ACES-specific evaluation overlay for defensive controls.

This section does not define a competing event schema. Implementations
SHOULD use OCSF for normalized defensive events, alerts, findings, and
evidence artifacts. This section defines the ACES-specific reporting and
evaluation model that sits on top of those records in scenario artifacts,
experiment specifications, and execution reports.

#### 17.1 Scope and Intent

The purpose of this section is to make defensive scenarios reproducible
and comparable across implementations. A defensive control definition
should answer the following questions:

* What product or control is present in the scenario?
* Where is it placed in the environment?
* What activity is it expected to detect?
* What activity is it expected to block or otherwise prevent?
* What OCSF-normalized telemetry, alerts, findings, or evidence artifacts
  prove the result?
* What exact product, policy, content, and configuration versions were used?
* For each scenario action, what observed evaluation outcome occurred?

This section deliberately separates two concerns:

* OCSF defines the normalized observation layer for defensive telemetry,
  findings, evidence artifacts, and control outcomes.
* This section defines the ACES scenario layer: control placement in the
  scenario, expected coverage for named runtime actions, supplemental
  reproducibility metadata, and per-action evaluation results.

Defensive controls SHOULD be modeled by reference to existing scenario
objects:

* `topology.nodes` for control placement on hosts, gateways, routers,
  switches, or dedicated security appliances.
* `topology.networks` for control placement at trust boundaries, VLANs,
  subnets, or monitored segments.
* `resources.bindings` for images, packages, and infrastructure bindings
  associated with the control.
* `runtime.phases` and `runtime.actions` for the offensive, administrative,
  or validation activities that the control is expected to observe or affect.

#### 17.2 Common Control Metadata

Each defensive control instance SHOULD reuse OCSF objects where possible
and only add ACES-specific metadata where OCSF does not directly express
scenario-evaluation intent.

| Concern | Preferred Representation | Notes |
|:--------|:-------------------------|:------|
| Product or control identity | OCSF `product.{uid,vendor_name,name,version}` or `agent.{uid,vendor_name,name,version}` | Use `agent` for host-resident sensors and `product` for reporting products or services. |
| Policy or rule traceability | OCSF `policy.{uid,name,type,version}`, `rule.{uid,name,type,version}`, `security_control.policy`, `security_control.firewall_rule` | Use the OCSF policy and rule objects instead of parallel ACES version fields when possible. |
| Detection and finding records | OCSF `detection_finding`, `finding_info.{uid,title,analytic,product,related_events}`, and `evidences` | Use for normalized alerts, findings, and evidence artifacts. |
| Adversary and countermeasure taxonomy | OCSF `attack` and `d3fend` | Use ATT&CK references for covered adversary behavior and D3FEND for countermeasure taxonomy. |
| Protected assets or enforcement points | OCSF `endpoint`, `application`, `idp`, or `logger` | Choose the object that best represents the observed control or protected service. |

ACES adds only the following supplemental metadata where OCSF does not
fully capture scenario-evaluation intent:

| Property | Type | Description | Example |
|:---------|:-----|:------------|:--------|
| `id` | String | Unique identifier for the control instance within the ACES scenario. | `edge-waf-01` |
| `family` | String | Optional ACES family label used for summaries and report rollups. | `network`, `endpoint`, `application`, `identity`, `monitoring_response` |
| `type` | String | Optional scenario-local subtype label when a short local label is helpful. | `waf` |
| `placement` | Object | References to ACES nodes, networks, services, or protected assets where the control is deployed. | `{nodes: [waf-0], networks: [dmz]}` |
| `telemetry` | Array | Logical ACES telemetry stream identifiers expected to carry OCSF-normalized records from this control. | `[waf_alert_log, http_access_log]` |
| `content_version` | String | Version of signatures, models, feeds, or detection content when distinct from product or policy version. | `crs-3.4.0` |
| `artifact_digest` | String | Immutable digest of the deployed image, package, or artifact. | `sha256:abcd1234` |
| `config_digest` | String | Immutable digest of the applied configuration. | `sha256:efgh5678` |

The combination of OCSF product, policy, and rule identifiers plus
`content_version`, `artifact_digest`, and `config_digest` SHOULD be
sufficient to reproduce the same defensive setup in a future run.

#### 17.3 Capability Declaration: Detect Versus Block

Each defensive control SHOULD explicitly declare which scenario activities
it is intended to detect and which it is intended to block. These
declarations express expected coverage over named ACES `runtime.actions`;
they do not replace the observed OCSF records emitted during execution.
Implementations SHOULD avoid ambiguous labels such as "protects web
traffic" when the expected behavior can be expressed against named
scenario actions.

The following capability fields are RECOMMENDED:

| Property | Type | Description | Example |
|:---------|:-----|:------------|:--------|
| `detects` | Array | Scenario actions, attack steps, or conditions expected to produce OCSF-observable detection telemetry or findings. | `[sqli-login-attempt]` |
| `blocks` | Array | Scenario actions, attack steps, or conditions expected to produce OCSF blocking or denial outcomes. | `[sqli-login-attempt]` |
| `response_actions` | Array | Post-detection actions triggered by the control or an integrated system. | `[block_source_ip, isolate_host]` |
| `mode` | String | Intended operational behavior of the control during the experiment. | `monitor`, `enforce`, `simulate` |

The intent of these fields is:

* `detects` identifies activity that SHOULD raise observable telemetry, a
  normalized OCSF detection finding, or another alertable signal.
* `blocks` identifies activity that SHOULD be prevented from completing
  successfully.
* `response_actions` identifies the follow-on behavior that may occur after
  a detection.
* `mode` records whether the product was observing, enforcing, or simulating
  policy during the run.

Some control types are commonly `detect_only`, while others are commonly
`detect_and_block`. Scenario authors SHOULD declare the intended behavior
for the specific product instance used in the scenario rather than
assuming it from the control family.

Observed behavior SHOULD be captured via OCSF records, typically by
applying the `security_control` profile to activity events or by emitting
a `detection_finding` when the control produces a normalized alert or
analytic result. In other words, `detects`, `blocks`, and
`response_actions` declare intent before the run; OCSF captures what
actually happened during the run.

#### 17.4 Evaluation Outcome Model

To compare defensive results across experiments, implementations SHOULD
evaluate defensive controls against named scenario actions and produce a
per-control result record.

Each evaluation record SHOULD include the following fields:

| Property | Type | Description | Example |
|:---------|:-----|:------------|:--------|
| `actionRef` | String | Reference to the runtime action, attack step, or validation step under test. | `sqli-login-attempt` |
| `controlRef` | String | Reference to the defensive control instance. | `edge-waf-01` |
| `expected_effect` | String | Expected control behavior for the action. | `detect`, `block`, `respond`, `none` |
| `detection_observed` | Boolean | Whether observable telemetry or an alert was generated. | `true` |
| `blocking_observed` | Boolean | Whether the action was prevented from completing. | `true` |
| `final_outcome` | String | Normalized result for this action/control pair. | `bypassed`, `detected`, `blocked`, `partially_blocked`, `error`, `not_applicable` |
| `evidence` | Array | References to OCSF-normalized findings, evidence artifacts, alerts, logs, packet captures, or other artifacts. | `[finding_uid:waf-detection-44321]` |
| `notes` | String | Operator notes or implementation-specific context. | `Alert fired after request body inspection.` |

The normalized `final_outcome` values are intended to mean:

* `bypassed`: the action succeeded and the control did not produce
  effective prevention.
* `detected`: the action produced a detection, but the action still
  succeeded fully or partially.
* `blocked`: the action did not complete because the control prevented it.
* `partially_blocked`: the control reduced or interrupted the action, but
  some objective was still achieved.
* `not_applicable`: the control was not intended to cover that action.

Each evaluation record is an ACES overlay over one or more observed OCSF
records. Implementations SHOULD prefer stable identifiers such as
`finding_info.uid`, `evidences.uid`, product identifiers, and logger event
identifiers when constructing evidence references.

#### 17.5 Control Taxonomy and OCSF Mapping

This section is non-normative. ACES does not define a competing defensive
product ontology. Implementations SHOULD rely on OCSF objects for
normalized control-related telemetry and MAY use the following family
labels only for scenario summaries and report rollups.

| ACES Family | Representative Controls | Primary OCSF Building Blocks | Notes |
|:------------|:------------------------|:-----------------------------|:------|
| `network` | `firewall`, `ids`, `ips`, `proxy`, `segmentation_gateway` | `endpoint`, `firewall_rule`, `security_control`, `evidences.{src_endpoint,dst_endpoint,connection_info,url}` | Use for boundary and network choke-point controls. |
| `endpoint` | `av`, `epp`, `edr`, `host_ids`, `host_firewall`, `application_allowlisting` | `agent`, `endpoint`, `security_control`, `evidences.{process,file,device,user}` | Use for host-resident sensors and on-host enforcement. |
| `application` | `waf`, `api_gateway_security`, `reverse_proxy_filter`, `rasp` | `application`, `firewall_rule`, `security_control`, `evidences.{http_request,http_response,url,api}` | Use for application-layer inspection and enforcement. |
| `identity` | `mfa`, `idp_policy`, `pam`, `directory_policy`, `conditional_access` | `idp`, `policy`, `security_control` | Use for authentication, authorization, privilege, and trust controls. |
| `monitoring_response` | `siem`, `soar`, `log_collector`, `threat_intel_enrichment`, `case_management` | `detection_finding`, `finding_info.analytic`, `logger`, `agent`, `evidences` | Often `detect_only` or `respond_after_detection` unless explicit downstream blocking is modeled. |

Where a control needs explicit countermeasure taxonomy, implementations
SHOULD use OCSF `d3fend`. Where covered adversary behavior needs
classification, implementations SHOULD use OCSF `attack`.

#### 17.6 Reporting and Reproducibility Guidance

Implementations SHOULD emit OCSF-normalized alerts, findings, and
evidence artifacts for defensive telemetry where applicable. This section
adds the cross-scenario comparison layer needed to evaluate what was
bypassed, detected, and blocked across products and runs.

At minimum, a report SHOULD include:

* The scenario identifier and version.
* The runtime action or attack-step identifiers under evaluation.
* The defensive control instances present in the run.
* For each control instance, OCSF-aligned product, agent, policy, and rule
  identifiers where applicable, plus any ACES-specific supplemental
  metadata such as `content_version`, `artifact_digest`, and
  `config_digest`.
* For each action/control pair, the normalized result of `bypassed`,
  `detected`, `blocked`, `partially_blocked`, or `not_applicable`.
* Evidence references sufficient for an evaluator to trace the result to
  source artifacts, preferably by stable identifiers such as OCSF
  `finding_info.uid`, `evidences.uid`, product identifiers, or logger
  `event_uid`.

When raw telemetry cannot be normalized cleanly to OCSF, reports SHOULD
preserve the vendor-native reference alongside the ACES result and
document the gap.

Implementations MAY also calculate summary measures such as:

* percentage of relevant actions detected
* percentage of relevant actions blocked
* mean time to detection
* mean time to response
* false positive count
* service availability impact during enforcement

#### 17.7 Illustrative YAML Fragment

The following example is non-normative and demonstrates one way to
describe an ACES defensive control overlay and its evaluation results
while reusing OCSF-aligned product, policy, and evidence references.

```yaml
defenseControls:
  - id: edge-waf-01
    family: application
    type: waf
    ocsf:
      product:
        vendor_name: example-sec
        name: appshield
        version: 4.2.1
      policy:
        name: edge-waf-enforce
        version: 2026-03-10
    content_version: crs-3.4.0
    artifact_digest: sha256:abcd1234
    config_digest: sha256:efgh5678
    mode: enforce
    placement:
      nodes: [waf-0]
      protects: [web-0]
      networks: [dmz]
    detects:
      - sqli-login-attempt
      - xss-comment-post
    blocks:
      - sqli-login-attempt
    response_actions:
      - block_source_ip
    telemetry:
      - waf_alert_log
      - http_access_log

evaluationResults:
  - actionRef: sqli-login-attempt
    controlRef: edge-waf-01
    expected_effect: block
    detection_observed: true
    blocking_observed: true
    final_outcome: blocked
    evidence:
      - finding_uid: waf-detection-44321
      - evidence_uid: waf-request-44321
      - event_uid: gw-2026-03-10-00044321
    notes: Request blocked during request body inspection.

  - actionRef: xss-comment-post
    controlRef: edge-waf-01
    expected_effect: detect
    detection_observed: true
    blocking_observed: false
    final_outcome: detected
    evidence:
      - finding_uid: waf-detection-44355
      - evidence_uid: waf-request-44355
    notes: Alert generated but request completed.
```

## Implementation Reference

This RFC is informed by production experience in:

1. **Dreadnode Ares (Red Team)** — Autonomous red team agent with multi-agent
   architecture for Active Directory penetration testing. Relevant
   implementation patterns:
   - Vulnerability priority queue (`core/dispatcher/vulnerability.py`)
   - ACL chain tracking (`core/dispatcher/acl_chains.py`)
   - Credential chain lineage (`core/models.py` — `parent_id`, `attack_step`)
   - Edge type discovery from BloodHound (`core/dispatcher/result_processing.py`)
   - Exploitation toolsets (`tools/red/kerberos_attacks.py`, `tools/red/acl_attacks.py`)

2. **Dreadnode Ares (Blue Team)** — Autonomous SOC investigation agent with
   multi-agent orchestration for incident response. Relevant implementation
   patterns:
   - Blue team roles and task types (`core/models.py` — `BlueRole`, `BlueTaskType`)
   - Investigation state machine (`tools/blue/investigation.py`)
   - ~40 detection query templates (`tools/blue/query_templates.py`)
   - Pyramid of Pain evidence classification (`tools/blue/investigation.py`)
   - Multi-agent orchestration (`agents/blue/multi_agent_orchestrator.py`)
   - SOC investigator agent (`agents/blue/soc_investigator.py`)
   - Loki/Prometheus observability tools (`tools/blue/observability.py`)
   - Investigation completion and escalation (`tools/blue/actions.py`)
   - Historical pattern learning (`tools/blue/learning.py`)
   - Lateral movement graph tracking (`tools/blue/investigation.py`)

The ares implementation demonstrates that the proposed taxonomy is
sufficient to express real-world scenarios, including:

**Red Team (Offensive):**

- Multi-hop ACL abuse chains
- ADCS exploitation (ESC1-13)
- Kerberos delegation attacks (constrained, unconstrained, RBCD)
- MSSQL lateral movement chains
- GPO abuse for privilege escalation
- gMSA password retrieval
- AdminSDHolder persistence

**Blue Team (Defensive):**

- Multi-stage investigation workflow (triage → causation → lateral → synthesis)
- Evidence pyramid climbing (IOCs → tools → TTPs)
- Lateral movement scope analysis with connection graphing
- Detection technique coverage for 40+ attack patterns
- MITRE ATT&CK technique correlation
- Historical investigation pattern learning
- Multi-agent task coordination (orchestrator, triage, threat hunter, lateral analyst)
