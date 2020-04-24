---
layout: post
title: "Why Rust uses Return Values for errors instead of Exceptions"
date: August 4th, 2018
categories:
- rust
- code
- quote
description: 'why rust uses return values instead of exceptions'
keywords: rust, posts, error handling, model, error
author: Matt
---

I was up asking myself why error handling in Rust uses return values istead of exceptions and I
found this explanation that I'm quoting here for my future self.


> Some people need to use Rust in places where exceptions aren't allowed (because the unwind 
> tables and cleanup code are too big). Those people include virtually all browser vendors and game developers.
> Furthermore, exceptions have this nasty codegen tradeoff. Either you make them zero-cost 
> (as C++, Obj-C, and Swift compilers typically do), in which case throwing an exception is 
> very expensive at runtime, or you make them non-zero-cost (as Java HotSpot and Go 6g/8g do), 
> in which case you eat a performance penalty for every single try block (in Go, defer) even 
> if no exception is thrown. For a language with RAII, every single stack object with a destructor 
> forms an implicit try block, so this is impractical in practice.
>
>
> The performance overhead of zero-cost exceptions is not a theoretical issue. I remember stories 
> of Eclipse taking 30 seconds to start up when compiled with GCJ (which used zero-cost exceptions) 
> because it throws thousands of exceptions while starting.
>
>
> The C approach to error handling has a great performance and code size story relative to exceptions 
> when you consider both the error and success paths, which is why systems code overwhelmingly prefers it. 
> It has poor ergonomics and safety, however, which Rust addresses with Result. Rust's approach 
> forms a hybrid that's designed to achieve the performance of C error handling while eliminating its gotchas.
>
> ~ pcwalton

