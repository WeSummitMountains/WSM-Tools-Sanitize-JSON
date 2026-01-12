@isTest
private class SanitizeJSONTest {

    @isTest
    static void testSanitizeWithNewlines() {
        // JSON with embedded newline in address field
        String dirtyJSON = '{"address": {"line1": "123 Main St\nApt 4"}}';

        List<String> inputs = new List<String>{ dirtyJSON };
        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(1, results.size());
        System.assertEquals('{"address": {"line1": "123 Main St Apt 4"}}', results[0]);
    }

    @isTest
    static void testSanitizeWithCarriageReturnNewline() {
        // Windows-style line endings
        String dirtyJSON = '{"name": "Test\r\nValue"}';

        List<String> inputs = new List<String>{ dirtyJSON };
        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(1, results.size());
        System.assertEquals('{"name": "Test Value"}', results[0]);
    }

    @isTest
    static void testSanitizeWithTabs() {
        String dirtyJSON = '{"field": "value\twith\ttabs"}';

        List<String> inputs = new List<String>{ dirtyJSON };
        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(1, results.size());
        System.assertEquals('{"field": "value with tabs"}', results[0]);
    }

    @isTest
    static void testSanitizeWithMultipleControlChars() {
        // Multiple consecutive control characters should become single space
        String dirtyJSON = '{"field": "line1\n\n\nline2"}';

        List<String> inputs = new List<String>{ dirtyJSON };
        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(1, results.size());
        System.assertEquals('{"field": "line1 line2"}', results[0]);
    }

    @isTest
    static void testSanitizeCleanJSON() {
        // Already clean JSON should pass through unchanged
        String cleanJSON = '{"name": "Test", "value": 123}';

        List<String> inputs = new List<String>{ cleanJSON };
        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(1, results.size());
        System.assertEquals(cleanJSON, results[0]);
    }

    @isTest
    static void testSanitizeNullInput() {
        List<String> inputs = new List<String>{ null };
        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(1, results.size());
        System.assertEquals(null, results[0]);
    }

    @isTest
    static void testSanitizeEmptyString() {
        List<String> inputs = new List<String>{ '' };
        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(1, results.size());
        System.assertEquals('', results[0]);
    }

    @isTest
    static void testSanitizeMultipleInputs() {
        // Invocable methods can receive multiple inputs in bulk operations
        List<String> inputs = new List<String>{
            '{"a": "test\nvalue"}',
            '{"b": "clean"}',
            '{"c": "tabs\there"}'
        };

        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(3, results.size());
        System.assertEquals('{"a": "test value"}', results[0]);
        System.assertEquals('{"b": "clean"}', results[1]);
        System.assertEquals('{"c": "tabs here"}', results[2]);
    }

    @isTest
    static void testSanitizeRealisticPayload() {
        // Realistic test case matching the DealerTrack integration
        String payload = '{"applicant": {"address": {"line1": "0996 Deer Blvd.\n#A PO Box 1957"}}}';

        List<String> inputs = new List<String>{ payload };
        List<String> results = SanitizeJSON.sanitize(inputs);

        System.assertEquals(1, results.size());
        System.assert(!results[0].contains('\n'), 'Newline should be removed');
        System.assertEquals('{"applicant": {"address": {"line1": "0996 Deer Blvd. #A PO Box 1957"}}}', results[0]);
    }
}
