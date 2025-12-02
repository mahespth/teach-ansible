# Red Hat Satellite Hammer CLI cheatsheet

Updated for Satellite 6.14+ / Hammer 3.x (common across 6.13–6.16). The old Red Hat cheat sheet (Article 2258471) misses newer flags and defaults—use the commands below and run `hammer --help` after upgrades to spot additions.

Notes:
- Verify your version: `hammer --version` (or `rpm -q tfm-rubygem-hammer_cli` on the Satellite server).
- Many commands accept `--search` with the same syntax as the Satellite UI search bar.
- Output formats: `--output table|csv|json|yaml`; increase rows with `--per-page 500`.

## Authentication and defaults
- One-off with credentials: `hammer -u admin -p 'secret' --server https://sat.example.com --verify-ssl true organization list`
- Use a config file (`~/.hammer/cli_config.yml`):
  ```yaml
  :foreman:
    :host: https://sat.example.com
    :username: admin
    :password: <redacted>
    :ssl_ca: /etc/pki/katello/certs/katello-server-ca.crt
    :default_output: table
  ```
- Safer password prompt: add `--ask-password` instead of `-p`.
- Set persistent defaults so you can omit flags:
  - `hammer defaults add --param-name organization_id --param-value 1`
  - `hammer defaults add --param-name location_id --param-value 2`
- Quick health check of backend services: `hammer ping`

## Organizations and locations
- List orgs/locations: `hammer organization list`, `hammer location list`
- Show identifiers for scripting: `hammer organization info --name "Default Organization"`
- Set default org/location (if you skipped the `defaults` entries): add `--organization <name>` / `--location <name>` on each command.

## Content lifecycle (CVs, LCEs, repos)
- Lifecycle environments: `hammer lifecycle-environment list`, `hammer lifecycle-environment paths`
- Content views:
  - List: `hammer content-view list`
  - Publish: `hammer content-view publish --name "RHEL Base" --description "Monthly patch set"`
  - Promote: `hammer content-view version promote --content-view "RHEL Base" --to-lifecycle-environment "QA" --version 5.0`
- Repositories:
  - List: `hammer repository list --content-view "RHEL Base" --lifecycle-environment "Library"`
  - Sync: `hammer repository synchronize --id 123`
  - Last sync status: `hammer repository info --id 123 | grep -E "Last sync|Sync state"`

## Activation keys and subscriptions
- List AKs: `hammer activation-key list`
- Show AK with products/repos: `hammer activation-key info --id 45`
- Add subscription: `hammer activation-key add-subscription --id 45 --subscription-id 302`
- Attach content view/LCE: `hammer activation-key update --id 45 --content-view "RHEL Base" --lifecycle-environment "Dev"`
- Host subscription inventory: `hammer host subscription list --host "web01"`

## Hosts and errata
- List hosts with filters: `hammer host list --search 'lifecycle_environment = QA and content_facet_attributes.applicable_errata > 0'`
- Host details: `hammer host info --name web01 --fields "Name,OS,Environment,Content View,Subscriptions"`
- Applicable errata: `hammer host errata list --host web01 --search "type = security"`
- Apply errata: `hammer host errata apply --host web01 --errata-ids RHSA-2024:1234,RHSA-2024:2345`
- Re-register a host (when you rotate activation keys):
  ```bash
  subscription-manager unregister
  subscription-manager register --activationkey=new-ak --org="Default_Organization"
  ```

## Capsules (smart proxies)
- List capsules: `hammer capsule list`
- Show capsule services: `hammer capsule info --id 3`
- Sync capsule content: `hammer capsule content synchronize --id 3`
- Add lifecycle envs to capsule: `hammer capsule content lifecycle-environment add --id 3 --lifecycle-environment "QA" --organization "Default Organization"`
- Check capsule SSL certs: `hammer capsule certificates status --id 3`

## Remote jobs and templates
- Find templates: `hammer job-template list --search 'name ~ Run Command'`
- Run a quick command via remote execution:
  ```bash
  hammer job-invocation create \
    --job-template "Run Command - Script Default" \
    --search-query 'name ~ web' \
    --inputs command="uptime"
  ```
- Check job status: `hammer job-invocation info --id 99`

## Users, roles, and RBAC
- Users and roles: `hammer user list`, `hammer role list`
- Assign role to user: `hammer user add-role --id 12 --role-id 5`
- Audit recent logins: `hammer user login-list --since '7 days ago'`

## Tasks and troubleshooting
- Stuck tasks: `hammer task list --search 'state != stopped'`
- Inspect a task: `hammer task progress --id <uuid>`
- Resume/cancel: `hammer task resume --id <uuid>`, `hammer task cancel --id <uuid>`
- Bulk cancel long-running Pulp syncs (careful): `hammer task list --search 'action ~ Sync and state = running' --fields id | awk '/[a-f0-9-]{36}/{print $1}' | xargs -n1 hammer task cancel --id`

## Tips to keep this current
- After Satellite upgrades, rerun `hammer --help` on key subcommands (content-view, host errata, capsule content) to spot new flags.
- `hammer ping` and `hammer --version` are quick sanity checks before automating.
- When scripting, prefer IDs over names to avoid clashes; use `--fields` to pull IDs quickly.
