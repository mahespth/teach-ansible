# Quoting and YAML gotchas

Most `json_query` failures are not about JMESPath at all — they’re about **quoting**:

- YAML quoting
- Jinja quoting
- JMESPath quoting (backticks)

This page shows the common traps and how to avoid them.

---

## 1. The three layers of quoting

When you write:

```yaml
msg: "{{ servers | json_query('[?state==`running`].name') }}"
```

You have three things going on:

1. **YAML**: the whole string is a YAML value
2. **Jinja2**: `{{ ... }}` is a Jinja expression
3. **JMESPath**: inside `json_query('...')` is a JMESPath string

Visually:

```text
YAML           "{{ servers | json_query('[?state==`running`].name') }}"
Jinja2            ^-----------------------------------------------^
JMESPath                           '[?state==`running`].name'
                                   ^                    ^
                               single quotes         backticks
```

**Rule of thumb**

- Use **single quotes** `'...'` around the JMESPath expression.
- Use **backticks** `` `...` `` around literal values inside JMESPath.
- Let YAML use double quotes `"` for the whole Jinja expression when needed.

---

## 2. Correct vs incorrect examples

### Correct

```yaml
msg: "{{ servers | json_query('[?state==`running`].name') }}"
```

- Outer: `"` (YAML string)
- JMESPath: `'[?state==\`running\`].name'`
- Literal `running`: backticks

### Incorrect: double quotes inside double quotes

```yaml
# BAD
msg: "{{ servers | json_query("[?state=='running'].name") }}"
```

This breaks because:

- YAML sees `"{{ servers | json_query("[?state=='running'].name") }}"`  
- The inner `"` closes the outer string too early.

If you insist on `"` around the JMESPath expression, you must escape them, which gets ugly. Better to stick with single quotes for JMESPath.

---

## 3. Using folded style for complex queries

Long expressions are easier to read with YAML’s folded (`>-`) syntax:

```yaml
- name: Names of running web servers
  ansible.builtin.debug:
    msg: >-
      {{ servers
         | json_query('[?state==`running` && role==`web`].name') }}
```

Benefits:

- No horizontal scrolling
- Easier to spot missing brackets
- YAML still treats it as a single string

> The `>-` just tells YAML: “join these lines with spaces into one string”.

---

## 4. Numbers vs strings

JMESPath values in backticks are **typed**:

- `` `1` `` is a **number**
- `` `true` `` is a **boolean**
- `` `"1"` `` is a **string**

For most Ansible module outputs, numbers or booleans are fine:

```yaml
# state is a string
'[?state==`running`]'

# http status is a number
'[?status==`200`]'

# ready/true boolean
'[?ready==`true`]'
```

If your data contains stringified numbers like `"200"` (as a string), you must compare to a string:

```yaml
'[?status==`"200"`]'
```

But that’s rare — most modules use proper numbers.

---

## 5. Common patterns and their quoting

### Equality on strings

```yaml
json_query('[?state==`running`].name')
json_query('[?role==`db`].{name: name, ip: ip}')
```

### Equality on numbers

```yaml
json_query('[?status==`200`].item')
json_query('[?port==`5432`].name')
```

### Equality on booleans

```yaml
json_query('[?ready==`true`].name')
json_query('[?primary==`false`].ip')
```

### Multiple conditions

```yaml
json_query('[?state==`running` && zone==`a`].name')
json_query('[?state!=`running` || maintenance==`true`].name')
```

---

## 6. Quoting inside `set_fact`

The same rules apply in `set_fact`:

```yaml
- name: Running DB servers
  ansible.builtin.set_fact:
    running_db_servers: >-
      {{ servers
         | json_query('[?state==`running` && role==`db`].name') }}
```

It’s still:

- YAML key: `running_db_servers:`
- Jinja expression: `{{ ... }}`
- JMESPath string: `'[...]'` with backticks

---

## 7. Quick checklist

When something weird happens:

1. **Check YAML structure**  
   - Are you accidentally breaking the line early?
   - Is indentation correct?

2. **Check Jinja wrapping**  
   - Entire `json_query` call inside `{{ ... }}`?
   - No stray `}}` or `{% %}` nearby?

3. **Check JMESPath quotes**  
   - Expression in `'...'`?
   - Literal values in backticks `` `...` ``?

If all that looks right and you still get `null` or an empty list, the problem is usually the **path** or field names, not quoting.

---

## Next up

With quoting under control, you’re ready for real-world, complex structures where `json_query` actually saves you time.

- 👉 [Complex real-world examples](./06-complex-real-world-examples.md)
