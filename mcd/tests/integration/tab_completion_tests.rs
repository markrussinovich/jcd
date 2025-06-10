const assert = require('assert');

describe('Tab Completion Tests', () => {
    it('should expand mcd 4 to foo/foo1/foo2/foo3a/foo4 and offer foo/foo1/foo2/foo3b/foo4', () => {
        const input = 'mcd 4';
        const expectedExpansion = 'foo/foo1/foo2/foo3a/foo4';
        const expectedCompletion = ['foo/foo1/foo2/foo3b/foo4'];

        const expansionResult = expandCommand(input);
        const completionResult = getTabCompletion(expansionResult);

        assert.strictEqual(expansionResult, expectedExpansion);
        assert.deepStrictEqual(completionResult, expectedCompletion);
    });

    it('should offer subdirectories of datadrive when typing mcd /tmp/', () => {
        const input = 'mcd /tmp/';
        const expectedCompletion = ['foo1', 'foo2'];

        const completionResult = getTabCompletion(input);

        assert.deepStrictEqual(completionResult, expectedCompletion);
    });

    it('should handle empty directories gracefully', () => {
        const input = 'mcd emptyDir';
        const expectedExpansion = 'emptyDir';

        const expansionResult = expandCommand(input);
        const completionResult = getTabCompletion(expansionResult);

        assert.strictEqual(expansionResult, expectedExpansion);
        assert.deepStrictEqual(completionResult, []);
    });
});