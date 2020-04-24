---
layout: post
title: "Python Context Managers"
image: ''
date: February 06, 2017
categories:
- code
description: ''
author: Matt
---

## What

A context manager, in Python, is a resource  acquisition and release mechanism that prevents
resource leak and ensures startup and cleanup (exit) actions are always  done.

A resource is basically a computing component with limited availability e.g. files, network sockets
etc. The act of refusing to release a resource when a process has finished using it is known as a
*resource leak*. An example would be leaving a file open after writing into it, thereby making it
impossible for other processes to acquire it.


## Why

The main motivation behind context managers is to ease resource management by providing support
for resource acquisition and release. This introduces to several advantages:

* eliminates the need of repeating resource acquisition/release code fragments: the DRY
      principle.
* prevent errors arounds resource management.
* eases code refactoring: this is a consequence of DRY principle.
* makes resource cleanup easier: by guarranteeing startup (entry) and cleanup (exit) actions.


## Whom, when, where

Context managers became a feature of the Python standard library with the  acceptance of [PEP 343 --
The "with" statement](https://www.python.org/dev/peps/pep-0343/) on 27 June 2005 and was implemented in a beta version of Python 2.5.

PEP 343, written by Guido van Rossum and Nick Coghlan, brought together ideas and concepts that had
been proposed in other PEPs (that were rejected in favour of 343):

* [PEP 340](https://www.python.org/dev/peps/pep-0340/), Anonymous Block Statements
* [PEP 310](https://www.python.org/dev/peps/pep-0310/), Reliable Acquisition/Release Pairs
* [PEP 346](https://www.python.org/dev/peps/pep-0346/), User Defined ("with") Statements
* [PEP 319](https://www.python.org/dev/peps/pep-0319/), Python Synchronize/Asynchronize Block

A *with* statement uses the syntax:

```python
with EXPR as VAR:
    BLOCK
```

Where _with_ and _as_ are keywords, _EXPR_ is an arbitrary expression and _VAR_ is a single
assignment target.


## How

A context manager is expected to implement *`__enter__()`* and *`__exit__()`* methods that are invoked on
entry to and exit from the body of the *with* statement. These methods are known as the _"context
management protocol"_.

The translation of the *with* statement syntax is:

```python
mgr = (EXPR)
exit = type(mgr).__exit__
value = type(mgr).__enter__(mgr) # entry method invoked
exc = True
try:
    try:
        VAR = value  # Only if "as VAR" is present
        BLOCK
    except:
        # The exceptional case is handled here
        exc = False
        if not exit(mgr, *sys.exc_info()):
            raise
        # The exception is swallowed if exit() returns true
finally:
    # The normal and non-local-goto cases are handled here
    if exc:
        exit(mgr, None, None, None) # exit method invoked
```

Example of a context manager would look like this:

```python
class Locked:
    def __init__(self, lock):
        self.lock = lock

    def __enter__(self):
        self.lock.acquire()

    def __exit__(self, type, value, tb):
        self.lock.release()
```

Where special state needs to be preserved, a generator-based template can be used:

```python
class GeneratorContextManager(object):

    def __init__(self, gen):
        self.gen = gen

    def __enter__(self):
        try:
            return self.gen.next()
        except StopIteration:
            raise RuntimeError("generator did not yield")

    def __exit__(self, type, value, traceback):
        if type is None:
            try:
                self.gen.next()
            except StopIteration:
                return
            else:
                raise RuntimeError("generator did not stop")
        else:
            try:
                self.gen.throw(type, value, traceback)
                raise RuntimeError("generator did not stop after throw()")
            except StopIteration:
                return True
            except:
                if sys.exc_info()[1] is not value:
                    raise

class contextmanager(func):
    def helper(*args, **kwargs):
        return GeneratorContextManager(func(*args, **kwargs))
    return helper
```

This decorator could be used as follows:

```python
@contextmanager
def openfile(fname):
    f = open(fname)
    try:
        yield f
    finally:
        f.close()
```

A robust implementation of this decorator is available as part of the [contextlib](https://docs.python.org/3/library/contextlib.html)
module of the standard library which provides utilities for common tasks involving the `with` statement.

Some types in the standard library can be identified as context managers, that is, they are already
endowed with the `__enter__()` and `__exit__()` methods. They include:

- file
- thread.LockType
- threading.Lock
- threading.RLock
- threading.Condition
- threading.Semaphore

Thus the Pythonic way of working with files is usually:

```python
with open('filename') as myfile:
    do_something(myfile)
```
This ensures the file is closed after the `do_something` block is exited.


## Recap

Python context managers are meant to make resource management painless, they are used in conjunction with the builtin `with` statement. There were as a result of several Python Enhancement Proposals (PEPs) and there is a `contextlib` module in the standard library that provides utilities for common context management tasks.
