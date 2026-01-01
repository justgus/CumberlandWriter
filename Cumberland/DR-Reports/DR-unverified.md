# Discrepancy Reports (DR) - Unverified Issues

This document tracks discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **0 unverified DRs**

---

## Template for Adding New DRs

When a new issue is identified or resolved but not yet verified, add it here using this template:

```markdown
## DR-XXXX: [Brief Title]

**Status:** 🟡 Resolved - Not Verified
**Platform:** iOS / macOS / visionOS / All platforms
**Component:** [Component Name]
**Severity:** Critical / High / Medium / Low
**Date Identified:** YYYY-MM-DD
**Date Resolved:** YYYY-MM-DD

**Description:**
[Detailed description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Fix Applied:**
[Description of the fix]

**Test Steps:**
1. [How to verify the fix]
2. [Expected results]

---
```

## Status Indicators

Per DR-GUIDELINES.md:
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*When user verifies a DR, move it to the appropriate DR-verified-XXXX-YYYY.md file*
