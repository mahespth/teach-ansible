# Working with facts and module output

Most of the time you’ll use `json_query` on **registered variables** – the output of modules, API calls, or facts.

In this section we’ll look at:

- A simple registered result
- A list of results (from `loop`)
- The classic “API response with `items[]`” pattern

---

## 1. Simple registered result

Given a module that returns a dictionary:

```yaml
- name: Get app info
  my_namespace.my_collection.app_info:
    name: shop
  register: app_result
```

Let’s say `app_result` looks like this (simplified):

```yaml
app_result:
  changed: false
  failed: false
  app:
    name: shop
    version: "1.2.3"
    state: running
```

### Goal

Extract just the app name: `shop`.

### `json_query` expression

```yaml
- name: Show app name
  ansible.builtin.debug:
    msg: "{{ app_result | json_query('app.name') }}"
```

**Notes**

- Start from the **registered variable** (`app_result`)
- Walk down into the structure: `app.name`

You could also use `{{ app_result.app.name }}` – again, we’re keeping the JMESPath mapping clear.

---

## 2. Results from a loop (`results[]` pattern)

When you use `loop` with `register`, Ansible collects individual results into `results`.

Example:

```yaml
- name: Check multiple URLs
  ansible.builtin.uri:
    url: "{{ item }}"
    method: GET
  loop:
    - https://example.com
    - https://example.net
    - https://example.org
  register: http_checks
```

A simplified `http_checks` looks like:

```yaml
http_checks:
  changed: false
  results:
    - item: https://example.com
      status: 200
    - item: https://example.net
      status: 500
    - item: https://example.org
      status: 200
```

### Goal 1

Get a list of all status codes:

```yaml
[200, 500, 200]
```

### Expression

```yaml
- name: All status codes
  ansible.builtin.debug:
    msg: "{{ http_checks | json_query('results[].status') }}"
```

**What’s happening**

- `results` → the list of per-item results
- `[].status` → “for each result, give me `status`”

---

### Goal 2

Get the URLs that returned 200.

Expected:

```yaml
["https://example.com", "https://example.org"]
```

We’ll use filters properly in the next page, but here’s a sneak peek that ties selectors + a simple filter together:

```yaml
- name: OK URLs only
  ansible.builtin.debug:
    msg: "{{ http_checks | json_query('results[?status==`200`].item') }}"
```

Don’t worry too much about the filter syntax yet – pay attention to the pattern:

- Start at `results`
- Filter: `[?condition]`
- Project one field: `.item`

We’ll revisit this in detail in **filters and projections**.

---

## 3. API-style output with `items[]`

Many modules (especially API wrappers) return data like this:

```yaml
api_result:
  changed: false
  failed: false
  json:
    items:
      - name: web1
        status: running
        zone: a
      - name: web2
        status: stopped
        zone: b
      - name: db1
        status: running
        zone: a
```

Imagine this coming from a `uri` call or a cloud module.

### Goal

Get the names of all items:

```yaml
["web1", "web2", "db1"]
```

### Expression

```yaml
- name: All item names
  ansible.builtin.debug:
    msg: "{{ api_result | json_query('json.items[].name') }}"
```

**What’s happening**

- `json` → top-level key containing parsed JSON
- `items` → list of items
- `[].name` → names of each item

This pattern – `json.items[].name` – is very common.

---

## 4. Dealing with `stdout` and `stdout_lines`

For modules like `command` or `shell`, you often see `stdout` and `stdout_lines`.

Example:

```yaml
- name: List running services (demo)
  ansible.builtin.command: "systemctl list-units --type=service --state=running --no-legend"
  register: svc_cmd
```

A simplified result:

```yaml
svc_cmd:
  stdout_lines:
    - "sshd.service loaded active running OpenSSH server daemon"
    - "crond.service loaded active running Command Scheduler"
    - "NetworkManager.service loaded active running Network Manager"
```

This is just a **list of strings**. You don’t need `json_query` unless you want to do something more structured. For example, to get only the service names (first field):

```yaml
- name: Extract service names using json_query
  ansible.builtin.set_fact:
    running_services: >-
      {{ svc_cmd.stdout_lines
         | json_query('[].split(` `)[0]') }}
```

Now `running_services` will be like:

```yaml
["sshd.service", "crond.service", "NetworkManager.service"]
```

> ⚠️ Be careful: this is a slightly more advanced JMESPath expression.  
> The point here is: you *can* use `json_query` on simple lists, but it’s not always necessary.

---

## 5. Checklist for module output

When you look at a registered variable and want to use `json_query`, ask:

1. Is there a **list** I care about?
   - Look for keys like `results`, `items`, `instances`, `vms`, `interfaces`.
2. For that list, what **field(s)** do I want?
   - e.g. just `name`, or `{name, status}`.
3. What is the **path** from the top-level registered variable to that list?

Then build your query as:

```text
<path to list>[].<field>
```

Examples:

- `results[].status`
- `json.items[].name`
- `vms[].{name: name, power_state: power_state}`

---

## Next up

Now that you can walk through module outputs and facts, we’ll add **filters and projections** so you can say things like:

> “Give me the names of all running VMs in zone a”

- 👉 [Filters and projections](./04-filters-and-projections.md)
