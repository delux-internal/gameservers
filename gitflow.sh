#!/bin/bash
echo "Initing C.TF git flow..."
echo "stable
unstable
feature/
release/
hotfix/
support/
v." | git flow init
