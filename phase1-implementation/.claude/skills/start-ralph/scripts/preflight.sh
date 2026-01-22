#!/bin/bash
# Preflight checks for Ralph orchestration
# Phase 1: Basic checks only

set -e

echo "Running Ralph preflight checks..."

# Check git is installed
if ! command -v git &> /dev/null; then
  echo "❌ ERROR: git not found"
  echo "   Install git: https://git-scm.com/downloads"
  exit 1
fi

echo "✓ Git installed: $(git --version | head -1)"

# Check repository is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ ERROR: Repository has uncommitted changes"
  echo "   Commit or stash changes before starting Ralph"
  git status --short
  exit 1
fi

echo "✓ Repository clean"

# Check OpenCode is installed
if ! command -v opencode &> /dev/null; then
  echo "❌ ERROR: opencode not found"
  echo "   Install OpenCode: https://opencode.ai"
  exit 1
fi

echo "✓ OpenCode installed: $(opencode --version 2>&1 | head -1 || echo 'unknown version')"

# Check config file exists
if [ ! -f ".autoralph/config.yaml" ]; then
  echo "❌ ERROR: .autoralph/config.yaml not found"
  echo "   Create config file first"
  exit 1
fi

echo "✓ Config file exists"

# Check work ledger exists
if [ ! -f ".autoralph/work_ledger.json" ]; then
  echo "❌ ERROR: .autoralph/work_ledger.json not found"
  echo "   Create work ledger first"
  exit 1
fi

echo "✓ Work ledger exists"

# Check dev branch exists
if ! git show-ref --verify --quiet refs/heads/dev; then
  echo "❌ ERROR: dev branch does not exist"
  echo "   Create dev branch: git checkout -b dev"
  exit 1
fi

echo "✓ Dev branch exists"

echo ""
echo "✅ All preflight checks passed"
echo ""
