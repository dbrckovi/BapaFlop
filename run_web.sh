#!/bin/bash -eu

./build_web.sh
cd build/web
python3 -m http.server
