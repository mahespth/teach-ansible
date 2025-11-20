# Complex real-world examples

This page shows realistic `json_query` expressions for “ugly” data:

- Nested lists
- Optional keys
- Module output that looks nothing like your mental model

Each example follows this structure:

1. **Data** (simplified real output)
2. **Goal**
3. **Expression**
4. **Explanation**

---

## Example 1: vSphere VMs from `vmware.vmware_rest`

Imagine a task that gets all VMs:

```yaml
- name: Get all VMs
  vmware.vmware_rest.vcenter_vm_info:
  register: vm_info
```

Simplified result:

```yaml
vm_info:
  value:
    - vm: "vm-101"
      name: "web1"
      power_state: "POWERED_ON"
      cpu_count: 2
      memory_size_MiB: 4096
      tags:
        - "env:prod"
        - "tier:web"
    - vm: "vm-102"
      name: "web2"
      power_state: "POWERED_OFF"
      cpu_count: 2
      memory_size_MiB: 4096
      tags:
        - "env:prod"
        - "tier:web"
    - vm: "vm-201"
      name: "db1"
      power_state: "POWERED_ON"
      cpu_count: 4
      memory_size_MiB: 8192
      tags:
        - "env:prod"
        - "tier:db"
```

### Goal 1

Names of all **powered-on** VMs:

```yaml
["web1", "db1"]
```

### Expression

```yaml
- name: Powered on VM names
  ansible.builtin.debug:
    msg: >-
      {{ vm_info
         | json_query('value[?power_state==`"POWERED_ON"`].name') }}
```

**Notes**

- `value` is the list of VMs.
- `power_state` is a **string** like `"POWERED_ON"`, so we compare to a string:
  - `` `"POWERED_ON"` `` → string literal `"POWERED_ON"` in JMESPath.
- Filter, then `.name` projection.

If your data uses plain values without the extra quotes, you’d use:

```yaml
'value[?power_state==`POWERED_ON`].name'
```

Adjust based on the actual structure.

---

### Goal 2

For powered-on **prod** VMs, get `name` and `cpu_count`:

```yaml
- name: web1
  cpu: 2
- name: db1
  cpu: 4
```

### Expression

```yaml
- name: Powered-on prod VMs (name + cpu)
  ansible.builtin.debug:
    msg: >-
      {{ vm_info
         | json_query('value[?power_state==`"POWERED_ON"` && contains(tags, `"env:prod"`)].{name: name, cpu: cpu_count}') }}
```

**What’s happening**

- `contains(tags, \`"env:prod"\`)` → keep VMs whose `tags` list contains `"env:prod"`.
- Projection: `{name: name, cpu: cpu_count}`.

---

## Example 2: Kubernetes pods via `k8s_info`

Imagine:

```yaml
- name: Get all pods in namespace
  kubernetes.core.k8s_info:
    kind: Pod
    namespace: myapp
  register: pod_info
```

Simplified result:

```yaml
pod_info:
  resources:
    - metadata:
        name: "web-abc123"
        labels:
          app: "web"
          env: "prod"
      status:
        phase: "Running"
        containerStatuses:
          - name: "web"
            ready: true
            restartCount: 0
    - metadata:
        name: "web-def456"
        labels:
          app: "web"
          env: "prod"
      status:
        phase: "CrashLoopBackOff"
        containerStatuses:
          - name: "web"
            ready: false
            restartCount: 5
    - metadata:
        name: "db-xyz999"
        labels:
          app: "db"
          env: "prod"
      status:
        phase: "Running"
        containerStatuses:
          - name: "db"
            ready: true
            restartCount: 1
```

### Goal 1

Names of pods where **any container** is not ready.

Expected:

```yaml
["web-def456"]
```

### Expression

```yaml
- name: Pods with any not-ready container
  ansible.builtin.debug:
    msg: >-
      {{ pod_info
         | json_query(
             'resources[?status.containerStatuses[?ready==`false`]].metadata.name'
           ) }}
```

**What’s happening**

- `resources` → list of pods.
- `status.containerStatuses[?ready==\`false\`]` → list of containers that are not ready.
- If that list is **non-empty**, the pod matches the filter.
- `.metadata.name` → pod name.

---

### Goal 2

For pods with `app=web` and `env=prod`, get `name` and `restartCount` of the main container:

```yaml
- name: web-abc123
  restarts: 0
- name: web-def456
  restarts: 5
```

Assuming the “main” container is the first one:

```yaml
- name: Restart count for web pods
  ansible.builtin.debug:
    msg: >-
      {{ pod_info
         | json_query(
             'resources[?metadata.labels.app==`"web"` && metadata.labels.env==`"prod"`].{name: metadata.name, restarts: status.containerStatuses[0].restartCount}'
           ) }}
```

Adjust based on how exactly your labels appear (plain strings vs quoted).

---

## Example 3: API response with nested interfaces

Imagine using `uri` to query a device inventory API:

```yaml
- name: Get devices from API
  ansible.builtin.uri:
    url: https://api.example.com/devices
    method: GET
    return_content: yes
  register: dev_api
```

Simplified parsed JSON (assume Ansible put it under `json`):

```yaml
dev_api:
  json:
    devices:
      - hostname: "sw1"
        site: "lon1"
        interfaces:
          - name: "eth0"
            primary: true
            ip: "10.0.0.11"
          - name: "eth1"
            primary: false
            ip: "192.168.1.1"
      - hostname: "sw2"
        site: "lon1"
        interfaces:
          - name: "eth0"
            primary: false
            ip: "10.0.0.12"
          - name: "eth1"
            primary: true
            ip: "192.168.2.1"
      - hostname: "sw3"
        site: "par1"
        interfaces:
          - name: "eth0"
            primary: true
            ip: "10.0.1.10"
```

### Goal

For devices in `lon1`, get hostname and **primary interface IP**:

```yaml
- hostname: sw1
  ip: 10.0.0.11
- hostname: sw2
  ip: 192.168.2.1
```

### Expression

```yaml
- name: Host + primary IP for lon1 devices
  ansible.builtin.debug:
    msg: >-
      {{ dev_api
         | json_query(
             'json.devices[?site==`"lon1"`].{hostname: hostname, ip: interfaces[?primary==`true`][0].ip}'
           ) }}
```

**What’s happening**

- `json.devices` → list of devices
- Filter: `[?site==\`"lon1"\`]`
- Projection:
  - `hostname: hostname`
  - `ip: interfaces[?primary==\`true\`][0].ip` → filter interfaces to primary, take first, get `ip`

If there might be no primary interface, the `[0]` can fail; in that case you’d usually handle missing values or filter further.

---

## Example 4: Loop output with nested `results[].item`

Sometimes you loop over structured items:

```yaml
- name: Check ports on devices
  ansible.builtin.command: "nc -z -w1 {{ item.ip }} {{ item.port }}"
  loop:
    - { name: "web1", ip: "10.0.0.11", port: 80 }
    - { name: "web2", ip: "10.0.0.12", port: 80 }
    - { name: "db1",  ip: "10.0.0.21", port: 5432 }
  register: port_checks
  ignore_errors: yes
```

Simplified `port_checks`:

```yaml
port_checks:
  results:
    - item:
        name: "web1"
        ip: "10.0.0.11"
        port: 80
      rc: 0
    - item:
        name: "web2"
        ip: "10.0.0.12"
        port: 80
      rc: 1
    - item:
        name: "db1"
        ip: "10.0.0.21"
        port: 5432
      rc: 0
```

### Goal

Build a list of failed endpoints:

```yaml
- name: web2
  ip: 10.0.0.12
  port: 80
```

### Expression

```yaml
- name: Failed endpoints
  ansible.builtin.set_fact:
    failed_endpoints: >-
      {{ port_checks
         | json_query(
             'results[?rc!=`0`].{name: item.name, ip: item.ip, port: item.port}'
           ) }}

- name: Show failed endpoints
  ansible.builtin.debug:
    var: failed_endpoints
```

Now `failed_endpoints` is a neat list you can loop over, log, or alert on.

---

## How to adapt these examples

When you have your own complex structure:

1. Run `debug: var=your_var` and inspect the shape.
2. Identify:
   - The list you care about
   - Any filters you need
   - The fields you want to output
3. Build the query in this order:

```text
<top-level-path-to-list>[?filter].{projection}
```

Examples from above:

- `value[?power_state==`"POWERED_ON"`].name`
- `resources[?status.containerStatuses[?ready==`false`]].metadata.name`
- `json.devices[?site==`"lon1"`].{hostname: hostname, ip: interfaces[?primary==`true`][0].ip}`
- `results[?rc!=`0`].{name: item.name, ip: item.ip, port: item.port}`

If it feels impossible, you can usually break it into **two queries**:

1. Use `set_fact` + `json_query` to narrow down/simplify the data.
2. Run a second `json_query` on that simpler structure.

---

## Next steps

From here, you might want:

- A **cheat sheet** of common patterns, or
- A **troubleshooting** page for when you get `null`/empty results and don’t know why.

Once you’ve nailed a couple of these in your own environment, `json_query` goes from “mystical” to “just another tool”.
