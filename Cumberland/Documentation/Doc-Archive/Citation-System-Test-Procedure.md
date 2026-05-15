# Citation System Manual Test Procedure

This document provides a step-by-step procedure to test the citation system including Sources, Citations, and their integration with Cards.

---

## Prerequisites

- Cumberland app running on macOS
- Empty or minimal database (recommended for clean testing)

---

## Part 1: Create Test Sources

### Step 1.1: Navigate to Sources View

1. Open Cumberland
2. In the sidebar, scroll to find "Sources" (if available) or access via Settings/Data Management
3. If no dedicated Sources view exists in sidebar, sources can be created inline during citation creation (skip to Part 2)

### Step 1.2: Create Source A - Book

Create a source with the following data:

| Field | Value |
|-------|-------|
| Title | The Hero with a Thousand Faces |
| Authors | Joseph Campbell |
| Publisher | Princeton University Press |
| Year | 1949 |
| Pages | 1-403 |
| Notes | Classic work on the monomyth structure |

### Step 1.3: Create Source B - Website

| Field | Value |
|-------|-------|
| Title | Writing Compelling Characters |
| Authors | Jane Writerson |
| URL | https://example.com/character-guide |
| Accessed Date | (today's date) |
| License | CC BY 4.0 |

### Step 1.4: Create Source C - Academic Article

| Field | Value |
|-------|-------|
| Title | Narrative Structure in Modern Fiction |
| Authors | Dr. Sarah Academic |
| Container Title | Journal of Literary Studies |
| Volume | 42 |
| Issue | 3 |
| Pages | 127-145 |
| Year | 2023 |
| DOI | 10.1234/jls.2023.42.3.127 |

---

## Part 2: Create Test Cards

### Step 2.1: Create a Character Card

1. In sidebar, select "Characters"
2. Click "+" to create new card
3. Fill in:
   - **Name**: Aria Stormwind
   - **Subtitle**: Protagonist
   - **Detailed Text**: A young cartographer who discovers an ancient map leading to a forgotten kingdom. She must overcome her fear of the unknown to fulfill her destiny.

4. Save the card

### Step 2.2: Create a Scene Card

1. In sidebar, select "Scenes"
2. Click "+" to create new card
3. Fill in:
   - **Name**: The Call to Adventure
   - **Subtitle**: Act 1, Scene 3
   - **Detailed Text**: Aria discovers the ancient map hidden in her grandmother's belongings. The map seems to glow faintly in moonlight, revealing hidden pathways.

4. Save the card

### Step 2.3: Create a Location Card

1. In sidebar, select "Locations" (or Worlds)
2. Click "+" to create new card
3. Fill in:
   - **Name**: The Forgotten Kingdom
   - **Subtitle**: Ancient Realm
   - **Detailed Text**: A kingdom that vanished from human memory centuries ago, accessible only through specific celestial alignments.

4. Save the card

---

## Part 3: Add Citations to Cards

### Step 3.1: Add Quote Citation to Character Card

1. Open the "Aria Stormwind" character card
2. Select the **Citations** tab (quote bubble icon)
3. Verify the tab displays "No citations yet for this card."
4. Click **"Add Citation"** button
5. Fill in the citation:

| Field | Value |
|-------|-------|
| Source | The Hero with a Thousand Faces (select from picker, or create inline) |
| Kind | Quote |
| Locator | p. 49 |
| Excerpt | The hero is the man or woman who has been able to battle past his personal limitations |
| Note | Applies to Aria's character arc - overcoming fear of unknown |

6. Click Save
7. Verify citation appears in the list with source title, kind badge, and locator

### Step 3.2: Add Paraphrase Citation to Character Card

1. Still on "Aria Stormwind" Citations tab
2. Click **"Add Citation"** again
3. Fill in:

| Field | Value |
|-------|-------|
| Source | Writing Compelling Characters |
| Kind | Paraphrase |
| Locator | Section 3 |
| Excerpt | Protagonists need a clear internal conflict that mirrors the external journey |
| Note | Aria's fear vs. destiny tension |

4. Save and verify it appears in the list

### Step 3.3: Add Quote Citation to Scene Card

1. Open "The Call to Adventure" scene card
2. Select **Citations** tab
3. Click **"Add Citation"**
4. Fill in:

| Field | Value |
|-------|-------|
| Source | The Hero with a Thousand Faces |
| Kind | Quote |
| Locator | p. 53 |
| Excerpt | The call to adventure signifies that destiny has summoned the hero |
| Note | Classic call structure - map discovery is Aria's call |

5. Save

### Step 3.4: Add Data Citation to Location Card

1. Open "The Forgotten Kingdom" location card
2. Select **Citations** tab
3. Click **"Add Citation"**
4. Fill in:

| Field | Value |
|-------|-------|
| Source | Narrative Structure in Modern Fiction |
| Kind | Data |
| Locator | p. 134, Table 2 |
| Excerpt | 78% of fantasy novels feature a hidden or lost realm as the primary destination |
| Note | Validates the "forgotten kingdom" trope choice |

5. Save

---

## Part 4: Verify Citation Management

### Step 4.1: Edit a Citation

1. Open "Aria Stormwind" card, Citations tab
2. Double-click on the first citation (or use context menu > Edit)
3. Modify the Note field: add " - EDITED" to the end
4. Save
5. Verify the change persists

### Step 4.2: Delete a Citation

1. On the same card, context-click (right-click) on the Paraphrase citation
2. Select "Delete"
3. Verify the citation is removed from the list
4. Verify only 1 citation remains

### Step 4.3: Re-add the Deleted Citation

1. Click "Add Citation"
2. Re-create the Paraphrase citation from Step 3.2
3. Verify it appears in the list

---

## Part 5: Verify Cross-Card Source Reuse

### Step 5.1: Check Source Picker

1. Open any card's Citations tab
2. Click "Add Citation"
3. In the Source picker, verify all three sources appear:
   - The Hero with a Thousand Faces
   - Writing Compelling Characters
   - Narrative Structure in Modern Fiction

4. Cancel without saving

### Step 5.2: Inline Source Creation

1. On any card's Citations tab, click "Add Citation"
2. Expand "Create New Source" disclosure
3. Fill in:
   - **Title**: Test Inline Source
   - **Authors**: Test Author

4. Click "Create Source"
5. Verify the new source is auto-selected
6. Complete the citation with Kind: Quote, Locator: "test", Excerpt: "test excerpt"
7. Save
8. Open another card's Citations tab
9. Click Add Citation
10. Verify "Test Inline Source" appears in the source picker

---

## Part 6: Verify Citation Kinds

Test that all four citation kinds work correctly:

| Kind | Use Case | Icon/Badge |
|------|----------|------------|
| Quote | Direct quotation from source | Should show "Quote" badge |
| Paraphrase | Rephrased idea from source | Should show "Paraphrase" badge |
| Data | Statistical or factual information | Should show "Data" badge |
| Image | Image attribution | Should show "Image" badge |

### Step 6.1: Create Image Citation

1. On any card with an image, go to Citations tab
2. Add Citation with:
   - Source: (any source with license info)
   - Kind: **Image**
   - Locator: "Figure 1"
   - Excerpt: "Map illustration"
   - Note: "Used under CC BY 4.0 license"

3. Verify the Image kind badge displays correctly

---

## Part 7: Data Integrity Checks

### Step 7.1: Card Deletion Cascade

1. Create a temporary card: "Test Card for Deletion"
2. Add 2 citations to it
3. Delete the card
4. Verify the citations are also deleted (cascade delete)

### Step 7.2: Source with Multiple Citations

1. Verify "The Hero with a Thousand Faces" source has citations on multiple cards:
   - Aria Stormwind (Character)
   - The Call to Adventure (Scene)

2. The source should remain intact and shared

---

## Part 8: Expected Chicago-Style Output

When manuscript assembly runs, citations should produce output like:

### Footnotes (in order of appearance):

1. Campbell, "The Hero with a Thousand Faces", 1949, p. 49, "The hero is the man or woman who has been able to battle past his personal limitations", Applies to Aria's character arc

2. Writerson, "Writing Compelling Characters", Section 3, "Protagonists need a clear internal conflict...", Aria's fear vs. destiny tension

3. Campbell, "The Hero with a Thousand Faces", 1949, p. 53, "The call to adventure signifies that destiny has summoned the hero"

4. Academic, "Narrative Structure in Modern Fiction", 2023, p. 134, Table 2, "78% of fantasy novels feature a hidden or lost realm..."

### Bibliography (deduplicated):

- Academic, Sarah. "Narrative Structure in Modern Fiction." Journal of Literary Studies 42 no. 3 127-145 2023 10.1234/jls.2023.42.3.127

- Campbell, Joseph. "The Hero with a Thousand Faces." Princeton University Press, 1949.

- Writerson, Jane. "Writing Compelling Characters." https://example.com/character-guide

---

## Test Results Checklist

| Test | Pass/Fail | Notes |
|------|-----------|-------|
| Sources can be created | | |
| Citations tab appears on all card types | | |
| Quote citations can be added | | |
| Paraphrase citations can be added | | |
| Data citations can be added | | |
| Image citations can be added | | |
| Citations can be edited | | |
| Citations can be deleted | | |
| Sources are reusable across cards | | |
| Inline source creation works | | |
| Citation list displays correctly | | |
| Card deletion cascades to citations | | |

---

*Last Updated: 2026-02-09*
*Created for DR-0082 verification*
