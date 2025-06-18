# JCD - Enhanced Directory Navigation Tool

`jcd` is a Rust-based command-line tool that provides enhanced directory navigation with substring matching and smart selection. It's like the `cd` command, but with superpowers!

![JCD Demo](https://github.com/markrussinovich/jcd/blob/main/assets/jcd.gif?raw=true)

## Features

- **Tab Navigation**: Intelligent cycling through all matches with visual feedback and animated loading indicators
- **First-Match Jump**: Press Enter after typing to immediately navigate to the best match
- **Priority Matching Order**:
  1. Exact matches prioritized over partial matches
  2. Up-tree matches (parent directories) have highest priority
  3. Down-tree matches (subdirectories) sorted by proximity
  4. Alphabetical sorting within same priority level
- **Substring Matching**: Find directories by partial name matches
- **Bidirectional Search**: Searches both up the directory tree and down into subdirectories

## Installation

1. **Clone and Build**:
   ```bash
   git clone <repository-url>
   cd jcd

   ```

2. **Add to Shell Configuration**:
   Add the following lines to your `~/.bashrc` (replace `/path/to/jcd` with your actual path):
   ```bash
   export JCD_BINARY="/path/to/jcd/target/release/jcd"
   source /path/to/jcd/jcd_function.sh
   ```

3. **Reload Shell**:
   ```bash
   source ~/.bashrc
   ```

> **Note**: The shell function integration is **required** because a Rust binary cannot change the directory of its parent shell process. The `jcd_function.sh` wrapper handles this limitation by calling the binary and then changing directories based on its output.

## Usage

```bash
jcd <substring>        # Navigate to directory matching substring
jcd <absolute_path>    # Navigate to absolute path
jcd <path/pattern>     # Navigate using path-like patterns
```

### Examples

#### Basic Navigation
```bash
# Navigate to any directory containing "proj"
jcd proj

# Find directories with "src" in the name
jcd src

# Navigate to parent directories matching "work"
jcd work

# Navigate to absolute path
jcd /home/user/projects

# Use path patterns
jcd projects/src    # Find 'src' within 'projects'
```


### Advanced Tab Completion

When multiple directories match your search term, `jcd` provides intelligent tab completion that cycles through all available matches with visual feedback:

```bash
# Type 'jcd fo' and press Tab - shows animated dots while searching
$ jcd fo<Tab>
...  # Animated loading indicator
jcd /.font-unix

# Press Tab again to cycle to next match
$ jcd /.font-unix<Tab>
jcd /foo

# Press Tab again to cycle to next match
$ jcd /foo<Tab>
jcd /some/other/folder

# Press Enter to navigate to the currently shown match
$ jcd /foo<Enter>
# Now in /foo directory
```

#### Tab Completion Features

- **Animated Loading**: Visual dots animation during search operations
- **Inline Cycling**: Tab repeatedly to cycle through all matches
- **Smart Prioritization**: Exact matches shown before partial matches
- **Proximity Sorting**: Closer directories (fewer levels away) shown first
- **Trailing Slash Support**: Add `/` to explore subdirectories of the current match
- **Relative Path Support**: Full tab completion for `../`, `../../`, etc.



## How It Works

The `jcd` tool works in two parts:

1. **Rust Binary (`src/main.rs`)**:
   - Performs the directory search and sorting
   - Returns **all matching directories** when given different index parameters
   - Supports cycling through multiple matches via index parameter
   - Cannot change the parent shell's directory (fundamental limitation)

2. **Shell Function (`jcd_function.sh`)**:
   - Wraps the Rust binary and handles directory changing
   - Provides intelligent tab completion with animated visual feedback
   - Manages completion state to enable smooth cycling experience
   - Handles fast shell-based navigation for common relative patterns
   - Changes to the selected directory using the shell's `cd` command
   - Shows animated loading indicators during search operations

### Search Process

1. **Relative Path Resolution**: Handles `..`, `../..`, `../pattern` etc. before search
2. **Search Up**: Looks through parent directories for matches
3. **Search Down**: Recursively searches subdirectories (up to 8 levels deep for performance)
4. **Comprehensive Collection**: Gathers **all** matching directories (not just the first one)
5. **Smart Sorting**:
   - Prioritizes match quality (exact vs partial)
   - Sorts by proximity within each quality category
   - Maintains consistent ordering for reliable tab completion
6. **Shell Integration**: Uses a bash wrapper function with sophisticated tab completion cycling
7. **Visual Feedback**: Provides animated loading indicators for longer operations

## Technical Details

- **Language**: Rust for performance and reliability
- **Dependencies**: Standard library only (no external crates)
- **Architecture**: Rust binary + enhanced bash wrapper function
- **Search Depth**: Limited to 8 levels deep for performance
- **Shell Support**: Bash (with advanced tab completion cycling and animations)
- **Visual Feedback**: Animated loading indicators using ANSI escape sequences
- **Performance**: Shell-based fast paths for common navigation patterns
- **Relative Path Support**: Full resolution and search from resolved directories


## Development

### Building

```bash
# Debug build
cargo build

# Release build
cargo build --release

# Run tests
cargo test
```

### Project Structure

```
jcd/
├── src/
│   └── main.rs                  # Core Rust implementation with relative path support
├── .github/
│   └── copilot-instructions.md  # Copilot custom instructions
├── .vscode/
│   └── tasks.json               # VS Code build tasks
├── jcd_function.sh              # Enhanced bash wrapper with animations (ESSENTIAL)
├── Cargo.toml                   # Rust dependencies and metadata
├── Cargo.lock                   # Dependency lock file
├── tests/                       # Test scripts
└── README.md                    # This file
```

### Testing

The project includes a comprehensive test suite located in the `tests/` directory:

```bash
# Run all tests (recommended)
./tests/run_all_tests.sh

# Individual test suites:
# Run comprehensive test suite
./tests/test_relative_comprehensive.sh

# Quick validation for CI/CD
./tests/validate_jcd.sh

# Simple functionality test
./tests/simple_test.sh

# Quick regression test
./tests/quick_regression_test.sh

# Specific bug fix tests
./tests/test_absolute_bug.sh
./tests/test_absolute_path_consistency.sh
./tests/test_regression_fix.sh
./tests/final_absolute_path_test.sh

# Python-based basic functionality verification
./tests/verify_basic_functionality.py
```

### Manual Testing
You can also test manually:
```bash
# Build the project
cargo build --release

# Test basic navigation
cd /tmp
jcd ..

# Test relative paths
jcd ../Documents
jcd ../../usr/local

# Test pattern matching
jcd ../proj   # Should match project directories in parent
```

See `tests/README.md` for detailed information about the test suite.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

```
