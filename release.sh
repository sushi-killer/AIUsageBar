#!/bin/bash
set -euo pipefail

PBXPROJ="AIUsageBar.xcodeproj/project.pbxproj"

usage() {
  echo "Usage: $0 <version>"
  echo "Example: $0 1.2.0"
  exit 1
}

# Validate args
[ $# -eq 1 ] || usage
VERSION="$1"

# Validate semver
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Error: Version must be semver (e.g. 1.2.0)"
  exit 1
fi

# Must run from repo root
if [ ! -f "$PBXPROJ" ]; then
  echo "Error: Run from repository root (AIUsageBar.xcodeproj not found)"
  exit 1
fi

# Ensure clean working tree
if ! git diff --quiet HEAD 2>/dev/null; then
  echo "Error: Working tree is not clean. Commit or stash changes first."
  exit 1
fi

echo "Releasing v$VERSION..."

# Update MARKETING_VERSION in pbxproj
sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $VERSION/" "$PBXPROJ"

# Commit and tag
git add "$PBXPROJ"
git commit -m "chore: bump version to $VERSION"
git tag "v$VERSION"

echo ""
echo "Version $VERSION tagged."
echo "Push to trigger CI release:"
echo "  git push origin main --tags"
