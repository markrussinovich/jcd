<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# JCD - Enhanced Directory Navigation Tool

This is a Rust command-line tool that provides enhanced directory navigation capabilities:

## Key Features
- Substring matching for directory names
- Search both up the directory tree and down into subdirectories
- Interactive selection with tab cycling when multiple matches are found
- Shell integration through a bash wrapper function

## Architecture
- `src/main.rs`: Core Rust binary that finds matching directories
- `jcd.sh`: Bash wrapper function that enables directory changing in the parent shell
- Uses `crossterm` for terminal interaction and key handling

## Development Guidelines
- Follow Rust best practices and idiomatic code style
- Handle errors gracefully with appropriate user feedback
- Keep the search depth limited to avoid performance issues
- Maintain cross-platform compatibility where possible
- Prioritize user experience with clear, intuitive interactions
