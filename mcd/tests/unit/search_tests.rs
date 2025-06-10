const assert = require('assert');

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mcd_expansion() {
        let input = "mcd 4";
        let expected = "foo/foo1/foo2/foo3a/foo4";
        let result = mcd_expand(input);
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
    fn test_unexpected_characters() {
        let input = "mcd foo1@/";
        let expected_options = vec!["foo1"];
        let result = tab_complete(input);
        assert_eq!(result, expected_options);
    }
}