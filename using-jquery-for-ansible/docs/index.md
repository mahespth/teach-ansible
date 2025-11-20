# Using "jquery" in Ansible (a.k.a. `json_query` / JMESPath)

If you've ever stared at a huge Ansible variable dump and thought:

> "I just want a list of names out of this… why is this so hard?"

…this site is for you.

When people say *"jquery in Ansible"*, they almost always mean the **`json_query`** filter – a JMESPath expression used inside Jinja2. It’s incredibly powerful for slicing and dicing complex JSON/YAML data, but the syntax trips people up constantly.

This mini-site walks through `json_query` from first principles to real-world horror shows:

1. Start with simple selections
2. Move through filters & projections
3. End with deep, nested data that looks like a bowl of spaghetti

Each page includes:

- **Raw data** (what your registered variable actually looks like)
- **Goal** (what we want to extract)
- **`json_query` expression**
- **Ansible example** (cut-and-paste play snippet)

---

## Who is this for?

- Ansible users who already know basic Jinja templating
- People consuming APIs, cloud modules, or network modules that return massive JSON structures
- Anyone who has ever written `debug: var=some_var` and regretted it

If you’ve used `map(attribute=...)` and normal Jinja filters but hit a wall with more complex data, learning `json_query` is the next step.

---

## About the author

**Steve Maher** is a DevOps engineer specialising in infrastructure with Ansible.  
This guide comes from real-world experience untangling messy data structures in automation platforms and turning them into something predictable and reusable.

---

## Prerequisites

To follow along you should:

- Know how to run a simple Ansible playbook
- Be comfortable with basic Jinja syntax like `{{ my_var }}` and `{{ my_list[0].name }}`

You **don’t** need to know JMESPath already. We’ll build it up a piece at a time.

> 💡 Tip: In the Ansible documentation and code, the correct name is `json_query`. We deliberately use the phrase *"jquery for Ansible"* in the title because many people search for it that way.

---

## Start here

- 👉 [What is `json_query` and when should I use it?](./01-what-is-json-query.md)
