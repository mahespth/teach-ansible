# Filters and projections

This is where `json_query` becomes genuinely powerful:

- **Filters**: choose *which* items you want
- **Projections**: choose *which fields* you want from them

Together they replace a lot of nested loops and `when:` conditions.

---

## 1. Basic filter: `[?field=='value']`

Starting from our familiar data:

```yaml
vars:
  servers:
    - name: web1
      ip: 10.0.0.11
      role: web
      state: running
    - name: web2
      ip: 10.0.0.12
      role: web
      state: stopped
    - name: db1
      ip: 10.0.0.21
      role: db
      state: running
```

### Goal

Get only the servers with `state: running`.

### Expression

```yaml
- name: Running servers only
  ansible.builtin.debug:
    msg: "{{ servers | json_query('[?state==`running`]') }}"
```

**What’s happening**

- `[?state==\`running\`]` means:
  - “From this list, keep only items where `state` equals `running`.”
- Backticks are JMESPath’s way to quote literal values inside expressions.

Result:

```yaml
- name: web1
  ip: 10.0.0.11
  role: web
  state: running
- name: db1
  ip: 10.0.0.21
  role: db
  state: running
```

> 💡 In YAML you’re already inside quotes for the whole expression,  
> so JMESPath uses backticks for inner values.

---

## 2. Filter + projection: names of running servers

Same data.

### Goal

Get a list of names of running servers:

```yaml
["web1", "db1"]
```

### Expression

```yaml
- name: Names of running servers
  ansible.builtin.debug:
    msg: "{{ servers | json_query('[?state==`running`].name') }}"
```

Read it left to right:

1. Start with `servers` (list).
2. Apply filter `[?state==\`running\`]` → still a list, but only running servers.
3. `.name` → project the `name` field from each item.

---

## 3. Multiple conditions

You can combine conditions with `&&` (and) / `||` (or).

### Goal

Running **web** servers only:

Expected:

```yaml
["web1"]
```

### Expression

```yaml
- name: Names of running web servers
  ansible.builtin.debug:
    msg: >-
      {{ servers
         | json_query('[?state==`running` && role==`web`].name') }}
```

**Notes**

- `&&` → logical AND
- `||` → logical OR
- Use `>-` in YAML to keep long expressions readable on multiple lines.

---

## 4. Projections with `{}` objects

Filters pick **which items** to keep. Projections with `{}` shape the output.

Same servers data.

### Goal

Get a list of objects with just `name` and `ip` for running servers:

```yaml
- name: web1
  ip: 10.0.0.11
- name: db1
  ip: 10.0.0.21
```

### Expression

```yaml
- name: Name + IP of running servers
  ansible.builtin.debug:
    msg: >-
      {{ servers
         | json_query('[?state==`running`].{name: name, ip: ip}') }}
```

**What’s happening**

- Filter: `[?state==\`running\`]`
- Projection: `{name: name, ip: ip}`
  - Left side of `:` → output key
  - Right side → field to read from each item

---

## 5. Applying this to module output (`results[]`)

Back to our earlier `http_checks` example:

```yaml
http_checks:
  results:
    - item: https://example.com
      status: 200
    - item: https://example.net
      status: 500
    - item: https://example.org
      status: 200
```

### Goal

Get a list of failed URLs and their status:

```yaml
- url: https://example.net
  status: 500
```

### Expression

```yaml
- name: Failed HTTP checks
  ansible.builtin.debug:
    msg: >-
      {{ http_checks
         | json_query('results[?status!=`200`].{url: item, status: status}') }}
```

Result is a list of dictionaries you can loop over later, or pass into `set_fact`.

---

## 6. Using filtered data in later tasks

You can combine `set_fact` with `json_query` to build reusable variables.

Example: build a list of running DB servers:

```yaml
- name: List of running DB servers
  ansible.builtin.set_fact:
    running_db_servers: >-
      {{ servers
         | json_query('[?state==`running` && role==`db`].name') }}

- name: Show them
  ansible.builtin.debug:
    var: running_db_servers
```

Later you might use:

```yaml
- name: Do something on all running DBs
  ansible.builtin.debug:
    msg: "Would act on {{ item }}"
  loop: "{{ running_db_servers }}"
```

---

## 7. Quick reference

Common patterns:

```text
# Filter a list by equality
[?field==`value`]

# Filter by inequality
[?field!=`value`]

# Logical AND / OR
[?state==`running` && role==`web`]
[?zone==`a` || zone==`b`]

# Filter, then project one field
[?state==`running`].name

# Filter, then project a custom object
[?state==`running`].{name: name, ip: ip}
```

---

## Next up (optional)

At this point you can:

- Walk module output to the list you care about
- Filter that list
- Shape the result

From here you can either:

- Dive into **real-world, ugly structures** (nested lists, optional keys), or
- Jump to the **cheat sheet** once it’s written.

If you’re ready for pain, the next fun step is a page of **complex, real examples** where people usually get stuck.
