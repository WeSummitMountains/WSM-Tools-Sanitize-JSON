# JSON Sanitization Invocable Action - Implementation Guide

## Overview

This guide walks through implementing an Apex Invocable Action that sanitizes JSON strings by removing control characters (newlines, carriage returns, tabs) that can cause "Invalid JSON payload" errors when calling external APIs.

**Problem**: Flow text templates inject field values directly into JSON. If a field like `MailingStreet` contains a newline character, the resulting JSON becomes malformed.

**Solution**: Create a reusable Apex action that sanitizes the JSON string before sending it to the external API.

---

## Step 1: Create the Apex Class

**File**: `force-app/main/default/classes/SanitizeJSON.cls`

```apex
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
```

---

## Step 2: Create the Test Class

Salesforce requires 75% code coverage for deployment. This test class provides 100% coverage.

**File**: `force-app/main/default/classes/SanitizeJSONTest.cls`

```apex
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
```

---

## Step 3: Deploy the Apex Classes

### Option A: Deploy via Salesforce Setup UI

1. Navigate to **Setup** → **Apex Classes**
2. Click **New**
3. Paste the `SanitizeJSON` class code
4. Click **Save**
5. Repeat for `SanitizeJSONTest`
6. Run the tests to verify: **Setup** → **Apex Test Execution** → **Select Tests** → **SanitizeJSONTest**

### Option B: Deploy via VS Code / SFDX

```bash
# If using scratch org or sandbox
sfdx force:source:push

# If deploying to production
sfdx force:source:deploy -p force-app/main/default/classes -l RunSpecifiedTests -r SanitizeJSONTest
```

---

## Step 4: Modify the Flow

Open the Flow: **WSM - ALF - Test DealerTrak Post**

### 4.1 Create New Variables for Sanitized Output

1. In the Toolbox, click **New Resource**
2. Create a new variable:
   - **Resource Type**: Variable
   - **API Name**: `SanitizedWithoutCoAppBody`
   - **Data Type**: Text
   - **Available for input**: unchecked
   - **Available for output**: unchecked

3. Repeat to create `SanitizedWithCoAppBody`

### 4.2 Add Sanitize Action Before HTTP Calls (Without Co-Applicant Path)

1. On the path leading to `HTTP_Live_Call`, add a new **Action** element between the decision and the HTTP call
2. Configure the Action:
   - **Search**: "Sanitize JSON String"
   - **Label**: `Sanitize Body Without CoApp`
   - **API Name**: `Sanitize_Body_Without_CoApp`
   - **Input**: Set the input parameter to `{!WithoutCoAppBodyCalc}`
   - **Output**: Store the output in `{!SanitizedWithoutCoAppBody}`

3. Update the `HTTP_Live_Call` action:
   - Change **Body** from `{!WithoutCoAppBodyCalc}` to `{!SanitizedWithoutCoAppBody}`

### 4.3 Add Sanitize Action Before HTTP Calls (With Co-Applicant Path)

1. On the path leading to `HTTP_Live_Call_CoApp`, add a new **Action** element
2. Configure the Action:
   - **Label**: `Sanitize Body With CoApp`
   - **API Name**: `Sanitize_Body_With_CoApp`
   - **Input**: Set the input parameter to `{!WithCoAppBodyCalc}`
   - **Output**: Store the output in `{!SanitizedWithCoAppBody}`

3. Update the `HTTP_Live_Call_CoApp` action:
   - Change **Body** from `{!WithCoAppBodyCalc}` to `{!SanitizedWithCoAppBody}`

### 4.4 Repeat for Test Path

Apply the same pattern to the test path HTTP calls:
- `Copy_3_of_Make_HTTP_Call_Action_2` (without co-app)
- `Make_HTTP_Call_Action_2` (with co-app)

---

## Step 5: Updated Flow Structure

After modification, the flow should look like:

```
[Auth Call]
    → [Decision: Co-Applicant?]
        → Yes: [Sanitize Body With CoApp] → [HTTP Call CoApp]
        → No:  [Sanitize Body Without CoApp] → [HTTP Call]
```

---

## Step 6: Test the Implementation

### 6.1 Create Test Data

Create or update a Contact record with a newline in the address:
1. Open a Contact record
2. In the Mailing Street field, enter:
   ```
   123 Main St
   Apt 4B
   ```
   (Press Enter between the lines)

### 6.2 Run the Flow in Test Mode

1. Open the Flow in Flow Builder
2. Click **Debug**
3. Set `LivePushVar` = `false` (to use test endpoint)
4. Select a record with the test address
5. Run and verify the HTTP call succeeds

### 6.3 Verify in Debug Logs

1. Enable debug logs for the running user
2. Trigger the flow
3. Check the logs for the sanitized JSON body - confirm no `\n` characters present

---

## Troubleshooting

### "Sanitize JSON String" action not appearing in Flow

- Verify the Apex class compiled without errors
- Check that `@InvocableMethod` annotation is present
- Try refreshing the Flow Builder or clearing browser cache

### Tests failing

- Run tests from Setup → Apex Test Execution
- Check the error messages for specific assertion failures
- Verify the regex pattern handles all expected control characters

### HTTP calls still failing after implementation

- Add a debug element in Flow to output `{!SanitizedWithoutCoAppBody}`
- Verify the sanitized variable is actually being used in the HTTP call
- Check for other potential issues (invalid VIN length, missing required fields, etc.)

---

## Summary

| Component | Purpose |
|-----------|---------|
| `SanitizeJSON.cls` | Invocable action that removes control characters |
| `SanitizeJSONTest.cls` | Test coverage for deployment |
| Flow Variables | Store sanitized JSON before HTTP calls |
| Flow Actions | Call the sanitizer before each HTTP callout |

This solution sanitizes the entire JSON payload in one operation, protecting against control characters in any field without needing to modify individual formula fields.
