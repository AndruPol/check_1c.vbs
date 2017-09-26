' NSClient++ ������ (https://www.nsclient.org/) ��� �������� �������� 1� ����������� 8
' � ������� ����������� Nagios/Icinga. ���������� COM ���������� (V83|V82.ComConnector)
' ��� ��������� ������ �� ������� 1�:�����������. ������� ���� ;) a.pol@mail.ru
'
' ������:
' 1. ��������� � ����� nsclient.ini �������� NSClient++ ������� ��������
'; A list of wrappped scripts (ie. using the template mechanism)
'[/settings/external scripts/wrapped scripts]
'check_1c_cluster=scripts\\check_1c.vbs /command:cluster
'check_1c_session=scripts\\check_1c.vbs /command:session
'
'; A list of templates for wrapped scripts
'[/settings/external scripts/wrappings]
'; VISUAL BASIC WRAPPING - 
'vbs = cscript.exe //T:30 //NoLogo scripts\\lib\\wrapper.vbs %SCRIPT% %ARGS%
'
' 2. � Nagios/Icinga ��������� ������� �������� �������
' $USER1$/check_nrpe -H $HOSTADDRESS$ -c check_1c_cluster
'
' ������ ����������:
' /hostname:value	- ��� ����� ������� 1�, �� ��������� localhost
' /port:value		- ����� ����� ������� 1�, �� ��������� 1540
' /platform:value	- ��������� 1� (V83 ��� V82), �� ��������� V83
' /infobase:value	- ��� �������������� ���� �� ������� (������ � �������� infobase)
' /clusteradmin:value	- ��� �������������� ��������
' /clusterpwd:value	- ������ �������������� ��������
' /infobaseadmin:value	- ��� �������������� �������������� ���� (������ � �������� infobase)
' /infobasepwd:value	- ������ �������������� �������������� ���� (������ � �������� infobase)
' /warn:value		- ����� ������ warning ��� ������ connection, session, license
' /crit:value		- ����� ������ critical ��� ������ connection, session, license
'
' /command:value	- ������������ ��������, ������� ��������
' �������������� �������:
'  /command:cluster	- �������� ����������� �������� 1�
'  /command:server	- �������� ���������� ����������� ��������
'  /command:process	- �������� ���������� ������� ���������
'  /command:connection	- �������� ���������� ������������� ����������
'  /command:session	- �������� ���������� �������� ������
'  /command:license	- �������� ���������� ������������ ��������
'  /command:infobase	- �������� ���������� ������������������ �������������� ���,
'                         ���� ����� ������ /infobase:ibname - ��� ��, �� �����������
'                         ���������� ������� � ������������ ������� �������������� ����


On Error Resume Next

Const PROGNAME = "check_1c.vbs"
Const VERSION = "0.0.1"

Dim Connector
Dim ConAgent
Dim Clusters
Dim Cluster

' Create the NagiosPlugin object
Set np = New NagiosPlugin

strHostName = Wscript.Arguments.Named.Item("Hostname")
strPort = Wscript.Arguments.Named.Item("Port")
strCommand = Wscript.Arguments.Named.Item("Command")
strPlatform = Wscript.Arguments.Named.Item("Platform")
strInfoBase = Wscript.Arguments.Named.Item("InfoBase")
strClusterAdmin = Wscript.Arguments.Named.Item("ClusterAdmin")
strClusterPwd = Wscript.Arguments.Named.Item("ClusterPwd")
strInfobaseAdmin = Wscript.Arguments.Named.Item("InfobaseAdmin")
strInfobasePwd = Wscript.Arguments.Named.Item("InfobasePwd")
strWarn = Wscript.Arguments.Named.Item("Warn")
strCrit = Wscript.Arguments.Named.Item("Crit")


If strHostName = "" Then
  strHostName = "localhost" 
End If

If strPort = "" Then
  strPort = "1540"
End If

If strPlatform = "" Then
  strPlatform = "V83" 
End If

intWarn = 0
If strWarn > "" Then
  intWarn = Int(strWarn)
End If

intCrit = 0
If strCrit > "" Then
  intCrit = Int(strCrit)
End If

' Default settings for your script.
threshold_warning = intWarn
threshold_critical = intCrit

' Define what args that should be used
np.add_arg "command", "command to check; defaults to cluster", 1
np.add_arg "host", "hostname to connect to; defaults to localhost", 0
np.add_arg "port", "port to connect to; defaults to 1540", 0
np.add_arg "platform", "1C Enterprise version, V83 or V82; defaults to V83", 0
np.add_arg "infobase", "information database name, use with --command=infobase", 0
np.add_arg "clusteradmin", "cluster administrator username", 0
np.add_arg "clusterpwd", "cluster administrator password", 0
'np.add_arg "infobaseadmin", "infomation database administrator username"
'np.add_arg "infobasepwd", "infomation database administrator password"
np.add_arg "warning", "warning threshold, use with command: connection or session", 0
np.add_arg "critical", "critical threshold, use with command: connection or session", 0

' If we have no args or arglist contains /help or not all of the required arguments are fulfilled show the usage output,.
If Args.Count < 1 Or Args.Exists("help") Or np.parse_args = 0 Then
  WScript.Echo Args.Count
  np.Usage
End If

' If we define /warning /critical on commandline it should override the script default.
If Args.Exists("warning") Then threshold_warning = Args("warning")
If Args.Exists("critical") Then threshold_critical = Args("critical")
np.set_thresholds threshold_warning, threshold_critical


' 
Err.Clear
Set Connector = CreateObject(strPlatform & ".COMConnector")
If Err.Number <> 0 Then
  msg = Err.Decription
  return_code = UNDEFINED
  np.nagios_exit msg, return_code
End If

Err.Clear
Set ConAgent = Connector.ConnectAgent("tcp://" + strHostName + ":" + strPort)
If Err.Number <> 0 Then
  msg = Err.Decription
  return_code = WARNING
  np.nagios_exit msg, return_code
End If

Err.Clear
Clusters = ConAgent.GetClusters()
If Err.Number <> 0 Then
  msg = Err.Decription
  return_code = WARNING
  np.nagios_exit msg, return_code
End If

' ���������� ������ 1 �������
Set Cluster = Clusters (0)

' ����������� � �������� ���� ���� ��������� 
Err.Clear
ConAgent.Authenticate Cluster, strClusterAdmin, strClusterPwd
If Err.Number <> 0 Then
  msg = Err.Decription
  return_code = WARNING
  np.nagios_exit msg, return_code
End If

If strCommand = "" Then
  msg = "local cluster on " & Cluster.HostName & ":" & Cluster.MainPort & " found"
  return_code = OK
  np.nagios_exit msg, return_code
End If

Select Case strCommand

  Case "cluster"
    msg = "local cluster on " & Cluster.HostName & ":" & Cluster.MainPort & " found"
    return_code = OK
    np.nagios_exit msg, return_code

  Case "server"
    intWorkingServers = getWorkingServerCount

    msg = intWorkingServers & " working server(s) found | servers=" & intWorkingServers
    return_code = OK
    np.nagios_exit msg, return_code

  Case "process"
    intWorkingProcesses = getWorkingProcessCount

    msg = intWorkingProcesses & " working process(es) found | processes=" & intWorkingProcesses
    return_code = OK
    np.nagios_exit msg, return_code

  Case "infobase"
    If strInfoBase > "" Then
      intInfobaseState = getInfobaseState(strInfoBase)
      If intInfobaseState = 0 Then
        msg = strInfobase & " infobase session or scheduled jobs denied"
        return_code = CRITICAL
        np.nagios_exit msg, return_code
      End If
      msg = strInfobase & " infobase not locked"
      return_code = OK
      np.nagios_exit msg, return_code
    Else
      intInfobases = getInfobaseCount

      msg = intInfobases & " infobase(s) found | infobases=" & intInfobases
      return_code = OK
      np.nagios_exit msg, return_code
    End If

  Case "connection"
    intConnections = getConnectionCount

    If intCrit > 0 Then
      If intConnections >= intCrit Then
        msg = intConnections & " connection(s) found | connections=" & intConnections
        return_code = CRITICAL
        np.nagios_exit msg, return_code
      End If
    End If
  
    If intWarn > 0 Then
      If intConnections >= intWarn Then
        msg = intConnections & " connection(s) found | connections=" & intConnections
        return_code = WARNING
        np.nagios_exit msg, return_code
      End If
    End If

    msg = intConnections & " connection(s) found | connections=" & intConnections
    return_code = OK
    np.nagios_exit msg, return_code

  Case "session"
    intSessions = getSessionCount( strInfoBase )
  
    If intCrit > 0 Then
      If intSessions >= intCrit Then
        msg = intSessions & " session(s) found | sessions=" & intSessions
        return_code = CRITICAL
        np.nagios_exit msg, return_code
      End If
    End If
  
    If intWarn > 0 Then
      If intSessions >= intWarn Then
        msg = intSessions & " session(s) found | sessions=" & intSessions
        return_code = WARNING
        np.nagios_exit msg, return_code
      End If
    End If

    msg = intSessions & " session(s) found | sessions=" & intSessions
    return_code = OK
    np.nagios_exit msg, return_code

  Case "license"
    intLicenses = getLicenseCount
  
    If intCrit > 0 Then
      If intLicenses >= intCrit Then
        msg = intLicenses & " license(s) used | licenses=" & intLicenses
        return_code = CRITICAL
        np.nagios_exit msg, return_code
      End If
    End If
  
    If intWarn > 0 Then
      If intLicenses >= intWarn Then
        msg = intLicenses & " license(s) used | licenses=" & intLicenses
        return_code = WARNING
        np.nagios_exit msg, return_code
      End If
    End If

    msg = intLicenses & " license(s) used | licenses=" & intLicenses
    return_code = OK
    np.nagios_exit msg, return_code

  Case Else
    msg = "command " & strCommand & " not supported"
    return_code = UNDEFINED
    np.nagios_exit msg, return_code

End Select

wscript.Quit


' ���������� ����� ������� ��������
Function getWorkingServerCount()

  Err.Clear
  WorkingServers = conAgent.GetWorkingServers(Cluster)
  If Err.Number <> 0 Then
    msg = Err.Decription
    return_code = WARNING
    np.nagios_exit msg, return_code
  End If
  getWorkingServerCount = Ubound(WorkingServers) + 1

End Function

' ���������� ����� ������� ���������
Function getWorkingProcessCount()

  Err.Clear
  WorkingProcesses = conAgent.GetWorkingProcesses(Cluster)
  If Err.Number <> 0 Then
    msg = Err.Decription
    return_code = WARNING
    np.nagios_exit msg, return_code
  End If
  getWorkingProcessCount = Ubound(WorkingProcesses) + 1

End Function

' ���������� ����� ����������
Function getConnectionCount()

  Err.Clear
  Connections = conAgent.GetConnections(Cluster)
  If Err.Number <> 0 Then
    msg = Err.Decription
    return_code = WARNING
    np.nagios_exit msg, return_code
  End If
  getConnectionCount = Ubound(Connections) + 1

End Function

' ���������� ����� ������ ����� ���� �� �� ���� ������� BaseName
Function getSessionCount( BaseName )

  Err.Clear
  Sessions = ConAgent.GetSessions (Cluster)
  If Err.Number <> 0 Then
    msg = Err.Decription
    return_code = WARNING
    np.nagios_exit msg, return_code
  End If
  If BaseName = "" Then
    getSessionCount = Ubound(Sessions) + 1
  Else 
    Amount = 0
    For Each Session In Sessions
      If Session.InfoBase.Name = BaseName Then
        Amount = Amount + 1
      End If
    Next
    getSessionCount = Amount
  End If

End Function

' ���������� ����� �������������� ���
Function getInfobaseCount()

  Err.Clear
  Infobases = conAgent.GetInfoBases(Cluster)
  If Err.Number <> 0 Then
    msg = Err.Decription
    return_code = WARNING
    np.nagios_exit msg, return_code
  End If
  getInfobaseCount = Ubound(Infobases) + 1

End Function

' ��������� �� �� �� ������ ������ � ������������ �������
Function getInfobaseState(BaseName)

  Err.Clear
  WorkingProcesses = conAgent.GetWorkingProcesses(Cluster)
  If Err.Number <> 0 Then
    msg = Err.Decription
    return_code = WARNING
    np.nagios_exit msg, return_code
  End If

  For Each WorkingProcess In WorkingProcesses
    If WorkingProcess.Running = 1 Then
      ' ��� ������� �������� �������� ������� ���������� � ������� ���������
      Err.Clear
      Set ConnectToWorkProcess = Connector.ConnectWorkingProcess("tcp://" + WorkingProcess.HostName + ":" + CStr(WorkingProcess.MainPort))
      If Err.Number <> 0 Then
        msg = Err.Decription
        return_code = WARNING
        np.nagios_exit msg, return_code
      End If
      ' �������� ������ �� �������� ��������
      InfoBases = ConnectToWorkProcess.GetInfoBases()
      IBFound = False
      For Each InfoBase In InfoBases
	If InfoBase.Name = BaseName Then
	  If strInfobaseAdmin > "" AND strInfobasePwd > "" Then
            Err.Clear
            ConnectToWorkProcess.AddAuthentication strInfobaseAdmin, strInfobasePwd
            If Err.Number <> 0 Then
              msg = Err.Decription
              return_code = WARNING
              np.nagios_exit msg, return_code
            End If
          End If
'          wscript.Echo(InfoBase.name)
'          wscript.Echo(InfoBase.SessionsDenied)
'          wscript.Echo(InfoBase.ScheduledJobsDenied)
          If strPlatform = "V83" Then
            If InfoBase.SessionsDenied OR InfoBase.ScheduledJobsDenied Then
              getInfobaseState = 0
              Exit Function
            End If
          Else  
            If InfoBase.SessionsDenied OR CStr(InfoBase.ScheduledJobsDenied) = "True" Then
              getInfobaseState = 0
              Exit Function
            End If
          End If
          IBFound = True
          Exit For
	End If
      Next
    End if
    If IBFound Then
      Exit For
    End If
  Next

  getInfobaseState = 1

End Function

' ���������� ����� �������� ������������ ��������
Function getLicenseCount()

  Err.Clear
  Sessions = ConAgent.GetSessions (Cluster)
  If Err.Number <> 0 Then
    wscript.Echo("WARNING - " & Err.Decription)
    wscript.Quit(WARNING)
  End If
  Amount = 0
  For Each Session In Sessions
    If IsObject(Session.License) Then
      Amount = Amount + 1
    End If
  Next
  getLicenseCount = Amount

End Function
