# Cumberland Issue Tracking Systems

This directory contains two complementary systems for tracking work on the Cumberland project:

## Systems Overview

### 📋 Discrepancy Reports (DR)
**Purpose:** Track and resolve bugs, defects, and unintended system behavior

**Use when:**
- System is not working as intended
- Bugs or errors occur
- Performance doesn't meet standards
- Features behave incorrectly

**Documentation:** [DR-Documentation.md](./DR-Documentation.md)
**Guidelines:** [DR-Guidelines.md](./DR-Guidelines.md)

---

### ✨ Enhancement Requests (ER)
**Purpose:** Track planned improvements, new features, and requirement changes

**Use when:**
- Adding new features or capabilities
- Improving existing workflows
- Refactoring or reducing technical debt
- Enhancing UI/UX
- Adding new requirements

**Documentation:** [ER-Documentation.md](./ER-Documentation.md)
**Guidelines:** [ER-Guidelines.md](./ER-Guidelines.md)

---

## Quick Decision Guide

| Question | Answer | System |
|----------|--------|--------|
| Is the system broken or behaving incorrectly? | Yes | **DR** |
| Is the system working, but you want it to do something new/different? | Yes | **ER** |
| Did something that used to work stop working? | Yes | **DR** |
| Do you want to add a feature that never existed? | Yes | **ER** |
| Is there a crash, error, or data loss? | Yes | **DR** |
| Do you want to improve the code architecture? | Yes | **ER** |

## Common Workflows

### Both Systems Follow Similar Process:

1. **Document** - Create detailed entry with requirements/symptoms
2. **Implement** - Claude writes the code and marks as implemented
3. **Verify** - Developer tests and marks as verified
4. **Archive** - Move to verified batch files

### Status Indicators:

- 🔴 **Active/Open** - DR awaiting fix
- 🔵 **Proposed** - ER awaiting implementation
- 🟡 **In Progress** - Work is ongoing
- 🟡 **Resolved/Implemented - Not Verified** - Claude finished, awaiting user test
- ✅ **Verified** - Developer confirmed it works

## File Structure

```
DR-Reports/
├── README.md                    # This file - overview of both systems
│
├── DR-Documentation.md          # DR index and quick reference
├── DR-Guidelines.md             # DR rules and templates
├── DR-unverified.md             # Active DRs awaiting verification
├── DR-verified-0001-0010.md     # First batch of verified DRs
├── DR-verified-0011-0018.md     # Second batch of verified DRs
│
├── ER-Documentation.md          # ER index and quick reference
├── ER-Guidelines.md             # ER rules and templates
└── ER-unverified.md             # Active ERs awaiting verification
```

## Current Status

### Discrepancy Reports
- Total: 18 DRs
- Verified: 18 (100%)
- Unverified: 0

### Enhancement Requests
- Total: 0 ERs
- Verified: 0
- Active: 0

---

## Key Rules

1. **Only Claude** can mark items as "Resolved" or "Implemented - Not Verified"
2. **Only Developer** can mark items as "Verified"
3. Always provide clear test steps for verification
4. Keep documentation updated as work progresses
5. Use the right system (DR vs ER) for each issue

---

*Last Updated: 2026-01-01*
*Version: 1.0*
