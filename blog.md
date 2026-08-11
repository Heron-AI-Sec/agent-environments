# Agentic AI Specification: Moving Towards Reproducibility

When autonomous agents can move, collude, and exploit faster than human operators can triage alerts, the robustness of our current defensive systems is called into question. The future of cyber defense relies on our ability to proactively identify and disrupt malicious AI actors, especially when they distribute actions across multiple sessions and agents.

Our project focuses on developing a specification to address the following:

* **Improving the reproducibility** of experiment scenarios, particular those designed an executed on cyber ranges.
* **Testing the observability** of agents across environments, including multi-agent environments.
* **Reducing functional assessment gaps** between synthetic test environments and the real world.

Achieving this requires a rigorously structured approach. We propose a suite of five declarative schema specifications (RFC-0001 through RFC-0005) that transform abstract concepts into empirical, quantifiable data.

Here is how this framework breaks down the problem.

---

## Does the Theater Matter to the Play?

When testing AI agents, we want to know if the environment affects the outcomes. If we use the exact same foundation model but change the environment, does the attack path change? A cyber agent's "kill chain" is rarely a static sequence memorized from training data, but it may still be predictable.

* **The Foundation Model** provides the *vocabulary* of the attack (the knowledge of exploits and techniques).
* **The Scaffold and System Prompt** provide the *logic* (the localized reward function, such as prioritizing stealth over speed).
* **The Environment** provides the *execution path*. By architecting the environment, we posit that we can predictably force an agent down specific paths.

If we hold the environment in a static, declarative snapshot, essentially "unit testing" the orchestrator's Chain of Thought, we can empirically measure how varying levels of observability, perceived vulnerabilities, and resource availability dictate the agent's behavior.

---

## Improving the Reproducibility of Experiment Scenarios

Testing environments designed and executed on cyber ranges must be highly reproducible and clearly versioned. Without this standard, experiments cannot be accurately shared, re-run, or compared.

* **Infrastructure (RFC-0001):** This specification defines what exists by declaratively mapping topologies and resource bindings. This eliminates environmental drift and ensures that the baseline environment state is identical across runs.
* **Agentic Experiments (RFC-0002):** This standardizes the experiment itself by defining what agents exist, what they can observe, and how success is measured. By keeping experiments independent of the environment, researchers can plug different orchestrators or foundation models into the same infrastructure.
* **Scenario Definition (RFC-0004):** This formalizes execution instances into defined `Runs` and `Studies`. By requiring a strict `reset_strategy`, it guarantees that benchmarks are statistically valid and that the starting state is universally understood.

---

## Testing the Observability of Agents Across Environments

If autonomous agents are distributing actions across multiple sessions and agents, defenses must correlate disjointed events into a unified narrative. Measuring this across complex, multi-agent environments requires a structured approach to logging and data normalization.

* **Observability Schema (RFC-0003):** This specification introduces standard correlation patterns using `trace_id`, `correlation_id`, and `action_id` to tie an agent's specific tool invocation directly to the resulting environment state change. It also supports multi-agent tracking of communications and shared objective chains across different agents. It defines telemetry tiering to establish a measurable baseline.
* **Security Domain Schema (RFC-0005):** This schema models explicit attack relationships and credential chains for a cyber attack scenario. While standard Open Cybersecurity Schema Framework  (OCSF) mappings handle isolated events, this taxonomy explicitly captures the graph structure of an attack path. If one agent compromises a host and another uses the resulting hash to move laterally, this explicit lineage is tracked.

---

## Objective 3: Reducing Functional Assessment Gaps

To ensure experimental findings translate to real-world environments, we aim to eliminate the variables that plague synthetic environments. When an AI agent fails a test, we must be absolutely certain that it failed due to the agent's logic or the environmental controls rather than a random program error.

We couple cyber range infrastructure specification with standardized observability schemas to bridge the gap between simulation and emulation. This ensures that the limits we discover in our experiment systems accurately reflect the limits that would be faced in real systems.

---

## Tracking Mechanics

To operationalize these concepts, the framework relies on specific telemetry and relationship tracking properties to monitor agent behavior:

| Property | Type | Description |
| --- | --- | --- |
| `agent.decision.cot` | String | Captures Chain-of-Thought reasoning steps extracted from agent output to measure why an agent chose a specific path. |
| `telemetry.tier` | Enum | Adjusts logging verbosity, dictating the truncation of attributes and the depth of agent reasoning records to benchmark detection limits. |
| `DerivedFrom` | EdgeType | Maps credential chain lineage (e.g., cracked from hash) to explicitly track cross-session collusion. |
| `correlation_id` | String | Links causally-related events, such as connecting an agent's discrete action directly to the resulting environment state change. |

---

## What Comes Next

By treating testing environments as rigorous, version-controlled code, and by standardizing how we measure an agent interactions, we can improve the empirical results of cyber range experiments.
