# Event Log Analyzer Fix - Invalid Query Error

## Issue Summary

The Event Log Analyzer was failing to retrieve events from all Windows Event Logs with the error:
```
Get-EventLogAnalysis : Failed to analyze event log 'Application': The specified query is invalid
```

This error occurred for all three default logs: Application, System, and Security.

## Root Cause

The issue was in the XML query construction for `Get-WinEvent`. The Level filter portion of the XPath query was being constructed inline within the here-string, causing potential issues with string interpolation and XML formatting.

**Problematic Code (Line 311):**
```powershell
$filterXml = @"
<QueryList>
  <Query Id="0" Path="$LogName">
    <Select Path="$LogName">
      *[System[TimeCreated[@SystemTime&gt;='$($StartTime.ToUniversalTime().ToString('o'))' and @SystemTime&lt;='$($EndTime.ToUniversalTime().ToString('o'))'] and ($($levels | ForEach-Object { "Level=$_" }) -join ' or ')]]
    </Select>
  </Query>
</QueryList>
"@
```

The inline construction `($($levels | ForEach-Object { "Level=$_" }) -join ' or ')` was problematic because:
1. Complex nested string interpolation within XML here-strings can fail
2. The expression wasn't being properly expanded before XML construction
3. Error messages were not helpful for debugging

## Solution Implemented

### 1. Separate Level Filter Construction

**File:** `scripts/EventLogAnalyzer.ps1`  
**Lines:** 301-312

**Fixed Code:**
```powershell
# Build Level filter part properly
$levelFilter = ($levels | ForEach-Object { "Level=$_" }) -join ' or '

$filterXml = @"
<QueryList>
  <Query Id="0" Path="$LogName">
    <Select Path="$LogName">
      *[System[TimeCreated[@SystemTime&gt;='$($StartTime.ToUniversalTime().ToString('o'))' and @SystemTime&lt;='$($EndTime.ToUniversalTime().ToString('o'))'] and ($levelFilter)]]
    </Select>
  </Query>
</QueryList>
"@
```

**Benefits:**
- Level filter is constructed before the XML string
- Easier to debug - can inspect $levelFilter variable
- Cleaner code separation
- More reliable string interpolation

### 2. Enhanced Error Handling

**Added** (Lines 314-336):
```powershell
# Log the filter for debugging
Write-Verbose "FilterXml Query:`n$filterXml"
Write-Log "Query filter: Start=$($StartTime.ToUniversalTime().ToString('o')), End=$($EndTime.ToUniversalTime().ToString('o')), Levels=$($levels -join ',')" -Level INFO

try {
    $events = Get-WinEvent -FilterXml $filterXml -MaxEvents $MaxEvents -ErrorAction Stop
    Write-Log "Retrieved $($events.Count) events from $LogName" -Level SUCCESS
}
catch {
    if ($_.Exception.Message -match "No events were found") {
        Write-Log "No events found in $LogName for specified criteria" -Level INFO
        $events = @()
    }
    elseif ($_.Exception.Message -match "specified query is invalid") {
        Write-Log "Invalid query for $LogName. Filter: $levelFilter" -Level ERROR
        Write-Error "Failed to analyze event log '$LogName': The specified query is invalid. This may be due to incorrect date format or log access permissions."
        return $null
    }
    else {
        Write-Log "Error querying $LogName : $($_.Exception.Message)" -Level ERROR
        throw
    }
}
```

**Benefits:**
- Specific error handling for "invalid query" errors
- Verbose logging of the actual XML query for debugging
- Better user-facing error messages
- Logs query parameters for troubleshooting

### 3. Code Cleanup

**Removed unused variables:**
- Line 285: `$filterHash` - was defined but never used
- Line 596: `$logInfo` - Initialize-Logging return value wasn't needed

## Testing

After implementing these fixes, test the Event Log Analyzer:

1. **Run the analyzer:**
   ```powershell
   .\scripts\EventLogAnalyzer.ps1
   ```

2. **Expected behavior:**
   - Should successfully query Application, System, and Security logs
   - Should display event counts
   - Should create export files (JSON and CSV)

3. **With verbose output:**
   ```powershell
   .\scripts\EventLogAnalyzer.ps1 -Verbose
   ```
   This will show the actual XML query being executed for debugging.

## Technical Details

### XPath Query Structure

The corrected XPath query follows this structure:

```xml
*[System[TimeCreated[@SystemTime>='StartDateTime' and @SystemTime<='EndDateTime'] and (Level=1 or Level=2 or Level=3)]]
```

Where:
- `System` - The System element of the event
- `TimeCreated[@SystemTime>=... and @SystemTime<=...]` - Time range filter
- `(Level=1 or Level=2 or Level=3)` - Event level filter (properly parenthesized)

### Level Mapping

| Entry Type | Level IDs |
|-----------|-----------|
| Error | 1 (Critical), 2 (Error) |
| Warning | 3 (Warning) |
| Information | 4 (Information) |

### Date Format

The query uses ISO 8601 format (`'o'` format specifier) in UTC:
```
2025-10-23T19:52:55.0000000Z
```

This ensures consistent date parsing across different locales.

## Prevention

To avoid similar issues in the future:

1. **Keep XML construction simple** - Build complex expressions outside of here-strings
2. **Use variables for dynamic content** - Don't nest complex expressions in strings
3. **Add verbose logging** - Include diagnostic output for debugging
4. **Test with -Verbose** - Use verbose mode to see actual queries
5. **Handle specific errors** - Catch and handle known error patterns

## Common Issues

### If errors persist:

1. **Check Administrator privileges:**
   ```powershell
   # Some logs require admin access
   # Run as Administrator
   ```

2. **Verify log exists:**
   ```powershell
   Get-WinEvent -ListLog Application,System,Security
   ```

3. **Check date range:**
   ```powershell
   # Ensure date range is valid and not too far in the past
   # Default is last 24 hours
   ```

4. **Test manually:**
   ```powershell
   # Test the query manually
   Get-WinEvent -FilterXml $filterXml -MaxEvents 10
   ```

## Files Modified

1. **scripts/EventLogAnalyzer.ps1**
   - Lines 284-290: Removed unused filterHash
   - Lines 301-312: Fixed Level filter construction  
   - Lines 314-336: Enhanced error handling
   - Line 596: Fixed unused logInfo variable

2. **docs/EVENT_ANALYZER_FIX.md** (this file)
   - Created documentation for the fix

3. **workflow_state.md**
   - Updated with fix progress

## Date

Fixed: October 23, 2025

## Status

✅ **FIXED** - XML query construction corrected, error handling improved, testing recommended

---

**Note:** If you continue to experience issues, run with `-Verbose` flag and check the log file in:
```
C:\Users\[YourName]\AppData\Local\Temp\SouliTEK-Scripts\EventLogAnalyzer\
```

