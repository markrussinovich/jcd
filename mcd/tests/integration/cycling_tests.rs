const assert = require('assert');

describe('mcd command cycling tests', () => {
    it('should expand mcd 4 to foo/foo1/foo2/foo3a/foo4 and offer foo/foo1/foo2/foo3b/foo4 on tab', () => {
        const input = 'mcd 4';
        const expectedExpansion = 'foo/foo1/foo2/foo3a/foo4';
        const expectedTabCompletion = ['foo/foo1/foo2/foo3b/foo4'];

        const expansionResult = expandCommand(input);
        const tabCompletionResult = getTabCompletion(expansionResult);

        assert.strictEqual(expansionResult, expectedExpansion);
        assert.deepStrictEqual(tabCompletionResult, expectedTabCompletion);
    });

    it('should offer subdirectories of datadrive when typing mcd /tmp/', () => {
        const input = 'mcd /tmp/';
        const expectedSubdirectories = ['foo'];

        const tabCompletionResult = getTabCompletion(input);

        assert.deepStrictEqual(tabCompletionResult, expectedSubdirectories);
    });

    it('should handle empty directories gracefully', () => {
        const input = 'mcd emptyDir';
        const expectedResult = 'No subdirectories available';

        const result = expandCommand(input);

        assert.strictEqual(result, expectedResult);
    });

    it('should handle directories with unexpected characters', () => {
        const input = 'mcd weird@dir';
        const expectedResult = 'Invalid directory name';

        const result = expandCommand(input);

        assert.strictEqual(result, expectedResult);
    });
});