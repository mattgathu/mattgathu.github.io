---
layout: post
title: "Python Decorators Reuse"
date: April 26, 2015
categories:
- code
keywords: python, decorators, decorator, function, retry
description: 'python decorators reuse'
author: Matt
---

A python [decorator](https://docs.python.org/3.4/glossary.html#term-decorator)
is a function (or class) that returns another function usually after applying
some transformation to it. Common examples of decorators are classmethod() and
staticmethod().

Decorators have a barrage of uses ranging from memoization, profiling, access
control to function timeouts. There is a collection of these and other decorator
code pieces [here](https://wiki.python.org/moin/PythonDecoratorLibrary).

I have found myself mostly using decorators for retry and occasionally
timeouts for network centric operations. Normally I would have a single
decorator function that deals with particular exception and does several
retries before re-raising the exception.

Here is an example.

```python
import time
from functools import wraps
from http.client import BadStatusLine

def if_http_errors_retry(func):
    """Decorator: retry calling function func in case of http.client errors.

    Decorator will try to call, the function three times, with a ten seconds
    delay between them. If the retries get maxed out, the decorator will raise
    the http error.

    args:
        func (function): function to be decorated.

    returns:
        func (function): decorated function

    """
    @wraps(func)
    def wrapper(*args, **kwargs):
        """func wrapper"""
        error = Exception
        for _ in range(3):
            try:
                return func(*args, **kwargs)
            except BadStatusLine as err:
                error = err
                time.sleep(10)
                continue
        raise error

    return wrapper
```

Looking keenly at the above decorator, you will realise that it bears some
design flaws:

<b>You can't specify the amount of time delay: it's hard coded</b>

<b>You can't specifiy the number of retries: it's hard coded</b>

<b>It's hard to generalize the decorator for another exception without entirely
    duplicating it</b>


After noting how much my code stinks I decided to refactor it and deal with the
three issues above. The motivation for this mainly came when I saw this retry template.

```python
def auto_retry(n=3, exc=Exception):
    for i in range(n):
        try:
            yield None
            return
            except exc, err:
                # perhaps log exception here
                continue
    raise # re-raise the exception we caught earlier
```

It's not a decorator at all but it had all the three qualities that my decorator
lacked and it gave me a basis for me to start exploring.

It turns out refactoring the decorator was pretty easy.

```python
import time
from functools import wraps
from http.client import BadStatusLine

def auto_retry(tries=3, exc=Exception, delay=5):
    def deco(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for _ in range(tries):
                try:
                    return func(*args, **kwargs)
                except exc:
                    time.sleep(delay)
                    continue
            raise exc
        return wrapper
    return deco

# decorating

@auto_retry(tries=3, exc=BadStatusLine, delay=5)
def network_call():
    # some code using http.client

```
Voila, now I have a very flexible retry decorator that can  be applied on any
type of exception, time delay and number of retries.

The key to achieving this is having a function (auto_retry) that returns a
decorator function (deco) which will in turn decorates a function (func).
Thanks to the power of [closures] the parameters passed to the high order
function (auto_retry) are also available to the nested functions and are
used for the control flow within them.

[closures]: http://en.wikipedia.org/wiki/Closure_(computer_programming
