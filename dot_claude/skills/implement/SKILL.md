---
name: implement
description: Implement a Jira ticket end to end on a new branch and open a Draft PR. Use this skill whenever the user runs `/implement {jira_ticket_link}`, or asks to "implement this ticket", "build this Jira ticket", or pastes a roverdotcom.atlassian.net ticket link and wants it coded up. Handles reading the ticket and all its context links, writing the implementation, and opening a Draft PR with the right labels, description, and acceptance tests following Carles's Rover conventions.
---

# Implement a Jira Ticket

End-to-end workflow: read a Jira ticket and all its context, implement it on a new branch, and open a Draft PR that follows Rover conventions.

The invocation is `/implement {jira_ticket_link}`. Extract the ticket key from the link (e.g. `DEV-151820` from `.../browse/DEV-151820`).

The working branch MUST be named EXACTLY the ticket key, nothing else: `DEV-151820`. No prefixes (no `claude/`, no `feature/`, no username), no suffixes, no description appended. Just the bare key.

## Hard rules (apply to all output: code, commits, PR description)

- Never use the `—` (em-dash) symbol anywhere.
- Do NOT generate OpenAPI schemas, orval types, or run makemessages. A PR action handles these.
- Do NOT write Storybook files.
- Do NOT add comments to the code unless absolutely necessary to understand it.

## Step 1: Gather full context

Read the ticket, then every context link in its description (RFC, spec, design docs, linked tickets). Do not start coding until you have read all of them.

Source priority for each link:
1. Jira ticket: Atlassian MCP (`Atlassian:getJiraIssue`). Resolve the cloudId first via `Atlassian:getAccessibleAtlassianResources` if needed.
2. Confluence pages (RFC, spec): Atlassian MCP (`Atlassian:getConfluencePage`, or `Atlassian:searchConfluenceUsingCql`).
3. GitHub links: GitHub MCP / Claude Code GitHub integration.
4. Any other link: use whatever relevant MCP is available, otherwise fall back to `web_fetch`.

Note the linked tickets too. If the ticket references a related PR or fixture, capture those URLs, you will likely reuse them in acceptance tests.

## Step 2: Implement

Work on a branch named EXACTLY the ticket key (e.g. `DEV-151820`).

Branch naming is strict:
- The branch name must be exactly the ticket key, with no prefix or suffix.
- If a branch was already created earlier in this session under a different name (for example, the GitHub integration auto-created something like `claude/DEV-151820-fix` or a description-based name), RENAME it to the exact ticket key before opening the PR. Use `git branch -m {TICKET-KEY}` while on that branch; if it was already pushed, push the renamed branch and delete the old remote branch (`git push origin :old-name` then `git push -u origin {TICKET-KEY}`) so the PR is opened from the correctly named branch.
- Double-check the branch name right before opening the PR. If it is not exactly the ticket key, fix it first.

Implement the change following existing patterns in the repo. Respect the hard rules above: no schemas/orval/makemessages, no spec files, no Storybook files, no em-dashes.

## Step 3: Open the Draft PR

Use the Claude Code GitHub integration to commit, push the branch, and open a **Draft** PR.

Labels:
- Always add `create-staging`.
- Add `create-mobile` only if the change has to be tested on mobile: the ticket asks for mobile, the change is mobile-only (native flows, mobile UI), or there is another reason mobile must be tested. Default is web only, no `create-mobile`.

### PR description

Keep it concise. Only enumerate the changes, do not explain how they are implemented. Follow the repo's PR template. The structure that matches Rover's template:

```
[{TICKET-KEY} "{ticket title}"]({ticket url}).
RFC: [{rfc title}]({rfc url})
SPEC: [{spec title}]({spec url})

## Changes
- {change 1}
- {change 2}
```

Be very concise, brief and clear on the changes section. Only adding human readable short statements.

Only include RFC / SPEC lines if the ticket actually links them.

### Acceptance tests

Go under `# Code Review Instructions` -> `## Acceptance tests`. Keep them concise, brief, clear, and use direct links wherever possible.

Acceptance tests cover **one platform**: either web or mobile, not both. Pick the platform the change actually affects:
- A web change gets web steps only.
- A mobile change gets `### Mobile Setup` + `### Mobile` steps only (and the `create-mobile` label).

Include **both** web and mobile sections only when the ticket explicitly requires testing on both, or the change clearly affects both platforms. This is the exception, not the default. When in doubt, pick the single platform the change touches.

Critical: keep the same wording as the reference example, especially the fixture steps. Reuse this exact phrasing, substituting the PR number and fixture:

- Mobile setup: `Run \`rover-cli mobile fetch ios --branch {TICKET-KEY} -t release\`` and `Run \`rover-cli mobile h ios https://staging-pr-{PR_NUMBER}.webapp.roverstaging.com\``
- Fixture login (mobile): `On the simulator, click \`Login As Requester Deeplink\` on the [**The Standard Scenario**](https://staging-pr-{PR_NUMBER}.webapp.roverstaging.com/dev/fixtures/templates/1-standard-scenario) fixture.`
- Fixture login (web): `Click \`Login As Requester\` on the [**The Standard Scenario**](https://staging-pr-{PR_NUMBER}.webapp.roverstaging.com/dev/fixtures/templates/1-standard-scenario) fixture.`

Each step is a `- [ ]` checkbox and it should have each step needed to reproduce the feature/fix. If the ticket references steps, just add each of the steps here again.

IMPORTANT: The 'standard scenario' in the example acceptance tests is just an example. For every case, investigate all the fixtures and scenarios we have and pick the one that makes most sense. A lot of projects have specific fixtures built for them, priorize them over others.

The full reference is in `references/pr-example.md`. Read it to match the exact format.

## Final check before opening the PR

- Branch named EXACTLY the ticket key (e.g. `DEV-151820`), no prefix/suffix. IMPORTANT: If it was auto-created with another name, rename it to the ticket before pushing, if that is impossible, create a new branch with the desired name that has all the same commits and push that one.
- No em-dashes anywhere.
- No schemas, orval types, makemessages, spec files, or Storybook files generated.
- PR is a Draft.
- `create-staging` label present, `create-mobile` present only if mobile testing is needed.
- Description enumerates changes without implementation detail.
- Acceptance tests concise, fixture wording matches the reference exactly, links direct.

