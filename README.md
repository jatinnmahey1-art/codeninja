# QEMU WebAssembly Build System

This repository contains a comprehensive GitHub Actions workflow for building QEMU with WebAssembly support, generating `.js` and `.wasm` files that can run in browsers and Node.js environments.

## 🚀 Features

- **Multi-architecture Support**: Builds QEMU for i386 and x86_64 targets
- **WebAssembly Optimization**: Optimized WASM output for browser performance
- **Automated Releases**: Automatic GitHub releases for tagged versions
- **Comprehensive Testing**: Built-in testing and validation
- **Caching**: Intelligent caching for faster builds
- **JavaScript Wrapper**: Easy-to-use JavaScript interface

## 📋 Requirements

- GitHub repository with GitHub Actions enabled
- No additional setup required - workflow handles all dependencies

## 🛠️ Workflow Overview

### Main Workflow (`build-wasm.yml`)

The main workflow automatically triggers on:
- Push to `main`, `master`, or `develop` branches
- Pull requests to these branches
- Manual workflow dispatch
- Tagged releases (for automatic releases)

### Jobs

1. **build-wasm**: Compiles QEMU to WebAssembly
   - Sets up Emscripten SDK
   - Configures QEMU for WASM compilation
   - Optimizes output files
   - Creates JavaScript wrapper
   - Uploads build artifacts

2. **release**: Creates GitHub releases (tags only)
   - Downloads all build artifacts
   - Creates release archives
   - Generates release notes
   - Publishes to GitHub releases

3. **test**: Validates WebAssembly build
   - Tests module loading
   - Validates file structure
   - Checks syntax correctness

### Test Workflow (`test-wasm.yml`)

Additional workflow for testing and validation:
- Weekly scheduled tests
- Syntax validation
- Emscripten functionality tests
- Workflow structure validation

## 📦 Build Outputs

For each target architecture, the workflow generates:

```
qemu-{target}-wasm/
├── qemu-system-{arch}.js       # Main QEMU JavaScript module
├── qemu-system-{arch}.wasm     # WebAssembly binary
├── qemu-system-{arch}.data     # Data files (if any)
├── qemu-wrapper.js             # JavaScript wrapper class
└── package.json                # NPM package configuration
```

### Available Targets

- `i386-softmmu`: 32-bit x86 system emulation
- `x86_64-softmmu`: 64-bit x86 system emulation

## 🔧 Usage

### Using the JavaScript Wrapper

```javascript
import QEMUJS from './qemu-wrapper.js';

// Initialize QEMU
const qemu = new QEMUJS();
await qemu.initialize();

// Start emulation
await qemu.start({
  memory: '256M',
  cpu: 'i386',
  drives: [
    { file: 'disk.img', format: 'raw', interface: 'ide' }
  ]
});

// Check status
console.log(qemu.getStatus());

// Stop emulation
qemu.stop();
```

### Using in Node.js

```javascript
const QEMUJS = require('./qemu-wrapper.js');

// Same API as browser usage
const qemu = new QEMUJS();
await qemu.start();
```

### Using in HTML

```html
<!DOCTYPE html>
<html>
<head>
    <script src="qemu-wrapper.js"></script>
</head>
<body>
    <script>
        const qemu = new QEMUJS();
        qemu.start().then(() => {
            console.log('QEMU started in browser!');
        });
    </script>
</body>
</html>
```

## 🏗️ Build Configuration

### Emscripten Flags

The workflow uses optimized Emscripten flags:

- `-s WASM=1`: Enable WebAssembly output
- `-s ALLOW_MEMORY_GROWTH=1`: Dynamic memory allocation
- `-s MAXIMUM_MEMORY=2GB`: Maximum memory limit
- `-s INITIAL_MEMORY=256MB`: Initial memory allocation
- `-O3`: Aggressive optimization
- `-flto --llvm-lto 3`: Link-time optimization

### QEMU Configuration

QEMU is configured with minimal dependencies for WebAssembly:

- Disabled: GUI, network, graphics, audio, etc.
- Enabled: Core emulation functionality
- Optimized: Small binary size and fast execution

## 🔄 Manual Build Trigger

You can manually trigger builds with custom parameters:

1. Go to the "Actions" tab in your GitHub repository
2. Select "Build QEMU for WebAssembly" workflow
3. Click "Run workflow"
4. Choose your preferred options:
   - Target architecture (i386-softmmu, x86_64-softmmu, etc.)
   - Size optimization preference

## 📊 Performance Optimization

### WebAssembly Optimization

The workflow includes several optimization steps:

1. **Compiler Optimizations**: `-O3` with link-time optimization
2. **WASM Optimizations**: `wasm-opt` for further size reduction
3. **Tree Shaking**: Removal of unused code
4. **Memory Management**: Configurable memory limits

### Size Optimization

To reduce file size:
- Disabled unnecessary QEMU features
- Used aggressive compiler optimizations
- Applied WASM-specific optimizations
- Compressed release archives

## 🚨 Troubleshooting

### Common Issues

1. **Build Timeout**: Increase job timeout or reduce parallelism
2. **Memory Issues**: Adjust `-s MAXIMUM_MEMORY` flag
3. **Feature Missing**: Enable additional QEMU configuration flags
4. **Browser Compatibility**: Test with different browsers

### Debug Builds

For debugging, modify the workflow to use:
- `-O0` instead of `-O3` (no optimization)
- `-g` for debug symbols
- `-s ASSERTIONS=1` for runtime checks

## 📈 Monitoring

### Build Metrics

The workflow provides:
- Build time tracking
- File size reporting
- Memory usage statistics
- Success/failure rates

### Artifacts

Build artifacts are retained for:
- 30 days for regular builds
- Forever for releases
- 7 days for test builds

## 🤝 Contributing

### Adding New Targets

1. Update the build matrix in `build-wasm.yml`
2. Add target-specific configuration
3. Update documentation
4. Test the new target

### Modifying Build Flags

1. Edit the `--extra-cflags` and `--extra-ldflags` sections
2. Test with different optimization levels
3. Validate output functionality

## 📄 License

This workflow configuration follows the same license as QEMU (GPL-2.0). The generated WebAssembly binaries inherit the same licensing terms.

## 🔗 Related Projects

- [QEMU.js](https://github.com/atrosinenko/qemujs) - Original QEMU WebAssembly port
- [Emscripten](https://emscripten.org/) - C++ to WebAssembly compiler
- [WebAssembly](https://webassembly.org/) - Official WebAssembly website

## 📞 Support

For issues with:
- **This workflow**: Create an issue in this repository
- **QEMU functionality**: Refer to [QEMU documentation](https://www.qemu.org/docs/master/)
- **Emscripten issues**: Check [Emscripten issues](https://github.com/emscripten-core/emscripten/issues)

---

## 🗺️ Development Roadmap

### Planned Features

- [ ] Additional target architectures (ARM, RISC-V)
- [ ] Docker-based build environment
- [ ] Automated performance benchmarking
- [ ] Progressive Web App template
- [ ] Cloud deployment integration

### Contributions Welcome

Feel free to submit pull requests for:
- Bug fixes
- Performance improvements
- New target support
- Documentation updates
- Test improvements