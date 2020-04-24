#!/usr/bin/env bash

echo "Publishing.."
cargo run
cp -r site/* .
rm -r site
git add .
git commit --no-verify -m "Update"
git push origin
echo "Done!"
