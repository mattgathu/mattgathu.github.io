---
layout: post
title: "Why Functional Programming Matters (paper review)"
image: ''
date: August 06, 2017
categories:
- reviews
- papers
description: ''
author: Matt
---

![functional-love](https://imgs.xkcd.com/comics/functional.png)

## What

> In this paper we show that two features of
> functional languages in particular, higher-order functions and lazy evaluation,
> can contribute greatly to modularity. ~ John Hughes

Modular Programming is a key technique in successful software design and all major programming
languages have a notion of component based engineering. 
Functional programming has contributed a lot in enhancing modular software design by providing
features such as high order functions and lazy evaluation that have pushed back on the conceptual
limits of conventional languages on the ways problems can be modularised.

["Why Functional Programming Matters"](https://github.com/papers-we-love/papers-we-love/blob/master/paradigms/functional_programming/why-functional-programming-matters.pdf) 
is a late 80s paper by John Hughes that portrays the
importance of functional programming moreso where modularisation is key:

> This paper is an attempt to demonstrate to the “real world” that functional
> programming is vitally important, and also to help functional programmers
> exploit its advantages to the full by making it clear what those advantages are.

## Why

![haskell](https://imgs.xkcd.com/comics/haskell.png)

> Such a catalogue of “advantages” is all very well, but one must not be surprised
> if outsiders don’t take it too seriously. It says a lot about what functional
> programming is not (it has no assignment, no side effects, no flow of control) but
> not much about what it is.

Perhaps the biggest motivation for this paper could have been to provide an adequate characterisation of
functional programming and argue that it supports the development of reusable software
way better than conventional programming paradigms.

Hughes gives a great analogy of functional programming with structured programming, and shows how FP
strives beyond structured programming by enabling greater modularity and supporting _"programming in
the large"_

> It is helpful to draw an analogy between functional and structured programming.
> In the past, the characteristics and advantages of structured programming have
> been summed up more or less as follows. Structured programs contain no goto
> statements. Blocks in a structured program do not have multiple entries or exits.
> Structured programs are more tractable mathematically than their unstructured
> counterparts. These “advantages” of structured programming are very similar in
> spirit to the “advantages” of functional programming we discussed earlier.

## Whom, when, where

Why functional programming matters, was published in 1989 in the _Computer Journal_ by [John
Hughes](http://www.cse.chalmers.se/~rjmh/) as a professor at  Chalmers University of Technology. 
He had however originally written it in 1984 as a post-doc.

> I wrote the paper in 1984 as a post-doc, but misjudged its significance completely. 
> I thought it would be unpublishable, because it contained no difficult research results, 
> just a manifesto and some nice programming examples. So I circulated it privately to friends, 
> who passed it on to others, and soon I found it turning up in the most unexpected places. 
> Finally, after five years, I was invited to submit it to the Computer Journal. [link]


## How

As examples of the application of high-order functions and lazy-evaluation, the paper covers several
topics:

### Lists and Trees manipulation.

Use of high-order functions and recursive patterns is used to illustrate how simple modularizations
can be re-used to implement more complex functionality.

### Numerical algorithms

The Newton-Raphson Square Roots algorithm is implemented in a modular fashion using lazy
evalaution.

> This program is indivisible in conventional languages. We will express it in a
> more modular form using lazy evaluation, and then show some other uses to
> which the parts may be put.

Numerical differentiation and integration implementations are also illustrated using lazy
evaluation.

### Alpha-beta heuristic, an AI algorithm

> We have argued that functional languages are powerful primarily because they
> provide two new kinds of glue: higher-order functions and lazy evaluation. In
> this section we take a larger example from Artificial Intelligence and show how
> it can be programmed quite simply using these two kinds of glue.

The paper implements the alpha-beta heurisitc, an algorithm for estimating how good a position a
game player is in. The algorithm works by looking ahead to see how the game might develop, but
avoids pursuing unprofitable plays. It's used to predict favourable positions.

## Recap

"Why Functional Programming Matters" argues that modularity is key to successful programming. It
illustrates how functional programming eases modularisation and composability way
better than conventional languages. To this end, it gives examples of lists and trees manipulation,
numerical algorithms and an artificial intelligence algorithm applications.

[link]: http://www.cse.chalmers.se/~rjmh/citations/my_most_influential_papers.htm
