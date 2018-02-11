# IC XML Format documentation

In this file I will describe XML schema for Fertilizer Control specialization. In shema I'll be using this symbols with this meaning:

* `( x | y )` - this means, that script using x OR y - not both at same time
* `[xyz=""]` - means that attribute is not required and default value is no set
* `[xyz="abc"]` - optional attribute with default value
* `[xyz="" abc="xyz"]` - list of optional attributes - if you fill one you must fill other
* `xyz=""//type` - means that attribute has type `type`
* Also whole tag can be optional
* Everything outside of [] breackets is required and without propper filling script will not work!

```xml
<!-- XML schema documentation -->
<>
```

You can read how to setup each part in [this document](./featuresSetup.md).
