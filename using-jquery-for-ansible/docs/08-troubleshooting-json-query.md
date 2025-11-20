# Troubleshooting `json_query`

You will see this a lot:

- `null`
- `[]` (empty list)
- “JMESPathTypeError” in logs
- “Expected xxx but was yyy” errors

This page gives a quick way to debug what’s wrong.

---

## 1. Check the basics

### 1.1 Does the variable exist?

Make sure the registered variable is actually there:

```yaml
- ansible.builtin.debug:
    var: my_var
```

If you get `VARIABLE IS NOT DEFINED`, fix that first. No amount of `json_query` will help.

---

### 1.2 Are you starting from the right root?

Example:

```yaml
vm_info:
  value:
    - name: web1
```

**Wrong**

```jinja
vm_info | json_query('[].name')
```

**Right**

```jinja
vm_info | json_query('value[].name')
```

Always start your path from the top-level registered variable structure.

---

## 2. Look at the raw shape

When something fails, **dump the variable** in full or partially:

```yaml
- ansible.builtin.debug:
    var: vm_info

# or for smaller logs:
- ansible.builtin.debug:
    msg: "{{ vm_info.value }}"
```

Then:

1. Identify where the list you care about lives.
2. Identify exact key names (case sensitive).
3. Build the path in small steps.

---

## 3. Build the query step by step

Instead of jumping straight to:

```jinja
vm_info | json_query('value[?power_state==`"POWERED_ON"`].name')
```

Work incrementally.

### Step 1: Get the list

```jinja
vm_info | json_query('value')
```

If that’s not giving a list, your path is wrong.

### Step 2: Filter the list

```jinja
vm_info | json_query('value[?power_state==`"POWERED_ON"`]')
```

Check you get **some items** back.

### Step 3: Project the field

```jinja
vm_info | json_query('value[?power_state==`"POWERED_ON"`].name')
```

If something breaks at a step, fix that step before moving on.

---

## 4. Understand `null` vs `[]`

- `null` → “this path doesn’t exist at all” or value is `null`
- `[]` → “path exists, but the list is empty after filtering”

Examples:

```jinja
# path doesn't exist → null
{ } | json_query('items')

# list exists but filter matches nothing → []
[ {state: "stopped"} ] | json_query('[?state==`running`]')
```

This helps decide whether you have:

- A spelling / path issue (null), or
- A logic issue in the filter (empty list).

---

## 5. Quote/type issues

If path looks right but filter never matches, you might be comparing the wrong types.

### 5.1 String vs number

**Data**

```yaml
status: 200        # number
```

**OK**

```jinja
[?status==`200`]
```

**Data**

```yaml
status: "200"      # string
```

**Need string**

```jinja
[?status==`"200"`]
```

---

### 5.2 Boolean vs string `"true"`

**Data**

```yaml
ready: true        # boolean
```

```jinja
[?ready==`true`]   # correct
[?ready==`"true"`] # will not match
```

If a filter matches nothing, print out an example item and look carefully at how the field is represented.

---

## 6. YAML/Jinja quoting problems

If you get YAML parsing errors or Jinja template errors, the issue isn’t JMESPath at all.

Quick checklist:

- Is the whole Jinja expression wrapped in `{{ ... }}`?
- Is the JMESPath expression in **single quotes** `'...'`?
- Are literal values in **backticks** `` `...` ``?

Example of a safe pattern:

```yaml
msg: >-
  {{ servers
     | json_query('[?state==`running` && role==`web`].name') }}
```

If you see `unexpected character` or `found character that cannot start any token` in Ansible logs, suspect YAML/quoting first.

---

## 7. `results` vs `value` vs `json` vs `resources`

Common root keys:

- `results` → output from `loop + register`
- `value` → many `*_info` modules
- `json` → `uri` module parsed JSON
- `resources` → `k8s_info`, some cloud modules

If you write a query that ignores these wrappers, you’ll get `null`.

Examples:

```jinja
# Loop output
port_checks | json_query('results[].rc')

# vCenter VM info
vm_info | json_query('value[].name')

# REST API via uri
dev_api | json_query('json.devices[].hostname')

# Kubernetes Pods
pod_info | json_query('resources[].metadata.name')
```

If in doubt: `debug: var=the_var` and look at the **top-level keys**.

---

## 8. Nulls from nested filters

Nested filters can be tricky:

```jinja
resources[?status.containerStatuses[?ready==`false`]].metadata.name
```

If this returns `null` or empty list:

1. Check `status` exists on the objects.
2. Check `containerStatuses` is present (it might be missing for some pods).
3. Check the field name is exact (`ready` vs `isReady`, etc.).

You can also debug inner parts:

```jinja
pod_info | json_query('resources[].status.containerStatuses')
pod_info | json_query('resources[].status.containerStatuses[].ready')
```

If these return `null`, fix that before adding filters.

---

## 9. Mixed Jinja and `json_query`

Remember that `json_query` is *inside* Jinja. Avoid doing too much in one line when debugging.

Instead of:

```yaml
msg: "{{ (my_var | json_query('value[?state==`"POWERED_ON"`].name')) | join(', ') }}"
```

Try:

```yaml
- set_fact:
    running_names: "{{ my_var | json_query('value[?state==`"POWERED_ON"`].name') }}"

- debug:
    var: running_names
```

Once it works, you can shorten again if you like.

---

## 10. When all else fails

If a query just won’t behave:

1. Reduce it to the simplest thing that *does* work.
2. Add one piece at a time (path → filter → projection).
3. If you’re still stuck, log:
   - The full variable (`debug: var=...`)
   - The query you’re trying
   - The current result (`null`, `[]`, wrong data)

Often you’ll spot:

- A typo in a key, or
- A wrong assumption about where the list actually lives.

---

Use this page whenever you think:

> “Why is this `null`? It *should* be there…”

and walk through the steps one by one.
