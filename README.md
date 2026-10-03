# Network Machine

A decentralized security and network observation engine for systems and networks.

## Vision

Network Machine is an experimental project inspired by the idea of a distributed "Machine": a system capable of observing its environment, correlating technical evidence, detecting changes, investigating anomalies and producing human-readable conclusions.

The objective is not to blindly automate security decisions.

The system follows:

```text
OBSERVE
   ↓
NORMALIZE
   ↓
CORRELATE
   ↓
REMEMBER
   ↓
COMPARE
   ↓
FORM HYPOTHESIS
   ↓
INVESTIGATE
   ↓
CONCLUDE
   ↓
REACT
   ↓
VERIFY
```

## Architecture

The project uses independent agents instead of a single central controller.

```text
                    Network Machine
                          │
          ┌───────────────┼────────────────┐
          │               │                │
      Observation      Memory          Analysis
          │               │                │
     ┌────┼────┐          │          ┌─────┼─────┐
     │    │    │          │          │     │     │
   DNS  Network Process  SQLite   Behavior Security
                                      │
                                      ↓
                                Investigation
                                      │
                                      ↓
                                  Reaction
```

## Agents

Current and planned agents:

* `process-agent` — observes processes and their relationships
* `network-agent` — observes interfaces, routes and network state
* `connection-agent` — observes active network connections
* `dns-agent` — resolves and correlates network destinations
* `exposure-agent` — analyzes listening services and network exposure
* `firewall-agent` — analyzes firewall state and filtering
* `memory-agent` — stores historical observations
* `behavior-agent` — compares current behavior with historical baselines
* `hypothesis-agent` — builds and evaluates security hypotheses
* `investigation-agent` — performs targeted verification

## Security philosophy

The project deliberately separates observation from interpretation.

A technical signal is not automatically a security incident.

Examples:

```text
OPEN PORT        ≠ VULNERABILITY
ANOMALY          ≠ ATTACK
NEW PROCESS      ≠ MALWARE
NEW DESTINATION  ≠ MALICIOUS ACTIVITY
```

The system should collect evidence, correlate observations and test hypotheses before producing a conclusion.

## Design principles

### Decentralization

Agents should be able to communicate directly.

### Resilience

Failure of one agent should degrade the system rather than stop the entire system.

### Observability

Every important operation should have a trace identifier.

### Memory

The system should remember previous observations and build behavioral baselines.

### Evidence

Conclusions should be based on observable technical evidence.

### Safe reactions

Automated reactions must be controlled by explicit policies and should be reversible whenever possible.

## Current status

This project is under active development.

The current implementation is a research prototype focused on macOS and shell-based agents.

## Roadmap

### Phase 1 — Foundation

* [x] Agent architecture
* [x] Registry concept
* [x] Message passing concept
* [x] Distributed tracing concept
* [ ] Production-grade runtime

### Phase 2 — Observation

* [ ] Process observation
* [ ] Network observation
* [ ] Connection observation
* [ ] DNS observation
* [ ] Firewall observation

### Phase 3 — Memory

* [ ] SQLite storage
* [ ] Historical observations
* [ ] Baselines
* [ ] Change detection

### Phase 4 — Security analysis

* [ ] Exposure analysis
* [ ] Process/network correlation
* [ ] Behavioral analysis
* [ ] Hypothesis engine
* [ ] Investigation engine

### Phase 5 — Network intelligence

* [ ] tcpdump integration
* [ ] Zeek integration
* [ ] Flow correlation
* [ ] DNS intelligence

### Phase 6 — AI

* [ ] Human-readable diagnostic generation
* [ ] Evidence-aware AI analyst
* [ ] Natural-language investigation
* [ ] Controlled reaction planning

## Warning

This project is intended for systems and networks that you own or are explicitly authorized to analyze.

Do not use it to monitor or investigate networks without authorization.

## License

MIT

