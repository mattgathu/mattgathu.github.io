---
layout: post
title: "Rust Compiler Lints"
date: January 16, 2019
categories:
- rust
- code
description: 'an overview of the Rust compiler lints'
keywords: rust, compiler, lint
author: Matt
---

## What
The Rust compiler allows to enable or disable various lints during code compilation. This
is a short overview of these lints.

**TLDR:** The quickest way to discover these lints is to have the compiler list them.

```shell
$ rustc -W help
```

## Why
Lints are useful for various use cases:
* preventing bugs by catching common gotchas such as unused variables.
* enforcing coding standards such as having documentation. 
* relaxing compiler defaults that might not fit your use case e.g. allowing use of CamelCase

The above list is not exhaustive but gives an ideas of where linting is applicable.

## How
The Rust compiler lints are categorised into four levels:
* allow
* warn
* deny
* forbid

These are pretty self-explanatory. The compiler with either stay silent, issue an warning or throw
an error. The extra `forbid` level is same as deny but cannot be overridden.

How do you configure these lint levels? There are a couple of ways:
* **via compiler flags**

    Running `rustc -W help` on your terminal will, among other things, show you how to set lint
    levels:
    ```shell
    Available lint options:
    -W <foo>           Warn about <foo>
    -A <foo>           Allow <foo>
    -D <foo>           Deny <foo>
    -F <foo>           Forbid <foo> (deny <foo> and all attempts to override)
    ```
* **via attributes**

    You can also have attributes, such as `#![warn(missing_docs)]`, in your `lib.rs` file.

The compiler can also set the maximum level of all lints using the `--cap-lints` flag. e.g. 
```shell
$ rustc --cap-lints warn
```

There is a list of lints that the compiler allows, warns and denies by default. The help command
`rustc -W help` lists out all lints with their corresponding default level.

## Reference
- <https://doc.rust-lang.org/rustc/lints/index.html>
