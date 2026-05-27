#!/usr/bin/env bash
set -euo pipefail

for repo in "$@"; do
  imgs=$(aws ecr list-images --repository-name "$repo" --query 'imageIds[*]' --output json 2>/dev/null || echo "[]")
  if [ "$imgs" != "[]" ] && [ -n "$imgs" ]; then
    aws ecr batch-delete-image --repository-name "$repo" --image-ids "$imgs" >/dev/null
    echo ":: emptied $repo"
  else
    echo ":: $repo already empty"
  fi
done
