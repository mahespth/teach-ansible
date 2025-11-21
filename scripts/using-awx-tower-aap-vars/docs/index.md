# AWX / Controller (Tower & AAP) job variables

When you launch a job from Ansible Automation Platform (AAP), Controller (formerly Ansible Tower), or AWX, your playbook receives a set of injected variables. They make it easy to branch logic based on **who** ran the job, **what** launched it, and **where** it is running.

Notes:
- Modern releases provide both the legacy `tower_*` names and `awx_*` aliases. Stick to one style to keep tasks clear.
- Exact availability can vary a little by version and launch method (manual, schedule, webhook, workflow). Use the “discover” task below to verify in your environment.

## Quick way to see what you actually get

```yaml
- name: Show Controller/AWX variables
  debug:
    var: _awx_vars
  vars:
    _awx_vars: >-
      {{
        vars
        | dict2items
        | selectattr('key', 'match', '^(awx|tower)_')
        | sort(attribute='key')
      }}
```

Run once in a test job (safe to limit to `localhost`) and copy the resulting list for your own reference.

## Common uses
- Gate tasks for schedule vs manual launches.
- Include run metadata in notifications or tickets.
- Fetch the project revision used for the run in downstream tools.
- Branch workflows when a job is launched from a parent workflow.

## Variable reference

### Job metadata
| Variable | Description | Example use |
| --- | --- | --- |
| `tower_job_id` | Numeric ID of the job run. | Tag log lines or external tickets with the job URL: `https://controller.example.tld/#/jobs/playbook/{{ tower_job_id }}` |
| `tower_job_template_id` | ID of the Job Template that was launched. | Conditional: only allow certain steps from specific templates. |
| `tower_job_template_name` | Name of the Job Template. | Display in notifications for readability. |
| `tower_job_launch_type` | How the job was started: `manual`, `workflow`, `scheduled`, `webhook`, `relaunch`, etc. | Skip prompts for scheduled runs:<br>`when: tower_job_launch_type != 'scheduled'` |
| `tower_hostname` | Controller/AWX base URL used for the job. | Build links back to the job or API. |

### User / organization
| Variable | Description | Example use |
| --- | --- | --- |
| `tower_user_id` | Numeric user ID of the launcher. | Audit who kicked off a manual run. |
| `tower_user_name` | Username of the launcher. | Add to notifications or change tickets. |
| `tower_user_email` | Email of the launcher (if set). | Address notification recipients dynamically. |
| `tower_organization_id` | ID of the organization owning the template. | Enforce org-specific policy or tags. |
| `tower_organization_name` | Name of the organization. | Human-friendly display in messages. |

### Inventory & project
| Variable | Description | Example use |
| --- | --- | --- |
| `tower_inventory_id` | Inventory ID attached to the job. | Choose vaults/credential logic per inventory. |
| `tower_inventory_name` | Inventory name. | Human-readable summary output. |
| `tower_project_revision` | SCM commit hash used for the project sync feeding this job. | Record the exact content revision deployed. |
| `tower_project_scm_branch` | Branch / refspec requested on the job template. | Prevent running non-production branches in production inventories. |

### Schedule & workflow context
| Variable | Description | Example use |
| --- | --- | --- |
| `tower_schedule_id` | ID of the schedule when launched by a schedule. | Alter behavior for nightly maintenance runs. |
| `tower_schedule_name` | Schedule name. | Friendly context in reports. |
| `tower_workflow_job_id` | ID of the parent workflow job, if any. | Link playbook runs back to the workflow for traceability. |
| `tower_workflow_job_name` | Name of the workflow job. | Include in notifications or logs. |
| `tower_workflow_job_template_id` | Workflow job template ID. | Conditional routing inside shared roles. |
| `tower_workflow_job_template_name` | Workflow job template name. | Readable output. |

### Execution environment
| Variable | Description | Example use |
| --- | --- | --- |
| `tower_execution_environment_id` | ID of the execution environment image used. | Confirm you are on the expected EE before running tasks. |
| `tower_execution_environment_name` | Friendly name of the execution environment. | Display in output for diagnostics. |
| `tower_execution_environment_image` | Container image reference. | Validate image pinning: `assert: { that: \"'prod-ee:' in tower_execution_environment_image\" }` |

### Webhook launches
Variables are set only when the job was triggered via a GitHub/GitLab webhook.

| Variable | Description | Example use |
| --- | --- | --- |
| `tower_webhook_service` | `github` or `gitlab`. | Branch logic per VCS provider. |
| `tower_webhook_guid` | Event GUID from the VCS. | Store for audit correlation. |
| `tower_webhook_commit` | Commit hash that triggered the job. | Validate the content revision matches expectations. |
| `tower_webhook_ref` / `tower_webhook_branch` | Ref or branch name from the webhook. | Enforce branch allowlists. |
| `tower_webhook_repo` | Repository full name (`org/repo`). | Route notifications to team based on repo. |

### Helpful snippets

**Build a job URL for notifications**
```yaml
- set_fact:
    controller_job_url: "{{ tower_hostname | default('https://controller.example.tld') }}/#/jobs/playbook/{{ tower_job_id }}"
```

**Fail fast if someone runs the job manually**
```yaml
- name: Block manual runs
  fail:
    msg: "This playbook must be run by schedule (found: {{ tower_job_launch_type }})"
  when: tower_job_launch_type != 'scheduled'
```

**Attach metadata to a CMDB or ticket**
```yaml
- name: Post job metadata
  uri:
    url: "https://cmdb.example/api/runs"
    method: POST
    body_format: json
    body:
      job_id: "{{ tower_job_id }}"
      template: "{{ tower_job_template_name }}"
      inventory: "{{ tower_inventory_name }}"
      project_revision: "{{ tower_project_revision }}"
      launched_by: "{{ tower_user_name }}"
```

If you prefer the newer naming, substitute `awx_` for `tower_` in the variables above. Keep the discovery task handy because Controller/AAP occasionally adds new fields in releases.
