# What is `json_query`?

`json_query` is an Ansible filter that lets you run a **JMESPath** expression on a variable.

You use it like any other filter:

```yaml
{{ my_var | json_query('some.expression.here') }}
```

Think of it as:

> "Take this variable, treat it as JSON, and run a query language over it."

---

## A minimal example

Imagine you have a list of servers:

```yaml
vars:
  servers:
    - name: web1
      ip: 10.0.0.11
      role: web
    - name: web2
      ip: 10.0.0.12
      role: web
    - name: db1
      ip: 10.0.0.21
      role: db
```

### Goal

Get a simple list of server names:

```yaml
["web1", "web2", "db1"]
```

### Without `json_query`

You might loop and build a list manually, or rely on other Jinja tricks.

### With `json_query`

```yaml
- name: Get list of server names
  ansible.builtin.debug:
    msg: "{{ servers | json_query('[].name') }}"
```

**Explanation:**

- `servers` is your list
- `[]` means "each element of the list"
- `.name` means "take the `name` field"
- Combined: `[].name` → “for each item, give me its `name`”

Result:

```text
ok: [localhost] => {
    "msg": [
        "web1",
        "web2",
        "db1"
    ]
}
```

---

## Where does `json_query` come from?

Under the hood, `json_query` uses a library called **JMESPath**. It’s a generic query language for JSON, used by AWS tools, Ansible, and others.

You don’t need to install anything extra if you’re on a modern Ansible / AAP version – but in some minimal environments, you may need to ensure the Python `jmespath` library is present.

---

## When should I use `json_query`?

Use `json_query` when:

- You have **nested or complex data** (lists inside dicts inside lists…)
- You want to **filter** items (e.g. only powered-on VMs, only servers in `prod`)
- You want to **project** part of the structure (e.g. “give me all names”, “give me a list of IPs”)
- You’re working with **API responses** or **module outputs** that are already JSON-like

You *don’t* need `json_query` for:

- Simple attribute access:
  - `{{ my_hostvars.ansible_hostname }}`
  - `{{ my_list[0].name }}`
- Simple loops:
  - `loop: "{{ my_list }}"`

A good rule of thumb:

> If you can get it with `{{ var.key }}` or a simple loop, stick to that.  
> When your data starts to look like you need multiple nested loops, consider `json_query`.

---

## What’s next?

Next we’ll look at **basic selectors**: how to pick values out of lists and dictionaries with small, readable expressions.

- 👉 [Basic selectors with `json_query`](./02-basic-selectors.md)
