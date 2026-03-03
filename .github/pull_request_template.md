## CSCE 431 PR Template (Maintainability-focused)

### Summary (required)
What changed (1-3 bullets):
Why this improves maintainability (1 sentence):
Notebook evidence plan (what will you screenshot/link for Section 5.6 Quality Assurance -> Maintainability?):

---

## Maintainability PR Checklist
## (per Project Notebook + course coding standard)

### A) Definition of Done / required checks
[ ] Code review performed (at least 1 reviewer other than the author).
[ ] Meets coding standard (see items below).
[ ] RuboCop checked: no new serious offenses introduced; output/CI link included.
[ ] Any config/build/setup changes documented (README / notes / PR description).

### B) Human-only maintainability checks ###	(RuboCop may NOT catch these)
[ ] Comments add value: no commented-out dead code; remove outdated comments; don’t comment obvious code.
[ ] Naming is meaningful (classes, methods, variables reflect behavior and intent).
[ ] Skinny controllers: controllers are "traffic directors" (no domain/business logic or persistence/model-changing logic beyond request/response flow).
[ ] Views are thin: minimal Ruby logic; views do NOT interact with the data repository.
[ ] DRY: no unnecessary copy/paste across controllers/models/views; reuse via partials/helpers/

modules/concerns/service objects where appropriate.
[ ] Rails conventions followed (controller pluralization, model singular naming, etc.).
[ ] Foreign keys / join tables follow conventions (e.g., *_id; join tables named consistently).
[ ] Smart use of Enums where they clarify state (not used to hide unclear states/logic).
[ ] Nested routes used appropriately when a resource belongs to another (not excessive nesting).

### C) Tests / safety checks
###	(support  maintainability  over  time)
[ ] Tests updated/added as needed; test suite passes.
[ ] Refactor safety: if logic moved (SRP), tests still cover the behavior (note which tests validate it).

### D) Notes / decisions (required if anything is deferred)
Deferred / intentionally ignored items (what + why + plan to address later):
RuboCop exclusions added/changed? (what + why it’s acceptable):

---

## Reviewer comments (for linking to lines in GitHub) Reviewers: link directly to code lines using GitHub’s "Copy permalink".

Comment 1 (maintainability): <paste GitHub permalink>
Comment 2 (maintainability): <paste GitHub permalink>
Optional additional comments: <permalinks>

### Reviewer decision
[ ] Approve
[ ] Request changes (list required fixes):
