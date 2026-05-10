# Code Examples

This folder contains code examples and technical reference material for the band reporting integration.

## Files in This Folder

### 1. autofill-example.js
**Purpose:** JavaScript code that gets injected into the reportband.gov WebView to auto-fill contact fields.

**What it does:**
- Maps user contact info to USGS form field IDs
- Fills the form fields automatically
- Triggers change/input events so form knows fields were updated
- Includes helper functions for verification and debugging

**How it's used:**
```dart
// From Flutter
await webViewController.runJavaScript(
  'prefillBandReport(' + jsonEncode(userData) + ')'
);
```

**Key function:** `prefillBandReport(userData)`

---

### 2. pdf-extraction-patterns.txt
**Purpose:** Regex patterns for extracting certificate data from PDFs.

**What it does:**
- Provides 7 regex patterns for extracting fields
- Includes pattern explanation and examples
- Shows accuracy levels for each pattern
- Includes implementation examples in Python and Dart

**Patterns included:**
- Species (e.g., "Mallard")
- Age at Banding (e.g., "Adult")
- Sex (e.g., "Female")
- Banding Date (e.g., "3/15/2023")
- Banding Location (e.g., "Lake Maurepas")
- Banding State (e.g., "LA")
- Research Project (e.g., "Waterfowl Migration Study")

**Example:**
```
Pattern: r'Species:?\s*([^\n,]+)'
Matches: "Species: Mallard" → captures "Mallard"
```

---

### 3. database-schema.sql
**Purpose:** Supabase PostgreSQL schema for storing contact info and band records.

**What it does:**
- Creates two tables: `user_contact_info` and `band_certificates`
- Sets up indexes for fast queries
- Implements Row-Level Security (RLS)
- Includes sample queries and common use cases

**Tables:**

**user_contact_info:**
- Stores hunter's contact information (one per user)
- Fields: first_name, last_name, email, phone, address, city, state, zip
- Used to pre-fill reportband.gov form

**band_certificates:**
- Stores each band report (multiple per user)
- Fields: band_number, harvest_date, location, plus certificate data
- Fields: species, age, sex, banding_date, banding_location, banding_state, project
- Tracks status: pending → submitted → awaiting_certificate → complete

**How to use:**
1. Copy all SQL into Supabase SQL Editor
2. Run to create tables and indexes
3. RLS is automatically enabled

---

## How These Work Together

### User Journey (Technical)

```
1. USER ENTERS CONTACT INFO
   ↓
   Flutter app sends to Supabase
   ↓
   Stored in user_contact_info table

2. USER REPORTS BAND
   ↓
   Opens reportband.gov in WebView
   ↓
   autofill-example.js runs automatically
   ↓
   Contact fields filled (Species, Name, Email, Phone, Address, etc.)
   ↓
   User fills band-specific info manually
   ↓
   User clicks submit to USGS
   ↓
   Band saved to band_certificates table (status: "submitted")

3. USER GETS CERTIFICATE
   ↓
   USGS emails PDF
   ↓
   User uploads PDF to BlindBook
   ↓
   PDF read and text extracted
   ↓
   pdf-extraction-patterns.txt patterns run on text
   ↓
   Fields extracted: species, age, sex, banding_date, etc.
   ↓
   Data shown to user for confirmation
   ↓
   User clicks Save
   ↓
   band_certificates table updated with certificate data
   ↓
   Status changed to "complete"

4. USER VIEWS BAND
   ↓
   Reads from band_certificates table
   ↓
   Displays all data + generated story
```

---

## Implementation Checklist

### PART 1: Foundation (Band Reporting)

- [ ] Create Supabase tables (use database-schema.sql)
- [ ] Create Dart models for ContactInfo and BandCertificate
- [ ] Create service for saving/loading contact info
- [ ] Create service for saving/loading band records
- [ ] Create UI form for entering contact information
- [ ] Create WebView screen for reportband.gov
- [ ] Integrate autofill-example.js into WebView
- [ ] Create main "Bands" tab showing user's bands
- [ ] Add database indexes
- [ ] Test end-to-end

### PART 2: Enhancement (Certificate Capture)

- [ ] Add file picker package (file_picker)
- [ ] Add PDF reading package (pdfx)
- [ ] Create PDF extraction service using pdf-extraction-patterns.txt
- [ ] Create certificate upload screen (file picker)
- [ ] Create certificate preview screen
- [ ] Implement regex extraction logic
- [ ] Create certificate summary screen
- [ ] Add story generation from certificate data
- [ ] Add certificate data to band_certificates table
- [ ] Test with real USGS certificates

---

## Testing the Code

### Test JavaScript (in Browser Console)

```javascript
// Load autofill-example.js code
// Then run:

const testData = {
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '(555) 123-4567',
  street: '123 Main St',
  city: 'Springfield',
  state: 'MO',
  zip: '65201'
};

prefillBandReport(testData);
verifyFormFilled(testData);  // See results
```

### Test Regex Patterns (in Python)

```python
import re
from pdf_extraction_patterns import patterns

# Sample certificate text
cert_text = """
CERTIFICATE OF APPRECIATION
Band Number: 1234567
Species: Mallard
Age at Banding: Adult
Sex: Female
Banding Date: 3/15/2023
Banding Location: Lake Maurepas
Banding State: LA
Research Project: Waterfowl Migration Study
"""

# Extract data
results = {}
for field, pattern in patterns.items():
    match = re.search(pattern, cert_text)
    if match:
        results[field] = match.group(1)

print(results)
# Output: {'species': 'Mallard', 'age': 'Adult', ...}
```

### Test Database Schema

```sql
-- In Supabase SQL Editor, run database-schema.sql

-- Then test with sample queries:
SELECT * FROM user_contact_info;
SELECT * FROM band_certificates;

-- Test insert:
INSERT INTO user_contact_info (user_id, first_name, last_name, email, phone, street_address, city, state_province, zip_postal_code)
VALUES ('test-user-id', 'John', 'Doe', 'john@example.com', '(555)123-4567', '123 Main', 'Springfield', 'MO', '65201');

-- Test select:
SELECT * FROM user_contact_info WHERE user_id = 'test-user-id';
```

---

## Key Implementation Notes

### JavaScript Injection (Flutter WebView)

```dart
// In your WebView controller setup:
await webViewController.runJavaScript(
  '''
  function prefillBandReport(userData) {
    // ... JavaScript code from autofill-example.js
  }
  '''
);

// When user clicks "Report Band":
await webViewController.runJavaScript(
  'prefillBandReport(' + jsonEncode(userData) + ')'
);
```

### Regex Pattern Matching (Dart)

```dart
// For each certificate PDF:
final pattern = RegExp(r'Species:?\s*([^\n,]+)', caseSensitive: false);
final match = pattern.firstMatch(pdfText);
if (match != null) {
  final species = match.group(1);
}
```

### Database Operations (Supabase)

```dart
// Save contact info
await supabase
  .from('user_contact_info')
  .upsert({
    'user_id': userId,
    'first_name': firstName,
    'last_name': lastName,
    // ... other fields
  });

// Load contact info
final data = await supabase
  .from('user_contact_info')
  .select()
  .eq('user_id', userId)
  .single();

// Save band
await supabase
  .from('band_certificates')
  .insert({
    'user_id': userId,
    'band_number': bandNumber,
    'harvest_date': harvestDate,
    // ... other fields
  });
```

---

## Dependencies Needed

### PART 1
- `flutter_webview_plugin` or `webview_flutter` - For embedding reportband.gov
- `supabase_flutter` - For database access

### PART 2
- `file_picker` - For selecting PDF files
- `pdfx` - For reading PDF files
- `regex` or built-in Dart `RegExp` - For pattern matching

### Optional
- `intl` - For date formatting
- `uuid` - For generating UUIDs
- `logger` - For debugging

---

## Environment Setup

1. **Supabase Project**
   - Create account at supabase.com
   - Create new project
   - Run database-schema.sql in SQL Editor
   - Get your Supabase URL and API key

2. **Flutter Project**
   - Add dependencies to pubspec.yaml
   - Import packages in Dart files
   - Initialize Supabase client

3. **API Keys**
   - Store Supabase URL in environment
   - Store API key securely (not in code)

---

## Common Issues & Solutions

### Issue: JavaScript injection doesn't work
**Solution:**
- Check if webViewController is properly initialized
- Verify JavaScript code has no syntax errors
- Try alternative field selectors (name instead of id)
- Check browser console for errors

### Issue: Regex extraction misses fields
**Solution:**
- PDF text might have extra whitespace
- Try alternative patterns (provided in pdf-extraction-patterns.txt)
- Pre-process text (normalize whitespace, trim)
- Add manual fallback (show form to user)

### Issue: RLS prevents data access
**Solution:**
- Ensure user is logged in to auth.users
- Verify user_id matches auth.uid()
- Check RLS policies are correctly set
- Test with admin user (bypass RLS)

---

## Production Checklist

- [ ] Test with real reportband.gov (not mocked)
- [ ] Test with real USGS certificates
- [ ] Test RLS policies with multiple users
- [ ] Test error handling (network, invalid PDF, etc.)
- [ ] Test performance with many bands (100+)
- [ ] Monitor USGS website for form changes
- [ ] Set up alerting for extraction failures
- [ ] Create admin dashboard for monitoring
- [ ] Document any form/format changes
- [ ] Have manual fallback for edge cases

---

## Support & Troubleshooting

If code doesn't work:
1. Check that all dependencies are installed
2. Verify Supabase tables are created
3. Test JavaScript in browser console first
4. Test regex patterns in regex tester
5. Check Supabase logs for errors
6. Enable debug logging in Flutter

For detailed implementation help, see the main RESEARCH_AND_RECOMMENDATION.md file.
