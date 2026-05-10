// USGS Band Report Form Auto-Fill JavaScript
// This code gets injected into reportband.gov WebView
// Purpose: Pre-fill contact information fields automatically
// Usage: Called from Flutter when user clicks "Report Band to USGS"

/**
 * Main function to pre-fill band report form
 * Maps user contact info to USGS form field IDs
 * 
 * @param {Object} userData - User contact information
 * @param {string} userData.firstName - First name
 * @param {string} userData.lastName - Last name
 * @param {string} userData.email - Email address
 * @param {string} userData.phone - Phone number
 * @param {string} userData.street - Street address
 * @param {string} userData.street2 - Street address line 2 (optional)
 * @param {string} userData.city - City
 * @param {string} userData.state - State/province
 * @param {string} userData.zip - Zip/postal code
 */
function prefillBandReport(userData) {
  // Mapping of USGS form field IDs to user data properties
  const fieldMappings = {
    'p_first_name': userData.firstName,
    'p_last_name': userData.lastName,
    'p_email': userData.email,
    'p_phone': userData.phone,
    'p_street1': userData.street,
    'p_street2': userData.street2 || '',
    'p_zip': userData.zip,
    'p_city': userData.city,
    'p_c_state': userData.state
  };

  // Fill each form field
  for (const [fieldId, value] of Object.entries(fieldMappings)) {
    const element = document.getElementById(fieldId);
    
    if (element) {
      // Set the value
      element.value = value || '';
      
      // Trigger change event so form knows field was updated
      // This is important for reactive forms that update on change
      element.dispatchEvent(new Event('change', { bubbles: true }));
      
      // Also trigger input event for forms that listen to input
      element.dispatchEvent(new Event('input', { bubbles: true }));
      
      // Trigger blur event if needed (some forms validate on blur)
      element.dispatchEvent(new Event('blur', { bubbles: true }));
    }
  }

  // Log success for debugging
  console.log('Band report form pre-filled successfully');
  
  // Optional: Scroll to top of form so user sees filled fields
  window.scrollTo(0, 0);
  
  return true;
}

/**
 * Alternative version if form fields use different selectors
 * (This is a fallback if the ID-based approach doesn't work)
 */
function prefillBandReportByName(userData) {
  const fieldMappings = {
    'p_first_name': userData.firstName,
    'p_last_name': userData.lastName,
    'p_email': userData.email,
    'p_phone': userData.phone,
    'p_street1': userData.street,
    'p_zip': userData.zip,
    'p_city': userData.city,
    'p_c_state': userData.state
  };

  for (const [fieldName, value] of Object.entries(fieldMappings)) {
    const element = document.querySelector(`[name="${fieldName}"]`) || 
                   document.querySelector(`[id="${fieldName}"]`);
    
    if (element) {
      element.value = value || '';
      element.dispatchEvent(new Event('change', { bubbles: true }));
      element.dispatchEvent(new Event('input', { bubbles: true }));
    }
  }

  return true;
}

/**
 * Helper function to verify form was filled correctly
 * Can be used for debugging or validation
 */
function verifyFormFilled(userData) {
  const results = {
    filled: 0,
    empty: 0,
    mismatched: 0,
    fields: {}
  };

  const fieldMappings = {
    'p_first_name': userData.firstName,
    'p_last_name': userData.lastName,
    'p_email': userData.email,
    'p_phone': userData.phone,
    'p_street1': userData.street,
    'p_zip': userData.zip,
    'p_city': userData.city,
    'p_c_state': userData.state
  };

  for (const [fieldId, expectedValue] of Object.entries(fieldMappings)) {
    const element = document.getElementById(fieldId);
    
    if (element) {
      const actualValue = element.value;
      const isCorrect = actualValue === expectedValue;
      
      results.fields[fieldId] = {
        expected: expectedValue,
        actual: actualValue,
        correct: isCorrect
      };
      
      if (isCorrect) results.filled++;
      else if (!actualValue) results.empty++;
      else results.mismatched++;
    }
  }

  console.log('Form verification results:', results);
  return results;
}

/**
 * Function to handle form submission (if needed)
 * NOTE: This should NOT be used. User should manually click submit button.
 * Included here for reference only.
 */
function getFormForManualSubmission() {
  const form = document.querySelector('form');
  if (form) {
    console.log('Form found. User should manually click submit button.');
    console.log('Form ID:', form.id);
    console.log('Submit buttons:', form.querySelectorAll('button[type="submit"]'));
    return form;
  }
  return null;
}

// ============================================================
// FLUTTER INTEGRATION EXAMPLE
// ============================================================

/*
In Flutter, you would call this JavaScript like:

```dart
// In your WebView controller setup:
final userData = {
  'firstName': 'John',
  'lastName': 'Doe',
  'email': 'john@example.com',
  'phone': '(555) 123-4567',
  'street': '123 Main Street',
  'street2': '',
  'city': 'Springfield',
  'state': 'Missouri',
  'zip': '65201'
};

// Inject and run JavaScript
await webViewController.runJavaScript(
  'prefillBandReport(' + jsonEncode(userData) + ')'
);

// Optionally verify:
await webViewController.runJavaScript(
  'verifyFormFilled(' + jsonEncode(userData) + ')'
);
```
*/

// ============================================================
// TEST DATA
// ============================================================

// Example userData for testing
const testUserData = {
  firstName: 'John',
  lastName: 'Doe',
  email: 'john.doe@example.com',
  phone: '(555) 123-4567',
  street: '123 Main Street',
  street2: 'Apt 4B',
  city: 'Springfield',
  state: 'MO',
  zip: '65201'
};

// To test in browser console:
// prefillBandReport(testUserData);
// verifyFormFilled(testUserData);
