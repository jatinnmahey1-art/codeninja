#!/bin/bash

# QEMU WebAssembly Repository Setup Script
# This script sets up a new repository for building QEMU with WebAssembly support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME=${1:-"qemu-wasm"}
DESCRIPTION=${2:-"QEMU compiled to WebAssembly for browser-based virtualization"}
AUTHOR_NAME=${3:-"GitHub Actions"}
AUTHOR_EMAIL=${4:-"actions@github.com"}

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v node &> /dev/null; then
        missing_deps+=("node")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Please install the missing dependencies and try again."
        exit 1
    fi
    
    print_success "All dependencies are installed"
}

# Create repository structure
create_structure() {
    print_status "Creating repository structure..."
    
    # Create main directories
    mkdir -p .github/workflows
    mkdir -p docs
    mkdir -p test
    mkdir -p example
    mkdir -p scripts
    mkdir -p qemu/output
    
    # Create additional utility directories
    mkdir -p tools
    mkdir -p benchmarks
    mkdir -p configs
    
    print_success "Repository structure created"
}

# Initialize Git repository
init_git() {
    print_status "Initializing Git repository..."
    
    # Initialize git if not already initialized
    if [ ! -d .git ]; then
        git init
    fi
    
    # Configure git user if not set
    if [ -z "$(git config user.name)" ]; then
        git config user.name "$AUTHOR_NAME"
        git config user.email "$AUTHOR_EMAIL"
    fi
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# Build outputs
build/
dist/
*.o
*.a
*.so
*.dylib

# QEMU build artifacts
qemu/build-*/
qemu/output/*/
!qemu/output/.gitkeep

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Emscripten cache
emsdk-cache/
.emscripten_cache/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
.cache/

# Logs
*.log
logs/

# Environment files
.env
.env.local
.env.*.local

# Coverage
coverage/
.nyc_output/

# Test outputs
test-results/
coverage-reports/
EOF

    # Create initial commit
    git add .gitignore
    git commit -m "Initial commit: Add gitignore"
    
    print_success "Git repository initialized"
}

# Create package.json for the repository
create_package_json() {
    print_status "Creating package.json..."
    
    cat > package.json << EOF
{
  "name": "$REPO_NAME",
  "version": "1.0.0",
  "description": "$DESCRIPTION",
  "main": "index.js",
  "scripts": {
    "test": "node test/qemu-wasm.test.js",
    "test:watch": "nodemon test/qemu-wasm.test.js",
    "build": "echo 'Use GitHub Actions to build QEMU WebAssembly'",
    "clean": "rm -rf qemu/build-* qemu/output/*",
    "lint": "eslint . --ext .js",
    "validate": "npm run lint && npm run test",
    "dev": "http-server example -p 8080 -o",
    "benchmark": "node benchmarks/run-benchmarks.js"
  },
  "keywords": [
    "qemu",
    "emulator",
    "webassembly",
    "wasm",
    "virtualization",
    "browser",
    "javascript"
  ],
  "author": {
    "name": "$AUTHOR_NAME",
    "email": "$AUTHOR_EMAIL"
  },
  "license": "GPL-2.0",
  "repository": {
    "type": "git",
    "url": "."
  },
  "bugs": {
    "url": "./issues"
  },
  "homepage": "./#readme",
  "devDependencies": {
    "eslint": "^8.0.0",
    "nodemon": "^3.0.0",
    "http-server": "^14.0.0"
  },
  "engines": {
    "node": ">=14.0.0",
    "npm": ">=6.0.0"
  }
}
EOF

    print_success "package.json created"
}

# Create development configuration files
create_dev_configs() {
    print_status "Creating development configuration files..."
    
    # Create ESLint configuration
    cat > .eslintrc.js << 'EOF'
module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
  ],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module',
  },
  rules: {
    'indent': ['error', 2],
    'linebreak-style': ['error', 'unix'],
    'quotes': ['error', 'single'],
    'semi': ['error', 'always'],
    'no-unused-vars': ['warn'],
    'no-console': ['warn'],
  },
};
EOF

    # Create .editorconfig
    cat > .editorconfig << 'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.js]
indent_style = space
indent_size = 2

[*.yml]
indent_style = space
indent_size = 2

[*.yaml]
indent_style = space
indent_size = 2

[*.json]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
EOF

    # Create .npmrc
    cat > .npmrc << 'EOF'
audit=false
fund=false
progress=false
EOF

    print_success "Development configuration files created"
}

# Create utility scripts
create_utility_scripts() {
    print_status "Creating utility scripts..."
    
    # Create validate-build.js
    cat > scripts/validate-build.js << 'EOF'
#!/usr/bin/env node

/**
 * Build Validation Script
 * Validates that QEMU WebAssembly builds are working correctly
 */

const fs = require('fs');
const path = require('path');

const buildPath = path.join(__dirname, '../qemu/output');

function validateBuild() {
    console.log('🔍 Validating QEMU WebAssembly build...\n');

    if (!fs.existsSync(buildPath)) {
        console.log('❌ Build directory does not exist');
        console.log('💡 Run the GitHub Actions workflow to build QEMU WASM');
        return false;
    }

    const targets = fs.readdirSync(buildPath).filter(dir => 
        fs.statSync(path.join(buildPath, dir)).isDirectory()
    );

    if (targets.length === 0) {
        console.log('❌ No build targets found');
        return false;
    }

    console.log(`✅ Found ${targets.length} build targets:`);
    targets.forEach(target => {
        console.log(`   - ${target}`);
    });

    let allValid = true;

    for (const target of targets) {
        const targetPath = path.join(buildPath, target);
        const requiredFiles = ['qemu-wrapper.js', 'package.json'];
        
        console.log(`\n🔍 Validating ${target}...`);
        
        for (const file of requiredFiles) {
            const filePath = path.join(targetPath, file);
            if (fs.existsSync(filePath)) {
                console.log(`   ✅ ${file}`);
            } else {
                console.log(`   ❌ Missing ${file}`);
                allValid = false;
            }
        }

        // Check for WASM files
        const wasmFiles = fs.readdirSync(targetPath).filter(file => 
            file.endsWith('.wasm')
        );
        
        if (wasmFiles.length > 0) {
            console.log(`   ✅ ${wasmFiles.length} WASM file(s)`);
        } else {
            console.log(`   ❌ No WASM files found`);
            allValid = false;
        }
    }

    if (allValid) {
        console.log('\n🎉 All builds are valid!');
        return true;
    } else {
        console.log('\n💥 Some builds have issues. Please check the workflow logs.');
        return false;
    }
}

if (require.main === module) {
    const isValid = validateBuild();
    process.exit(isValid ? 0 : 1);
}

module.exports = { validateBuild };
EOF

    # Create clean-build.js
    cat > scripts/clean-build.js << 'EOF'
#!/usr/bin/env node

/**
 * Clean Build Script
 * Removes all build artifacts and cache files
 */

const fs = require('fs');
const path = require('path');

const rootPath = path.join(__dirname, '..');
const cleanPaths = [
    'qemu/build-*',
    'qemu/output/*',
    'emsdk-cache',
    '.emscripten_cache',
    'node_modules',
    'coverage',
    '.nyc_output',
    '*.log'
];

function cleanBuild() {
    console.log('🧹 Cleaning build artifacts...\n');

    cleanPaths.forEach(cleanPath => {
        const fullPath = path.join(rootPath, cleanPath);
        
        if (fs.existsSync(fullPath)) {
            try {
                if (fs.statSync(fullPath).isDirectory()) {
                    fs.rmSync(fullPath, { recursive: true, force: true });
                    console.log(`🗑️  Removed directory: ${cleanPath}`);
                } else {
                    fs.unlinkSync(fullPath);
                    console.log(`🗑️  Removed file: ${cleanPath}`);
                }
            } catch (error) {
                console.log(`⚠️  Could not remove ${cleanPath}: ${error.message}`);
            }
        } else {
            console.log(`ℹ️  Path does not exist: ${cleanPath}`);
        }
    });

    // Create empty output directory with .gitkeep
    const outputDir = path.join(rootPath, 'qemu/output');
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }
    fs.writeFileSync(path.join(outputDir, '.gitkeep'), '');
    
    console.log('\n✅ Build cleanup completed!');
}

if (require.main === module) {
    cleanBuild();
}

module.exports = { cleanBuild };
EOF

    # Make scripts executable
    chmod +x scripts/validate-build.js
    chmod +x scripts/clean-build.js

    print_success "Utility scripts created"
}

# Create benchmarks directory
create_benchmarks() {
    print_status "Creating benchmark files..."
    
    cat > benchmarks/run-benchmarks.js << 'EOF'
#!/usr/bin/env node

/**
 * QEMU WebAssembly Benchmark Suite
 * Measures performance characteristics of WASM builds
 */

const fs = require('fs');
const path = require('path');

class QEMUWASMBenchmark {
    constructor() {
        this.results = [];
        this.buildPath = path.join(__dirname, '../qemu/output');
    }

    async runAllBenchmarks() {
        console.log('🚀 Starting QEMU WebAssembly Benchmark Suite\n');

        try {
            await this.benchmarkFileSize();
            await this.benchmarkLoadTime();
            await this.benchmarkMemoryUsage();

            this.printResults();
        } catch (error) {
            console.error('❌ Benchmark suite failed:', error);
        }
    }

    async benchmarkFileSize() {
        console.log('📊 File Size Benchmark');
        
        const targets = fs.readdirSync(this.buildPath).filter(dir => 
            fs.statSync(path.join(this.buildPath, dir)).isDirectory()
        );

        for (const target of targets) {
            const targetPath = path.join(this.buildPath, target);
            const files = fs.readdirSync(targetPath);
            
            let totalSize = 0;
            let wasmSize = 0;
            let jsSize = 0;

            for (const file of files) {
                const filePath = path.join(targetPath, file);
                const stats = fs.statSync(filePath);
                const size = stats.size;
                
                totalSize += size;
                
                if (file.endsWith('.wasm')) {
                    wasmSize += size;
                } else if (file.endsWith('.js')) {
                    jsSize += size;
                }
            }

            this.results.push({
                test: `${target} File Size`,
                totalSize,
                wasmSize,
                jsSize,
                unit: 'bytes'
            });

            console.log(`   ${target}: ${(totalSize / 1024 / 1024).toFixed(2)} MB total`);
        }
    }

    async benchmarkLoadTime() {
        console.log('\n⏱️  Load Time Benchmark');

        const targets = fs.readdirSync(this.buildPath).filter(dir => 
            fs.statSync(path.join(this.buildPath, dir)).isDirectory()
        );

        for (const target of targets) {
            const wrapperPath = path.join(this.buildPath, target, 'qemu-wrapper.js');
            
            try {
                const start = process.hrtime.bigint();
                
                // Load and parse the wrapper
                delete require.cache[require.resolve(wrapperPath)];
                require(wrapperPath);
                
                const end = process.hrtime.bigint();
                const loadTime = Number(end - start) / 1000000; // Convert to milliseconds

                this.results.push({
                    test: `${target} Load Time`,
                    value: loadTime,
                    unit: 'ms'
                });

                console.log(`   ${target}: ${loadTime.toFixed(2)} ms`);
            } catch (error) {
                console.log(`   ${target}: Failed to load - ${error.message}`);
            }
        }
    }

    async benchmarkMemoryUsage() {
        console.log('\n💾 Memory Usage Benchmark');

        const beforeMemory = process.memoryUsage();

        try {
            const targets = fs.readdirSync(this.buildPath).filter(dir => 
                fs.statSync(path.join(this.buildPath, dir)).isDirectory()
            );

            for (const target of targets) {
                const wrapperPath = path.join(this.buildPath, target, 'qemu-wrapper.js');
                
                try {
                    // Load module
                    delete require.cache[require.resolve(wrapperPath)];
                    require(wrapperPath);
                    
                    const afterMemory = process.memoryUsage();
                    const memoryDelta = afterMemory.heapUsed - beforeMemory.heapUsed;

                    this.results.push({
                        test: `${target} Memory Usage`,
                        value: memoryDelta,
                        unit: 'bytes'
                    });

                    console.log(`   ${target}: ${(memoryDelta / 1024 / 1024).toFixed(2)} MB`);
                } catch (error) {
                    console.log(`   ${target}: Failed to measure memory - ${error.message}`);
                }
            }
        } catch (error) {
            console.log(`   Memory benchmark failed: ${error.message}`);
        }
    }

    printResults() {
        console.log('\n📈 Benchmark Results Summary:');
        console.log('='.repeat(60));

        this.results.forEach(result => {
            if (result.totalSize) {
                console.log(`${result.test}:`);
                console.log(`   Total: ${(result.totalSize / 1024 / 1024).toFixed(2)} MB`);
                console.log(`   WASM: ${(result.wasmSize / 1024 / 1024).toFixed(2)} MB`);
                console.log(`   JS:   ${(result.jsSize / 1024 / 1024).toFixed(2)} MB`);
            } else {
                const value = result.unit === 'ms' ? 
                    result.value.toFixed(2) : 
                    (result.value / 1024 / 1024).toFixed(2);
                console.log(`${result.test}: ${value} ${result.unit}`);
            }
        });

        console.log('='.repeat(60));
        console.log('🏁 Benchmark suite completed');
    }
}

if (require.main === module) {
    const benchmark = new QEMUWASMBenchmark();
    benchmark.runAllBenchmarks();
}

module.exports = QEMUWASMBenchmark;
EOF

    chmod +x benchmarks/run-benchmarks.js

    print_success "Benchmark files created"
}

# Create GitHub templates
create_github_templates() {
    print_status "Creating GitHub templates..."
    
    mkdir -p .github/ISSUE_TEMPLATE
    mkdir -p .github/pull_request_template
    
    # Issue template for build failures
    cat > .github/ISSUE_TEMPLATE/build-failure.md << 'EOF'
---
name: Build Failure
about: Report a build failure with the QEMU WebAssembly workflow
title: '[BUILD FAILURE] '
labels: bug, build-failure
assignees: ''
---

## Build Information

- **Workflow Run**: [Link to failed workflow]
- **Branch/Tag**: 
- **Commit Hash**: 
- **Target Architecture**: 
- **Build Configuration**: 

## Error Description

Describe what went wrong during the build process.

## Error Logs

Please paste the relevant error logs here.

```log
[Paste error logs here]
```

## Steps to Reproduce

1. 
2. 
3. 

## Expected Behavior

What should have happened during the build.

## Additional Context

Any additional information that might be helpful.
EOF

    # Issue template for feature requests
    cat > .github/ISSUE_TEMPLATE/feature-request.md << 'EOF'
---
name: Feature Request
about: Suggest a new feature for the QEMU WebAssembly build
title: '[FEATURE] '
labels: enhancement, feature-request
assignees: ''
---

## Feature Description

Describe the feature you would like to see implemented.

## Use Case

Explain why this feature would be useful.

## Proposed Solution

Describe how you think this feature should be implemented.

## Alternatives Considered

Describe any alternative solutions you've considered.

## Additional Context

Any additional information or context about the feature request.
EOF

    # Pull request template
    cat > .github/pull_request_template.md << 'EOF'
## Description

Describe the changes made in this pull request.

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Other (please describe)

## Testing

Describe how you tested these changes:

- [ ] Workflow runs successfully
- [ ] Generated WASM files are valid
- [ ] JavaScript wrapper works correctly
- [ ] Manual testing completed

## Checklist

- [ ] Code follows the project's style guidelines
- [ ] Self-review of the code completed
- [ ] Documentation updated if necessary
- [ ] Tests added or updated
- [ ] Build workflow tested

## Additional Notes

Any additional information or context.
EOF

    print_success "GitHub templates created"
}

# Create security and policy files
create_security_files() {
    print_status "Creating security and policy files..."
    
    # Security policy
    cat > SECURITY.md << 'EOF'
# Security Policy

## Supported Versions

Only the latest version of QEMU WebAssembly is actively maintained and supported.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it privately before disclosing it publicly.

### How to Report

- Send an email to: security@example.com
- Use the subject: "Security Vulnerability Report"
- Include detailed information about the vulnerability
- Provide steps to reproduce if possible

### Response Time

- We will acknowledge receipt within 48 hours
- We will provide a detailed response within 7 days
- We will aim to patch critical vulnerabilities within 30 days

### What to Include

- Type of vulnerability
- Affected versions
- Potential impact
- Reproduction steps
- Any additional relevant information

## Security Best Practices

When using QEMU WebAssembly, follow these security practices:

1. **Use HTTPS**: Always serve WebAssembly files over HTTPS
2. **Validate Input**: Sanitize all user inputs
3. **Memory Limits**: Set appropriate memory limits
4. **Regular Updates**: Keep dependencies updated
5. **Monitor Usage**: Monitor for unusual activity

## Known Security Considerations

- WebAssembly runs in a browser sandbox
- Memory usage should be monitored
- File system access is restricted
- Network access requires explicit configuration
EOF

    # Code of conduct
    cat > CODE_OF_CONDUCT.md << 'EOF'
# Contributor Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socioeconomic status,
nationality, personal appearance, race, religion, or sexual identity
and orientation.

## Our Standards

Examples of behavior that contributes to creating a positive environment
include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention or
  advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or electronic
  address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

## Our Responsibilities

Project maintainers are responsible for clarifying the standards of acceptable
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct, or to ban temporarily or
permanently any contributor for other behaviors that they deem inappropriate,
threatening, offensive, or harmful.

## Scope

This Code of Conduct applies within all project spaces, and it also applies when
an individual is representing the project or its community in public spaces.
Examples of representing a project or community include using an official
project e-mail address, posting via an official social media account, or acting
as an appointed representative at an online or offline event.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported to the project team at conduct@example.com. All
complaints will be reviewed and investigated and will result in a response that
is deemed necessary and appropriate to the circumstances. The project team is
obligated to maintain confidentiality with regard to the reporter of an
incident. Further details of specific enforcement policies may be posted
separately.

Project maintainers who do not follow or enforce the Code of Conduct in good
faith may face temporary or permanent repercussions as determined by other
members of the project's leadership.
EOF

    print_success "Security and policy files created"
}

# Create final setup instructions
create_setup_instructions() {
    print_status "Creating setup instructions..."
    
    cat > SETUP.md << 'EOF'
# QEMU WebAssembly Setup Instructions

This guide will help you set up the QEMU WebAssembly build system in your repository.

## Quick Setup

1. **Run the setup script:**
   ```bash
   ./scripts/setup-repo.sh
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Test the setup:**
   ```bash
   npm test
   ```

## Manual Setup

If you prefer to set up manually:

### 1. Repository Structure

Create the following directory structure:

```
.github/
├── workflows/
│   ├── build-wasm.yml
│   └── test-wasm.yml
docs/
├── workflow-configuration.md
└── ...
test/
├── qemu-wasm.test.js
└── ...
example/
├── index.html
└── ...
scripts/
├── setup-repo.sh
├── validate-build.js
└── clean-build.js
benchmarks/
└── run-benchmarks.js
```

### 2. Configuration Files

Copy the configuration files from the template:

- `package.json`
- `.gitignore`
- `.eslintrc.js`
- `.editorconfig`
- `README.md`

### 3. GitHub Actions

The workflows will automatically run when:
- Code is pushed to main/develop branches
- Pull requests are opened
- Tags are pushed (for releases)
- Manually triggered

### 4. Environment Setup

No additional environment setup is required. The GitHub Actions workflow handles all dependencies including:
- Emscripten SDK
- QEMU source code
- Build tools
- Optimization tools

## Verification

### Validate Repository Setup

```bash
# Check repository structure
npm run validate

# Validate build artifacts (after running workflow)
node scripts/validate-build.js
```

### Run Tests

```bash
# Run all tests
npm test

# Run with file watching
npm run test:watch
```

### Run Benchmarks

```bash
# Performance benchmarks
npm run benchmark
```

## Common Issues

### Workflow Not Running

1. Check that GitHub Actions is enabled in your repository
2. Verify the workflow files are in `.github/workflows/`
3. Check YAML syntax with `yamllint`

### Build Failures

1. Check the workflow logs for specific errors
2. Verify Emscripten version compatibility
3. Check QEMU source repository availability

### Local Development

1. Install Node.js 14+ and npm
2. Run `npm install` for dependencies
3. Use `npm run dev` to serve the example

## Next Steps

1. **Push to GitHub** to trigger the first build
2. **Review build logs** to ensure everything works
3. **Customize configuration** as needed
4. **Add custom tests** for your specific use case
5. **Set up releases** for automated deployments

## Support

- Check the [documentation](docs/)
- Review [workflow configuration](docs/workflow-configuration.md)
- Create an issue for problems
- Join our community discussions
EOF

    print_success "Setup instructions created"
}

# Main setup function
main() {
    print_status "Setting up QEMU WebAssembly repository..."
    print_status "Repository name: $REPO_NAME"
    print_status "Description: $DESCRIPTION"
    print_status ""
    
    # Run all setup functions
    check_dependencies
    create_structure
    init_git
    create_package_json
    create_dev_configs
    create_utility_scripts
    create_benchmarks
    create_github_templates
    create_security_files
    create_setup_instructions
    
    print_success ""
    print_success "🎉 Repository setup completed!"
    print_success ""
    print_status "Next steps:"
    print_status "1. Review and customize the configuration files"
    print_status "2. Commit the changes to Git"
    print_status "3. Push to GitHub to trigger the first build"
    print_status "4. Check the Actions tab for build progress"
    print_status ""
    print_status "Useful commands:"
    print_status "  npm install          # Install dependencies"
    print_status "  npm test             # Run tests"
    print_status "  npm run dev          # Start development server"
    print_status "  npm run benchmark    # Run performance benchmarks"
    print_status ""
    print_success "Happy building! 🚀"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
