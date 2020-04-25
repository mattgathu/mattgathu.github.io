#!/usr/bin/env bash

echo "drafting.."
cargo run
cp -r site/* .
echo "Done!"
