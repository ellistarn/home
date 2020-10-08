#!/bin/bash -exu

cd ~
git init
git checkout -b main
git remote add origin git@github.com:ellistarn/home.git
git pull
