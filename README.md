# MCD - Enhanced Directory Navigation Tool

`mcd` is a Rust-based command-line tool that provides enhanced directory navigation with substring matching and smart selection. It's like the `cd` command, but with superpowers!

## Demo
![MCD Demo](https://github.com/markrussinovich/mcd/assets/mcd.mp4?raw=true)

## Features

- **Substring Matching**: Find directories by partial name matches
- **Bidirectional Search**: Searches both up the directory tree and down into subdirectories  
- **Smart Prioritization**: Proximity-based sorting with intelligent exact vs substring match handling
- **Relative Path Navigation**: Support for `..`, `../..`, `../pattern`, etc.
- **Shell Integration**: Works seamlessly with bash through a wrapper function
- **Advanced Tab Completion**: Intelligent cycling through all matches with visual feedback
- **Performance Optimized**: Fast shell-based navigation for common patterns
- **Visual Feedback**: Animated loading indicators during search operations

## Installation

1. **Clone and Build**:
   ```bash
   git clone <repository-url>
   cd mcd
   cargo build --release
   ```

2. **Add to Shell Configuration**:
   Add the following lines to your `~/.bashrc` (replace `/path/to/mcd` with your actual path):
   ```bash
   export MCD_BINARY="/path/to/mcd/target/release/mcd"
   source /path/to/mcd/mcd_function.sh
   ```

3. **Reload Shell**:
   ```bash
   source ~/.bashrc
   ```

> **Note**: The shell function integration is **required** because a Rust binary cannot change the directory of its parent shell process. The `mcd_function.sh` wrapper handles this limitation by calling the binary and then changing directories based on its output.

## Usage

```bash
mcd <substring>        # Navigate to directory matching substring
mcd <absolute_path>    # Navigate to absolute path
mcd <path/pattern>     # Navigate using path-like patterns
mcd ..                 # Navigate to parent directory
mcd ../..              # Navigate up multiple levels
mcd ../pattern         # Search for pattern starting from parent directory
```

### Examples

#### Basic Navigation
```bash
# Navigate to any directory containing "proj"
mcd proj

# Find directories with "src" in the name  
mcd src

# Navigate to parent directories matching "work"
mcd work

# Navigate to absolute path
mcd /home/user/projects

# Use path patterns
mcd projects/src    # Find 'src' within 'projects'
```

#### Relative Path Navigation
```bash
# Standard directory navigation
mcd ..            # Go to parent directory  
mcd ../..         # Go up two directory levels
mcd ../../..      # Go up three directory levels
mcd .             # Stay in current directory (no-op)

# Relative search patterns
mcd ../foo        # Search for "foo" in parent directory
mcd ../project    # Find "project" directory in parent
mcd ../../config  # Find "config" starting from grandparent
mcd ./local       # Search in current directory
```

### Advanced Tab Completion

When multiple directories match your search term, `mcd` provides intelligent tab completion that cycles through all available matches with visual feedback:

```bash
# Type 'mcd fo' and press Tab - shows animated dots while searching
$ mcd fo<Tab>
...  # Animated loading indicator
mcd /.font-unix

# Press Tab again to cycle to next match
$ mcd /.font-unix<Tab>  
mcd /foo

# Press Tab again to cycle to next match
$ mcd /foo<Tab>
mcd /some/other/folder

# Press Enter to navigate to the currently shown match
$ mcd /foo<Enter>
# Now in /foo directory
```

#### Tab Completion Features

- **Animated Loading**: Visual dots animation during search operations
- **Inline Cycling**: Tab repeatedly to cycle through all matches
- **Smart Prioritization**: Exact matches shown before partial matches
- **Proximity Sorting**: Closer directories (fewer levels away) shown first
- **Trailing Slash Support**: Add `/` to explore subdirectories of the current match
- **Relative Path Support**: Full tab completion for `../`, `../../`, etc.

#### Tab Completion with Relative Paths
```bash
# Explore parent directory contents
mcd ../<TAB>          # Shows: child1/ child2/ subdir/

# Cycle through matching patterns in parent
mcd ../f<TAB>         # Cycles: ../foo → ../fbar → ../folder

# Multi-level navigation
mcd ../../<TAB>       # Shows all directories two levels up

# Explore subdirectories of relative matches
mcd ../foo/<TAB>      # Shows subdirectories of ../foo/
```

## Search Algorithm

The MCD tool uses a sophisticated search and sorting algorithm with support for multiple search modes:

### Search Modes
- **Simple Substring**: `mcd foo` - finds directories containing "foo"
- **Absolute Paths**: `mcd /path/to/dir` - navigates directly to absolute paths
- **Path Patterns**: `mcd parent/child` - finds "child" within "parent" directories
- **Relative Navigation**: `mcd ..` - navigates to parent directory
- **Multi-level Navigation**: `mcd ../..` - navigates up multiple directory levels
- **Relative Patterns**: `mcd ../foo` - searches for "foo" starting from parent directory
- **Complex Relative**: `mcd ../../bar` - searches for "bar" starting from grandparent directory

## Examples

### Basic Navigation
```bash
mcd foo           # Find directories containing "foo"
mcd /tmp          # Navigate to /tmp directly
mcd ..            # Go to parent directory  
mcd ../..         # Go up two directory levels
mcd ../../..      # Go up three directory levels
```

### Relative Path Search
```bash
mcd ../foo        # Search for "foo" in parent directory
mcd ../project    # Find "project" directory in parent
mcd ../../config  # Find "config" starting from grandparent
mcd ./local       # Search in current directory
```

### Tab Completion with Relative Paths
- `mcd ../<TAB>` - Shows all directories in parent directory
- `mcd ../f<TAB>` - Cycles through directories starting with "f" in parent
- `mcd ../../<TAB>` - Shows all directories two levels up
- `mcd ../foo/<TAB>` - Explores subdirectories of "../foo"

### Search Strategy
- **Upward Search**: Traverses parent directories to find matches
- **Downward Search**: Recursively searches subdirectories up to 8 levels deep
- **Smart Early Return**: Prioritizes immediate subdirectory matches over deeper searches for faster performance
- **Pattern Matching**: For path patterns, searches for each component sequentially
- **Comprehensive Match Collection**: Returns all matching directories for tab completion cycling
- **Deduplication**: Removes duplicate paths that might be found through different search paths

### Sorting Priority
1. **Match Quality First**: Exact matches are prioritized over partial matches
2. **Direction Priority**: 
   - **Up-tree matches** (parent directories) have highest priority
   - **Down-tree matches** (subdirectories) have lower priority
3. **Proximity Within Category**: 
   - For up-tree matches: closer to current directory first
   - For down-tree matches: shallower matches first
4. **Alphabetical**: Within same priority level, sorted alphabetically

### Example Behavior
From directory `/tmp`:
- `mcd fo` → First offers `/.font-unix`, then `/foo`, then other matches containing "fo"
- Tab completion cycles through: `/.font-unix` → `/foo` → `/some/folder` → etc.
- `mcd ../` → Shows animated loading, then displays parent directory contents
- `mcd ../project<TAB>` → Cycles through projects in parent directory

### Performance Optimizations
- **Shell-based Navigation**: Common patterns like `..`, `../..` handled directly in shell
- **Smart Search Prioritization**: Immediate subdirectory matches returned early to avoid deep searches
- **Animated Feedback**: Visual loading indicators only appear for longer operations
- **Intelligent Caching**: Tab completion results cached to avoid repeated searches
- **Fast Relative Resolution**: Relative paths resolved before expensive directory searches
- **Optimized State Management**: Improved cycling detection and fresh search handling

## How It Works

The `mcd` tool works in two parts:

1. **Rust Binary (`src/main.rs`)**: 
   - Performs the directory search and sorting
   - Returns **all matching directories** when given different index parameters
   - Supports cycling through multiple matches via index parameter
   - Cannot change the parent shell's directory (fundamental limitation)

2. **Shell Function (`mcd_function.sh`)**:
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

- **Language**: Rust (for performance and reliability)
- **Dependencies**: Standard library only (no external crates)
- **Architecture**: Rust binary + enhanced bash wrapper function
- **Search Depth**: Limited to 8 levels deep for performance
- **Shell Support**: Bash (with advanced tab completion cycling and animations)
- **Visual Feedback**: Animated loading indicators using ANSI escape sequences
- **Performance**: Shell-based fast paths for common navigation patterns
- **Relative Path Support**: Full resolution and search from resolved directories

## Recent Updates

### v1.1.1 - Search Optimization & State Management
- **OPTIMIZED**: Search algorithm now prioritizes immediate subdirectory matches over deeper searches
- **IMPROVED**: Enhanced state management for cycling and fresh search detection
- **IMPROVED**: Simplified state management and better busy indicator logic for tab completion
- **ENHANCED**: Comprehensive test suite with validation scripts

### v1.1.0 - Relative Path Navigation & Enhanced UX
- **NEW**: Full relative path support (`..`, `../..`, `../pattern`, etc.)
- **NEW**: Animated loading indicators during tab completion
- **NEW**: Fast shell-based navigation for common patterns
- **NEW**: Enhanced tab completion with relative path support
- **IMPROVED**: Performance optimizations for common navigation patterns
- **IMPROVED**: Visual feedback system with animated dots during searches
- **IMPROVED**: State management for seamless tab completion cycling

### v1.0.1 - Tab Completion Cycling Fix
- **Fixed**: Tab completion now properly cycles through all matching directories
- **Improved**: Binary now returns comprehensive match lists instead of single matches
- **Enhanced**: Shell function state management for seamless cycling experience
- **Example**: `mcd fo<Tab>` now cycles through `/.font-unix` → `/foo1` → other matches

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
mcd/
├── src/
│   └── main.rs                  # Core Rust implementation with relative path support
├── .github/
│   └── copilot-instructions.md  # Copilot custom instructions  
├── .vscode/
│   └── tasks.json               # VS Code build tasks
├── mcd_function.sh              # Enhanced bash wrapper with animations (ESSENTIAL)
├── test_relative_comprehensive.sh  # Comprehensive relative path tests
├── simple_test.sh               # Basic functionality tests
├── RELATIVE_PATH_ENHANCEMENT.md # Detailed enhancement documentation
├── Cargo.toml                   # Rust dependencies and metadata
├── Cargo.lock                   # Dependency lock file
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
./tests/validate_mcd.sh

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
mcd ..

# Test relative paths
mcd ../Documents
mcd ../../usr/local

# Test pattern matching
mcd ../proj   # Should match project directories in parent
```

See `tests/README.md` for detailed information about the test suite.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is open source. See LICENSE file for details.

## Troubleshooting

### Command Not Found
Make sure you've:
1. Set the `MCD_BINARY` environment variable to point to the release binary
2. Sourced the `mcd_function.sh` script in your shell configuration file
3. Reloaded your shell with `source ~/.bashrc`

### Tab Completion Not Working
If tab completion doesn't cycle through matches:
1. Ensure `mcd_function.sh` is properly sourced
2. Check that the binary path in `MCD_BINARY` is correct
3. Test the binary directly: `/path/to/mcd fo 0` should return a directory
4. Enable debug mode: `export MCD_DEBUG=1` to see completion details

### No Matches Found
The tool searches with case-insensitive substring matching. Try:
- Shorter or more general search terms
- Checking if the target directory actually exists
- Verifying you're in the right starting location
- Testing with debug mode: `MCD_DEBUG=1 mcd <pattern>`

### Tab Completion Shows Slow Performance
If tab completion feels slow or shows animation for too long:
- The search depth is limited to 8 levels for performance
- Very large directory trees may take longer to search
- Consider using more specific patterns to narrow the search scope
- Animation appears only for operations taking longer than 500ms

### Relative Path Navigation Issues
If relative path navigation doesn't work as expected:
- Ensure you're using the shell function, not calling the binary directly
- Test: `mcd ".."` should change to parent directory
- Verify the shell function is properly loaded: `type mcd` should show it's a function
- Check for shell compatibility (requires bash)

### Binary Not Found Error
Ensure the binary exists and has execute permissions:
```bash
ls -la /path/to/mcd/target/release/mcd
chmod +x /path/to/mcd/target/release/mcd
```

### Function Not Working
Test the binary directly first:
```bash
/path/to/mcd/target/release/mcd <search_term> 0
```
If this works but the function doesn't, check your shell configuration.
```
