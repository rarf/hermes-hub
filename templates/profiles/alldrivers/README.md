# AllDrivers profile rollout

Owner: Hermes Hub. Reference: [current Hermes profiles documentation](https://hermes-agent.nousresearch.com/docs/user-guide/profiles) and [single multiplexed gateway](https://hermes-agent.nousresearch.com/docs/user-guide/multi-profile-gateways).

## Curated roles

`curation.json` defines the relevant skill allowlists and optional plugins. These are work profiles, not OS sandboxes. Native personal memory, messaging channels and scheduled jobs must not be inherited. Cloning configuration and skills avoids re-discovering existing inference/tool keys; OAuth refresh tokens must not be duplicated.

- `alldrivers-dev`: bounded code delivery, canonical test loop and risk-proportionate review.
- `alldrivers-support`: customer support and read-only evidence by default; mutations require exact-scope approval. This is an instruction boundary, not a credential-enforced read-only sandbox.
- OptMem stays profile-local. Seed only product/work rules; do not import personal/family history. On this installed host the plugin identity is `optmem-hermes`: the v0.3.0 `mode optmem-only` CLI writes the stale provider name `optmem`. After that command explicitly set `memory.provider=optmem-hermes`, read it back and run a real `optmem_recall` session smoke. Status/check alone did not expose the missing runtime tools.
- Default to two independent leaves. Preserve the main/leaf model routes; disable redundant automatic background review only in the new profiles. Required acceptance review still applies.
- Use Antigravity when independent code review is meaningful or explicitly required, not to ratify every trivial decision/configuration/docs edit.

## Access and isolation

Host terminal tools keep real OS `HOME` (`terminal.home_mode=auto`). Model OAuth uses Hermes' root credential fallback. Static keys are inherited privately; never commit or print them.

For MCP OAuth, the owner explicitly selected sharing the default `mcp-tokens/` **directory** through profile-local symlinks. A whole-directory link keeps atomic token replacements and refresh locks on one underlying store. Separate copies or per-file symlinks can fork rotating tokens. This is a local compatibility arrangement, not permission isolation or a claim of upstream profile-OAuth sharing support. Independent identities require fresh profile-specific authorization instead.

## Single gateway boundary

Do not install/start secondary gateways. Check the live default control socket and its recorded `served_profiles`, not just config or a dry run. If the default process is single-profile, enabling multiplexing needs a controlled restart. Do not interrupt live #402/#403 owners or this chat just to demonstrate it. Freeze recovery checkpoints, obtain exact maintenance approval and verify the one existing service afterwards.

The desktop/profile selector and CLI can use named profiles independently of channel multiplexing. This alone does not prove the gateway serves them.

## Verification and rollback

Run `bash scripts/doctor.sh --profile <name>`, actual bounded inference/tool smokes and read-only `hermes -p <name> mcp test <server>`. Verify OptMem mode/status and distinct resolved stores; a configured credential alone is not access proof.

Private inventories, removed skills, quarantined duplicate MCP copies and native-memory rollback live under `_local/alldrivers-profile-rollout/`, excluded from Git. Preserve default memory, original worktrees and live processes. Inspect interrupted-operation effects before repeating a move or external write.

Keep current #402/#403 owners in default through their approved gates. Start the next milestone in the development profile using a compact exact-SHA/rules/approvals/blockers handoff, not copied history. Stop at production GO unless separately authorized.
