# "Scenario" Definition Language (SDL) for Agentic AI Evaluations

This repository contains a proposed definition language for describing,
reproducing, and comparing AI cyber capability evaluations.

The SDL aims to describe an environment, in addition to allowing for comparable 
agentic assessments in a manner which is structurally consistent.

It is designed to be readable by humans and actionable by software, including
LLM coding agents that need to write, extend, audit, or recreate experiments
from structured specifications rather than scattered prose.

In this repo, a good specification should answer four different questions:

1. What exists in the target world?
2. What is the agent asked or allowed to do?
3. What exact runnable evaluation unit was executed?
4. What happened during the run, and can someone else reproduce it?

This matters for AI safety because cyber capability claims are hard to compare
when the environment, objective, reset method, telemetry, or scoring are only
described informally. A shared definition language gives us a path toward
replayable tests instead of one-off demos.

These RFCs are proposal documents for an evolving schema, and this repository
is intended to invite review, implementation feedback, and discussion grounded
in concrete evaluation use cases.

### Core Idea

The language is split into layers so that reproducibility does not depend on a
single giant scenario file. The table below is the main map of how the RFCs
divide responsibility:

| RFC | Primary responsibility | Main question it answers | Representative contents |
| --- | --- | --- | --- |
| [RFC-0001](rfc/rfc-0001-infrastructure-schema.md) | Infrastructure schema | What exists in the target world? | Topology, nodes, networks, telemetry endpoints, agent platform, connectivity, and environment artifacts such as `loot` |
| [RFC-0002](rfc/rfc-0002-agentic-experiment-specification.md) | Agentic experiment schema | What is the agent asked or allowed to do? | Agents, objectives, observation and action surfaces, runtime behavior, and `interventions` |
| [RFC-0003](rfc/rfc-0003-observability-schema-specification.md) | Observability schema | What evidence should execution emit? | Telemetry conventions, event structure, logging expectations, and comparability-oriented evidence |
| [RFC-0004](rfc/rfc-0004-scenario-definition-language.md) | Scenario definition language | What exact evaluation unit was run, and how can it be reproduced? | `Scenario`, `Run`, and `Study` objects, reproducible packaging, and recorded run context |
| [RFC-0005](rfc/rfc-0005-security-domain-schema.md) | Security-domain schema | What security-specific structure should be modeled when a scenario needs it? | Attack relationships, credential kinds, privilege structure, and evaluation-relevant security metadata |

That separation is intentional. It lets the repo distinguish world state,
agent behavior, execution evidence, reproducible packaging, and optional
security-domain structure without collapsing everything into one monolithic
scenario file.

### Why This Repo Exists

This project is aimed at agentic AI evaluation, especially those focused on
cyber capabilities. In practice that means the language should support:

- Recreating the same environment across teams and backends.
- Pinning the exact agent setup, goals, and stopping conditions.
- Capturing telemetry rich enough for later audit, replay, and analysis.
- Recording reset strategy and versioning so repeated runs are actually comparable.
- Expressing cyber-relevant structure without forcing every scenario into a single attack-graph formalism.

The standard we are aiming for is stronger than "someone wrote a README and a Docker
Compose file." A useful evaluation artifact should be machine-readable, versioned, 
and clear about what is ground truth versus what was merely observed in one run.

### Why This Helps LLM Coding Agents

One of the strongest reasons to define this language well is that LLM coding
agents can use it directly.

When an experiment is specified as clear environment, experiment, scenario, and
telemetry artifacts, an LLM coding agent can:

- generate a missing testbed implementation from the spec,
- recreate an evaluation package in a new repo or backend,
- check whether an implementation still matches the intended experiment,
- produce harness glue, validation scripts, and run wrappers,
- and compare two versions to explain what changed in capability, setup, or scoring.

This is much harder when the evaluation only exists as a paper, a Docker
Compose file, and a long README. In such a scenario, the agent has to infer hidden
assumptions about which facts belong to the environment, which belong to the
experiment contract, which should appear in telemetry, and which are specific
to a recorded run. The layered split summarized above reduces that ambiguity,
which is exactly what helps coding agents do useful work reliably.

A well-defined language turns "please recreate this cyber evaluation from a
vague description" into "implement this versioned package and preserve these
semantics."

### Repository Layout

- [rfc/](rfc) holds the proposed language specifications.
- [research/](research) holds supporting research notes and design material.

### How to Read the Specs

If you are new to the repo, the cleanest path is:

1. Read [rfc-0001-infrastructure-schema.md](rfc/rfc-0001-infrastructure-schema.md) and [rfc-0002-agentic-experiment-specification.md](rfc/rfc-0002-agentic-experiment-specification.md) first.
2. Read [rfc-0004-scenario-definition-language.md](rfc/rfc-0004-scenario-definition-language.md) to see how reproducible execution and run records are represented.
3. Use [rfc-0003-observability-schema-specification.md](rfc/rfc-0003-observability-schema-specification.md) to understand what evidence a compliant runtime should emit.
4. Add [rfc-0005-security-domain-schema.md](rfc/rfc-0005-security-domain-schema.md) when you need security-specific modeling such as credentials, attack edges, or defensive evaluation metadata.
5. Then apply the specs to a concrete package or implementation in your own evaluation workflow.

### Design Principles

- Reproducibility over convenience. Versioned artifacts and run semantics matter more than short manifests.
- Separation of concerns. Infrastructure, agent behavior, observability, and study metadata are different layers.
- Backend agnosticism. The language should survive changes in orchestration or runtime implementation.
- AI safety usefulness. The schema should help us evaluate agent capability, not just deploy labs.
- Honest partiality. If a domain taxonomy does not fit a scenario exactly, the specs should allow explicit approximation rather than hiding it.

## Current State

These RFCs are proposed specifications intended for real package-level usage,
and some boundaries are still evolving, especially around cyber-domain modeling,
run records, and how much structure should be native versus extension-based.

That is expected. The immediate purpose of the repo is to make those design
choices explicit and test them against concrete AI safety evaluations rather
than arguing about them in the abstract.

**What Success Looks Like**

If this project succeeds, a future researcher should be able to:

- take a published scenario package,
- instantiate the same environment,
- run a different model or harness against it,
- collect comparable telemetry,
- and explain any result difference in terms of versioned environment,
  experiment, scenario, or runtime changes.

That is the bar this definition language is trying to meet.
