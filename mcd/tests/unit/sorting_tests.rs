fn test_mcd_expansion() {
    let input = "mcd 4";
    let expected_expansion = "foo/foo1/foo2/foo3a/foo4";
    let expected_completion = vec!["foo/foo1/foo2/foo3b/foo4"];

    let expansion = mcd_expand(input);
    assert_eq!(expansion, expected_expansion);

    let completions = mcd_tab_complete(expected_expansion);
    assert_eq!(completions, expected_completion);
}

fn test_mcd_edge_cases() {
    let input = "mcd /tmp/";
    let expected_subdirectories = vec!["datadrive"];

    let completions = mcd_tab_complete(input);
    assert_eq!(completions, expected_subdirectories);
}

fn main() {
    test_mcd_expansion();
    test_mcd_edge_cases();
}