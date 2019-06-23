#!/usr/bin/env bash

hugo && cd public && git add -A && git commit -m 'deploy' && git push -u origin master
cd - && git push origin backen
