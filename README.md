# check_1c.bat

 NSClient++ плагин (https://www.nsclient.org/) для проверки кластера 1С Предприятие 8
 
 в системе мониторинга Nagios/Icinga. Использует сервер администрирования RAS
 
 для получения данных от сервера 1С:Предприятие.

 смотри скрипт для подробностей
 
 
# check_1c.vbs

 NSClient++ плагин (https://www.nsclient.org/) для проверки кластера 1С Предприятие 8
 
 в системе мониторинга Nagios/Icinga. Использует COM соединение (V83|V82.ComConnector)
 
 для получения данных от сервера 1С:Предприятие.
 

 Запуск:
 
 1. Прописать в файле nsclient.ini настроек NSClient++ команды проверки
 
  ; A list of wrappped scripts (ie. using the template mechanism)
  
  [/settings/external scripts/wrapped scripts]
  
  check_1c_cluster=scripts\\check_1c.vbs /command:cluster
  
  check_1c_session=scripts\\check_1c.vbs /command:session
  
  ; A list of templates for wrapped scripts
  
  [/settings/external scripts/wrappings]
  
  ; VISUAL BASIC WRAPPING - 
  
  vbs = cscript.exe //T:30 //NoLogo scripts\\lib\\wrapper.vbs %SCRIPT% %ARGS%
  
  
   2. В Nagios/Icinga прописать команду проверки сервиса
   
   $USER1$/check_nrpe -H $HOSTADDRESS$ -c check_1c_cluster
  
  
   Список параметров:
   
   /hostname:value	- имя хоста сервера 1С, по умолчанию localhost
   
   /port:value		- номер порта сервера 1С, по умолчанию 1540
   
   /platform:value	- платформа 1С (V83 или V82), по умолчанию V83
   
   /infobase:value	- имя информационной базы на сервере (только с командой infobase)
   
   /clusteradmin:value	- имя администратора кластера
   
   /clusterpwd:value	- пароль администратора кластера
   
   /infobaseadmin:value	- имя администратора информационной базы (только с командой infobase)
   
   /infobasepwd:value	- пароль администратора информационной базы (только с командой infobase)
   
   /warn:value		- порог выдачи warning для команд connection, session, license
   
   /crit:value		- порог выдачи critical для команд connection, session, license
   
  
   /command:value	- обязательный параметр, команда проверки
   
   поддерживаемые команды:
   
    /command:cluster	- проверка доступности кластера 1С
    
    /command:server	- проверка количества центральных серверов
    
    /command:process	- проверка количества рабочих процессов
    
    /command:connection	- проверка количества установленных соединений
    
    /command:session	- проверка количества активных сессий
    
    /command:license	- проверка количества используемых лицензий
    
    /command:infobase	- проверка количества зарегистрированных информационных баз,
    
                           если также указан /infobase:ibname - имя ИБ, то проверяется
                           
                           блокировка сеансов и регламентных заданий информационной базы

