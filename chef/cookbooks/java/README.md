Java Cookbook
============
Install and manages open jdk

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

e.g.
#### operating systems
- Redhat
- Debian

Attributes
----------

Usage
-----
#### java::default

Just include `java` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[java]"
  ]
}
```

License and Authors
-------------------
Authors: Ashrith
