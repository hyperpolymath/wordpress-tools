# Tri-Perimeter Contribution Framework (TPCF)

## Overview

The **Tri-Perimeter Contribution Framework (TPCF)** is a graduated trust model for open source collaboration. It provides clear paths for contribution while maintaining project security and quality.

TPCF recognizes that different contributors have different levels of:
- **Trust** (earned through proven contributions)
- **Expertise** (domain knowledge and skill)
- **Availability** (time commitment)
- **Risk tolerance** (willingness to take responsibility)

## The Three Perimeters

```
┌─────────────────────────────────────────────────────┐
│  Perimeter 1: Core Maintainers (🔐 Full Access)     │
│  • Release management                                │
│  • Merge to main                                     │
│  • Security triage                                   │
│  • Strategic decisions                               │
└───────────────────┬─────────────────────────────────┘
                    │
        ┌───────────▼──────────────────────────────────┐
        │  Perimeter 2: Verified Contributors          │
        │  (🛡️ Write Access)                           │
        │  • Merge to feature branches                 │
        │  • Review community PRs                      │
        │  • Triage issues                             │
        │  • Guide newcomers                           │
        └──────────────┬───────────────────────────────┘
                       │
           ┌───────────▼────────────────────────────────┐
           │  Perimeter 3: Community Sandbox            │
           │  (🌐 Open Access)                          │
           │  • Submit issues                           │
           │  • Submit PRs                              │
           │  • Participate in discussions              │
           │  • Anyone can contribute                   │
           └────────────────────────────────────────────┘
```

---

## Perimeter 3: Community Sandbox (🌐 Open Access)

### Who: Everyone

Anyone can participate in Perimeter 3, no approval needed:
- First-time contributors
- Casual contributors
- Users reporting bugs
- Documentation writers
- Community supporters

### Permissions

✅ **Can Do:**
- Open issues (bug reports, feature requests)
- Submit pull requests (for review)
- Participate in discussions
- Fork the repository
- Use the software
- Share and promote the project
- Provide feedback and suggestions

⚠️ **Cannot Do:**
- Merge pull requests
- Close issues (except your own)
- Modify GitHub settings
- Access CI/CD secrets
- Make releases

### Contribution Types

1. **Documentation**
   - Fix typos and grammar
   - Improve README clarity
   - Add examples and tutorials
   - Translate to other languages

2. **Bug Reports**
   - Describe the problem clearly
   - Provide reproduction steps
   - Include environment details
   - Suggest potential fixes (optional)

3. **Feature Requests**
   - Describe the use case
   - Explain why it's valuable
   - Discuss potential implementation
   - Accept that not all features will be added

4. **Code Contributions**
   - Submit pull requests
   - Follow coding standards (see CONTRIBUTING.md)
   - Write tests for new functionality
   - Respond to review feedback

5. **Community Support**
   - Answer questions in discussions
   - Help newcomers get started
   - Share use cases and examples
   - Advocate for the project

### Graduation Path: Perimeter 3 → Perimeter 2

**Requirements:**
- **5+ merged pull requests** (high quality, not trivial)
- **3+ months** of sustained engagement
- **Demonstrate** understanding of codebase
- **Follow** Code of Conduct consistently
- **Show** willingness to help others

**Process:**
1. Self-nominate via GitHub Discussion or email
2. Perimeter 1 maintainers review contributions
3. Vote (simple majority)
4. Onboarding to Perimeter 2

**Timeline:** Typically 3-6 months of active contribution

---

## Perimeter 2: Verified Contributors (🛡️ Write Access)

### Who: Trusted Contributors

Contributors who have proven themselves through sustained high-quality work.

### Permissions

✅ **Can Do:**
- **Merge pull requests** (to non-main branches)
- **Create branches** on the main repository
- **Triage issues** (label, close, comment)
- **Review PRs** from Perimeter 3
- **Guide newcomers** (mentorship)
- **Participate** in roadmap discussions
- **Vote** on Perimeter 2 decisions

⚠️ **Cannot Do:**
- Merge to `main` branch (Perimeter 1 only)
- Make releases (Perimeter 1 only)
- Modify GitHub settings (Perimeter 1 only)
- Handle security incidents (Perimeter 1 only)

### Responsibilities

1. **Code Review**
   - Review PRs from Perimeter 3 contributors
   - Provide constructive, educational feedback
   - Ensure coding standards are met
   - Test changes locally when needed

2. **Issue Triage**
   - Label issues appropriately
   - Close duplicates and spam
   - Ask for clarification when needed
   - Prioritize based on severity and impact

3. **Mentorship**
   - Help newcomers get started
   - Answer questions patiently
   - Guide contributors through the process
   - Model good community behavior

4. **Quality Assurance**
   - Ensure tests pass before merging
   - Verify documentation is updated
   - Check for breaking changes
   - Maintain backward compatibility

### Graduation Path: Perimeter 2 → Perimeter 1

**Requirements:**
- **Sustained contributions** over 6+ months
- **Deep understanding** of project architecture
- **Alignment** with project values
- **Consensus** from existing Perimeter 1 maintainers

**Process:**
- **Invitation only** (not self-nomination)
- Unanimous consent from Perimeter 1
- Discussion of responsibilities and commitment
- Onboarding: Legal, security, release process

**Timeline:** Typically 6-12 months from Perimeter 2 entry

---

## Perimeter 1: Core Maintainers (🔐 Full Access)

### Who: Project Leaders

Small group of trusted individuals responsible for project health and direction.

### Permissions

✅ **Full Access:**
- Merge to `main` branch
- Create releases and tags
- Manage GitHub repository settings
- Access CI/CD secrets
- Handle security incidents
- Make strategic decisions
- Promote/demote contributors
- Modify governance

### Responsibilities

1. **Release Management**
   - Plan and execute releases
   - Write release notes
   - Tag versions
   - Publish artifacts

2. **Security**
   - Triage security vulnerabilities
   - Coordinate disclosure
   - Develop and deploy patches
   - Communicate with reporters

3. **Strategic Direction**
   - Roadmap planning
   - Feature prioritization
   - Breaking change decisions
   - Deprecation policies

4. **Community Health**
   - Enforce Code of Conduct
   - Resolve conflicts
   - Foster inclusive culture
   - Recognize contributors

5. **Governance**
   - Update TPCF as needed
   - Review perimeter transitions
   - Make final decisions
   - Represent project publicly

### Decision Making

**Consensus preferred**, but when needed:
- **Vote**: Simple majority
- **Tie-breaker**: Lead maintainer (if designated)
- **RFC**: For major decisions, open to community input

### Stepping Down

Maintainers can step down at any time:
- No explanation required
- Optional transition period
- Move to Emeritus status
- Retain Perimeter 2 if desired

---

## Benefits of TPCF

### For the Project

- **Security**: Critical code reviewed by trusted maintainers
- **Quality**: Graduated responsibility ensures competence
- **Sustainability**: Clear succession paths prevent bottlenecks
- **Inclusivity**: Anyone can contribute at Perimeter 3
- **Transparency**: Clear expectations and paths

### For Contributors

- **Safety**: Experiment freely in Perimeter 3
- **Growth**: Clear path to more responsibility
- **Recognition**: Contributions valued at all levels
- **Flexibility**: Contribute at your own pace
- **Reversibility**: Can step back without stigma

### For Users

- **Stability**: Trusted maintainers guard main branch
- **Innovation**: Community can experiment in Perimeter 3
- **Support**: Multiple levels of help available
- **Trust**: Know who makes final decisions

---

## TPCF in Practice

### Typical Contribution Flow

1. **Perimeter 3 contributor** opens issue or PR
2. **Perimeter 2 maintainer** reviews and provides feedback
3. Contributor addresses feedback
4. **Perimeter 2 maintainer** merges to feature branch (if needed)
5. **Perimeter 1 maintainer** merges feature branch to main
6. Changes appear in next release

### Special Cases

**Hotfix (Security):**
- Perimeter 1 can merge directly to main
- Skip normal review if time-critical
- Notify team after merge

**Documentation:**
- Perimeter 2 can merge docs directly (low risk)
- Perimeter 1 review not required

**Breaking Changes:**
- Requires Perimeter 1 approval
- Community RFC (Request for Comments)
- Deprecation period (1 major version)

---

## Comparison to Other Models

### vs. "Benevolent Dictator For Life" (BDFL)

- ✅ **TPCF**: Distributed leadership, succession planning
- ⚠️ **BDFL**: Single point of failure, burnout risk

### vs. "Anyone Can Commit"

- ✅ **TPCF**: Graduated trust, quality control
- ⚠️ **Anyone**: Security risks, code quality issues

### vs. "Foundation Governance"

- ✅ **TPCF**: Lightweight, meritocratic
- ⚠️ **Foundation**: Bureaucratic, slow

### vs. "Corporate Open Source"

- ✅ **TPCF**: Community-driven, politically neutral
- ⚠️ **Corporate**: Company interests may override community

---

## Frequently Asked Questions

### How long does it take to graduate from Perimeter 3 to Perimeter 2?

Typically **3-6 months** of sustained, high-quality contributions. Quality matters more than quantity.

### Can I skip Perimeter 3 and go straight to Perimeter 2?

**No.** The graduation path ensures trust is earned through proven work, not credentials or affiliations.

### What if I disagree with a decision?

1. Discuss respectfully in issue/PR
2. If unresolved, escalate to Perimeter 1
3. If still unresolved, accept decision and move on
4. Fork is always an option (it's open source!)

### Can I be demoted from Perimeter 2 to Perimeter 3?

**Yes**, if:
- Inactive for extended period (6+ months)
- Code of Conduct violations
- Repeated poor judgment
- Voluntary request (step back)

Demotion is **reversible** - you can graduate again.

### What if all Perimeter 1 maintainers disappear?

- Perimeter 2 maintainers can vote to promote someone
- Requires 2/3 majority
- Must document in MAINTAINERS.md
- New Perimeter 1 must update governance

### Is TPCF required for RSR compliance?

**Yes.** RSR Bronze level requires documented contribution governance. TPCF satisfies this requirement.

---

## Acknowledgments

TPCF is inspired by:
- Rust language governance model
- Apache Software Foundation's meritocracy
- Kubernetes contributor ladder
- Mozilla's module ownership model

Adapted for political neutrality and emotional safety.

---

## Modification

This TPCF document can be modified by:
- **Perimeter 1 maintainers** (unanimous consent)
- **Community RFC** (for major changes)

Changes must be documented in CHANGELOG.md.

---

**Version**: 1.0.0
**Last Updated**: 2025-11-22
**Contact**: contrib@sinople.org
