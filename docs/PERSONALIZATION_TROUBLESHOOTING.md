# Personalization Troubleshooting Guide

## Issue: Data Not Persisting Between Sessions

### Symptoms
- Claude says it updated personalization data
- But in the next session, the information is missing or incorrect
- Claude makes up information that was never saved

### Root Causes

#### 1. **Data Structure Mismatch**

**Problem:** When Claude updates `relationships.partner` with just a string `"Louiza"`, it may overwrite an existing object structure.

**Solution:** The update handler now automatically preserves object structure for `relationships.partner`. If you pass a string, it converts to:
```json
{
  "name": "Louiza",
  "relationship_type": "partner"
}
```

#### 2. **Claude Hallucinating Information**

**Problem:** Claude may make up details that weren't actually saved (e.g., saying Louiza is a software engineer when that was never mentioned).

**Solution:** 
- System messages now explicitly tell Claude to ONLY use information actually in the file
- Claude is instructed not to make up or infer details
- If information isn't in the file, Claude should say it doesn't have that information

#### 3. **Update Handler Not Preserving Structure**

**Problem:** The handler was overwriting structured data with simple values.

**Solution:** Special handling for `relationships.partner` field to preserve object structure even when a string is passed.

## Verification Steps

### Check What's Actually Saved

```bash
# View full personalization file
cat ~/.gtd_personalization.json | python3 -m json.tool

# Check specific category
cat ~/.gtd_personalization.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(json.dumps(data.get('relationships', {}), indent=2))
"
```

### Test Update Tool

```python
# Test updating partner name
gtd_update_personalization(
    category="relationships",
    field="partner",
    value="Louiza",
    operation="set"
)

# Then check if it was saved correctly
gtd_get_personalization(category="relationships")
```

### Verify Data Persists

1. Update personalization in one session
2. End the session
3. Start a new session
4. Call `gtd_get_personalization()` 
5. Verify the data is still there

## Common Issues

### Issue: Partner Field is String Instead of Object

**Symptom:** `"partner": "Louiza"` instead of `"partner": {"name": "Louiza", "relationship_type": "partner"}`

**Fix:** The handler now automatically converts strings to objects for `relationships.partner`. If you have existing data that's a string, you can:

1. **Manual fix:**
```bash
python3 << 'EOF'
import json
from pathlib import Path
from datetime import datetime

personalization_file = Path.home() / ".gtd_personalization.json"
with open(personalization_file, 'r') as f:
    data = json.load(f)

if isinstance(data.get("relationships", {}).get("partner"), str):
    data["relationships"]["partner"] = {
        "name": data["relationships"]["partner"],
        "relationship_type": "partner"
    }
    data["last_updated"] = datetime.now().isoformat()
    
    with open(personalization_file, 'w') as f:
        json.dump(data, f, indent=2)
    print("✓ Fixed")
EOF
```

2. **Or use the wizard:**
```bash
gtd-wizard
# Select: 67) Personalization Setup
# Then: 1) Relationships & Life Situation
# Re-enter partner name - it will save correctly
```

### Issue: Claude Making Up Information

**Symptom:** Claude says things like "Louiza is a software engineer" when that was never mentioned.

**Cause:** Claude is hallucinating or inferring information not in the personalization file.

**Fix:**
- System messages now explicitly tell Claude to ONLY use information in the file
- Claude should call `gtd_get_personalization()` to verify what's actually stored
- If information isn't there, Claude should say it doesn't have that information

### Issue: Updates Not Saving

**Symptom:** Claude calls `gtd_update_personalization` and says it succeeded, but the file doesn't change.

**Check:**
1. Verify file permissions: `ls -la ~/.gtd_personalization.json`
2. Check for errors in the tool response
3. Verify the update handler is being called correctly

**Fix:**
- Ensure file is writable: `chmod 644 ~/.gtd_personalization.json`
- Check disk space: `df -h ~`
- Review tool execution logs if available

## Best Practices

### For Claude

1. **Always verify before updating:**
   - Call `gtd_get_personalization(category="...")` first
   - Check what's already there
   - Only update if information is missing or needs correction

2. **Only save explicit information:**
   - Don't infer or assume
   - Don't make up details
   - If uncertain, ask the user

3. **Verify after updating:**
   - Call `gtd_get_personalization()` after updating
   - Confirm the data was saved correctly
   - If not, try again or report the issue

### For Users

1. **Review saved data periodically:**
   ```bash
   cat ~/.gtd_personalization.json | python3 -m json.tool
   ```

2. **Use the wizard for important updates:**
   ```bash
   gtd-wizard
   # Select: 67) Personalization Setup
   ```

3. **Correct Claude if it's wrong:**
   - If Claude says something incorrect, correct it
   - Claude can update the personalization data based on your correction

## Testing

### Test Update and Retrieval

```bash
# In a Claude session:
# 1. Update personalization
gtd_update_personalization(category="goals", field="career", value="Learn Kubernetes", operation="append")

# 2. Verify it was saved
gtd_get_personalization(category="goals")

# 3. End session and start new one

# 4. Verify data persists
gtd_get_personalization(category="goals")
```

### Test Data Structure Preservation

```bash
# Test that partner field maintains object structure
python3 << 'EOF'
from pathlib import Path
import json

# Simulate update
personalization_file = Path.home() / ".gtd_personalization.json"
with open(personalization_file, 'r') as f:
    data = json.load(f)

# Check partner structure
partner = data.get("relationships", {}).get("partner")
if isinstance(partner, dict):
    print("✓ Partner is object (correct)")
    print(f"  Name: {partner.get('name')}")
    print(f"  Type: {partner.get('relationship_type')}")
elif isinstance(partner, str):
    print("⚠ Partner is string (needs fixing)")
    print(f"  Value: {partner}")
else:
    print("? Partner field has unexpected type")
EOF
```

## Related Documentation

- [Personalization Capabilities](./PERSONALIZATION_CAPABILITIES.md) - What information is helpful
- [Personalization Wizard](./PERSONALIZATION_WIZARD.md) - Manual setup
- [Personalization Learning](./PERSONALIZATION_LEARNING.md) - AI-driven updates
- [Personalization Skill](./PERSONALIZATION_SKILL.md) - How Claude accesses data
