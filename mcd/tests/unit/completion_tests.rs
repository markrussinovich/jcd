const assert = require('assert');

#[cfg(test)]
mod completion_tests {
    use super::*;

    #[test]
    fn test_mcd_expansion() {
        let input = "mcd 4";
        let expected = "foo/foo1/foo2/foo3a/foo4";
        let result = expand_directory(input);
        assert_eq!(result, expected);
    }

    #[test]
    fn test_tab_completion() {
        let input = "mcd foo/foo1/foo2/foo3a/foo4/";
        let expected_options = vec!["foo/foo1/foo2/foo3b/foo4"];
        let result = tab_complete(input);
        assert_eq!(result, expected_options);
    }

    #[test]
    fn test_empty_directory() {
        let input = "mcd empty_dir/";
        let expected = vec![];
        let result = tab_complete(input);
        assert_eq!(result, expected);
    }

    #[test]
    fn test_special_characters() {
        let input = "mcd special@dir/";
        let expected_options = vec!["special@dir1", "special@dir2"];
        let result = tab_complete(input);
        assert_eq!(result, expected_options);
    }
}