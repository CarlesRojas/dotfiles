# Reference PR format

This is the canonical example to match for PR description structure, acceptance-test wording, and the Claude session footer. Source: roverdotcom/web PR 97011 (DEV-151594, a mobile-only Meet & Greet fix).

Match the structure and especially the fixture-step wording. Substitute ticket key, titles, URLs, PR number, brands, and the specific steps for the current ticket.

---

```markdown
[DEV-151594 "[M&G] Edit availability not loading current proposal"](https://roverdotcom.atlassian.net/browse/DEV-151594).
RFC: [Meet and Greet](https://roverdotcom.atlassian.net/wiki/spaces/TECH/pages/5941166724/RFC+Meet+and+Greet)
SPEC: [M&G Scheduling - Booking Vision M3](https://roverdotcom.atlassian.net/wiki/spaces/BKS/pages/5843648538/Spec+M+G+Scheduling+Booking+Vision+M3)
After the fix:
https://github.com/user-attachments/assets/9c81167c-71fd-4536-87ff-7938a1547707
## Changes
- The Meet & Greet edit scheduler no longer opens as a blank form after a proposal is submitted; it now loads the just-submitted dates and times without requiring an app restart (mobile only).
- Added test coverage for the edit scheduler reload after a successful proposal.

## Acceptance tests

### Mobile Setup
- [ ] Run `rover-cli mobile fetch ios --branch DEV-151594 -t release`
- [ ] Run `rover-cli mobile h ios https://staging-pr-97011.webapp.roverstaging.com`

### Mobile
- [ ] On the simulator, click `Login As Requester Deeplink` on the [**The Standard Scenario**](https://staging-pr-97011.webapp.roverstaging.com/dev/fixtures/templates/1-standard-scenario) fixture.
- [ ] Create a new request and contact the sitter, then start the Meet & Greet scheduling flow.
- [ ] Propose a schedule by selecting dates/times and tap **Confirm & continue**.
- [ ] Back on the conversation, tap the **proposal submitted** banner to open the proposal, then tap **Edit**.
- [ ] Verify the scheduler opens in edit mode pre-filled with the dates/times you just submitted (previously blank until the app was restarted).
```

Note: the original PR 97011 also had a `### Web (regression)` section. Do NOT replicate that by default. It was specific to that change. Most PRs should not include a web regression section at all.

---

## Notes on what to keep verbatim

- The fixture step wording (`Login As Requester Deeplink` / `Login As Requester`, `The Standard Scenario`, the `/dev/fixtures/templates/1-standard-scenario` path) is intentional and should not be reworded. Only the PR number changes. and this wording comes from each feature entrypoints, choose one of those by checking the code of the current fixture. If you need to reference any of the fields on a ficture to be modified, reference the human readable name: 'Service Start' instead of 'service_start'.
- The `rover-cli mobile fetch ios --branch {TICKET} -t release` and `rover-cli mobile h ios ...` setup commands stay as-is, swapping ticket key and PR number.
- Acceptance tests should cover one platform by default, web OR mobile, whichever the change affects. Include both only when the ticket requires testing on both. The example above happens to show both because that change touched both, but that is the exception.
- Mobile sections (`### Mobile Setup`, `### Mobile`) and the `create-mobile` label go together: include them only for mobile changes.
