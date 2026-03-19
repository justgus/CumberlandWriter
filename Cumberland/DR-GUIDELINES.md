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

## File Organization and Batch Management

### Batch File Policy

**Verified DRs are organized into batch files of 10 DRs each:**

- **DR-verified-0001-0010.md** - DRs 1-10
- **DR-verified-0011-0020.md** - DRs 11-20
- **DR-verified-0021-0030.md** - DRs 21-30
- **DR-verified-0031-0040.md** - DRs 31-40
- *...and so on*

**Rationale:** Keeps individual files manageable (~800-1000 lines each) for easier navigation, editing, and version control.

### When to Create a New Batch File

When DR-00X0 (the 10th DR in a batch) is verified:
1. Create new batch file for next 10 DRs
2. Update DR-Documentation.md index to reference new batch
3. Move "Unverified DRs" section to the new batch file

**Example:** When DR-0030 is verified, create `DR-verified-0031-0040.md` for the next batch.

### Quick Reference Index

**DR-Documentation.md serves as a lean index with these sections:**
1. **Unverified DRs** - Table of active issues (naturally bounded)
2. **Verified DRs** - Table of batch files (one row per batch, grows slowly)
3. **Closed DRs** - Table of closed-without-verification batches
4. **Archived Open DRs** - Reference to deferred issues
5. **Statistics** - Current counts only (no history log)

**MUST be updated whenever:**
- A new DR is created (add to Unverified table)
- A DR status changes (update status emoji in table)
- A DR is verified (remove from Unverified table, update batch row status)
- Statistics counts change

**CRITICAL:** Do NOT add activity logs, summaries, or per-DR detail tables to DR-Documentation.md. Details belong in DR-unverified.md (for active work) or the verified batch files (for completed work). The index must stay compact.

## File Naming Convention

- **DR-Documentation.md** - Quick reference index (all DRs, always up-to-date)
- **DR-unverified.md** - Active issues awaiting resolution or verification
- **DR-verified-XXXX-YYYY.md** - Verified issues in batches of 10
- **DR-closed-XXXX-YYYY.md** - Closed issues (not verified, will not be verified)
- **DR-archive-XXXX-YYYY.md** - Archived open/deferred issues
- **DR-GUIDELINES.md** - This file (documentation standards)
- **ER-Documentation.md** - Enhancement Requests index (see ER-Guidelines.md)

### File Purpose Details

**DR-unverified.md:**
- Contains only active DRs (Open, In Progress, or Resolved-Not-Verified)
- Updated frequently as work progresses
- Should never contain "Closed" or "Verified" DRs

**DR-verified-XXXX-YYYY.md:**
- Contains DRs that have been resolved and verified
- Organized in batches of 10
- Once a DR is here, it's considered complete and successful

**DR-closed-XXXX-YYYY.md:** (Added 2026-02-05)
- Contains DRs that were closed WITHOUT verification
- Used for:
  - External limitations (e.g., AI provider safety filters)
  - Issues superseded by other work (e.g., "Will be addressed by ER-XXXX")
  - Design decisions to not fix
  - Known issues with documented workarounds
- These DRs will NEVER be verified but should be preserved for historical reference
- Organized by batch ranges (matching verified batches)

**DR-archive-XXXX-YYYY.md:**
- Contains older open or deferred DRs
- Issues that remain open but are not actively being worked on
- Preserved for historical tracking

---

## DR-Documentation.md Update Checklist

**Use this checklist for EVERY DR operation:**

### When Creating a New DR:
- [ ] DR added to DR-unverified.md
- [ ] DR added to Unverified table in DR-Documentation.md
- [ ] Unverified count updated
- [ ] "Next available DR" incremented
- [ ] Statistics updated
- [ ] "Last Updated" date updated

### When Resolving a DR:
- [ ] Status changed to 🟡 in DR-unverified.md
- [ ] Status emoji updated in Unverified table
- [ ] Statistics updated
- [ ] "Last Updated" date updated

### When Verifying a DR:
- [ ] DR moved from DR-unverified.md to appropriate batch file
- [ ] DR removed from Unverified table in DR-Documentation.md
- [ ] Batch row status updated in Verified table (if batch completion changed)
- [ ] Statistics updated
- [ ] "Last Updated" date updated

### When Closing a DR Without Verification: (Added 2026-02-05)
- [ ] DR moved from DR-unverified.md to appropriate DR-closed-XXXX-YYYY.md file
- [ ] DR removed from "Unverified DRs (Active Issues)" table (if it was there)
- [ ] DR added to "Closed DRs (Not Verified)" section in DR-Documentation.md
- [ ] "Reason for Closure" documented in the closed DR file
- [ ] Closed count incremented in DR-Documentation.md
- [ ] Unverified count decremented (if applicable)
- [ ] "Last Updated" date updated

**Reasons for Closing Without Verification:**
- **External Limitation:** Issue is in third-party code/service (e.g., AI provider behavior)
- **Superseded:** Work will be done in different ER (e.g., "Will be addressed by ER-0021")
- **Design Decision:** Team/user decides not to fix
- **Known Issue:** Issue acknowledged with documented workaround, fix deferred indefinitely

**Important:** Closed DRs should still include full documentation (description, root cause, proposed solutions, workarounds) for future reference. They are closed due to circumstances, not lack of documentation.

---

**REMINDER:** Every DR operation MUST update DR-Documentation.md before marking work as complete. This is not optional!
