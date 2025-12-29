# DR (Discrepancy Report) Guidelines

## Documentation Requirements

**CRITICAL: All DR reports MUST be documented in DR-Documentation.md**

When a new DR report is issued:

1. **Create DR Entry in DR-Documentation.md**
   - Add new section with format: `## DR-XXXX: [Title]`
   - Include all required fields (see template below)
   - Maintain sequential numbering (DR-0001, DR-0002, etc.)

2. **Required Fields**
   - **Status:** (🔴 Open / ⚠️ In Progress / ✅ Resolved - Verified)
   - **Platform:** (iOS, macOS, visionOS, All platforms)
   - **Component:** (Affected component/file)
   - **Severity:** (Critical / High / Medium / Low)
   - **Description:** Clear description of the issue
   - **Expected Behavior:** What should happen
   - **Actual Behavior:** What actually happens
   - **Date Identified:** YYYY-MM-DD
   - **Steps to Reproduce:** (if applicable)
   - **Root Cause Analysis:** Technical explanation
   - **Resolution:** Implementation details
   - **Files Affected:** List of modified files
   - **Verification:** Testing steps and results

3. **Location**
   - File: `/Cumberland/DR-Reports/DR-Documentation.md`
   - Append new DR entries at the end
   - Maintain separator line (`---`) between entries

## DR Entry Template

```markdown
## DR-XXXX: [Title of issue]

**Status:** 🔴 Open
**Platform:** [iOS / macOS / visionOS / All platforms]
**Component:** [Component name]
**Severity:** [Critical / High / Medium / Low]

**Description:**
[Clear description of the problem]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Impact:**
- [Impact item 1]
- [Impact item 2]

**Date Identified:** YYYY-MM-DD

**Root Cause Analysis:**
[Technical explanation of why the issue occurs]

**Resolution:**

**Fix Date:** YYYY-MM-DD
**Verification Date:** YYYY-MM-DD

**Implementation:**

1. **[Change description 1]** (File.swift:line)
   - [Details]

2. **[Change description 2]** (File.swift:line)
   - [Details]

**Code Changes:**
```swift
// Code examples if relevant
```

**Result:**
✅ [Outcome 1]
✅ [Outcome 2]

**Files Affected:**
- `FileName.swift` - [Description of changes]

**Verification:**
- ✅ [Test 1]
- ✅ [Test 2]

**Related Issues:**
- [Related DR numbers or issues]

---
```

## Status Indicators

- 🔴 **Open** - Issue identified, not yet being worked on
- ⚠️ **In Progress** - Actively being investigated/fixed
- 🟡 **Resolved - Not Verified** - Fixed but not yet tested on device/simulator
- ✅ **Resolved - Verified** - Fixed and verified on device/simulator

**Authorization Note:** Claude is authorized to mark DRs as "Resolved - Not Verified" (🟡) when implementation is complete, but only the user can mark as "Resolved - Verified" (✅) after physical device testing.

## Best Practices

1. **Document as you work** - Don't wait until the end
2. **Include line numbers** - Reference specific file locations
3. **Add code examples** - Show before/after when relevant
4. **Verify on device** - Always test fixes on actual hardware when possible
5. **Update status** - Keep status current throughout the process
6. **Cross-reference** - Link related DRs together

## Severity Levels

- **Critical:** Crashes, data loss, complete feature failure
- **High:** Major functionality broken, significant user impact
- **Medium:** Feature partially broken, workarounds available
- **Low:** Minor issues, cosmetic problems, non-essential features

## File Naming Convention

- **DR-Documentation.md** - Main documentation file (all DRs)
- **DR-XXXX-[ShortTitle].md** - Individual DR files (if needed for complex issues)
- **DR-GUIDELINES.md** - This file (documentation standards)

---

**REMINDER:** Every new DR report MUST be added to DR-Documentation.md before marking work as complete.
