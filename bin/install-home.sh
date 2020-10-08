#!/bin/bash -exu

cd ~
git init
git remote add origin git@github.com:ellistarn/home.git
git fetch origin
git reset --hard origin/main
