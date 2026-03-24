# ACES Appendix: Defensive Control Evaluation Metadata

## Status

`Draft`

## Relationship to ACES RFCs

`This appendix complements the ACES RFC suite, including RFC-0001 and future experiment specifications. OCSF remains the normative schema for normalized defensive telemetry, alerts, findings, and evidence artifacts. This appendix defines the ACES-specific overlay needed to connect those records back to scenario intent, reproducibility, and per-action evaluation outcomes.`

## Summary

`This appendix helps scenario authors compare defensive controls across ACES runs without redefining telemetry schemas already covered by OCSF. It specifies how to identify a control-under-test, bind it to ACES topology and runtime actions, capture reproducibility metadata that is not fully standardized by OCSF, and report normalized outcomes such as bypassed, detected, and blocked.`

## Appendix A. Defensive Control Evaluation Metadata

This appendix does not define a competing event schema. Implementations SHOULD use
OCSF for normalized defensive events, alerts, findings, and evidence artifacts.
This appendix only defines the ACES-specific reporting and evaluation model that
sits on top of those records in scenario artifacts, experiment specifications,
and execution reports.

### A.1. Scope and Intent

The purpose of this appendix is to make defensive scenarios reproducible and
comparable across implementations. A defensive control definition should answer
the following questions:

* What product or control is present in the scenario?
* Where is it placed in the environment?
* What activity is it expected to detect?
* What activity is it expected to block or otherwise prevent?
* What OCSF-normalized telemetry, alerts, findings, or evidence artifacts prove
  the result?
* What exact product, policy, content, and configuration versions were used?
* For each scenario action, what observed evaluation outcome occurred?

This appendix deliberately separates two concerns:

* OCSF defines the normalized observation layer for defensive telemetry,
  findings, evidence artifacts, and control outcomes.
* This appendix defines the ACES scenario layer: control placement in the
  scenario, expected coverage for named runtime actions, supplemental
  reproducibility metadata, and per-action evaluation results.

Defensive controls SHOULD be modeled by reference to existing scenario objects:

* `topology.nodes` for control placement on hosts, gateways, routers, switches, or dedicated security appliances.
* `topology.networks` for control placement at trust boundaries, VLANs, subnets, or monitored segments.
* `resources.bindings` for images, packages, and infrastructure bindings associated with the control.
* `runtime.phases` and `runtime.actions` for the offensive, administrative, or validation activities that the control is expected to observe or affect.

### A.2. Common Control Metadata

Each defensive control instance SHOULD reuse OCSF objects where possible and
only add ACES-specific metadata where OCSF does not directly express
scenario-evaluation intent.

| `Concern` | `Preferred Representation` | `Notes` |
| :---- | :---- | :---- |
| Product or control identity | OCSF `product.{uid,vendor_name,name,version}` or `agent.{uid,vendor_name,name,version}` | Use `agent` for host-resident sensors and `product` for reporting products or services. |
| Policy or rule traceability | OCSF `policy.{uid,name,type,version}`, `rule.{uid,name,type,version}`, `security_control.policy`, `security_control.firewall_rule` | Use the OCSF policy and rule objects instead of parallel ACES version fields when possible. |
| Detection and finding records | OCSF `detection_finding`, `finding_info.{uid,title,analytic,product,related_events}`, and `evidences` | Use for normalized alerts, findings, and evidence artifacts. |
| Adversary and countermeasure taxonomy | OCSF `attack` and `d3fend` | Use ATT&CK references for covered adversary behavior and D3FEND for countermeasure taxonomy. |
| Protected assets or enforcement points | OCSF `endpoint`, `application`, `idp`, or `logger` | Choose the object that best represents the observed control or protected service. |

ACES adds only the following supplemental metadata where OCSF does not fully
capture scenario-evaluation intent:

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `id` | `String` | `Unique identifier for the control instance within the ACES scenario.` | `edge-waf-01` |
| `family` | `String` | `Optional ACES family label used for summaries and report rollups.` | `{network, endpoint, application, identity, monitoring_response}` |
| `type` | `String` | `Optional scenario-local subtype label when a short local label is helpful.` | `waf` |
| `placement` | `Object` | `References to ACES nodes, networks, services, or protected assets where the control is deployed.` | `{nodes: [waf-0], networks: [dmz]}` |
| `telemetry` | `Array` | `Logical ACES telemetry stream identifiers expected to carry OCSF-normalized records from this control.` | `[waf_alert_log, http_access_log]` |
| `content_version` | `String` | `Version of signatures, models, feeds, or detection content when distinct from product or policy version.` | `crs-3.4.0` |
| `artifact_digest` | `String` | `Immutable digest of the deployed image, package, or artifact.` | `sha256:abcd1234` |
| `config_digest` | `String` | `Immutable digest of the applied configuration.` | `sha256:efgh5678` |

The combination of OCSF product, policy, and rule identifiers plus
`content_version`, `artifact_digest`, and `config_digest` SHOULD be sufficient
to reproduce the same defensive setup in a future run.

### A.3. Capability Declaration: Detect Versus Block

Each defensive control SHOULD explicitly declare which scenario activities it is
intended to detect and which it is intended to block. These declarations express
expected coverage over named ACES `runtime.actions`; they do not replace the
observed OCSF records emitted during execution. Implementations SHOULD avoid
ambiguous labels such as "protects web traffic" when the expected behavior can
be expressed against named scenario actions.

The following capability fields are RECOMMENDED:

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `detects` | `Array` | `Scenario actions, attack steps, or conditions expected to produce OCSF-observable detection telemetry or findings.` | `[sqli-login-attempt]` |
| `blocks` | `Array` | `Scenario actions, attack steps, or conditions expected to produce OCSF blocking or denial outcomes.` | `[sqli-login-attempt]` |
| `response_actions` | `Array` | `Post-detection actions triggered by the control or an integrated system.` | `[block_source_ip, isolate_host]` |
| `mode` | `String` | `Intended operational behavior of the control during the experiment.` | `{monitor, enforce, simulate}` |

The intent of these fields is:

* `detects` identifies activity that SHOULD raise observable telemetry, a normalized
  OCSF detection finding, or another alertable signal.
* `blocks` identifies activity that SHOULD be prevented from completing successfully.
* `response_actions` identifies the follow-on behavior that may occur after a detection.
* `mode` records whether the product was observing, enforcing, or simulating policy during the run.

Some control types are commonly `detect_only`, while others are commonly `detect_and_block`. Scenario authors SHOULD declare the intended behavior for the specific product instance used in the scenario rather than assuming it from the control family.

Observed behavior SHOULD be captured via OCSF records, typically by applying the
`security_control` profile to activity events or by emitting a `detection_finding`
when the control produces a normalized alert or analytic result. In other words,
`detects`, `blocks`, and `response_actions` declare intent before the run; OCSF
captures what actually happened during the run.

### A.4. Evaluation Outcome Model

To compare defensive results across experiments, implementations SHOULD evaluate defensive controls against named scenario actions and produce a per-control result record.

Each evaluation record SHOULD include the following fields:

| `Property` | `Type` | `Description` | `Example` |
| :---- | :---- | :---- | :---- |
| `actionRef` | `String` | `Reference to the runtime action, attack step, or validation step under test.` | `sqli-login-attempt` |
| `controlRef` | `String` | `Reference to the defensive control instance.` | `edge-waf-01` |
| `expected_effect` | `String` | `Expected control behavior for the action.` | `{detect, block, respond, none}` |
| `detection_observed` | `Boolean` | `Whether observable telemetry or an alert was generated.` | `true` |
| `blocking_observed` | `Boolean` | `Whether the action was prevented from completing.` | `true` |
| `final_outcome` | `String` | `Normalized result for this action/control pair.` | `{bypassed, detected, blocked, partially_blocked, not_applicable}` |
| `evidence` | `Array` | `References to OCSF-normalized findings, evidence artifacts, alerts, logs, packet captures, or other artifacts.` | `[finding_uid:waf-detection-44321]` |
| `notes` | `String` | `Operator notes or implementation-specific context.` | `Alert fired after request body inspection.` |

The normalized `final_outcome` values are intended to mean:

* `bypassed`: the action succeeded and the control did not produce effective prevention.
* `detected`: the action produced a detection, but the action still succeeded fully or partially.
* `blocked`: the action did not complete because the control prevented it.
* `partially_blocked`: the control reduced or interrupted the action, but some objective was still achieved.
* `not_applicable`: the control was not intended to cover that action.

Each evaluation record is an ACES overlay over one or more observed OCSF
records. Implementations SHOULD prefer stable identifiers such as
`finding_info.uid`, `evidences.uid`, product identifiers, and logger event
identifiers when constructing evidence references.

### A.5. Control Taxonomy and OCSF Mapping

This section is non-normative. ACES does not define a competing defensive
product ontology. Implementations SHOULD rely on OCSF objects for normalized
control-related telemetry and MAY use the following family labels only for
scenario summaries and report rollups.

| `ACES Family` | `Representative Controls` | `Primary OCSF Building Blocks` | `Notes` |
| :---- | :---- | :---- | :---- |
| `network` | `firewall`, `ids`, `ips`, `proxy`, `segmentation_gateway` | `endpoint`, `firewall_rule`, `security_control`, `evidences.{src_endpoint,dst_endpoint,connection_info,url}` | Use for boundary and network choke-point controls. |
| `endpoint` | `av`, `epp`, `edr`, `host_ids`, `host_firewall`, `application_allowlisting` | `agent`, `endpoint`, `security_control`, `evidences.{process,file,device,user}` | Use for host-resident sensors and on-host enforcement. |
| `application` | `waf`, `api_gateway_security`, `reverse_proxy_filter`, `rasp` | `application`, `firewall_rule`, `security_control`, `evidences.{http_request,http_response,url,api}` | Use for application-layer inspection and enforcement. |
| `identity` | `mfa`, `idp_policy`, `pam`, `directory_policy`, `conditional_access` | `idp`, `policy`, `security_control` | Use for authentication, authorization, privilege, and trust controls. |
| `monitoring_response` | `siem`, `soar`, `log_collector`, `threat_intel_enrichment`, `case_management` | `detection_finding`, `finding_info.analytic`, `logger`, `agent`, `evidences` | Often `detect_only` or `respond_after_detection` unless explicit downstream blocking is modeled. |

Where a control needs explicit countermeasure taxonomy, implementations SHOULD
use OCSF `d3fend`. Where covered adversary behavior needs classification,
implementations SHOULD use OCSF `attack`.

### A.6. Reporting and Reproducibility Guidance

Implementations SHOULD emit OCSF-normalized alerts, findings, and evidence
artifacts for defensive telemetry where applicable. This appendix adds the
cross-scenario comparison layer needed to evaluate what was bypassed, detected,
and blocked across products and runs.

At minimum, a report SHOULD include:

* The scenario identifier and version.
* The runtime action or attack-step identifiers under evaluation.
* The defensive control instances present in the run.
* For each control instance, OCSF-aligned product, agent, policy, and rule identifiers where applicable, plus any ACES-specific supplemental metadata such as `content_version`, `artifact_digest`, and `config_digest`.
* For each action/control pair, the normalized result of `bypassed`, `detected`, `blocked`, `partially_blocked`, or `not_applicable`.
* Evidence references sufficient for an evaluator to trace the result to source artifacts, preferably by stable identifiers such as OCSF `finding_info.uid`, `evidences.uid`, product identifiers, or logger `event_uid`.

When raw telemetry cannot be normalized cleanly to OCSF, reports SHOULD preserve
the vendor-native reference alongside the ACES result and document the gap.

Implementations MAY also calculate summary measures such as:

* percentage of relevant actions detected
* percentage of relevant actions blocked
* mean time to detection
* mean time to response
* false positive count
* service availability impact during enforcement

### A.7. Illustrative YAML Fragment

The following example is non-normative and demonstrates one way to describe an
ACES defensive control overlay and its evaluation results while reusing
OCSF-aligned product, policy, and evidence references.

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
