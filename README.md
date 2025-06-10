# MCD - Enhanced Directory Navigation Tool

`mcd` is a Rust-based command-line tool that provides enhanced directory navigation with substring matching and smart selection. It's like the `cd` command, but with superpowers!

## Features

- **Substring Matching**: Find directories by partial name matches
- **Bidirectional Search**: Searches both up the directory tree and down into subdirectories  
- **Smart Prioritization**: Proximity-based sorting with intelligent exact vs substring match handling
- **Multiple Match Display**: Shows all matching options when multiple directories are found
- **Shell Integration**: Works seamlessly with bash through a wrapper function
- **Tab Completion**: Standard directory tab completion support

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
```

### Examples

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

### Multiple Matches & Tab Completion

When multiple directories match your search term, `mcd` automatically navigates to the best match (highest priority). However, you can use **tab completion** to cycle through all available matches before executing the command:

```bash
# Type 'mcd fo' and press Tab - cycles through matches
$ mcd fo<Tab>
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

The tab completion works by:
1. Finding all directories that match your search pattern
2. Cycling through them in priority order (exact matches first, then partial matches)
3. Allowing you to press Enter when you see the directory you want

### Tab Completion Features

- **Inline Cycling**: Tab repeatedly to cycle through all matches
- **Smart Prioritization**: Exact matches shown before partial matches
- **Proximity Sorting**: Closer directories (fewer levels away) shown first
- **Trailing Slash Support**: Add `/` to explore subdirectories of the current match

## Search Algorithm

The MCD tool uses a sophisticated search and sorting algorithm with support for multiple search modes:

### Search Modes
- **Simple Substring**: `mcd foo` - finds directories containing "foo"
- **Absolute Paths**: `mcd /path/to/dir` - navigates directly to absolute paths
- **Path Patterns**: `mcd parent/child` - finds "child" within "parent" directories

### Search Strategy
- **Upward Search**: Traverses parent directories to find matches
- **Downward Search**: Recursively searches subdirectories up to 8 levels deep
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

## How It Works

The `mcd` tool works in two parts:

1. **Rust Binary (`src/main.rs`)**: 
   - Performs the directory search and sorting
   - Returns **all matching directories** when given different index parameters
   - Supports cycling through multiple matches via index parameter
   - Cannot change the parent shell's directory (fundamental limitation)

2. **Shell Function (`mcd_function.sh`)**:
   - Wraps the Rust binary and handles directory changing
   - Provides intelligent tab completion that cycles through all matches
   - Manages completion state to enable smooth cycling experience
   - Changes to the selected directory using the shell's `cd` command

### Search Process

1. **Search Up**: Looks through parent directories for matches
2. **Search Down**: Recursively searches subdirectories (up to 8 levels deep for performance)
3. **Comprehensive Collection**: Gathers **all** matching directories (not just the first one)
4. **Smart Sorting**: 
   - Prioritizes match quality (exact vs partial)
   - Sorts by proximity within each quality category
   - Maintains consistent ordering for reliable tab completion
5. **Shell Integration**: Uses a bash wrapper function with sophisticated tab completion cycling

## Technical Details

- **Language**: Rust (for performance and reliability)
- **Dependencies**: Standard library only (no external crates)
- **Architecture**: Rust binary + bash wrapper function
- **Search Depth**: Limited to 8 levels deep for performance
- **Shell Support**: Bash (with advanced tab completion cycling)
- **Recent Improvements**: Enhanced to return all matching directories for proper tab completion cycling

## Recent Updates

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
│   └── main.rs                  # Core Rust implementation
├── .github/
│   └── copilot-instructions.md  # Copilot custom instructions  
├── .vscode/
│   └── tasks.json               # VS Code build tasks
├── mcd_function.sh              # Bash wrapper function (ESSENTIAL)
├── comprehensive_test.sh        # Complete test suite
├── demo.sh                      # Demonstration script
├── Cargo.toml                   # Rust dependencies and metadata
├── Cargo.lock                   # Dependency lock file
└── README.md                    # This file
```

### Testing

You can test the installation using the included demo script:

```bash
cd mcd
./demo.sh
```

Or test the binary directly:

```bash
# Test finding directories containing 'fo' - should return first match
./target/release/mcd fo 0

# Test cycling through matches - should return second match  
./target/release/mcd fo 1

# Test from different directory
cd /tmp
/path/to/mcd/target/release/mcd fo 0  # Returns /.font-unix
/path/to/mcd/target/release/mcd fo 1  # Returns /foo
```

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

### Tab Completion Shows Wrong Results
If tab completion shows unexpected directories:
- Remember that search includes both parent and child directories
- Use more specific patterns to narrow results
- Check current working directory as it affects search scope

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
