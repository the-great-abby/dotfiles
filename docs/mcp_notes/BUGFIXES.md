# Bug Fixes - JSON Parsing and Banter Display

## Issues Fixed

### 1. JSON Parsing Error in Auto-Suggestions
**Problem:** The AI was sometimes returning malformed JSON, causing parsing errors like:
```
Error parsing suggestions: Expecting ',' delimiter: line 4 column 5 (char 53)
```

**Fix:**
- Improved JSON extraction with multiple fallback strategies
- Better regex patterns to find JSON in responses
- Cleanup of markdown code blocks
- Graceful fallback to empty array if parsing fails
- Simplified prompt to request only JSON arrays

### 2. Banter Not Showing in gtd-daily-log
**Problem:** Auto-suggestions ran in background with output redirected to /dev/null, so banter never appeared.

**Fix:**
- Created `extract_banter.py` helper script for reliable JSON parsing
- Modified `gtd-daily-log` to extract and display banter after a short delay
- Banter now appears ~2 seconds after logging (non-blocking)
- Fallback parsing if helper script unavailable

### 3. Better Error Handling
- More robust JSON parsing that handles various response formats
- Better error messages
- Graceful degradation if parsing fails

## How It Works Now

### Daily Log Flow
1. User runs `gtd-daily-log "entry text"`
2. Entry is logged immediately
3. Auto-suggestions run in background
4. Banter is extracted and saved to temp file
5. After ~2 seconds, banter is displayed (non-blocking)

### Wizard Flow
1. User selects option 23 → Get task suggestions
2. Text is analyzed by AI
3. JSON is parsed with multiple fallback strategies
4. Results are displayed formatted
5. If parsing fails, raw output is shown

## Testing

Test the fixes:

```bash
# Test daily logging with banter
gtd-daily-log "Just finished a great workout!"

# Test wizard suggestions
gtd-wizard
# Choose option 23 → option 1
```

## Files Modified

- `mcp/gtd_auto_suggest.py` - Improved JSON parsing and prompts
- `bin/gtd-daily-log` - Added banter display
- `mcp/extract_banter.py` - New helper script
- `bin/gtd-wizard` - Better error handling for JSON

## Future Improvements

- Add JSON schema validation
- Better prompt engineering for more consistent JSON
- Cache parsing results
- Add retry logic for failed parsing

