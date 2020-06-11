#!/usr/bin/env bash
# if error
# git clone https://github.com/Jerling/Jerling.github.io public

hugo
cd public; git checkout master; git add -A ; git commit -m 'deploy'; git push origin master
cd -; git checkout backend; git add -A; git commit -m 'backend' && git push origin backend
