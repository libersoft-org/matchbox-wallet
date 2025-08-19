# Install Bun for JavaScript/TypeScript building
echo "Setting up Bun runtime..."
if ! command -v bun >/dev/null 2>&1; then
 echo "Installing Bun..."
 curl -fsSL https://bun.sh/install | bash || {
  echo "Failed to install Bun."
  exit 1
 }
 # Add bun to PATH for current session
 export PATH="$HOME/.bun/bin:$PATH"
fi

# Build JavaScript bundle for embedded Node runtime
if [ -d "src/js" ]; then
 echo "Building JavaScript/TypeScript bundle..."
 (cd src/js && bun install) || {
  echo "bun install failed in src/js"
  exit 1
 }
 (cd src/js && bun run build) || {
  echo "JavaScript build failed"
  exit 1
 }
 # Verify bundle was created
 if [ ! -f "src/js/dist/bundle.cjs" ]; then
  echo "ERROR: JavaScript bundle was not created!"
  exit 1
 fi
 BUNDLE_SIZE=$(du -h src/js/dist/bundle.cjs | cut -f1)
 echo "✅ JavaScript bundle created: src/js/dist/bundle.cjs ($BUNDLE_SIZE)"
fi
