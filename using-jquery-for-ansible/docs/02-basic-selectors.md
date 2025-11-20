# Basic selectors with `json_query`

Before we get clever with filters, you need to be solid on the basics:

- Selecting keys from dictionaries
- Selecting items from lists
- Getting “one field from every item”

These three patterns cover a surprising amount of real-world use.

---

## 1. Selecting a key from a dictionary

Given:

```yaml
vars:
  server:
    name: web1
    ip: 10.0.0.11
    role: web
```

### Goal

Get the `ip`:

```yaml
10.0.0.11
```

### `json_query` expression

```yaml
- name: Get server IP
  ansible.builtin.debug:
    msg: "{{ server | json_query('ip') }}"
```

**What’s happening**

- `server` is a dictionary
- `'ip'` selects the `ip` key

This is *identical* to `{{ server.ip }}` – we’re just showing the 1:1 mapping so the JMESPath mental model starts to stick.

---

## 2. Selecting from a list by index

Given:

```yaml
vars:
  servers:
    - web1
    - web2
    - db1
```

### Goal

Get the second item (`web2`).

### `json_query` expression

```yaml
- name: Get second server
  ansible.builtin.debug:
    msg: "{{ servers | json_query('[1]') }}"
```

**Notes**

- Lists are zero-based: `[0]` is the first element.
- `'[1]'` selects the second element.

Again, you *could* just write `{{ servers[1] }}`. We’re still in “mapping simple Jinja to JMESPath” territory.

---

## 3. Selecting a field from each item in a list

Now something actually useful.

Given:

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

Get a list of all server names:

```yaml
["web1", "web2", "db1"]
```

### `json_query` expression

```yaml
- name: Get list of server names
  ansible.builtin.debug:
    msg: "{{ servers | json_query('[].name') }}"
```

**What’s happening**

- `servers` is a list
- `[]` means “each element”
- `.name` means “take the `name` key”
- Combined: `[].name` → _for each item, give me its `name`_

This is one of the **core patterns** you’ll use all the time.

---

## 4. Getting multiple fields from each item

Same data as above.

### Goal

Get a list of small dictionaries with both `name` and `ip`:

```yaml
- name: web1
  ip: 10.0.0.11
- name: web2
  ip: 10.0.0.12
- name: db1
  ip: 10.0.0.21
```

### `json_query` expression

```yaml
- name: Name + IP projection
  ansible.builtin.debug:
    msg: "{{ servers | json_query('[].{name: name, ip: ip}') }}"
```

**What’s happening**

- `[]` → “for each element…”
- `{name: name, ip: ip}` → build a new object with keys `name` and `ip`
- Left side of `:` is the output field name, right side is the input key

---

## 5. Selecting nested keys

Given:

```yaml
vars:
  app:
    name: shop
    db:
      host: db1
      port: 5432
```

### Goal

Get the database host: `db1`.

### `json_query` expression

```yaml
- name: Get DB host
  ansible.builtin.debug:
    msg: "{{ app | json_query('db.host') }}"
```

**What’s happening**

- `db.host` → “go into `db`, then get `host`”

This is the same idea as `{{ app.db.host }}` but in JMESPath syntax.

---

## 6. Quick mental model

Map what you already know in Jinja to JMESPath:

| Jinja                        | JMESPath / `json_query`     |
|-----------------------------|-----------------------------|
| `var.key`                   | `'key'`                     |
| `var.sub.key`               | `'sub.key'`                 |
| `list[0]`                   | `'[0]'`                     |
| `item.name` in a loop       | `'[].name'` on the list     |
| Build `{ name, ip }` dicts | `'[].{name: name, ip: ip}'` |

> 💡 If you can write it in simple Jinja, you *don’t have to* use `json_query`.  
> But learning these mappings makes reading more complex expressions much easier later.

---

## Next up

Now that basic selectors make sense, let’s see how they apply to **real Ansible module results** and `register` output.

- 👉 [Working with facts and module output](./03-working-with-facts.md)
