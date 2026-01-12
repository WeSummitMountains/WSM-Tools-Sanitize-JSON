# JSON Sanitization Invocable Action

[![Deploy to Salesforce](image_url)](https://githubsfdeploy.herokuapp.com/.../WSM-Tools-Sanatize-JSON)

An Apex Invocable Action that sanitizes JSON strings by removing control characters (newlines, carriage returns, tabs) that can cause "Invalid JSON payload" errors when calling external APIs from Salesforce Flows.

## Problem

Flow text templates inject field values directly into JSON. If a field like `MailingStreet` contains a newline character, the resulting JSON becomes malformed and API calls fail.

## Solution

A reusable Apex action that sanitizes the entire JSON payload before sending it to an external API.

## Files

| File | Description |
|------|-------------|
| `SanitizeJSON.cls` | Invocable action that removes control characters |
| `SanitizeJSONTest.cls` | Test class with 100% coverage |

## Deployment

### Option A: Salesforce Setup UI

1. Navigate to **Setup** → **Apex Classes** → **New**
2. Paste the contents of `SanitizeJSON.cls` and save
3. Repeat for `SanitizeJSONTest.cls`
4. Run tests: **Setup** → **Apex Test Execution** → **SanitizeJSONTest**

### Option B: SFDX CLI

```bash
# Sandbox or scratch org
sfdx force:source:push

# Production
sfdx force:source:deploy -p force-app/main/default/classes -l RunSpecifiedTests -r SanitizeJSONTest
```

## Usage in Flow

### 1. Create Flow Variables

Create text variables to store the sanitized output:
- `SanitizedWithoutCoAppBody`
- `SanitizedWithCoAppBody`

### 2. Add Sanitize Action Before HTTP Calls

1. Add an **Action** element before each HTTP callout
2. Search for **"Sanitize JSON String"**
3. Set the input to your JSON body variable (e.g., `{!WithoutCoAppBodyCalc}`)
4. Store the output in your sanitized variable (e.g., `{!SanitizedWithoutCoAppBody}`)

### 3. Update HTTP Call

Change the HTTP call **Body** to use the sanitized variable instead of the original.

### Flow Structure

```
[Auth Call]
    → [Decision: Co-Applicant?]
        → Yes: [Sanitize Body With CoApp] → [HTTP Call CoApp]
        → No:  [Sanitize Body Without CoApp] → [HTTP Call]
```

## Troubleshooting

**Action not appearing in Flow?**
- Verify the Apex class compiled without errors
- Refresh Flow Builder or clear browser cache

**HTTP calls still failing?**
- Add a debug element to verify the sanitized variable is being used
- Check for other issues (invalid field lengths, missing required fields, etc.)
