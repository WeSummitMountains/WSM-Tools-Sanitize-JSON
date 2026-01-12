/**
 * Invocable Apex action to sanitize JSON strings by removing control characters.
 * Used in Flows before HTTP callouts to prevent "Invalid JSON payload" errors.
 */
public class SanitizeJSON {

    /**
     * Removes control characters (newlines, carriage returns, tabs) from JSON strings.
     * Replaces them with a single space to preserve word separation.
     *
     * @param inputs List of JSON strings to sanitize
     * @return List of sanitized JSON strings
     */
    @InvocableMethod(
        label='Sanitize JSON String'
        description='Removes newlines, carriage returns, and tabs from a JSON string to prevent API errors'
        category='Utilities'
    )
    public static List<String> sanitize(List<String> inputs) {
        List<String> results = new List<String>();

        for (String input : inputs) {
            if (String.isNotBlank(input)) {
                // Replace all control characters with a single space
                // \r = carriage return, \n = newline, \t = tab
                // The + means one or more consecutive occurrences become a single space
                String sanitized = input.replaceAll('[\\r\\n\\t]+', ' ');

                // Also collapse any resulting multiple spaces into single spaces
                sanitized = sanitized.replaceAll(' {2,}', ' ');

                results.add(sanitized);
            } else {
                results.add(input);
            }
        }

        return results;
    }
}
