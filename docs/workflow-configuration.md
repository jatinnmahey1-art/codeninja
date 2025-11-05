# QEMU WebAssembly Workflow Configuration Guide

This document provides detailed information about configuring and customizing the QEMU WebAssembly GitHub Actions workflow.

## 📁 File Structure

```
.github/
├── workflows/
│   ├── build-wasm.yml      # Main build workflow
│   └── test-wasm.yml       # Test and validation workflow
docs/
├── workflow-configuration.md  # This file
└── ...
example/
├── index.html             # Demo HTML page
└── ...
test/
├── qemu-wasm.test.js      # Test suite
└── ...
README.md                 # Main documentation
```

## ⚙️ Main Workflow Configuration

### Triggers

The main workflow (`build-wasm.yml`) triggers on:

```yaml
on:
  push:
    branches: [ main, master, develop ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main, master, develop ]
  workflow_dispatch:
    inputs:
      qemu_target:
        description: 'QEMU target architecture'
        required: false
        default: 'i386-softmmu'
        type: choice
        options:
          - 'i386-softmmu'
          - 'x86_64-softmmu'
          - 'arm-softmmu'
          - 'aarch64-softmmu'
```

### Environment Variables

```yaml
env:
  EM_VERSION: 3.1.58              # Emscripten SDK version
  EM_CACHE_FOLDER: 'emsdk-cache'  # Cache directory name
  QEMU_VERSION: '8.2.0'          # QEMU source version
  BUILD_TYPE: 'Release'          # Build configuration
```

### Build Matrix

The workflow uses a build matrix for multiple targets:

```yaml
strategy:
  matrix:
    target:
      - 'i386-softmmu'
      - 'x86_64-softmmu'
    include:
      - target: 'i386-softmmu'
        arch: 'i386'
        config_flags: '--target-list=i386-softmmu'
      - target: 'x86_64-softmmu'
        arch: 'x86_64'
        config_flags: '--target-list=x86_64-softmmu'
```

## 🔧 Customization Options

### Adding New Target Architectures

To add a new target architecture:

1. **Update the build matrix:**

```yaml
strategy:
  matrix:
    target:
      - 'i386-softmmu'
      - 'x86_64-softmmu'
      - 'arm-softmmu'          # New target
    include:
      - target: 'arm-softmmu'
        arch: 'arm'
        config_flags: '--target-list=arm-softmmu'
```

2. **Add target-specific configuration if needed:**

```yaml
- target: 'arm-softmmu'
  arch: 'arm'
  config_flags: '--target-list=arm-softmmu'
  extra_cflags: '-mcpu=cortex-a15'  # ARM-specific optimizations
```

### Modifying Emscripten Flags

The WebAssembly compilation flags are defined in the `--extra-cflags` and `--extra-ldflags`:

```bash
--extra-cflags="-s WASM=1 -s EXPORTED_RUNTIME_METHODS=[...] -s ALLOW_MEMORY_GROWTH=1 -s MAXIMUM_MEMORY=2GB -s INITIAL_MEMORY=256MB -O3 -flto --llvm-lto 3 -msimd128 -mbulk-memory -mmutable-globals -msign-ext"
```

#### Common Modifications

**For better optimization:**
```bash
-O3 -flto --llvm-lto 3 -msimd128 -mbulk-memory
```

**For debugging:**
```bash
-O0 -g -s ASSERTIONS=1 -s SAFE_HEAP=1
```

**For smaller size:**
```bash
-Oz -s AGGRESSIVE_VARIABLE_ELIMINATION=1 -s ELIMINATE_DUPLICATE_FUNCTIONS=1
```

**For better performance:**
```bash
-O3 -s WASM_ASYNC_COMPILATION=0 -s EXIT_RUNTIME=1
```

### Memory Configuration

Memory settings can be adjusted based on your needs:

```bash
-s INITIAL_MEMORY=256MB    # Starting memory
-s MAXIMUM_MEMORY=2GB      # Maximum memory limit
-s ALLOW_MEMORY_GROWTH=1   # Enable dynamic memory growth
```

### QEMU Configuration Options

The QEMU configure command includes many disabled features to reduce size. To enable additional features:

```bash
../configure \
  ${{matrix.config_flags}} \
  --enable-feature-name \     # Enable specific feature
  --disable-other-feature \    # Disable other features
  ...
```

#### Common Features to Enable

```bash
# Network support
--enable-slirp \
--enable-netmap \

# Storage support
--enable-libnfs \
--enable-libiscsi \

# Graphics (minimal)
--enable-vnc \
--disable-vnc-sasl \
```

## 🚦 Performance Tuning

### Build Performance

**Parallel builds:**
```yaml
BUILD_JOBS=$(nproc)  # Use all available cores
```

**Caching strategy:**
```yaml
# Cache Emscripten SDK
- name: Setup Emscripten cache
  uses: actions/cache@v4
  with:
    path: ${{env.EM_CACHE_FOLDER}}
    key: ${{env.EM_VERSION}}-${{runner.os}}-emscripten

# Cache system libraries
- name: Setup system libraries cache
  uses: actions/cache@v4
  with:
    path: |
      ${{github.workspace}}/build
      ~/.emscripten_cache
    key: libs-${{env.EM_VERSION}}-${{runner.os}}-${{matrix.target}}
```

### WebAssembly Performance

**Optimization levels:**
- `-O0`: No optimization (fastest compile, largest size)
- `-O1`: Basic optimization
- `-O2`: Standard optimization
- `-O3`: Aggressive optimization (recommended)
- `-Oz`: Size optimization
- `-Os`: Balance size and speed

**Link-time optimization:**
```bash
-flto --llvm-lto 3
```

**SIMD support:**
```bash
-msimd128 -mbulk-memory -mmutable-globals -msign-ext
```

## 🔍 Advanced Configuration

### Custom Build Steps

Add custom steps before or after the main build:

```yaml
- name: Custom pre-build step
  run: |
    echo "Custom preparation"
    # Your custom commands

- name: Build QEMU for WebAssembly
  run: |
    # Main build commands

- name: Custom post-build step
  run: |
    echo "Custom post-processing"
    # Your custom commands
```

### Conditional Builds

Use conditions to control when steps run:

```yaml
- name: Debug build
  if: github.event_name == 'pull_request'
  run: |
    echo "Running debug build for PR"

- name: Release build
  if: startsWith(github.ref, 'refs/tags/v')
  run: |
    echo "Running release build for tag"
```

### Secrets and Environment Variables

Use secrets for sensitive data:

```yaml
- name: Deploy with secrets
  if: startsWith(github.ref, 'refs/tags/v')
  env:
    DEPLOY_TOKEN: ${{secrets.DEPLOY_TOKEN}}
  run: |
    echo "Deploying with token"
```

## 🐛 Troubleshooting

### Common Build Issues

**1. Out of Memory**
```yaml
# Increase available memory
env:
  NODE_OPTIONS: '--max-old-space-size=4096'
```

**2. Build Timeout**
```yaml
# Increase job timeout
jobs:
  build-wasm:
    timeout-minutes: 120  # 2 hours
```

**3. Cache Issues**
```yaml
# Clear cache if needed
- name: Clear problematic cache
  run: |
    rm -rf ~/.emscripten_cache
```

### Debugging Builds

**Enable verbose output:**
```bash
emmake make VERBOSE=1 -j${BUILD_JOBS}
```

**Check intermediate files:**
```bash
# List build artifacts
find . -name "*.o" -o -name "*.a" | head -20

# Check configuration
cat config.log | grep -i error
```

### WebAssembly Debugging

**Enable debugging symbols:**
```bash
-s ASSERTIONS=1 -g -s SAFE_HEAP=1
```

**Check generated JavaScript:**
```bash
# View generated JS
head -50 qemu-system-i386.js

# Check for errors
node --check qemu-system-i386.js
```

## 📊 Monitoring and Metrics

### Build Metrics Collection

Add metrics collection to your workflow:

```yaml
- name: Collect build metrics
  run: |
    # Measure build time
    BUILD_TIME=$(date +%s)
    
    # Run build
    emmake make -j${BUILD_JOBS}
    
    # Calculate duration
    BUILD_DURATION=$(($(date +%s) - BUILD_TIME))
    echo "Build duration: ${BUILD_DURATION}s"
    
    # Measure output size
    OUTPUT_SIZE=$(du -sh . | cut -f1)
    echo "Output size: ${OUTPUT_SIZE}"
```

### Performance Monitoring

Create performance benchmarks:

```yaml
- name: Performance benchmarks
  run: |
    # Test WASM loading time
    time node -e "require('./qemu-wrapper.js')"
    
    # Test module initialization
    node -e "
    const QEMUJS = require('./qemu-wrapper.js');
    const start = Date.now();
    const qemu = new QEMUJS();
    console.log('Initialization time:', Date.now() - start, 'ms');
    "
```

## 🔗 Integration with Other Tools

### Docker Integration

For more reproducible builds, consider using Docker:

```yaml
- name: Build in Docker
  run: |
    docker run --rm \
      -v ${{github.workspace}}:/workspace \
      -w /workspace \
      emscripten/emsdk:${{env.EM_VERSION}} \
      emmake make -j$(nproc)
```

### NPM Package Publishing

Automatically publish to NPM:

```yaml
- name: Publish to NPM
  if: startsWith(github.ref, 'refs/tags/v')
  run: |
    cd qemu/output/${{matrix.target}}
    npm publish
  env:
    NPM_TOKEN: ${{secrets.NPM_TOKEN}}
```

### CDN Deployment

Deploy to a CDN for global distribution:

```yaml
- name: Deploy to CDN
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{secrets.GITHUB_TOKEN}}
    publish_dir: qemu/output
```

## 📚 Best Practices

1. **Use specific versions** for Emscripten and QEMU
2. **Implement comprehensive caching** to speed up builds
3. **Add thorough testing** for each target
4. **Monitor build performance** and optimize regularly
5. **Document customizations** for future reference
6. **Use semantic versioning** for releases
7. **Implement proper error handling** and reporting
8. **Test on multiple browsers** for compatibility

---

For additional help or questions, refer to the main [README.md](../README.md) or create an issue in the repository.
