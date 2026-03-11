$pat = '(?x)
^
  (?:  \[(?<time> [^\]]+)\])
  (?:\ \[(?<svr>  [^\]]+)\])
  (?:\.\[(?<db>   [^\]]+)\])?
  (?:\ \[(?<sync> [^\]]+)\])?
  (?:\ \[(?<proc> [^\]]+)\])?
  (?:\ \[(?<lbl1> [^\]]+)\])?
  \ Done:\ (?<action>[^\(\[]+)
  (?:\ \((?<rows> [\d,]+)\ rows?\))?
  (?:\ \[(?<ts>   [^\]]+)\])?
$
'
$last_log_file = gci -File -Filter *.log | sort LastWriteTime -Descending | select -First 1

$last_log_file | gc -Tail 10000 -Wait | ? { $_ -match 'Done:' } |
    % {
        if ($_ -notmatch $pat) { [pscustomobject]@{ Raw = $_ }; return }
        [pscustomobject]@{
            Timestamp  = [datetime]$Matches['time']
            Server     = $Matches['svr']
            Database   = $Matches['db']
            SyncObject = $Matches['sync']
            Proc       = $Matches['proc']
            Label1     = $Matches['lbl1']
            Action     = $Matches['action'].Trim()
            Rows       = $Matches['rows'] ? [int]$Matches['rows'] : $null
            Duration   = $Matches['ts'] ? [timespan]$Matches['ts'] : $null
            #Raw        = $_
        }
    } |
    ? { $_.Duration.TotalSeconds -gt 5  -and $_.Action -notin ('Instance','Database','Sync') } |
    ft Timestamp, Server, Database, SyncObject, Proc, Label1, Action, Rows, Duration, Raw