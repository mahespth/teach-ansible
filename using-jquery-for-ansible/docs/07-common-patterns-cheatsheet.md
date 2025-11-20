# Common patterns & cheat sheet

This page is a quick reference for “I have data that looks like X, I want Y”.

Each section shows:

- **Data shape** (abstracted)
- **Goal**
- **`json_query` expression**
- Optional: a minimal Ansible snippet

---

## 1. Lists of simple dictionaries

### 1.1 List of items → one field

**Data**

```yaml
servers:
  - name: web1
    ip: 10.0.0.11
  - name: web2
    ip: 10.0.0.12
  - name: db1
    ip: 10.0.0.21
```

**Goal**

Get a list of names:

```yaml
["web1", "web2", "db1"]
```

**Expression**

```jinja
servers | json_query('[].name')
```

---

### 1.2 List of items → multiple fields (projection)

**Goal**

```yaml
- name: web1
  ip: 10.0.0.11
- name: web2
  ip: 10.0.0.12
```

**Expression**

```jinja
servers | json_query('[].{name: name, ip: ip}')
```

---

### 1.3 Filter by equality on a field

**Goal**

Only `role: web` servers:

```yaml
["web1", "web2"]
```

**Expression**

```jinja
servers | json_query('[?role==`web`].name')
```

---

## 2. Typical Ansible `register` shapes

### 2.1 `loop` + `register` → `results[]`

**Data**

```yaml
http_checks:
  results:
    - item: https://example.com
      status: 200
    - item: https://example.net
      status: 500
```

**Goal**

All status codes:

```yaml
[200, 500]
```

**Expression**

```jinja
http_checks | json_query('results[].status')
```

---

### 2.2 Filter `results[]` by return code

**Goal**

Failed URLs only:

```yaml
["https://example.net"]
```

**Expression**

```jinja
http_checks | json_query('results[?status!=`200`].item')
```

---

### 2.3 Build simplified error list from `results[]`

**Goal**

```yaml
- url: https://example.net
  status: 500
```

**Expression**

```jinja
http_checks | json_query('results[?status!=`200`].{url: item, status: status}')
```

---

## 3. API-style outputs (`json.items[]` etc.)

### 3.1 Basic `json.items[]` pattern

**Data**

```yaml
api_result:
  json:
    items:
      - name: web1
        status: running
      - name: web2
        status: stopped
```

**Goal**

All item names:

```yaml
["web1", "web2"]
```

**Expression**

```jinja
api_result | json_query('json.items[].name')
```

---

### 3.2 Filter inside `items[]`

**Goal**

Names of `status: running` items:

```yaml
["web1"]
```

**Expression**

```jinja
api_result | json_query('json.items[?status==`running`].name')
```

---

## 4. Working with facts / nested structures

### 4.1 Simple nested dictionary

**Data**

```yaml
app:
  name: shop
  db:
    host: db1
    port: 5432
```

**Goal**

DB host:

```yaml
db1
```

**Expression**

```jinja
app | json_query('db.host')
```

---

### 4.2 Nested list inside dict

**Data**

```yaml
device:
  hostname: sw1
  interfaces:
    - name: eth0
      primary: true
      ip: 10.0.0.11
    - name: eth1
      primary: false
      ip: 192.168.1.1
```

**Goal**

IP of the primary interface:

```yaml
10.0.0.11
```

**Expression**

```jinja
device | json_query('interfaces[?primary==`true`][0].ip')
```

---

## 5. Common filter patterns

### 5.1 AND / OR conditions

```jinja
# Running web servers
servers | json_query('[?state==`running` && role==`web`].name')

# Servers in zone a or b
servers | json_query('[?zone==`a` || zone==`b`].name')
```

---

### 5.2 Using `contains()` for tags/labels

**Data**

```yaml
vm:
  name: web1
  tags:
    - "env:prod"
    - "tier:web"
```

**Expression**

```jinja
vms | json_query('[?contains(tags, `"env:prod"`)].name')
```

---

## 6. Kubernetes-flavoured patterns

### 6.1 Pods with any not-ready container

**Data (shape)**

```yaml
pod_info:
  resources:
    - metadata: ...
      status:
        containerStatuses:
          - ready: true
          - ready: false
```

**Goal**

Pods where any container is not ready.

**Expression**

```jinja
pod_info | json_query(
  'resources[?status.containerStatuses[?ready==`false`]].metadata.name'
)
```

---

### 6.2 Label-based selection

**Data**

```yaml
metadata:
  labels:
    app: web
    env: prod
```

**Goal**

Pods with `app=web`, `env=prod`:

```jinja
pod_info | json_query(
  'resources[?metadata.labels.app==`"web"` && metadata.labels.env==`"prod"`].metadata.name'
)
```

*(Adjust quoted vs unquoted based on how your labels appear in the structure.)*

---

## 7. `set_fact` helper patterns

### 7.1 Precompute filtered list for later loops

```yaml
- name: Running DB servers
  ansible.builtin.set_fact:
    running_db_servers: >-
      {{ servers
         | json_query('[?state==`running` && role==`db`].name') }}

- name: Use them in a loop
  ansible.builtin.debug:
    msg: "Will act on {{ item }}"
  loop: "{{ running_db_servers }}"
```

---

### 7.2 Simplify complex output in two steps

Pattern:

1. Narrow/reshape with first `json_query`
2. Use a second `json_query` or simple Jinja

```yaml
- name: Narrow down to prod servers
  ansible.builtin.set_fact:
    prod_servers: >-
      {{ all_servers | json_query('[?env==`prod`]') }}

- name: Now just get names (simpler)
  ansible.builtin.debug:
    msg: "{{ prod_servers | json_query('[].name') }}"
```

---

## 8. At-a-glance reference

```text
# list → field
[].field

# list → multiple fields
[].{out1: in1, out2: in2}

# list → filtered
[?field==`value`]
[?field!=`value`]

# filtered + projected
[?state==`running`].name
[?state==`running`].{name: name, ip: ip}

# nested path to list
json.items[].name
resources[].metadata.name
results[].status
```

Use this page when you think:

> “I’ve seen this before… what was that expression again?”
