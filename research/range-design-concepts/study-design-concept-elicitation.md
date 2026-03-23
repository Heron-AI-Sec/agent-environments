# Study Design: Conceptual Foundations of Cyber Range Environment Specification

## 1. Objective

Develop a grounded taxonomy of the concepts practitioners use when specifying,
building, and operating cyber range environments—whether those ranges support
human exercises, autonomous AI agents, or both. The taxonomy is derived from
practitioner mental models, not from existing specifications or researcher
assumptions.

## 2. Research Questions

**Primary:** What conceptual primitives do practitioners distinguish when
specifying cyber range environments, and how do they organize them?

**Supporting:**

- RQ1: What activities and artifacts do practitioners describe when building a
cyber range, and what language do they use?
- RQ2: Where do practitioners draw boundaries between concerns (infrastructure,
content, behavior, assessment), and what drives those distinctions?
- RQ3: What concepts do practitioners handle procedurally—through scripts,
manual steps, or tribal knowledge—that they wish they could express
declaratively?
- RQ4: How do practitioners think about reuse, composition, and
parameterization of range specifications?
- RQ5: What does reproducibility mean in concrete terms—what must be held
constant, what can vary, what must be recorded?

## 3. Method

### 3.1 Socio-Technical Grounded Theory

We apply STGT (Hoda 2021) for three reasons. The domain is socio-technical:
human design decisions about architecture, provisioning, and scenario structure
are inseparable from the technical artifacts they produce. We need to generate a
conceptual taxonomy from data, not test an existing decomposition—the existing
decomposition does not hold up under scrutiny. And STGT provides explicit
guidelines for SE and AI researchers, eliminating the ad hoc adaptation that
weakens most GT studies in technical domains.

We take an interpretivist position. Multiple valid decompositions may exist.
The goal is to surface the conceptual structure practitioners use in practice.

### 3.2 Problem-Centred Expert Interview

Interviews follow Döringer (2021), combining Witzel's problem-centred interview
with Bogner and Menz's expert interview typology. A narrative opening lets the
participant describe their work in their own language. A discursive-dialogic
follow-up probes the concepts they surfaced—what they are, how they relate, and
where the boundaries fall.

Interviews are conducted remotely over Zoom, 45–60 minutes each.

## 4. Sampling

### 4.1 Strategy

Snowball sampling seeded from the research team's professional contacts. Each
participant is asked to recommend others who build or operate cyber ranges. The
target population is small and specialized; practitioners know each other
through conferences, working groups, and collaborative projects. General
recruitment would not reach them.

Theoretical sampling augments snowball as analysis progresses. When an emerging
category needs development in a context not yet represented, we request
targeted referrals.

### 4.2 Participant Dimensions

We seek variation across three dimensions.

**Role:** Cyber range builder. Exercise/scenario designer.
Platform/infrastructure engineer. Researcher running evaluations (human or AI).

**Context:** Commercial range operations (SimSpace, Hack The Box, etc.).
Government or military exercises (CCDCOE, national ranges). Academic research
(AI agent evaluation, training exercises). Open-source projects (OCR, Crucible,
CybORG). Industry red/purple team operations.

**Technical approach:** Real infrastructure (cloud, bare metal). Container-based
(Docker, containerlab). Simulation (CybORG, CyberBattleSim). Hybrid (real and
simulated components).

**Participant type:** Ranges built for human teams. Ranges built for AI agents
(offensive, defensive, or both). Ranges that serve both.

### 4.3 Sample Size

STGT does not prescribe a fixed sample. We follow theoretical saturation:
interviewing continues until new interviews do not generate new categories.
Comparable STGT studies in software engineering report saturation between 12
and 20 participants. We anticipate a similar range.

Initial cohort: 5–6 participants spanning at least three roles and two
contexts, including both human-focused and AI-focused range work. Theoretical
sampling begins after coding the first 3–4 interviews.

### 4.4 Recruitment

Seed participants are recruited through the research team's professional
contacts, spanning at least three roles and two contexts.

At the end of each interview: "Who else does this kind of work that we should
talk to?" Follow referral chains. Document the referral network.

As categories emerge, targeted requests: "We need someone who works with
[container-based / simulation / government / etc.] environments—can you
recommend anyone?"

## 5. Interview Protocol

### 5.1 Pre-Interview

Informed consent covers recording, transcription, anonymization, data use, and
withdrawal rights. A brief background questionnaire (role, experience, tools,
environment types) is collected beforehand to preserve interview time.

Framing statement:

> We are studying how people who build and operate cyber ranges think about the
> concepts involved—whether those ranges are used for human exercises, AI agent
> experiments, or both. We are interested in your experience and your
> approach—there are no right or wrong answers. We will ask you to walk through
> how you do this work and then follow up on specifics.

### 5.2 Interview Guide

The guide follows the problem-centred expert interview structure. It will
evolve through theoretical sampling; what follows is the initial version.

**Phase 1: Narrative Opening (15–20 min)**

Let the participant describe their work without imposing categories. Listen for
what concepts they name, what distinctions they draw, what sequence they follow,
what they emphasize.

> Q1. Think of a recent cyber range you built or configured—for a training
> exercise, an evaluation, a competition, whatever the use case was. Walk me
> through the process from the beginning—from when you first understood what was
> needed to when participants or agents were running in it.

Probes if the narrative stalls: "What happened next?" / "Say more about that
part." / "What were you working with at that point?"

> Q1. When you think about everything that goes into specifying that
> range—all the different things you had to define or set up—how would you
> describe the main pieces?

**Phase 2: Probing Concepts (20–25 min)**

Based on what surfaced in Phase 1, probe the concepts the participant named.
The following are candidate probes, not a script.

On boundaries:

> Q1. You mentioned [X] and [Y]. Are those the same kind of thing, or
> different? What makes them different?
>
> Q2. If you had to explain to a new team member what they need to specify to
> recreate this environment, how would you organize it?

On the specification gap:

> Q1. Was there anything about this range you could not specify
> declaratively—that required scripts, manual steps, or institutional
> knowledge?
>
> Q2. If you had a specification language that could describe anything about a
> range, what would you want it to express that current tools do not?

On reuse and composition:

> Q1. Have you reused parts of one range in another? How? What was hard?
>
> Q2. If you needed ten variations of the same range—same topology, different
> configurations—how would you do that today?

On reproducibility:

> Q1. If another team needed to reproduce this range exactly, what would you
> give them? What would be hardest to capture?
>
> Q2. What must be identical between runs for results to be comparable? What
> is allowed to vary?

On the range–exercise boundary:

> Q1. When you think about "the range" versus "the exercise" or "the
> scenario"—where does one end and the other begin? Or is that not how you
> think about it?
>
> Q2. If I asked you to separate infrastructure from scenario, would that
> distinction mean something to you? Where would you draw the line?

On AI and automation:

> Q1. Do you build ranges that involve AI agents—offensive, defensive, or
> both? If so, does that change what you need to specify compared to a
> range built for human participants?

**Phase 3: Closing (10–15 min)**

> Q1. Across all the ranges you have built, is there a concept or concern
> that recurs and is not well handled by existing tools?
>
> Q2. If you were designing a standard for specifying cyber ranges—what would
> matter most to get right?
>
> Q3. Is there something I have not asked about that you think is important?

### 5.3 Guide Evolution

After coding the first 3–4 interviews, the guide changes:

1. New probes for emerging categories that need development.
2. Probes retired for saturated categories.
3. Referral requests shift to fill context gaps.
4. Emerging concepts reflected back: "Other practitioners have described X—does
  that match your experience?"

## 6. Analysis

### 6.1 Transcription

Record and transcribe verbatim. Preserve hesitations, self-corrections, and
emphasis—these often mark conceptual boundaries the participant is navigating.
Anonymize names, organizations, and identifying details.

### 6.2 Coding

**Open coding:** Line-by-line, using gerunds ("separating infrastructure from
scenario," "configuring accounts," "composing modules"). Prefer in vivo codes.
Memo each code: meaning, relationships, questions it raises. Constant
comparison against existing codes.

**Focused coding:** After 3–4 interviews, collapse codes into categories.
Identify properties (characteristics common across instances) and dimensions
(how those characteristics vary).

**Theoretical coding:** Identify relationships between categories. Develop a
core category. Build the taxonomy. Test against new data.

### 6.3 Cross-Participant Comparison

Track which concepts appear consistently and which are contested. In vivo codes
that recur across participants signal strong primitives. Boundary
disputes—where different practitioners draw different lines—are the most
analytically significant findings. They mark the points where specification
architecture is genuinely hard.

## 7. Outputs

1. A grounded taxonomy of concepts in cyber range specification, organized by
  the boundaries practitioners use—not boundaries imposed by existing specs.
2. A set of conceptual tensions: places where practitioners disagree about
  boundaries or where a concept spans multiple categories. These are the
   hard architectural decisions.
3. A specification gap inventory: concepts practitioners work with that no
  existing SDL captures declaratively—including gaps that emerge when ranges
   must support AI agents alongside or instead of human participants.
4. Design implications for specification architecture, grounded in empirical
  data rather than researcher intuition.

## 8. Rigor

| Concern         | Approach                                                                                                                  |
| --------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Credibility     | Member checking: participants review emerging taxonomy. Triangulation against existing SDL surveys (Garg 2025, Ear 2023). |
| Transferability | Thick description of each participant's context. Explicit sampling rationale. Scope limited to cyber range environments.  |
| Dependability   | Full audit trail: memos, coding journal, guide evolution log, theoretical sampling decisions.                             |
| Confirmability  | Every category grounded in data with exemplar quotes. Reflexive journaling. Disconfirming evidence reported.              |
| Saturation      | Category emergence tracked per interview. Saturation curve reported. Stopping decision documented.                        |

## 9. Reflexivity

The research team includes specification authors with a pre-existing
decomposition in mind. This is an asset—deep domain familiarity and theoretical
sensitivity—and a risk—confirmation bias toward the existing structure.

Mitigations: The interview guide does not present any existing decomposition.
Questions follow practitioner experience, not specification terminology.
Boundary probes do not suggest where boundaries should fall. Emerging concepts
are reflected back in participant language, not RFC language. We commit to
reporting findings that challenge the existing structure. At least one coder
should be external to the specification authorship team.

## 10. Ethics

Per Heron AI policy, IRB/ERB approval is not required for this category of
research. The study poses minimal risk: participants are professional
practitioners discussing their routine technical work, not vulnerable
populations, and no sensitive personal data is collected.

## 11. Timeline

| Phase               | Activities                                                              |
| ------------------- | ----------------------------------------------------------------------- |
| Preparation         | Seed recruitment, pilot (1–2 interviews for guide refinement)           |
| Round 1             | 5–6 interviews, concurrent open coding, memo writing                    |
| Checkpoint          | Focused coding, revise guide, plan theoretical sampling                 |
| Round 2             | 5–7 interviews (theoretical sample), continued coding                   |
| Checkpoint          | Theoretical coding, cross-participant comparison, saturation assessment |
| Round 3 (if needed) | 3–5 interviews targeting underdeveloped categories                      |
| Integration         | Taxonomy development, member checking, write-up                         |

## 12. Publication

**Paper structure:**

1. Introduction: the specification problem for cyber ranges, the
  decomposition challenge, the emerging role of offensive and defensive AI
2. Background: existing SDLs and their decompositions, the architectural
  question motivating the study
3. Method: STGT, problem-centred expert interview, snowball sampling
4. Findings: grounded taxonomy with exemplar quotes
5. Discussion: implications for specification architecture, comparison to
  existing decompositions, conceptual tensions
6. Threats to validity
7. Conclusion

## References

- Bogner, A., Littig, B., and Menz, W. (2009). *Interviewing Experts.* Palgrave
Macmillan. [doi:10.1057/9780230244276](https://doi.org/10.1057/9780230244276)
- Charmaz, K. and Belgrave, L.L. (2012). Qualitative Interviewing and Grounded
Theory Analysis. In *SAGE Handbook of Interview Research*, 2nd ed., 347–365.
[doi:10.4135/9781452218403.n25](https://doi.org/10.4135/9781452218403.n25)
- Costa, G., Russo, E., and Armando, A. (2022). Automating the Generation of
Cyber Range Virtual Scenarios with VSDL.
[arXiv:2001.06681](https://arxiv.org/abs/2001.06681)
- CyberSec4Europe (2020). D7.1: Report on existing cyber ranges, requirements.
EU H2020 Project 830929.
- Döringer, S. (2021). The problem-centred expert interview. *Int. J. Social
Research Methodology*, 24(3), 265–278.
[doi:10.1080/13645579.2020.1766777](https://doi.org/10.1080/13645579.2020.1766777)
- Ear, E., Remy, J.L.C., and Xu, S. (2023). Towards Automated Cyber Range
Design: Characterizing and Matching Demands to Supplies. *IEEE CSR 2023.*
[doi:10.1109/CSR57506.2023.10224940](https://doi.org/10.1109/CSR57506.2023.10224940)
- Foley, G., Timonen, V., Conlon, C., and Elliott O'Dare, C. (2021).
Interviewing as a Vehicle for Theoretical Sampling in Grounded Theory. *Int.
J. Qualitative Methods*, 20.
[doi:10.1177/1609406920980957](https://doi.org/10.1177/1609406920980957)
- Garg, A., Boualouache, A., Imeri, A., and Roth, U. (2025). A Survey of
Cyber Range Training Exercise Scenario Description, Generation, and
Execution. *TechRxiv.*
[doi:10.36227/techrxiv.175942879.94813577/v1](https://doi.org/10.36227/techrxiv.175942879.94813577/v1)
- Hoda, R. (2021). Socio-Technical Grounded Theory for Software Engineering.
*IEEE TSE*, 48(10), 3808–3832.
[doi:10.1109/TSE.2021.3106280](https://doi.org/10.1109/TSE.2021.3106280)
- Hoda, R. (2024). *Qualitative Research with Socio-Technical Grounded
Theory.* Springer.
[doi:10.1007/978-3-031-60533-8](https://doi.org/10.1007/978-3-031-60533-8)
- Janisch, J., Pevny, T., and Lisy, V. (2023). NASimEmu: Network Attack
Simulator & Emulator for Training Agents Generalizing to Novel Scenarios.
[arXiv:2305.17246](https://arxiv.org/abs/2305.17246)
- Kahlke, R., Maggio, L.A., Lee, M.C., Cristancho, S., LaDonna, K.,
Abdallah, Z., Khehra, A., Kshatri, K., Horsley, T., and Varpio, L. (2025).
When words fail us: An integrative review of innovative elicitation
techniques for qualitative interviews. *Medical Education*, 59(4), 382–394.
[doi:10.1111/medu.15555](https://doi.org/10.1111/medu.15555)
- Kouremetis, M., Dotter, M., Byrne, A., Martin, D., Michalak, E., Russo, G.,
Threet, M., and Zarrella, G. (2025). OCCULT: Evaluating Large Language Models
for Offensive Cyber Operation Capabilities. *The MITRE Corporation.*
[arXiv:2502.15797](https://arxiv.org/abs/2502.15797)
- Landauer, M., Hotwagner, W., Boenke, T., Skopik, F., and Wurzenberger, M.
(2026). AttackMate: Realistic Emulation and Automation of Cyber Attack
Scenarios Across the Kill Chain.
[arXiv:2601.14108](https://arxiv.org/abs/2601.14108)
- Li, L., El Rami, J.-P.S., Taylor, A., Rao, J.H., and Kunz, T. (2023).
Unified Emulation-Simulation Training Environment for Autonomous Cyber Agents.
[arXiv:2304.01244](https://arxiv.org/abs/2304.01244)
- Liu, Z., Huang, L., Zhang, J., Liu, D., Tian, Y., and Shao, J. (2025).
PACEbench: A Framework for Evaluating Practical AI Cyber-Exploitation
Capabilities. [arXiv:2510.11688](https://arxiv.org/abs/2510.11688)
- Lupinacci, M., Blefari, F., Romeo, F., Pironti, F.A., and Furfaro, A.
(2025). ARCeR: an Agentic RAG for the Automated Definition of Cyber Ranges.
[arXiv:2504.12143](https://arxiv.org/abs/2504.12143)
- Sanz-Gomez, M., Mayoral-Vilches, V., Balassone, F., Navarrete-Lozano, L.J.,
Veas Chavez, C.R.J., and del Mundo de Torres, M. (2025). Cybersecurity AI
Benchmark (CAIBench): A Meta-Benchmark for Evaluating Cybersecurity AI Agents.
[arXiv:2510.24317](https://arxiv.org/abs/2510.24317)
- Standen, M., Lucas, M., Bowman, D., Richer, T.J., Kim, J., and Marriott, D.
(2021). CybORG: A Gym for the Development of Autonomous Cyber Agents.
*IJCAI-21 1st International Workshop on Adaptive Cyber Defense.*
[arXiv:2108.09118](https://arxiv.org/abs/2108.09118)
- Strom, B.E., Applebaum, A., Miller, D.P., Nickels, K.C., Pennington, A.G.,
and Thomas, C.B. (2020). *MITRE ATT&CK: Design and Philosophy.* The MITRE
Corporation.
- Tholl, K., El Mezouar, M., Taylor, A., and Al Mallah, R. (2025). Towards
Production-Worthy Simulation for Autonomous Cyber Operations.
[arXiv:2508.19278](https://arxiv.org/abs/2508.19278)
- Tie, Y.C., Birks, M., and Francis, K. (2019). Grounded theory research: A
design framework for novice researchers. *SAGE Open Medicine*, 7.
[doi:10.1177/2050312118822927](https://doi.org/10.1177/2050312118822927)
- Witzel, A. (2000). The Problem-Centered Interview. *Forum: Qualitative
Social Research*, 1(1).
[doi:10.17169/fqs-1.1.1132](https://doi.org/10.17169/fqs-1.1.1132)
- Zhang, A.K., Perry, N., Dulepet, R., Ji, J., Menders, C., Lin, J.W.,
Jones, E., Hussein, G., Liu, S., Jasper, D., Peetathawatchai, P., Glenn, A.,
Sivashankar, V., Zamoshchin, D., Glikbarg, L., Askaryar, D., Yang, M.,
Zhang, T., Alluri, R., Tran, N., Sangpisit, R., Yiorkadjis, P., Osele, K.,
Raghupathi, G., Boneh, D., Ho, D.E., and Liang, P. (2025). CyBench: A
Framework for Evaluating Cybersecurity Capabilities and Risks of Language
Models. *ICLR 2025.* [arXiv:2408.08926](https://arxiv.org/abs/2408.08926)
