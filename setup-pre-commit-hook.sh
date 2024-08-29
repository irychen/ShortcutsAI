#!/bin/sh

# Ensure we are in the root directory of the git repository
cd "$(git rev-parse --show-toplevel)"

# Path to the pre-commit hook
HOOKS_DIR=".git/hooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

# Create the hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Add the pre-commit hook script
cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/sh

# Execute swiftformat
echo "Running SwiftFormat..."
swiftformat .

# Check if swiftformat made any changes
if [ -n "$(git status --porcelain)" ]; then
  echo "SwiftFormat made changes. Adding the changes to commit..."
  git add -u
fi

exit 0
EOF

# Ensure the pre-commit hook is executable
chmod +x "$PRE_COMMIT_HOOK"

# Check if swiftformat is installed
if ! command -v swiftformat &> /dev/null; then
  echo "SwiftFormat not found. Installing via Homebrew..."
  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Please install Homebrew first."
    exit 1
  fi
  brew install swiftformat
else
  echo "SwiftFormat is already installed."
fi

echo "pre-commit hook has been set up successfully."
