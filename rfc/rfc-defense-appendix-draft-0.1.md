# RFC-XXXX Appendix: Defensive Control Families and Evaluation Metadata

## Status

`Draft`

## Relationship to RFC-XXXX

`This document is a companion appendix to RFC-XXXX: Agentic Cyber Range Specification. It provides defensive control taxonomy, reproducibility metadata, and reporting guidance for scenarios defined using the topology, resources, and runtime model in the main RFC.`

## Summary

`This draft appendix helps scenario authors describe defensive products and controls that participate in an ACES scenario. It is inspired by the evaluation framing used in RFC 9411, but is adapted for cyber range scenarios that are declared using the topology, resources, and runtime model defined by RFC-XXXX.`

## Appendix A. Defensive Control Families and Evaluation Metadata

This appendix does not define a new root schema. Instead, it defines a common taxonomy and reporting model that implementations MAY use when describing security controls in an experiment specification, scenario catalog, or execution report.

### A.1. Scope and Intent

The purpose of this appendix is to make defensive scenarios reproducible and comparable across implementations. A defensive control definition should answer the following questions:

* What product or control is present in the scenario?
* Where is it placed in the environment?
* What activity is it expected to detect?
* What activity is it expected to block or otherwise prevent?
* What telemetry is produced as evidence?
* What exact product, ruleset, and configuration versions were used?
* For each scenario action, was the activity bypassed, detected, or blocked?

Defensive controls SHOULD be modeled by reference to existing scenario objects:

* `topology.nodes` for control placement on hosts, gateways, routers, switches, or dedicated security appliances.
* `topology.networks` for control placement at trust boundaries, VLANs, subnets, or monitored segments.
* `resources.bindings` for images, packages, and infrastructure bindings associated with the control.
* `runtime.phases` and `runtime.actions` for the offensive, administrative, or validation activities that the control is expected to observe or affect.

### A.2. Common Control Metadata

Each defensive control instance SHOULD include the following metadata.

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `id` | `String` | `Unique identifier for the control instance.` | `edge-waf-01` |
| `family` | `String` | `High-level control family.` | `{network, endpoint, application, identity, monitoring_response}` |
| `type` | `String` | `Specific control type.` | `waf` |
| `vendor` | `String` | `Vendor or project name.` | `example-sec` |
| `product` | `String` | `Product or package name.` | `appshield` |
| `code_version` | `String` | `Version of the executable or engine.` | `4.2.1` |
| `content_version` | `String` | `Version of signatures, models, feeds, or detection content.` | `crs-3.4.0` |
| `policy_version` | `String` | `Version of the policy bundle or scenario-specific rules.` | `policy-2026-03-10` |
| `artifact_digest` | `String` | `Immutable digest of the deployed image, package, or artifact.` | `sha256:abcd1234` |
| `config_digest` | `String` | `Immutable digest of the applied configuration.` | `sha256:efgh5678` |
| `placement` | `Object` | `Nodes, networks, or services where the control is deployed.` | `{nodes: [waf-0], networks: [dmz]}` |
| `telemetry` | `Array` | `Evidence streams produced by the control.` | `[waf_alert_log, http_access_log]` |

The combination of `vendor`, `product`, `code_version`, `content_version`, `policy_version`, `artifact_digest`, and `config_digest` SHOULD be sufficient to reproduce the same defensive setup in a future run.

### A.3. Capability Declaration: Detect Versus Block

Each defensive control SHOULD explicitly declare which scenario activities it is intended to detect and which it is intended to block. Implementations SHOULD avoid ambiguous labels such as "protects web traffic" when the expected behavior can be expressed against named scenario actions.

The following capability fields are RECOMMENDED:

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `detects` | `Array` | `Scenario actions, attack steps, or conditions the control is expected to alert on.` | `[sqli-login-attempt]` |
| `blocks` | `Array` | `Scenario actions, attack steps, or conditions the control is expected to prevent.` | `[sqli-login-attempt]` |
| `response_actions` | `Array` | `Post-detection actions triggered by the control or an integrated system.` | `[block_source_ip, isolate_host]` |
| `mode` | `String` | `Operational behavior of the control during the experiment.` | `{monitor, enforce, simulate}` |

The intent of these fields is:

* `detects` identifies activity that SHOULD raise observable telemetry or an alert.
* `blocks` identifies activity that SHOULD be prevented from completing successfully.
* `response_actions` identifies the follow-on behavior that may occur after a detection.
* `mode` records whether the product was observing, enforcing, or simulating policy during the run.

Some control types are commonly `detect_only`, while others are commonly `detect_and_block`. Scenario authors SHOULD declare the intended behavior for the specific product instance used in the scenario rather than assuming it from the control family.

### A.4. Agent Decision Records

An `AgentDecision` is the structured record emitted by an agent each time it acts. It captures the full decision loop — what the agent observed, how it reasoned, what it executed, and what came back. In the context of defensive evaluation, each `AgentDecision` represents a concrete action that defensive controls are evaluated against. The `id` field of an `AgentDecision` is what `actionRef` in section A.5 references.

| `Property` | `Type` | `Required` | `Description` | `Example` |
| :---- | :---- | :---- | :---- | :---- |
| `id` | `String` | `Yes` | `Unique identifier for this decision record.` | `decision-0042` |
| `agent_id` | `String` | `Yes` | `Which agent made this decision.` | `explorer` |
| `timestamp` | `String` | `Yes` | `When the decision was made (ISO 8601).` | `2026-03-13T14:32:00Z` |
| `objective_ref` | `String` | `Yes` | `Reference to the RFC-0002 objective the agent was pursuing.` | `environment-mapped` |
| `environment_state` | `Object` | `No` | `Snapshot of relevant environment state at decision time.` | `{nodes: {server-01: {compromised: false}}}` |
| `input` | `Object` | `Yes` | `What the agent received or observed before deciding.` | `{source: telemetry, data: {...}}` |
| `cot` | `Array` | `Yes` | `Chain-of-Thought reasoning steps. **How to gather this?**` | `["identified open port", "selected nmap"]` |
| `tool_calls` | `Array` | `Yes` | `Tools the agent executed. Each entry is a ToolCall object (see below).` | see ToolCall |
| `output` | `Object` | `Yes` | `What came back — results, responses, or errors.` | `{status: success, data: {...}}` |
| `outcome` | `String` | `No` | `Did it work? success, failure, aborted` | `success` |

#### ToolCall Object

Multiple tool calls may occur in parallel within a single decision. Each is recorded as a separate `ToolCall` entry.

| `Property` | `Type` | `Required` | `Description` | `Example` |
| :---- | :---- | :---- | :---- | :---- |
| `id` | `String` | `Yes` | `Unique identifier for this specific tool execution.` | `call_9f8a7b6c` |
| `tool_name` | `String` | `Yes` | `The name of the tool, function, or command invoked.` | `execute_shell`, `read_file` |
| `arguments` | `Object` | `Yes` | `Key-value pairs of the parameters passed to the tool.` | `{command: "nmap -p 22,80 10.0.5.50"}` |
| `timestamp` | `String` | `Yes` | `When the tool execution started (ISO 8601).` | `2026-03-13T14:32:01Z` |
| `duration_ms` | `Integer` | `No` | `How long the tool took to execute.` | `4520` |
| `output` | `Object` | `Yes` | `The raw output returned by the tool.` | `{stdout: "PORT STATE...", exit_code: 0}` |
| `status` | `String` | `Yes` | `The execution state of the tool itself.` | `success`, `error`, `timeout` |

The `tool_calls` field is the primary signal for defensive evaluation — it records exactly what the agent attempted, which is what defensive controls are positioned to detect or block.

### A.5. Evaluation Outcome Model

To compare defensive results across experiments, implementations SHOULD evaluate defensive controls against named scenario actions and produce a per-control result record.

Each evaluation record SHOULD include the following fields:

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `actionRef` | `String` | `Reference to an AgentDecision id (see A.4).` | `decision-0042` |
| `controlRef` | `String` | `Reference to the defensive control instance.` | `edge-waf-01` |
| `expected_effect` | `String` | `Expected control behavior for the action.` | `{detect, block, respond, none}` |
| `detection_observed` | `Boolean` | `Whether observable telemetry or an alert was generated.` | `true` |
| `blocking_observed` | `Boolean` | `Whether the action was prevented from completing.` | `true` |
| `final_outcome` | `String` | `Normalized result for this action/control pair.` | `{bypassed, detected, blocked, partially_blocked, not_applicable}` |
| `evidence` | `Array` | `References to alerts, logs, packet captures, or other artifacts.` | `[waf_alert_id:44321]` |
| `notes` | `String` | `Operator notes or implementation-specific context.` | `Alert fired after request body inspection.` |

The normalized `final_outcome` values are intended to mean:

* `bypassed`: the action succeeded and the control did not produce effective prevention.
* `detected`: the action produced a detection, but the action still succeeded fully or partially.
* `blocked`: the action did not complete because the control prevented it.
* `partially_blocked`: the control reduced or interrupted the action, but some objective was still achieved.
* `not_applicable`: the control was not intended to cover that action.

### A.6. Defensive Control Families

The following families are RECOMMENDED as a baseline taxonomy for ACES scenarios. The list is not exhaustive, but it covers the most common product classes likely to appear in an enterprise cyber range.

#### A.6.1. Network Security Controls

Network controls operate at trust boundaries, network choke points, routing domains, and monitored segments.

| `Attribute` | `Guidance` |
| :---- | :---- |
| `Representative Types` | `firewall`, `ids`, `ips`, `ndr`, `proxy`, `vpn_gateway`, `segmentation_gateway` |
| `Typical Placement` | `gateway nodes`, `router nodes`, `inter-network links`, `DMZ boundaries`, `SPAN/TAP visibility points` |
| `Typical Detects` | `port scans`, `lateral movement`, `command-and-control`, `policy violations`, `exploit traffic` |
| `Typical Blocks` | `unauthorized ingress`, `unauthorized egress`, `forbidden east-west traffic`, `known malicious signatures` |
| `Typical Telemetry` | `flow logs`, `firewall logs`, `IDS alerts`, `packet captures`, `proxy access logs` |
| `Typical Tradeoffs` | `added latency`, `reduced throughput`, `false positives on unusual traffic`, `encrypted traffic visibility limits` |

Network controls SHOULD be modeled by reference to the nodes and networks where they are deployed and by the actions that traverse or target those paths.

#### A.6.2. Endpoint Security Controls

Endpoint controls operate on workstations, servers, containers, or other host nodes.

| `Attribute` | `Guidance` |
| :---- | :---- |
| `Representative Types` | `av`, `epp`, `edr`, `host_ids`, `host_firewall`, `application_allowlisting` |
| `Typical Placement` | `server nodes`, `workstation nodes`, `persistent containers`, `jump hosts` |
| `Typical Detects` | `malware execution`, `credential dumping`, `process injection`, `suspicious persistence`, `tampering` |
| `Typical Blocks` | `malicious binaries`, `unapproved processes`, `host-to-host connections`, `known exploit chains` |
| `Typical Telemetry` | `process events`, `file events`, `registry events`, `alerts`, `quarantine actions`, `host audit logs` |
| `Typical Tradeoffs` | `CPU and memory overhead`, `alert noise`, `user disruption`, `host compatibility issues` |

Endpoint controls SHOULD reference the node names where agents or protections are deployed and the runtime actions that execute on or against those nodes.

#### A.6.3. Application Security Controls

Application controls protect application protocols, service logic, and exposed APIs.

| `Attribute` | `Guidance` |
| :---- | :---- |
| `Representative Types` | `waf`, `api_gateway_security`, `reverse_proxy_filter`, `rasp` |
| `Typical Placement` | `in front of web services`, `at ingress tiers`, `within service meshes`, `inside the application runtime` |
| `Typical Detects` | `SQL injection`, `cross-site scripting`, `path traversal`, `deserialization abuse`, `API misuse` |
| `Typical Blocks` | `malicious HTTP requests`, `abusive clients`, `forbidden API calls`, `payloads matching policy` |
| `Typical Telemetry` | `HTTP logs`, `WAF alerts`, `anomaly scores`, `request traces`, `application audit logs` |
| `Typical Tradeoffs` | `request latency`, `false positives on edge cases`, `TLS inspection complexity`, `application compatibility` |

Application controls SHOULD be associated with the service-hosting nodes and with the runtime actions that simulate user, attacker, or automated application traffic.

#### A.6.4. Identity and Access Security Controls

Identity controls govern authentication, authorization, privilege, and trust relationships.

| `Attribute` | `Guidance` |
| :---- | :---- |
| `Representative Types` | `mfa`, `idp_policy`, `pam`, `directory_policy`, `conditional_access` |
| `Typical Placement` | `directory services`, `identity gateways`, `bastions`, `privileged access paths`, `application auth tiers` |
| `Typical Detects` | `suspicious logins`, `impossible travel`, `credential abuse`, `privilege escalation attempts` |
| `Typical Blocks` | `unauthorized login`, `policy-violating access`, `risky sessions`, `forbidden privilege requests` |
| `Typical Telemetry` | `authentication logs`, `authorization events`, `MFA challenges`, `session records`, `directory audit logs` |
| `Typical Tradeoffs` | `added user friction`, `broken automation`, `lockout risk`, `federation complexity` |

Identity controls SHOULD be modeled against authentication and authorization actions that occur in runtime phases and against the nodes or services that enforce trust decisions.

#### A.6.5. Monitoring and Response Controls

Monitoring and response controls collect, correlate, enrich, and sometimes automate follow-on defensive actions.

| `Attribute` | `Guidance` |
| :---- | :---- |
| `Representative Types` | `siem`, `soar`, `log_collector`, `threat_intel_enrichment`, `case_management` |
| `Typical Placement` | `centralized monitoring nodes`, `log pipelines`, `security operations enclaves` |
| `Typical Detects` | `multi-stage attacks`, `cross-host correlations`, `policy violations`, `response failures` |
| `Typical Blocks` | `not usually direct blockers`, `may initiate containment via downstream controls` |
| `Typical Telemetry` | `normalized alerts`, `correlation results`, `cases`, `playbook executions`, `timeline artifacts` |
| `Typical Tradeoffs` | `correlation delay`, `rule tuning burden`, `large storage requirements`, `operator fatigue` |

Monitoring and response platforms are commonly `detect_only` or `respond_after_detection`. Scenario authors SHOULD not assume that these controls directly prevent an action unless an explicit downstream response path is modeled.

### A.7. Reporting and Reproducibility Guidance

Implementations SHOULD emit a structured report that makes it easy to compare what was bypassed, what was detected, and what was blocked across control products and scenario runs.

At minimum, a report SHOULD include:

* The scenario identifier and version.
* The runtime action or attack-step identifiers under evaluation.
* The defensive control instances present in the run.
* For each control instance, the `vendor`, `product`, `code_version`, `content_version`, and `policy_version`.
* For each action/control pair, the normalized result of `bypassed`, `detected`, `blocked`, `partially_blocked`, or `not_applicable`.
* Evidence references sufficient for an evaluator to trace the result to source artifacts.

Implementations MAY also calculate summary measures such as:

* percentage of relevant actions detected
* percentage of relevant actions blocked
* mean time to detection
* mean time to response
* false positive count
* service availability impact during enforcement

### A.8. Illustrative YAML Fragment

The following example is non-normative and demonstrates one way to describe a defensive control and its evaluation results within a scenario artifact or report.

```yaml
defenseControls:
  - id: edge-waf-01
    family: application
    type: waf
    vendor: example-sec
    product: appshield
    code_version: 4.2.1
    content_version: crs-3.4.0
    policy_version: policy-2026-03-10
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
      - waf_alert_id: "44321"
      - http_status: "403"
    notes: Request blocked during request body inspection.

  - actionRef: xss-comment-post
    controlRef: edge-waf-01
    expected_effect: detect
    detection_observed: true
    blocking_observed: false
    final_outcome: detected
    evidence:
      - waf_alert_id: "44355"
    notes: Alert generated but request completed.
```
