use std::{
    env,
    fs,
    path::{Path, PathBuf},
    process,
    sync::{Arc, Mutex},
    thread,
    time::{Duration, Instant},
    io::{self, Write},
};

// Configuration constants for performance tuning
const MAX_MATCHES: usize = 20;           // Stop after finding enough matches
const MAX_SEARCH_TIME_MS: u64 = 500;    // Max time to spend searching (milliseconds)

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
enum MatchQuality {
    ExactUp,     // Exact match up the path - highest priority
    PartialUp,   // Partial match up the path - second priority
    ExactDown,   // Exact match down the path - third priority
    PartialDown, // Partial match down the path - lowest priority
}

#[derive(Debug, Clone)]
struct DirectoryMatch {
    path: PathBuf,
    depth_from_current: i32, // negative for parents, positive for children
    match_quality: MatchQuality,
}

#[derive(Debug)]
struct SearchContext {
    start_time: Instant,
    max_matches: usize,
    max_time: Duration,
    current_matches: usize,
}

impl SearchContext {
    fn new() -> Self {
        Self {
            start_time: Instant::now(),
            max_matches: MAX_MATCHES,
            max_time: Duration::from_millis(MAX_SEARCH_TIME_MS),
            current_matches: 0,
        }
    }
    
    fn should_continue(&self) -> bool {
        self.current_matches < self.max_matches && self.start_time.elapsed() < self.max_time
    }
    
    fn add_match(&mut self) {
        self.current_matches += 1;
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Error: No search term provided");
        process::exit(1);
    }
    
    let search_term = &args[1];
    let tab_index = if args.len() > 2 {
        args[2].parse::<usize>().unwrap_or(0)
    } else {
        0
    };
    
    // Check for quiet mode flag (used during tab completion)
    let quiet_mode = args.len() > 3 && args[3] == "--quiet";
    
    let current_dir = match env::current_dir() {
        Ok(dir) => dir,
        Err(e) => {
            eprintln!("Error: Cannot get current directory: {}", e);
            process::exit(1);
        }
    };
    
    // eprintln!("DEBUG: Searching for '{}' from {}", search_term, current_dir.display());
    
    // Use threaded search with busy indicator (unless in quiet mode)
    let matches = if quiet_mode {
        find_matching_directories(&current_dir, search_term)
    } else {
        search_with_progress(&current_dir, search_term)
    };
    
    // eprintln!("DEBUG: Found {} matches", matches.len());
    
    if matches.is_empty() || tab_index >= matches.len() {
        // eprintln!("DEBUG: No matches or index out of range");
        process::exit(1);
    }
    
    println!("{}", matches[tab_index].path.display());
}

fn search_with_progress(current_dir: &Path, search_term: &str) -> Vec<DirectoryMatch> {
    let current_dir = current_dir.to_path_buf();
    let search_term = search_term.to_string();
    
    // Shared state for the search result
    let result = Arc::new(Mutex::new(None));
    let result_clone = Arc::clone(&result);
    
    // Shared flag to indicate when search is complete
    let search_complete = Arc::new(Mutex::new(false));
    let search_complete_clone = Arc::clone(&search_complete);
    
    // Start the search in a background thread
    let search_handle = thread::spawn(move || {
        let matches = find_matching_directories(&current_dir, &search_term);
        
        // Store the result
        {
            let mut result_guard = result_clone.lock().unwrap();
            *result_guard = Some(matches);
        }
        
        // Mark search as complete
        {
            let mut complete_guard = search_complete_clone.lock().unwrap();
            *complete_guard = true;
        }
    });
    
    // Give search a brief moment to complete (20ms)
    thread::sleep(Duration::from_millis(20));
    
    // Check if search is still running
    let show_progress = {
        let complete_guard = search_complete.lock().unwrap();
        !*complete_guard
    };
    
    if show_progress {
        // Start the busy indicator in a separate thread
        let search_complete_clone = Arc::clone(&search_complete);
        let indicator_handle = thread::spawn(move || {
            show_busy_indicator(&search_complete_clone);
        });
        
        // Wait for the search to complete
        search_handle.join().unwrap();
        
        // Wait for indicator to finish
        indicator_handle.join().unwrap();
        
        // Clear the progress line
        eprint!("\r\x1b[K");
        io::stderr().flush().unwrap();
    } else {
        // Search completed quickly, just wait for it
        search_handle.join().unwrap();
    }
    
    // Return the result
    let result_guard = result.lock().unwrap();
    result_guard.as_ref().unwrap().clone()
}

fn show_busy_indicator(search_complete: &Arc<Mutex<bool>>) {
    let dots = [" .", " ..", " ..."];
    let mut dot_index = 0;
    
    loop {
        // Check if search is complete
        {
            let complete_guard = search_complete.lock().unwrap();
            if *complete_guard {
                break;
            }
        }
        
        // Show the dots animation with carriage return
        eprint!("\r{}", dots[dot_index]);
        io::stderr().flush().unwrap();
        
        // Update dot index
        dot_index = (dot_index + 1) % dots.len();
        
        // Wait before next update
        thread::sleep(Duration::from_millis(200));
    }
}

fn find_matching_directories(current_dir: &Path, search_term: &str) -> Vec<DirectoryMatch> {
    let mut matches = Vec::new();
    
    // Handle absolute paths
    if search_term.starts_with('/') {
        let path = Path::new(search_term);
        
        if path.exists() && path.is_dir() {
            // Path exists exactly - add it as a match and search subdirectories
            matches.push(DirectoryMatch {
                path: path.to_path_buf(),
                depth_from_current: 0,
                match_quality: MatchQuality::ExactDown,
            });
            // Also search subdirectories
            let mut context = SearchContext::new();
            let adaptive_depth = get_adaptive_depth(path);
            search_down_tree_fast(path, "", &mut matches, &mut context, 1, adaptive_depth);
        } else {
            // Path doesn't exist - find the longest existing prefix and search from there
            let (search_root, search_pattern) = find_search_root_and_pattern(search_term);
            if let Some(root) = search_root {
                let mut context = SearchContext::new();
                // For absolute paths, do a breadth-first search to prioritize shallower matches
                search_breadth_first(&root, &search_pattern, &mut matches, &mut context, 3);
            }
        }
        return finalize_matches(matches);
    }
    
    // Handle path-like patterns (contains '/')
    if search_term.contains('/') {
        let mut context = SearchContext::new();
        search_path_pattern_fast(current_dir, search_term, &mut matches, &mut context);
        if !matches.is_empty() {
            return finalize_matches(matches);
        }
    }
    
    // New priority-based search logic
    
    // 1. Search up for exact matches, then partial matches
    let up_matches = search_up_tree_with_priority(current_dir, search_term);
    
    // 2. If we found matches up the tree, return them (they have highest priority)
    if !up_matches.is_empty() {
        return up_matches;
    }
    
    // 3. Search down for all matches (exact and partial)
    let down_matches = search_down_breadth_first_all(current_dir, search_term);
    if !down_matches.is_empty() {
        return down_matches;
    }
    
    // No matches found
    Vec::new()
}

fn search_up_tree_with_priority(current_dir: &Path, search_term: &str) -> Vec<DirectoryMatch> {
    let mut exact_matches = Vec::new();
    let mut partial_matches = Vec::new();
    let mut current = current_dir;
    let mut depth = -1;
    
    let search_lower = search_term.to_lowercase();
    
    while let Some(parent) = current.parent() {
        if let Some(name) = parent.file_name() {
            let name_str = name.to_string_lossy();
            let name_lower = name_str.to_lowercase();
            
            if name_lower == search_lower {
                // Exact match
                exact_matches.push(DirectoryMatch {
                    path: parent.to_path_buf(),
                    depth_from_current: depth,
                    match_quality: MatchQuality::ExactUp,
                });
            } else if name_lower.contains(&search_lower) {
                // Partial match
                partial_matches.push(DirectoryMatch {
                    path: parent.to_path_buf(),
                    depth_from_current: depth,
                    match_quality: MatchQuality::PartialUp,
                });
            }
        }
        current = parent;
        depth -= 1;
    }
    
    // Return exact matches first, then partial matches
    let mut result = exact_matches;
    result.extend(partial_matches);
    result
}

fn search_down_breadth_first_all(current_dir: &Path, search_term: &str) -> Vec<DirectoryMatch> {
    use std::collections::VecDeque;
    
    let mut queue = VecDeque::new();
    let mut all_matches = Vec::new();
    queue.push_back((current_dir.to_path_buf(), 0));
    let search_lower = search_term.to_lowercase();
    let max_depth = 8;
    
    while let Some((current_path, depth)) = queue.pop_front() {
        if depth > max_depth {
            continue;
        }
        
        let mut level_matches = Vec::new();
        let mut level_subdirs = Vec::new();
        
        if let Ok(entries) = fs::read_dir(&current_path) {
            // Collect and sort entries for deterministic order
            let mut entries: Vec<_> = entries.filter_map(|e| e.ok()).collect();
            entries.sort_by(|a, b| a.file_name().cmp(&b.file_name()));
            
            // Process all entries at this level
            for entry in &entries {
                if let Ok(metadata) = entry.metadata() {
                    if metadata.is_dir() {
                        let path = entry.path();
                        if let Some(name) = path.file_name() {
                            let name_str = name.to_string_lossy();
                            let name_lower = name_str.to_lowercase();
                            
                            // Check for any match (exact or partial)
                            if name_lower == search_lower {
                                // Exact match
                                level_matches.push(DirectoryMatch {
                                    path: path.clone(),
                                    depth_from_current: if depth == 0 { 0 } else { depth as i32 },
                                    match_quality: MatchQuality::ExactDown,
                                });
                            } else if name_lower.contains(&search_lower) {
                                // Partial match
                                level_matches.push(DirectoryMatch {
                                    path: path.clone(),
                                    depth_from_current: if depth == 0 { 0 } else { depth as i32 },
                                    match_quality: MatchQuality::PartialDown,
                                });
                            }
                            
                            // Collect subdirectories for next level
                            if depth < max_depth {
                                level_subdirs.push((path.clone(), depth + 1));
                            }
                        }
                    }
                }
            }
        }
        
        // Add matches from this level
        all_matches.extend(level_matches.clone());
        
        // Key logic: If we found matches at immediate subdirectory level (depth 1), stop here
        if depth == 0 && !level_matches.is_empty() {
            return finalize_matches(level_matches);
        }
        
        // If we found matches at any other depth level and have existing matches, 
        // check if we should stop (found matches at this level)
        if depth > 0 && !level_matches.is_empty() && !all_matches.is_empty() {
            // We found matches at this level - stop searching deeper
            return finalize_matches(all_matches);
        }
        
        // Add subdirectories to queue for next level search
        for (subdir, next_depth) in level_subdirs {
            queue.push_back((subdir, next_depth));
        }
    }
    
    finalize_matches(all_matches)
}

fn finalize_matches(mut matches: Vec<DirectoryMatch>) -> Vec<DirectoryMatch> {
    // Remove duplicates based on path
    matches.sort_by(|a, b| a.path.cmp(&b.path));
    matches.dedup_by(|a, b| a.path == b.path);
    
    // Sort by priority: match quality first, then depth
    matches.sort_by(|a, b| {
        // First prioritize by match quality (ExactUp > PartialUp > ExactDown > PartialDown)
        let quality_cmp = a.match_quality.cmp(&b.match_quality);
        if quality_cmp != std::cmp::Ordering::Equal {
            return quality_cmp;
        }
        
        // For same quality, sort by depth (closer first for up matches, shallower first for down matches)
        match a.match_quality {
            MatchQuality::ExactUp | MatchQuality::PartialUp => {
                // For up matches, sort by depth descending (closer to current = higher depth)
                b.depth_from_current.cmp(&a.depth_from_current)
            }
            MatchQuality::ExactDown | MatchQuality::PartialDown => {
                // For down matches, sort by depth ascending (shallower = lower depth)
                a.depth_from_current.cmp(&b.depth_from_current)
            }
        }
    });
    
    matches
}

fn get_adaptive_depth(current_dir: &Path) -> usize {
    // Estimate directory size by counting immediate children
    if let Ok(entries) = fs::read_dir(current_dir) {
        let dir_count = entries
            .filter_map(|entry| entry.ok())
            .filter(|entry| entry.path().is_dir())
            .take(50) // Stop counting after 50
            .count();
        
        match dir_count {
            0..=10 => 4,   // Small directory: search deeper
            11..=30 => 3,  // Medium directory: normal depth
            31..=50 => 2,  // Large directory: shallow search
            _ => 1,        // Very large directory: minimal search
        }
    } else {
        3 // Default depth if we can't read the directory
    }
}

// Keep existing functions for backward compatibility with absolute paths and patterns
fn search_down_tree_fast(
    current_dir: &Path,
    search_term: &str,
    matches: &mut Vec<DirectoryMatch>,
    context: &mut SearchContext,
    depth: usize,
    max_depth: usize,
) {
    if depth > max_depth {
        return;
    }
    
    // Only check time limit, not match count limit, to ensure we find ALL matches
    if context.start_time.elapsed() > context.max_time {
        return;
    }
    
    if let Ok(entries) = fs::read_dir(current_dir) {
        // Collect all entries first to avoid issues with iterator
        let entries: Vec<_> = entries.filter_map(|e| e.ok()).collect();
        
        for entry in entries {
            // Don't check should_continue() here to ensure we explore all branches
            if let Ok(metadata) = entry.metadata() {
                if metadata.is_dir() {
                    let path = entry.path();
                    if let Some(name) = path.file_name() {
                        let name_str = name.to_string_lossy();
                        
                        // Check for match
                        if search_term.is_empty() || name_str.to_lowercase().contains(&search_term.to_lowercase()) {
                            let match_quality = if search_term.is_empty() || name_str.to_lowercase() == search_term.to_lowercase() {
                                MatchQuality::ExactDown
                            } else {
                                MatchQuality::PartialDown
                            };
                            
                            matches.push(DirectoryMatch {
                                path: path.clone(),
                                depth_from_current: if depth == 0 { 0 } else { depth as i32 },
                                match_quality,
                            });
                            context.add_match();
                        }
                        
                        // Always recurse into subdirectory to find all matches
                        if depth < max_depth && context.start_time.elapsed() <= context.max_time {
                            search_down_tree_fast(&path, search_term, matches, context, depth + 1, max_depth);
                        }
                    }
                }
            }
        }
    }
}

fn search_path_pattern_fast(
    current_dir: &Path, 
    search_term: &str, 
    matches: &mut Vec<DirectoryMatch>,
    context: &mut SearchContext,
) {
    let parts: Vec<&str> = search_term.split('/').collect();
    if parts.is_empty() || !context.should_continue() {
        return;
    }
    
    let first_part = parts[0];
    let remaining_parts = &parts[1..];
    
    // Search for the first part in current directory and subdirectories
    search_pattern_recursive_fast(current_dir, first_part, remaining_parts, matches, context, 0, 3);
    
    // Also search up the tree for the first part (but limit this to avoid slowdown)
    let mut current = current_dir;
    let mut depth = -1;
    let mut up_count = 0;
    
    while let Some(parent) = current.parent() {
        if !context.should_continue() || up_count >= 10 {
            break;
        }
        
        if let Some(name) = parent.file_name() {
            let name_str = name.to_string_lossy();
            if name_str.to_lowercase().contains(&first_part.to_lowercase()) {
                if remaining_parts.is_empty() {
                    let match_quality = if name_str.to_lowercase() == first_part.to_lowercase() {
                        MatchQuality::ExactUp
                    } else {
                        MatchQuality::PartialUp
                    };
                    
                    matches.push(DirectoryMatch {
                        path: parent.to_path_buf(),
                        depth_from_current: depth,
                        match_quality,
                    });
                    context.add_match();
                } else {
                    search_pattern_recursive_fast(parent, &remaining_parts[0], &remaining_parts[1..], matches, context, depth, 3);
                }
            }
        }
        current = parent;
        depth -= 1;
        up_count += 1;
    }
}

fn search_pattern_recursive_fast(
    current_dir: &Path,
    pattern: &str,
    remaining_patterns: &[&str],
    matches: &mut Vec<DirectoryMatch>,
    context: &mut SearchContext,
    base_depth: i32,
    max_depth: usize,
) {
    if max_depth == 0 || !context.should_continue() {
        return;
    }
    
    if let Ok(entries) = fs::read_dir(current_dir) {
        for entry in entries.flatten() {
            if !context.should_continue() {
                break;
            }
            
            if let Ok(metadata) = entry.metadata() {
                if metadata.is_dir() {
                    let path = entry.path();
                    if let Some(name) = path.file_name() {
                        let name_str = name.to_string_lossy();
                        if name_str.to_lowercase().contains(&pattern.to_lowercase()) {
                            if remaining_patterns.is_empty() {
                                let match_quality = if name_str.to_lowercase() == pattern.to_lowercase() {
                                    if base_depth < 0 { MatchQuality::ExactUp } else { MatchQuality::ExactDown }
                                } else {
                                    if base_depth < 0 { MatchQuality::PartialUp } else { MatchQuality::PartialDown }
                                };
                                
                                matches.push(DirectoryMatch {
                                    path: path.clone(),
                                    depth_from_current: base_depth + 1,
                                    match_quality,
                                });
                                context.add_match();
                            } else {
                                search_pattern_recursive_fast(
                                    &path,
                                    remaining_patterns[0],
                                    &remaining_patterns[1..],
                                    matches,
                                    context,
                                    base_depth + 1,
                                    max_depth - 1,
                                );
                            }
                        }
                        
                        // Also recurse into subdirectories to find pattern deeper
                        if context.should_continue() {
                            search_pattern_recursive_fast(
                                &path,
                                pattern,
                                remaining_patterns,
                                matches,
                                context,
                                base_depth + 1,
                                max_depth - 1,
                            );
                        }
                    }
                }
            }
        }
    }
}

fn find_search_root_and_pattern(search_term: &str) -> (Option<PathBuf>, String) {
    let path = Path::new(search_term);
    let mut current = path;
    
    // Walk up the path to find the longest existing prefix
    while let Some(parent) = current.parent() {
        if parent.exists() && parent.is_dir() {
            // Found existing parent directory
            // The search pattern is the first component after this parent
            let remaining = path.strip_prefix(parent).unwrap();
            let mut components = remaining.components();
            if let Some(first_component) = components.next() {
                let pattern = first_component.as_os_str().to_string_lossy().to_string();
                return (Some(parent.to_path_buf()), pattern);
            }
        }
        current = parent;
    }
    
    // If we get here, even root doesn't exist (shouldn't happen on Unix)
    // Fall back to searching from root with the first component as pattern
    let first_component = Path::new(search_term)
        .components()
        .nth(1) // Skip the root component "/"
        .map(|c| c.as_os_str().to_string_lossy().to_string())
        .unwrap_or_else(|| search_term.trim_start_matches('/').to_string());
    (Some(PathBuf::from("/")), first_component)
}

fn search_breadth_first(
    root_dir: &Path,
    search_term: &str,
    matches: &mut Vec<DirectoryMatch>,
    context: &mut SearchContext,
    max_depth: usize,
) {
    use std::collections::VecDeque;
    
    let mut queue = VecDeque::new();
    queue.push_back((root_dir.to_path_buf(), 0));
    
    while let Some((current_dir, depth)) = queue.pop_front() {
        if depth > max_depth || !context.should_continue() {
            continue;
        }
        
        if let Ok(entries) = fs::read_dir(&current_dir) {
            let mut level_matches = Vec::new();
            let mut subdirs = Vec::new();
            
            for entry in entries.flatten() {
                if !context.should_continue() {
                    break;
                }
                
                if let Ok(metadata) = entry.metadata() {
                    if metadata.is_dir() {
                        let path = entry.path();
                        if let Some(name) = path.file_name() {
                            let name_str = name.to_string_lossy();
                            let name_lower = name_str.to_lowercase();
                            let search_lower = search_term.to_lowercase();
                            
                            // Check for match
                            let is_match = search_term.is_empty() || 
                                         name_lower == search_lower ||
                                         name_lower.starts_with(&search_lower) ||
                                         name_lower.contains(&search_lower);
                            
                            if is_match {
                                let quality_score = if name_lower == search_lower {
                                    0 // Exact match
                                } else if name_lower.starts_with(&search_lower) {
                                    1 // Prefix match
                                } else {
                                    2 // Substring match
                                };
                                
                                let match_quality = if quality_score == 0 {
                                    MatchQuality::ExactDown
                                } else {
                                    MatchQuality::PartialDown
                                };
                                
                                level_matches.push((quality_score, DirectoryMatch {
                                    path: path.clone(),
                                    depth_from_current: depth as i32,
                                    match_quality,
                                }));
                            }
                            
                            // Add to queue for next level search
                            if depth < max_depth {
                                subdirs.push(path);
                            }
                        }
                    }
                }
            }
            
            // Sort and add matches from this level
            level_matches.sort_by_key(|(score, _)| *score);
            for (_, match_entry) in level_matches {
                if !context.should_continue() {
                    break;
                }
                matches.push(match_entry);
                context.add_match();
            }
            
            // Add subdirectories to queue for next level
            for subdir in subdirs {
                if context.should_continue() {
                    queue.push_back((subdir, depth + 1));
                }
            }
        }
    }
}