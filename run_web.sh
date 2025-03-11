#!/bin/bash -eu

./build_web.sh
cd docs
python3 -m http.server
