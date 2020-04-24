---
layout: post
title: "Python Multiprocess Logging"
date: April 23, 2015
categories:
- code
keywords: multiprocessing, logging, python
description: 'python multiprocess logging'
author: Matt
---

This post marks the culmination of my journey (read struggle) trying to
leverage a common logging for several concurrent processes.

Single threaded logging is pretty straight forward,you instantiate a logger,
create a handler for it and add the handler and voila, a basic logger.

```python
def create_logger(name):
    """Create a logger

    args: name (str): name of logger

    returns: logger (obj): logging.Logger instance
    """
    logger = logging.getLogger(name)
    fmt = logging.Formatter('%(asctime)s - %(name)s -'
                            ' %(levelname)s -%(message)s')
    hdl = logging.FileHandler(name+'.log')
    hdl.setFormatter(fmt)

    logger.addHandler(hdl)

    return logger
```

I used a filehandler in the code snippet since it will present a challenge when
you execute the script in a multiprocessing environment.

What you ideally envision is that processes will log to a single log file, which is true,
however each process operate in it's own sandboxed environment and there is the
possibility of two processes writing to the log file at the same time which could lead to file corruption.

For you to use a single log file across several processes, your need a form of
log synchronization for all the logs, enter
[queues](http://en.wikipedia.org/wiki/Queue_%28abstract_data_type%29). The
concept of a queue is pretty straight forward, it's first-in-first-out (FIFO)
data structure. It will act as a bridge between the processes and the log file.
A log entry is enqueued to the queue and the queue is in turn dequeued and the
entry written to the file.
A custom handler with a queue is implemented.

```python
import sys
import logging
import traceback
import threading
import multiprocessing
from logging import FileHandler as FH


# ============================================================================
# Define Log Handler
# ============================================================================
class CustomLogHandler(logging.Handler):
    """multiprocessing log handler

    This handler makes it possible for several processes
    to log to the same file by using a queue.

    """
    def __init__(self, fname):
        logging.Handler.__init__(self)

        self._handler = FH(fname)
        self.queue = multiprocessing.Queue(-1)

        thrd = threading.Thread(target=self.receive)
        thrd.daemon = True
        thrd.start()

    def setFormatter(self, fmt):
        logging.Handler.setFormatter(self, fmt)
        self._handler.setFormatter(fmt)

    def receive(self):
        while True:
            try:
                record = self.queue.get()
                self._handler.emit(record)
            except (KeyboardInterrupt, SystemExit):
                raise
            except EOFError:
                break
            except:
                traceback.print_exc(file=sys.stderr)

    def send(self, s):
        self.queue.put_nowait(s)

    def _format_record(self, record):
        if record.args:
            record.msg = record.msg % record.args
            record.args = None
        if record.exc_info:
            dummy = self.format(record)
            record.exc_info = None

        return record

    def emit(self, record):
        try:
            s = self._format_record(record)
            self.send(s)
        except (KeyboardInterrupt, SystemExit):
            raise
        except:
            self.handleError(record)

    def close(self):
        self._handler.close()
        logging.Handler.close(self)
```

The logging configuration for the custom handler in yaml.

```yaml
version: 1
disable_existing_loggers: False
formatters:
    simple:
        format: "%(asctime)s %(levelname)s %(message)s"
handlers:
    clog:
        class: CustomLogHandler
        level: INFO
        formatter: simple
        fname: logs/cplog.log
root:
    level: DEBUG
    handlers: [clog]
```

In the main a process, a root logger with the config in created
and this will be inherited by the child processes.

```
logger = logging.getLogger(__name__)
config = yaml.load(open('logging.yaml').read())
logging.config.dictConfig(config)
```

The child process creates a root logger and and logs will pass
through the custom handler and be synchronized by the queue.

For the complete picture checkout this
[gist](https://gist.github.com/JesseBuesking/10674086) by [Jesse
Buesking](http://jessebuesking.com/)
