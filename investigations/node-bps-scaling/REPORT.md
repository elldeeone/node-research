# Node BPS Scaling

This report is intentionally a placeholder until the tier configuration is validated and the first real captures exist.

Planned report shape:

## Abstract

Summarise how node resource requirements changed as BPS and offered load increased on the `CPX42` reference host.

## 1. Introduction And Scope

- define the study question
- explain why the topology reuses the separated bootstrap-plus-relay design
- explain why `10 BPS` is out of scope for this report

## 2. Methodology

- tier ladder and exact validated labels
- custom params validation method
- topology and role definitions
- load generation and scaling policy
- capture stack
- success and failure rules

## 3. Tier Validation

- exact params used per tier
- observed cadence and load validation
- final naming of the `Validated Max Tier`

## 4. Relay Baseline Scaling

- `Baseline` results across all validated tiers
- CPU, RSS, storage, prune, and recovery comparisons

## 5. Downstream Penalty Scaling

- `Single-Downstream` results across tiers
- `Eight-Downstream` results across tiers
- comparison against per-tier baseline behavior

## 6. Resource Requirement Trends

- which resource bends first as BPS rises
- whether the cost grows linearly or nonlinearly
- when serving changes the story materially

## 7. Implications For Hardware Sizing

- what the `CPX42` curve suggests
- what remains unproven until Phase 2 boundary testing

## 8. Limitations

- synthetic load caveats
- bootstrap guardrail caveats
- single-host-class caveat for Phase 1

## Appendix

- exact run register
- tier metadata
- scenario matrix
