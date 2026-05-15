# Enhancement Request (ER) Guidelines

## Purpose

The Enhancement Request (ER) system tracks planned improvements, new features, and requirement changes for Cumberland. Unlike Discrepancy Reports (DRs) which address bugs and unintended behavior, ERs manage intentional evolution of the system.

## ER Lifecycle

```
Proposed → In Progress → Implemented → Verified
   🔵         🟡            🟡           ✅
```

### Status Definitions

1. **🔵 Proposed** - Enhancement has been identified and documented, awaiting implementation
   - Claude or User can create proposed ERs
   - Used when planning future work

2. **🟡 In Progress** - Enhancement is actively being worked on
   - Claude marks when starting implementation
   - Only ONE ER should be in progress at a time

3. **🟡 Implemented - Not Verified** - Implementation complete, awaiting user verification
   - **ONLY CLAUDE** can mark as implemented
   - Indicates code is written and ready for testing
   - Must include test steps for verification

4. **✅ Implemented - Verified** - User has tested and confirmed the enhancement works
   - **ONLY USER** can mark as verified
   - Final state for completed enhancements

## ER Workflow

### Phase 1: Analysis & Design
1. **Analyze Request** - Understand what needs to change and why
2. **Review Current Implementation** - Examine existing code and architecture
3. **Design Approach** - Plan the implementation strategy
4. **Identify Impact** - Determine which components will be affected

### Phase 2: Requirements
1. **Codify Requirements** - Document what the enhancement must accomplish
2. **Define Acceptance Criteria** - Specify how to verify success
3. **Consider Edge Cases** - Think through unusual scenarios
4. **Update Documentation** - Plan documentation changes

### Phase 3: Implementation
1. **Execute Changes** - Write the code
2. **Self-Test** - Verify basic functionality
3. **Update Related Code** - Fix any impacted areas
4. **Document Implementation** - Record what was done and why

### Phase 4: Verification
1. **Provide Test Steps** - Clear instructions for user verification
2. **User Testing** - Developer tests the enhancement
3. **Verification** - Only user can mark as verified

## ER Template Structure

```markdown
## ER-XXXX: [Brief Title]

**Status:** 🔵 Proposed / 🟡 In Progress / 🟡 Implemented - Not Verified / ✅ Implemented - Verified
**Component:** [Primary Component Name]
**Priority:** Critical / High / Medium / Low
**Date Requested:** YYYY-MM-DD
**Date Implemented:** YYYY-MM-DD (if applicable)
**Date Verified:** YYYY-MM-DD (if applicable)

**Rationale:**
[Why this enhancement is needed - business case, user benefit, technical debt reduction]

**Current Behavior:**
[How the system currently works]

**Desired Behavior:**
[How the system should work after enhancement]

**Requirements:**
1. [Specific requirement 1]
2. [Specific requirement 2]
3. [Specific requirement 3]

**Design Approach:**
[High-level implementation strategy]

**Components Affected:**
- Component 1: [What changes]
- Component 2: [What changes]

**Implementation Details:**
[Detailed description of changes made - filled in during implementation]

**Test Steps:**
1. [Step to verify requirement 1]
2. [Step to verify requirement 2]
3. [Expected results]

**Notes:**
[Any additional context, trade-offs, or future considerations]
```

## Authorization Rules

### What Claude CAN Do:
- ✅ Create proposed ERs (🔵 Proposed)
- ✅ Update ER status to In Progress (🟡 In Progress)
- ✅ Mark ERs as Implemented - Not Verified (🟡 Implemented - Not Verified)
- ✅ Add implementation details and test steps
- ✅ Update ER documentation and tracking files

### What Claude CANNOT Do:
- ❌ Mark ERs as Verified (✅ Implemented - Verified)
- ❌ Skip the analysis and design phases
- ❌ Implement without documenting requirements
- ❌ Close ERs without user approval

### What ONLY User Can Do:
- ✅ Mark ERs as Verified (✅ Implemented - Verified)
- ✅ Approve or reject proposed enhancements
- ✅ Change ER priority levels
- ✅ Move ERs between batches

## File Organization and Workflow Management

**Location:** All ER files are now located in `Documentation/ER-Reports/` (separate from DR-Reports)

### Active Work Files (New Structure - 2026-04-13, Updated 2026-05-15)

**ERs are organized into active work files based on status in the main ER-Reports directory:**

- **ER-proposed.md** - 🔵 Proposed enhancements awaiting approval/scheduling
- **ER-inprogress.md** - 🟡 ERs actively being implemented (In Progress + Implemented - Not Verified)
- **ER-unverified.md** - 🟡 Implemented but awaiting user verification
- **ER-backlog.md** - Low-priority enhancements not actively scheduled

**Rationale:** This structure mirrors Agile workflow boards (Backlog → In Progress → Done) and makes it easy to see what's being worked on vs. what's planned. It also reduces file size for easier processing by Claude Code.

### Backlog Management (Optional)

For long-term or lower-priority ERs (e.g., visionOS expansion features):

- **ER-backlog.md** - Low-priority enhancements not actively scheduled

**Backlog ERs** are similar to Agile product backlog items—documented for future consideration but not currently in active development. Move ERs from backlog to proposed when ready to prioritize.

### Verified Enhancements (Archive)

**Verified ERs are organized into batch files with flexible sizing in the `ER-verified/` subfolder:**

- **ER-verified/ER-verified-0001.md** - First batch (ERs 1-2)
- **ER-verified/ER-verified-0002.md** - Second batch (ERs 3, 5-6)
- **ER-verified/ER-verified-0003.md** - Third batch (future ERs)
- *...and so on*

**Rationale:** Unlike DRs which use fixed batches of 10, ERs use flexible batching since enhancements are typically more detailed and occur less frequently. Batch files are created as needed when previous batches reach a reasonable size (~1000-1500 lines). Subfolder organization keeps the main ER-Reports directory clean.

### When to Create a New Batch File

When a batch file becomes large (~1000-1500 lines or ~5-10 ERs):
1. Create new batch file in `ER-verified/` subfolder with next sequential number
2. Update ER-Documentation.md index to reference new batch
3. Continue adding verified ERs to the new batch

**Example:** When ER-verified-0002.md has sufficient content, create `ER-verified/ER-verified-0003.md` for the next batch.

### Quick Reference Index

**ER-Documentation.md serves as a lean index with three sections:**
1. **Proposed ERs** - Table of proposed enhancements (from ER-proposed.md)
2. **In Progress ERs** - Table of active work (from ER-inprogress.md)
3. **Complete Unverified ERs** - Table of implemented but unverified (from ER-complete-unverified.md)
4. **Verified ERs** - Table of batch files (one row per batch, grows slowly)
5. **Statistics** - Current counts only (no history log)

**MUST be updated whenever:**
- A new ER is created (add to Proposed table)
- An ER status changes to In Progress (move from Proposed to In Progress table)
- An ER is implemented (move from In Progress to Complete Unverified table)
- An ER is verified (remove from Complete Unverified table, add batch row if new file)
- Statistics counts change

**CRITICAL:** Do NOT add activity logs, summaries, or per-ER detail tables to ER-Documentation.md. Details belong in the active work files (ER-proposed.md, ER-inprogress.md, ER-complete-unverified.md) or the verified batch files. The index must stay compact.

## File Naming Convention

**Main ER-Reports directory (`Documentation/ER-Reports/`):**
- **ER-Documentation.md** - Quick reference index (all ERs, always up-to-date)
- **ER-proposed.md** - 🔵 Proposed enhancements (awaiting scheduling)
- **ER-inprogress.md** - 🟡 Active development (In Progress)
- **ER-unverified.md** - 🟡 Implemented but not yet verified by user
- **ER-backlog.md** - Low-priority enhancements (optional, for long-term planning)
- **ER-Guidelines.md** - This file (documentation standards)

**ER-verified subfolder (`Documentation/ER-Reports/ER-verified/`):**
- **ER-verified-XXXX.md** - Verified enhancements in sequential batches

**PLAN-Archive subfolder (`Documentation/ER-Reports/PLAN-Archive/`):**
- Contains detailed implementation plans and build plans for major ERs

**Note:** Discrepancy Reports (DR) are in a separate folder structure at `Documentation/DR-Reports/` (see DR-GUIDELINES.md)

## Best Practices

1. **One Enhancement, One ER** - Don't bundle multiple unrelated enhancements
2. **Clear Requirements** - Be specific about what success looks like
3. **Document Design Decisions** - Explain why you chose this approach
4. **Consider Alternatives** - Note other approaches considered and why they were rejected
5. **Update as You Go** - Keep the ER updated during implementation
6. **Thorough Test Steps** - Make verification easy for the user

## Relationship to DR System

- **DRs** fix bugs and unintended behavior
- **ERs** add features and change requirements
- Both systems use similar workflows and documentation
- Both require user verification before marking as complete
- Use cross-references when an ER addresses technical debt identified in a DR

## Priority Levels

- **Critical** - Blocking user workflow or needed for upcoming release
- **High** - Important improvement with significant user benefit
- **Medium** - Useful enhancement, can be scheduled flexibly
- **Low** - Nice to have, implement when time allows

---

## ER-Documentation.md Update Checklist

**Use this checklist for EVERY ER operation:**

### When Creating a New ER:
- [ ] ER added to ER-proposed.md
- [ ] ER added to Proposed table in ER-Documentation.md
- [ ] Proposed count updated
- [ ] "Next available ER" incremented
- [ ] Statistics updated
- [ ] "Last Updated" date updated

### When Starting Implementation (Proposed → In Progress):
- [ ] ER moved from ER-proposed.md to ER-inprogress.md
- [ ] Status changed to 🟡 In Progress
- [ ] ER moved from Proposed table to In Progress table in ER-Documentation.md
- [ ] Proposed count decremented, In Progress count incremented
- [ ] Statistics updated
- [ ] "Last Updated" date updated

### When Marking ER as Implemented - Not Verified:
- [ ] ER moved from ER-inprogress.md to ER-unverified.md
- [ ] Status changed to 🟡 Implemented - Not Verified
- [ ] ER moved from In Progress table to Unverified table in ER-Documentation.md
- [ ] Statistics updated
- [ ] "Last Updated" date updated

### When User Verifies an ER:
- [ ] ER moved from ER-unverified.md to appropriate batch file in `ER-verified/` subfolder
- [ ] Status changed to ✅ Implemented - Verified
- [ ] ER removed from Unverified table in ER-Documentation.md
- [ ] Batch row added to Verified table (if new batch file)
- [ ] Unverified count decremented, Verified count incremented
- [ ] Statistics updated
- [ ] "Last Updated" date updated

### When Moving ER to Backlog (Optional):
- [ ] ER moved from ER-proposed.md to ER-backlog.md
- [ ] ER removed from Proposed table in ER-Documentation.md
- [ ] Note added to ER explaining backlog reason
- [ ] Proposed count decremented
- [ ] Statistics updated
- [ ] "Last Updated" date updated

---

**REMINDER:** Every ER operation MUST update ER-Documentation.md before marking work as complete. This is not optional!

---

*Version: 2.0*
*Last Updated: 2026-01-10*
