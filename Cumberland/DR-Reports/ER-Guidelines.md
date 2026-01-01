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

## File Organization

Similar to the DR system, ERs are organized into multiple files:

- **ER-Documentation.md** - Main index and quick reference
- **ER-Guidelines.md** - This file - rules and templates
- **ER-unverified.md** - Active and implemented-but-unverified ERs
- **ER-verified-XXXX-YYYY.md** - Batches of verified enhancements

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

*Version: 1.0*
*Last Updated: 2026-01-01*
