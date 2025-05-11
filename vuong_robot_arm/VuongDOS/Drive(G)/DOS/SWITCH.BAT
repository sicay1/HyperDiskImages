@echo off
ipldrive
for %%n in ( \ibmbio.com \ibmdos.com \config.sys \autoexec.bat ) do if not exist %%n goto _fail
if exist \config.ps5 if exist \autoexec.ps5 goto _ps55
if exist \config.ps2 if exist \autoexec.ps2 goto _uspc
goto _fail
:_uspc
        for %%n in ( \config.ps5 \autoexec.ps5 ) do if exist %%n goto _fail
        IF %1. == MSGOFF. GOTO _NOMSG1
        chev > nul
        if not errorlevel 1 goto US_MSG
                echo.
                echo [注意]: モード切り換え中は(PS/2ﾓｰﾄﾞに切り換わるまで) 電源を切らないでください。
                echo.
                echo システムを、ＰＳ／２モード（英語モード）に切り換えます。
                echo.
                32705250
                if errorlevel 2 if not errorlevel 3 echo ３２７０ＰＣがロードされています。　３２７０業務を終了させてください。
                if errorlevel 3 if not errorlevel 4 echo ５２５０ＰＣがロードされています。　５２５０業務を終了させてください。
                if errorlevel 2 echo.
                choice /n "システムを切り換えますか (Y/N) ? "
                if errorlevel 2 goto _exit
                goto _NOMSG1
        :US_MSG
                echo.
                echo [Warning]: Do not turn off system during switching.
                echo.
                echo Switching the system into PS/2 mode (English mode).
                echo.
                32705250
                if errorlevel 2 if not errorlevel 3 echo The 3270PC program is running. Log off the 3270PC session(s).
                if errorlevel 3 if not errorlevel 4 echo The 5250PC program is running. Log off the 5250PC session(s).
                if errorlevel 2 echo.
                choice /n "Are you sure you want to switch the system (Y/N) ? "
                if errorlevel 2 goto _exit
:_NOMSG1
                hardboot ps52 ps22
                goto _fail
:_ps55
        for %%n in ( \config.ps2 \autoexec.ps2 ) do if exist %%n goto _fail
        IF %1. == MSGOFF. GOTO _NOMSG2
        echo.
        echo [Warning]: Do not turn off during switching.
        echo.
        echo Switching the system into PS/55 mode (Japanese mode).
        echo.
        choice /n "Are you sure to switch the system (Y/N) ? "
        if errorlevel 2 goto _exit
:_NOMSG2
                hardboot ps22 ps52
:_fail
        32705250
        if errorlevel 1 echo Cannot switch to PS/2 mode - Required file(s) missing.
        if not errorlevel 1 echo Cannot switch to PS/55 mode - Required file(s) missing.
:_exit
