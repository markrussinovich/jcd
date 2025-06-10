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
mcd --tab              # Cycle through previous matches
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

# Cycle through multiple matches
mcd foo             # Shows multiple matches
mcd --tab           # Cycle to next match
mcd --tab           # Cycle to next match
```

### Multiple Matches & Tab Cycling

When multiple directories match your search term, `mcd` shows all options and navigates to the best match. You can then use `mcd --tab` to cycle through the other matches:

```bash
$ mcd foo
Found 4 matches (use 'mcd --tab' to cycle):
→ 1. /path/to/foo1 (going here)
  2. /path/to/foo2  
  3. /path/to/foo3
  4. /path/to/foobaz

$ mcd --tab
Cycling matches for 'foo':
  1. /path/to/foo1
→ 2. /path/to/foo2 (going here)
  3. /path/to/foo3
  4. /path/to/foobaz
```

The tool automatically goes to the first (best) match while showing you what other options were available.

## Search Algorithm

The MCD tool uses a sophisticated search and sorting algorithm with support for multiple search modes:

### Search Modes
- **Simple Substring**: `mcd foo` - finds directories containing "foo"
- **Absolute Paths**: `mcd /path/to/dir` - navigates directly to absolute paths
- **Path Patterns**: `mcd parent/child` - finds "child" within "parent" directories

### Search Strategy
- **Upward Search**: Traverses parent directories to find matches
- **Downward Search**: Recursively searches subdirectories up to 3 levels deep
- **Pattern Matching**: For path patterns, searches for each component sequentially
- **Deduplication**: Removes duplicate paths that might be found through different search paths

### Sorting Priority
1. **Proximity First**: Closer directories (fewer levels away) are prioritized
2. **Exact vs Substring Behavior**:
   - **Exact Matches**: When directory name exactly matches search term, parent directories are preferred
   - **Substring Matches**: When search term is contained in directory name, child directories are preferred

### Example Behavior
From directory `foo/foo1/foo2a`:
- `mcd foo` → Goes to `foo3` (closest child match)
- `mcd foo1` → Offers parent `foo1` first, then child `foo1` options

## How It Works

The `mcd` tool works in two parts:

1. **Rust Binary (`src/main.rs`)**: 
   - Performs the directory search and sorting
   - Returns the best match for a given search term and index
   - Cannot change the parent shell's directory (fundamental limitation)

2. **Shell Function (`mcd_function.sh`)**:
   - Wraps the Rust binary and handles directory changing
   - Collects all matches to show the user available options
   - Changes to the best match directory using the shell's `cd` command

### Search Process

1. **Search Up**: Looks through parent directories for matches
2. **Search Down**: Recursively searches subdirectories (limited to 3 levels deep)
3. **Smart Sorting**: 
   - Prioritizes proximity (closer directories first)
   - For exact matches: prefers parent directories  
   - For substring matches: prefers child directories
4. **Shell Integration**: Uses a bash wrapper function to change directories in the parent shell

## Technical Details

- **Language**: Rust (for performance and reliability)
- **Dependencies**: Standard library only (no external crates)
- **Architecture**: Rust binary + bash wrapper function
- **Search Depth**: Limited to 3 levels deep for performance
- **Shell Support**: Bash (with tab completion)

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
# Test finding directories with 'src' in the name
./target/release/mcd src 0

# Test from different directory
cd /tmp
/path/to/mcd/target/release/mcd home 0
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

### No Matches Found
The tool searches with case-insensitive substring matching. Try:
- Shorter or more general search terms
- Checking if the target directory actually exists
- Verifying you're in the right starting location

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
