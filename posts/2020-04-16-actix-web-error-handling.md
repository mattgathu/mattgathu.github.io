---
layout: post
title: "Actix Web Error Handling"
date: April 16, 2020
categories:
- rust
- code
description: 'a crafty way for error handling in actix-web'
keywords: rust, compiler, lint
author: Matt
---


[Actix web][1] is one of the most popular web frameworks written in [Rust][2].
It is an async actor-based framework that prioritizes type safety, extensibility and speed.

Error handling in Actix is achieved using two things: It's own [Error type][3] and a [ResponseError][4] trait
that allows you to send back your custom error as an [HttpResponse][7].

Below is a simple contrived example of Actix's Error type in action.

```rust
use actix_web::{get, web, App, Error, HttpResponse, HttpServer};
use std::io::Read;

#[get("/file/{file_name}")]
async fn get_file(file_name: web::Path<String>) -> Result<HttpResponse, Error> {
    let mut s = String::new();
    std::fs::File::open(file_name.into_inner())?.read_to_string(&mut s)?;
    Ok(HttpResponse::Ok().body(s))
}

#[actix_rt::main]
async fn main() -> std::io::Result<()> {
   
    HttpServer::new(move || {
        App::new()
            .service(get_file)
    })
    .bind("0.0.0.0:80")?
    .run()
    .await
}
```

Anything that implements stdlib's [Error][5] can be propagated up to an Actix Error using the `?` syntax.
Actix will then generate a generic HttpResponse with the body being the error message. In the above example
Actix is even smart enough to infer Status Codes from the the io::Error kind, e.g. returning a `404 Not Found` when
the error kind is `io::ErrorKind::NotFound `. 

We however generally should avoid using this generic interface since it tends to expose a service's internals to its clients. 
For example if the file operation in the example is part of a larger request handling logic then it won't make sense for the
client when they get a `404 Not Found` response. This is typically true for most web services as errors can arise from multiple sources such as databases, filesystems, Oses and other apis used by the services.

Another reason to avoid this generic approach is when you would like to send a structured error response to the clients. This can
be a json response that has a defined format for errors such as:
```json
{
    "code": 404,
    "error": "NotFound",
    "message": "Requested file: `missing_file.ext` was not found"
}
```

Actix's [ResponseError][4] trait provides us with a way to provide a unified error response and to also avoid exposing
the service's internals to the client.

The way to achieve this is threefold:
- Define a custom error type that implements the `ResponseError` trait.
- Map all of internal errors to our custom error.
- Force actix to only return our custom error.

When we transform the contrived example to this new approach, we end up with:

```rust
use actix_web::{get, web, App, HttpResponse, HttpServer, error::ResponseError, http::StatusCode};
use std::io::Read;

use serde::{Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
enum CustomError {
    #[error("Requested file was not found")]
    NotFound,
    #[error("You are forbidden to access requested file.")]
    Forbidden,
    #[error("Unknown Internal Error")]
    Unknown
}
impl CustomError {
    pub fn name(&self) -> String {
        match self {
            Self::NotFound => "NotFound".to_string(),
            Self::Forbidden => "Forbidden".to_string(),
            Self::Unknown => "Unknown".to_string(),
        }
    }
}
impl ResponseError for CustomError {
    fn status_code(&self) -> StatusCode {
        match *self {
            Self::NotFound  => StatusCode::NOT_FOUND,
            Self::Forbidden => StatusCode::FORBIDDEN,
            Self::Unknown => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn error_response(&self) -> HttpResponse {
        let status_code = self.status_code();
        let error_response = ErrorResponse {
            code: status_code.as_u16(),
            message: self.to_string(),
            error: self.name(),
        };
        HttpResponse::build(status_code).json(error_response)
    }
}

fn map_io_error(e: std::io::Error) -> CustomError {
    match e.kind() {
        std::io::ErrorKind::NotFound => CustomError::NotFound,
        std::io::ErrorKind::PermissionDenied => CustomError::Forbidden,
        _ => CustomError::Unknown,
    }
}

#[derive(Serialize)]
struct ErrorResponse {
    code: u16,
    error: String,
    message: String,
}

#[get("/file/{file_name}")]
async fn get_file(file_name: web::Path<String>) -> Result<HttpResponse, CustomError> {
    let mut s = String::new();
    std::fs::File::open(file_name.to_string()).map_err(map_io_error)?.read_to_string(&mut s).map_err(map_io_error)?;
    Ok(HttpResponse::Ok().body(s))
}

#[actix_rt::main]
async fn main() -> std::io::Result<()> {
   
    HttpServer::new(move || {
        App::new()
            .service(get_file)
    })
    .bind("0.0.0.0:80")?
    .run()
    .await
}
```

We use the excellent [thiserror][6] crate to derive the `Error` trait for our `CustomError` enum.

We then implement the `ResponseError` trait for CustomError and map the io Errors.

We change the request handler's return type from `Result<HttpResponse, Error>` to `Result<HttpResponse, CustomError>`
and this ensures the all the errors returned are part of our CustomError enum. This return type constraining is
what guarantees that we never leak the service internals to the client when an error occurs.

Skipping the `map_err` on one of the io errors will result in a compilation error:

```
`?` couldn't convert the error to `CustomError`

the trait `std::convert::From<std::io::Error>` is not implemented for `CustomError`
```

Now whenever an error is encountered the service will return a formatted json response, such as:

```json
{
    "code":403,
    "error":"Forbidden",
    "message":"You are forbidden to access requested file."
}
```

[1]: https://actix.rs/
[2]: https://www.rust-lang.org/
[3]: https://docs.rs/actix-web/2/actix_web/error/struct.Error.html
[4]: https://docs.rs/actix-web/2/actix_web/error/trait.ResponseError.html
[5]: https://doc.rust-lang.org/stable/std/error/trait.Error.html
[6]: https://docs.rs/thiserror/1.0.15/thiserror/
[7]: https://docs.rs/actix-web/2.0.0/actix_web/struct.HttpResponse.html