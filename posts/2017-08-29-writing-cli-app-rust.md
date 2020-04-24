---
layout: post
title: "Writing a Command Line Tool in Rust"
image: '/assets/img/cli.png'
date: August 29, 2017
categories:
- rust
- code
description: 'how to write a command line tool using the rust programming language.'
keywords: rust, cli, command line tools, programming, clap, indicatif 
author: Matt
---

![cli-help-menu][cli]

## What

[Rust](https://www.rust-lang.org/en-US/) is a systems programming language that enables you to
write fast, safe and concurrent code. It fits in the same niche as C and C++ but provides a fresh
breath of features and convenience that makes writing programs in it fun.

[Command Line Tools](https://en.wikipedia.org/wiki/Command-line_interface) are programs designed to
be executed in a terminal (command line) interface. They are synonymous with Unix programming where
they are often called shell tools. An example is the `ls` command used to list directories.


We are going to cover how to write a command line tool using Rust by writing a simple clone of the
popular `wget` tool used for file downloads.

## Why

The aim here is to get started writing command line tools in Rust programming language also use some wonderful
crates (community libraries) that make writing CLI programs a breeze.


## How

Our simple `wget` clone will have the following features which a desirable in a command line tool:
* **Argument parsing**
* **Colored Output**
* **Progress bar**

### Project Setup

We use rust's build tool (and package manager)
[Cargo](https://doc.rust-lang.org/book/second-edition/ch01-02-hello-world.html#hello-cargo) to setup our project skeleton.

```bash
cargo new rget --bin
```

This creates a new project called `rget` and the `--bin` option tells cargo we are building an
executable and not a library. A folder is generated with the following structure.

```bash
$ cd rget
$ tree .
.
├── Cargo.toml
└── src
    └── main.rs

1 directory, 2 files
```

`Cargo.toml` is a manifest file and our code will live under the `src` directory, in `main.rs`

### Argument Parsing

We will use the [clap](https://crates.io/crates/clap) crate for parsing command line arguments. We
add to our project by updating cargo's manifest file dependecies section.

```toml
[package]
name = "rget"
version = "0.1.0"
authors = ["Matt Gathu <mattgathu@gmail.com>"]

[dependencies]
clap = "2.26.0"
```
We then update our **main** function in `main.rs` to perform argument parsing.

```rust
extern crate clap;

use clap::{Arg, App};

fn main() {
    let matches = App::new("Rget")
        .version("0.1.0")
        .author("Matt Gathu <mattgathu@gmail.com>")
        .about("wget clone written in Rust")
        .arg(Arg::with_name("URL")
                 .required(true)
                 .takes_value(true)
                 .index(1)
                 .help("url to download"))
        .get_matches();
    let url = matches.value_of("URL").unwrap();
    println!("{}", url);
}
```

We can now test our argument parser using Cargo.

`cargo run`

```bash
    Finished dev [unoptimized + debuginfo] target(s) in 0.0 secs
     Running `target/debug/rget`
error: The following required arguments were not provided:
    <URL>

USAGE:
    rget <URL>

For more information try --help
```

We can pass arguments to our program by adding `--` when calling `cargo run`

`cargo run -- -h`

```bash
    Finished dev [unoptimized + debuginfo] target(s) in 0.0 secs
     Running `target/debug/rget -h`
Rget 0.1.0
Matt Gathu <mattgathu@gmail.com>
wget clone written in Rust

USAGE:
    rget <URL>

FLAGS:
    -h, --help       Prints help information
    -V, --version    Prints version information

ARGS:
    <URL>    url to download
```

### Progress bar and colored output

[indicatif](https://crates.io/crates/indicatif) is a rust library for indicating 
progress in command line applications. We use it to implement a progress bar and a spinner for our wget clone. 

indicatif relies on another crate, [console](https://crates.io/crates/console) and uses it for colored output.
we'll always leverage console and use it to print out colored text.

Below is the function for creating the progress bar:

```rust
fn create_progress_bar(quiet_mode: bool, msg: &str, length: Option<u64>) -> ProgressBar {
    let bar = match quiet_mode {
        true => ProgressBar::hidden(),
        false => {
            match length {
                Some(len) => ProgressBar::new(len),
                None => ProgressBar::new_spinner(),
            }
        }
    };

    bar.set_message(msg);
    match length.is_some() {
        true => bar
            .set_style(ProgressStyle::default_bar()
                .template("{msg} {spinner:.green} [{elapsed_precise}] [{wide_bar:.cyan/blue}] {bytes}/{total_bytes} eta: {eta}")
                .progress_chars("=> ")),
        false => bar.set_style(ProgressStyle::default_spinner()),
    };

    bar
}
```

The function has several arguments and creates a progress bar based on their value. We use Rust's
[pattern matching](https://doc.rust-lang.org/book/second-edition/ch06-02-match.html) feature to
match the arguments to the desired progress bar.

### Cloning wget's logic

We use the [reqwest](https://crates.io/crates/reqwest) crate for implement file download function
that receives a url and downloads it into a local file.

The download function will also update the progress bar when each chunk of the file is downloaded
and also print out colored text with the download's metadata. This behaviour will be similar to
wget's.

Here's a code snippet showing the download function:

```rust
fn download(target: &str, quiet_mode: bool) -> Result<(), Box<::std::error::Error>> {

    // parse url
    let url = parse_url(target)?;
    let client = Client::new().unwrap();
    let mut resp = client.get(url)?
        .send()
        .unwrap();
    print(format!("HTTP request sent... {}",
                  style(format!("{}", resp.status())).green()),
          quiet_mode);
    if resp.status().is_success() {

        let headers = resp.headers().clone();
        let ct_len = headers.get::<ContentLength>().map(|ct_len| **ct_len);

        let ct_type = headers.get::<ContentType>().unwrap();

        match ct_len {
            Some(len) => {
                print(format!("Length: {} ({})",
                      style(len).green(),
                      style(format!("{}", HumanBytes(len))).red()),
                    quiet_mode);
            },
            None => {
                print(format!("Length: {}", style("unknown").red()), quiet_mode); 
            },
        }

        print(format!("Type: {}", style(ct_type).green()), quiet_mode);

        let fname = target.split("/").last().unwrap();

        print(format!("Saving to: {}", style(fname).green()), quiet_mode);

        let chunk_size = match ct_len {
            Some(x) => x as usize / 99,
            None => 1024usize, // default chunk size
        };

        let mut buf = Vec::new();

        let bar = create_progress_bar(quiet_mode, fname, ct_len);

        loop {
            let mut buffer = vec![0; chunk_size];
            let bcount = resp.read(&mut buffer[..]).unwrap();
            buffer.truncate(bcount);
            if !buffer.is_empty() {
                buf.extend(buffer.into_boxed_slice()
                               .into_vec()
                               .iter()
                               .cloned());
                bar.inc(bcount as u64);
            } else {
                break;
            }
        }

        bar.finish();

        save_to_file(&mut buf, fname)?;
    }

    Ok(())

}
```


The `download` function takes a target url, parses it to generate a filename and uses the
`Content-Length` HTTP header to determine the size of the file. It generates a colored progress bar and
downloads the file in chunks. Once each chunk is received, the progress bar is updated to show
progress. 

Once the full download is complete, the file contents are save to a file.

## Recap

Writing CLI tools in Rust is quite easy. Argument parsing can be done using the `clap` crate,
progress bars generated using the `indicatif` crate and colored output using the `console` crate.
The `cargo` build tool also makes it a breeze to build and run our code.

You can find the full implementation of the `wget` clone my [github](https://github.com/mattgathu/rget).


[cli]: /images/cli.png