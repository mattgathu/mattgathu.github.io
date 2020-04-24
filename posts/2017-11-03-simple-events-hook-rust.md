---
layout: post
title: "simple event hooks in Rust"
date: November 3, 2017
categories:
- rust
- code
description: 'how to implement a simple events hook system in Rust using the Observer Pattern'
keywords: rust, pub-sub, events hook, event driven programming
author: Matt
---

## What

The **observer pattern** is a software design pattern in which an object, called the subject, maintains
a list of its dependents, called observers, and notifies them automatically of any state changes,
usually by calling one of their methods. [1][1]

**Event hooks** (or callbacks) are a simple way of implementing the observer pattern where a the
subject notifies the observers when certain events occurs.

## Why

Event hooks can be used to implement event-driven programming, where the flow of the program is 
determined by events such as user actions, sensor outputs, or  messages from other programs/threads.[2][2]

## How

We use Rust's [traits][3] feature to define the expected behaviour of our events interface. The
trait will contain the event hooks that the event handlers are supposed to implement.

The use of trait makes our event handlers to be generic (they can be of any type), all that will be
required of them is to have an implementation of the trait.

For illustration, I'll implement an event-driven Logger that records tcp connection events.

Below is a trait that implements an events interface for a tcp socket communication

```rust
#[allow(unused_variables)]
pub trait Events {
    fn on_connect(&self, host: &str, port: i32) {}
    fn on_error(&self, err: &str) {}
    fn on_read(&self, resp: &[u8]) {}
    fn on_shutdown(&self) {}
    fn on_pre_read(&self) {}
    fn on_post_read(&self) {}
}
```

Then, a simple **Logger** struct implements the trait as follows

```rust
struct Logger;

impl Events for Logger {
    fn on_connect(&self, host: &str, port: i32) {
        println!("Connected to {} on port {}", host, port);
    }

    fn on_error(&self, err: &str) {
        println!("error: {}", err);
    }

    fn on_read(&self, resp: &[u8]) {
        print!("{}", str::from_utf8(resp).unwrap());
    }

    fn on_shutdown(&self) {
        println!("Connection closed.");
    }

    fn on_pre_read(&self) {
        println!("Receiving content:\n");
    }

    fn on_post_read(&self) {
        println!("\nFinished receiving content.")
    }
}
```
The **Logger** acts as the Observer that gets notified when events occur.

Next, we have a **HttpClient** struct that does some tcp network calls and notifies its registered hooks
(observers) when the events occurs.

```rust
struct HttpClient {
    host: String,
    port: i32,
    hooks: Vec<Box<Events>>,
}

impl HttpClient {
    pub fn new(host: &str, port: i32) -> Self {
        Self {
            host: host.to_owned(),
            port: port,
            hooks: Vec::new(),
        }
    }

    pub fn add_events_hook<E: Events + 'static>(&mut self, hook: E) {
        self.hooks.push(Box::new(hook));
    }

    pub fn get(&self, endpoint: &str) {
        let cmd = format!("GET {} HTTP/1.1\r\nHost: {}\r\n\r\n", endpoint, self.host).into_bytes();
        let mut socket = self.connect().unwrap();
        socket.write(cmd.as_slice()).unwrap();
        socket.flush().unwrap();
        for hook in &self.hooks {
            hook.on_pre_read();
        }
        loop {
            let mut buf = vec![0; 512usize];
            let cnt = socket.read(&mut buf[..]).unwrap();
            buf.truncate(cnt);
            if !buf.is_empty() {
                for hook in &self.hooks {
                    hook.on_read(buf.as_slice());
                }
            } else {
                for hook in &self.hooks {
                    hook.on_post_read();
                }
                break;
            }
        }
        for hook in &self.hooks {
            hook.on_shutdown();
        }

    }

    pub fn connect(&self) -> io::Result<TcpStream>{
        let addr = format!("{}:{}", self.host, self.port);
        match TcpStream::connect(addr) {
            Ok(stream) => {
                for hook in &self.hooks {
                    hook.on_connect(&self.host, self.port);
                }
                Ok(stream)
            },
            Err(error) => {
                for hook in &self.hooks {
                    hook.on_error(error.description());
                }
                Err(error)
            },
        }

    }
}
```

The **HttpClient** struct implements a **add_events_hook** method that is used to register the events handlers.

To piece all together, we have a **main** function that:
* initializes the **HttpClient** struct.
* registers the **Logger** has an event hooks handler for **HttpClient**
* makes a network call using **HttpClient**. This results in the **Logger** receiving events.

```rust
fn main() {
    let mut  http_stream = HttpClient::new("httpbin.org", 80);
    http_stream.add_events_hook(Logger);
    http_stream.get("/ip");
}
```

The **Logger** will log the events to the terminal:

```
Connected to httpbin.org on port 80
Receiving content:

HTTP/1.1 200 OK
Connection: keep-alive
Server: meinheld/0.6.1
Date: Fri, 03 Nov 2017 09:16:40 GMT
Content-Type: application/json
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
X-Powered-By: Flask
X-Processed-Time: 0.000749111175537
Content-Length: 33
Via: 1.1 vegur

{
  "origin": "212.22.171.150"
}

Finished receiving content.
Connection closed.
```
Voila! That's a simple implementation of event hooks in Rust. The complete code can be found
[here](https://gist.github.com/mattgathu/73712cb7399834d6f8162d641830cbb7)

## Footnotes

There is a lot of event driven work being done using Rust and here are some interesting projects
that you can check out:
* [mio][4] -  a lightweight I/O library for Rust. 
* [ws-rs][5] - Lightweight, event-driven WebSockets for Rust.
* [tokio-core][6] - I/O primitives and event loop for async I/O in Rust

## References

1. <https://en.wikipedia.org/wiki/Observer_pattern>
2. <https://en.wikipedia.org/wiki/Event-driven_programming>
3. <https://doc.rust-lang.org/book/second-edition/ch10-02-traits.html>
4. <https://doc.rust-lang.org/book/second-edition/ch19-03-advanced-traits.html>
5. <https://doc.rust-lang.org/std/net/struct.TcpStream.html>
6. <https://github.com/seanmonstar/reqwest/issues/155>

[1]: https://en.wikipedia.org/wiki/Observer_pattern
[2]: https://en.wikipedia.org/wiki/Event-driven_programming
[3]: https://doc.rust-lang.org/book/second-edition/ch10-02-traits.html
[4]: https://github.com/carllerche/mio
[5]: https://github.com/housleyjk/ws-rs
[6]: https://github.com/tokio-rs/tokio-core
