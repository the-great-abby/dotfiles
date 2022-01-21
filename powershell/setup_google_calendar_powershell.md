* https://www.cdata.com/kb/tech/googlecalendar-ado-powershell.rst

### can't seem to connect (product key?)
* https://developers.google.com/identity/protocols/oauth2
* https://www.example-code.com/powershell/googleCalendar.asp


## Install
```powershell
Install-Module GoogleCalendarCmdlets
```

## Connect
```powershell
$googlecalendar = Connect-GoogleCalendar
```

## Search and Retrieve Data
```powershell
$searchterms = "beach trip"
$vacationcalendar = Select-GoogleCalendar -Connection $googlecalendar -Table "VacationCalendar" -Where "SearchTerms = `'$SearchTerms`'"
$vacationcalendar
```

OR
```powershell
$vacationcalendar = Invoke-GoogleCalendar -Connection $googlecalendar -Query 'SELECT * FROM VacationCalendar WHERE SearchTerms = @SearchTerms' -Params @{'@SearchTerms'='beach trip'}
```

### Insert Data
```powershell
Add-GoogleCalendar -Connection $GoogleCalendar -Table VacationCalendar -Columns @("Summary", "StartDateTime") -Values @("MySummary", "MyStartDateTime")

```

### Delete Data
```powershell
Remove-GoogleCalendar -Connection $GoogleCalendar -Table "VacationCalendar" -Id "MyId"
```

### Update Data
```powershell
Update-GoogleCalendar -Connection $GoogleCalendar -Columns @('Summary','StartDateTime') -Values @('MySummary', 'MyStartDateTime') -Table VacationCalendar -Id "MyId"
```
