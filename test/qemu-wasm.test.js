/**
 * Test Suite for QEMU WebAssembly Build
 * Validates the generated WebAssembly modules and JavaScript wrapper
 */

const fs = require('fs');
const path = require('path');

class QEMUWASMTester {
    constructor() {
        this.testResults = [];
        this.buildPath = path.join(__dirname, '../qemu/output');
    }

    /**
     * Run all tests
     */
    async runAllTests() {
        console.log('🧪 Starting QEMU WebAssembly Test Suite\n');

        try {
            await this.testFileStructure();
            await this.testJavaScriptSyntax();
            await this.testWebAssemblyFiles();
            await this.testPackageJSON();
            await this.testWrapperFunctionality();
            await this.testMemoryConstraints();
            await this.testPerformance();

            this.printResults();
            return this.testResults.every(test => test.passed);
        } catch (error) {
            console.error('❌ Test suite failed:', error);
            return false;
        }
    }

    /**
     * Test file structure and existence
     */
    async testFileStructure() {
        this.addTest('File Structure Check', async () => {
            const requiredFiles = [
                'qemu-wrapper.js',
                'package.json'
            ];

            const targets = fs.readdirSync(this.buildPath).filter(dir => 
                fs.statSync(path.join(this.buildPath, dir)).isDirectory()
            );

            for (const target of targets) {
                const targetPath = path.join(this.buildPath, target);
                
                // Check required files exist
                for (const file of requiredFiles) {
                    const filePath = path.join(targetPath, file);
                    if (!fs.existsSync(filePath)) {
                        throw new Error(`Missing ${file} in ${target}`);
                    }
                }

                // Check for WASM files
                const wasmFiles = fs.readdirSync(targetPath).filter(file => 
                    file.endsWith('.wasm')
                );
                
                if (wasmFiles.length === 0) {
                    throw new Error(`No WASM files found in ${target}`);
                }

                // Check for JS files
                const jsFiles = fs.readdirSync(targetPath).filter(file => 
                    file.endsWith('.js')
                );
                
                if (jsFiles.length === 0) {
                    throw new Error(`No JS files found in ${target}`);
                }
            }

            return true;
        });
    }

    /**
     * Test JavaScript syntax validity
     */
    async testJavaScriptSyntax() {
        this.addTest('JavaScript Syntax Validation', async () => {
            const targets = fs.readdirSync(this.buildPath).filter(dir => 
                fs.statSync(path.join(this.buildPath, dir)).isDirectory()
            );

            for (const target of targets) {
                const targetPath = path.join(this.buildPath, target);
                const jsFiles = fs.readdirSync(targetPath).filter(file => 
                    file.endsWith('.js')
                );

                for (const jsFile of jsFiles) {
                    const filePath = path.join(targetPath, jsFile);
                    const content = fs.readFileSync(filePath, 'utf8');
                    
                    // Try to parse the JavaScript
                    try {
                        new Function(content);
                    } catch (error) {
                        throw new Error(`Syntax error in ${jsFile}: ${error.message}`);
                    }
                }
            }

            return true;
        });
    }

    /**
     * Test WebAssembly file validity
     */
    async testWebAssemblyFiles() {
        this.addTest('WebAssembly File Validation', async () => {
            const targets = fs.readdirSync(this.buildPath).filter(dir => 
                fs.statSync(path.join(this.buildPath, dir)).isDirectory()
            );

            for (const target of targets) {
                const targetPath = path.join(this.buildPath, target);
                const wasmFiles = fs.readdirSync(targetPath).filter(file => 
                    file.endsWith('.wasm')
                );

                for (const wasmFile of wasmFiles) {
                    const filePath = path.join(targetPath, wasmFile);
                    const stats = fs.statSync(filePath);
                    
                    // Check file size
                    if (stats.size === 0) {
                        throw new Error(`WASM file ${wasmFile} is empty`);
                    }

                    // Check WASM magic number
                    const buffer = fs.readFileSync(filePath);
                    const magic = buffer.readUInt32LE(0);
                    
                    if (magic !== 0x6d736100) { // 0x0061736d in little endian
                        throw new Error(`Invalid WASM magic number in ${wasmFile}`);
                    }

                    // Check file size is reasonable (between 1MB and 100MB)
                    if (stats.size < 1024 * 1024) {
                        console.warn(`⚠️  ${wasmFile} is smaller than expected (${stats.size} bytes)`);
                    }
                    
                    if (stats.size > 100 * 1024 * 1024) {
                        console.warn(`⚠️  ${wasmFile} is larger than expected (${stats.size} bytes)`);
                    }
                }
            }

            return true;
        });
    }

    /**
     * Test package.json validity
     */
    async testPackageJSON() {
        this.addTest('Package.json Validation', async () => {
            const targets = fs.readdirSync(this.buildPath).filter(dir => 
                fs.statSync(path.join(this.buildPath, dir)).isDirectory()
            );

            for (const target of targets) {
                const packagePath = path.join(this.buildPath, target, 'package.json');
                const content = fs.readFileSync(packagePath, 'utf8');
                
                let packageJson;
                try {
                    packageJson = JSON.parse(content);
                } catch (error) {
                    throw new Error(`Invalid JSON in package.json: ${error.message}`);
                }

                // Required fields
                const requiredFields = ['name', 'version', 'description', 'main', 'license'];
                for (const field of requiredFields) {
                    if (!packageJson[field]) {
                        throw new Error(`Missing required field '${field}' in package.json`);
                    }
                }

                // Check name format
                if (!packageJson.name.includes('qemu') || !packageJson.name.includes('wasm')) {
                    throw new Error(`Package name should include 'qemu' and 'wasm': ${packageJson.name}`);
                }

                // Check main file exists
                const mainFile = path.join(this.buildPath, target, packageJson.main);
                if (!fs.existsSync(mainFile)) {
                    throw new Error(`Main file not found: ${packageJson.main}`);
                }
            }

            return true;
        });
    }

    /**
     * Test JavaScript wrapper functionality
     */
    async testWrapperFunctionality() {
        this.addTest('JavaScript Wrapper Functionality', async () => {
            const targets = fs.readdirSync(this.buildPath).filter(dir => 
                fs.statSync(path.join(this.buildPath, dir)).isDirectory()
            );

            for (const target of targets) {
                const wrapperPath = path.join(this.buildPath, target, 'qemu-wrapper.js');
                const content = fs.readFileSync(wrapperPath, 'utf8');

                // Check for required class and methods
                const requiredPatterns = [
                    /class\s+QEMUJS/,
                    /constructor\s*\(\s*\)/,
                    /async\s+initialize\s*\(\s*\)/,
                    /async\s+start\s*\(/,
                    /stop\s*\(\s*\)/,
                    /getStatus\s*\(\s*\)/,
                    /buildArgs\s*\(\s*\)/
                ];

                for (const pattern of requiredPatterns) {
                    if (!pattern.test(content)) {
                        throw new Error(`Missing required method or class in wrapper`);
                    }
                }

                // Check export patterns
                if (!content.includes('module.exports') && !content.includes('window.QEMUJS') && !content.includes('global.QEMUJS')) {
                    throw new Error(`Missing export statement in wrapper`);
                }
            }

            return true;
        });
    }

    /**
     * Test memory constraints and configurations
     */
    async testMemoryConstraints() {
        this.addTest('Memory Configuration Check', async () => {
            const targets = fs.readdirSync(this.buildPath).filter(dir => 
                fs.statSync(path.join(this.buildPath, dir)).isDirectory()
            );

            for (const target of targets) {
                const wrapperPath = path.join(this.buildPath, target, 'qemu-wrapper.js');
                const content = fs.readFileSync(wrapperPath, 'utf8');

                // Check for memory-related configurations
                const memoryPatterns = [
                    /ALLOW_MEMORY_GROWTH/,
                    /MAXIMUM_MEMORY/,
                    /INITIAL_MEMORY/
                ];

                let foundMemoryConfig = false;
                for (const pattern of memoryPatterns) {
                    if (pattern.test(content)) {
                        foundMemoryConfig = true;
                        break;
                    }
                }

                if (!foundMemoryConfig) {
                    console.warn(`⚠️  No memory configuration found in ${target} wrapper`);
                }
            }

            return true;
        });
    }

    /**
     * Test performance characteristics
     */
    async testPerformance() {
        this.addTest('Performance Metrics', async () => {
            const targets = fs.readdirSync(this.buildPath).filter(dir => 
                fs.statSync(path.join(this.buildPath, dir)).isDirectory()
            );

            for (const target of targets) {
                const targetPath = path.join(this.buildPath, target);
                const files = fs.readdirSync(targetPath);
                
                // Calculate total size
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

                console.log(`📊 ${target} Performance Metrics:`);
                console.log(`   Total size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);
                console.log(`   WASM size: ${(wasmSize / 1024 / 1024).toFixed(2)} MB`);
                console.log(`   JS size: ${(jsSize / 1024 / 1024).toFixed(2)} MB`);

                // Performance assertions
                if (totalSize > 200 * 1024 * 1024) { // 200MB
                    console.warn(`⚠️  Large total size for ${target}: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);
                }

                if (wasmSize > 100 * 1024 * 1024) { // 100MB
                    console.warn(`⚠️  Large WASM size for ${target}: ${(wasmSize / 1024 / 1024).toFixed(2)} MB`);
                }

                if (jsSize > 50 * 1024 * 1024) { // 50MB
                    console.warn(`⚠️  Large JS size for ${target}: ${(jsSize / 1024 / 1024).toFixed(2)} MB`);
                }
            }

            return true;
        });
    }

    /**
     * Add a test to the suite
     */
    addTest(name, testFunction) {
        this.testResults.push({
            name,
            test: testFunction,
            passed: false,
            error: null,
            duration: 0
        });
    }

    /**
     * Run a single test
     */
    async runTest(test) {
        const startTime = Date.now();
        
        try {
            console.log(`🔍 Running: ${test.name}`);
            const result = await test.test();
            test.passed = result !== false;
            console.log(`✅ Passed: ${test.name}`);
        } catch (error) {
            test.passed = false;
            test.error = error.message;
            console.log(`❌ Failed: ${test.name} - ${error.message}`);
        }
        
        test.duration = Date.now() - startTime;
    }

    /**
     * Print test results
     */
    printResults() {
        console.log('\n📋 Test Results Summary:');
        console.log('='.repeat(50));

        let passed = 0;
        let failed = 0;

        for (const result of this.testResults) {
            const status = result.passed ? '✅ PASS' : '❌ FAIL';
            const duration = `${result.duration}ms`;
            
            console.log(`${status} ${result.name} (${duration})`);
            
            if (!result.passed && result.error) {
                console.log(`    Error: ${result.error}`);
            }

            if (result.passed) {
                passed++;
            } else {
                failed++;
            }
        }

        console.log('='.repeat(50));
        console.log(`Total: ${this.testResults.length} tests`);
        console.log(`Passed: ${passed}`);
        console.log(`Failed: ${failed}`);
        console.log(`Success Rate: ${((passed / this.testResults.length) * 100).toFixed(1)}%`);

        if (failed === 0) {
            console.log('\n🎉 All tests passed! QEMU WebAssembly build is ready.');
        } else {
            console.log('\n💥 Some tests failed. Please review the build configuration.');
        }
    }
}

// Export for use in other modules
module.exports = QEMUWASMTester;

// Run tests if this file is executed directly
if (require.main === module) {
    const tester = new QEMUWASMTester();
    tester.runAllTests().then(success => {
        process.exit(success ? 0 : 1);
    });
}
