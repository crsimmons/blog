#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage is $0 name"
  exit 1
fi

name=$1

this_dir="$( cd "$( dirname "${0}" )" && pwd )"
posts_dir="${this_dir}/../_posts"

kebab_name="${name// /-}"
today="$(date -u +%Y-%m-%d)"

cat << EOF > "${posts_dir}/${today}-${kebab_name}.md"
---
layout: post
title:
date: $today
categories:
---
EOF
