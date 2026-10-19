@echo off
set "JAVA_HOME=C:\Users\omerh\AppData\Local\Android\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"
if not exist "build" mkdir "build"
echo [Silas Crowe: Shadow and Rain] Android APK Derleniyor...
"C:\Users\omerh\AppData\Local\Programs\Godot\Godot_v4.3-stable_win64_console.exe" --headless --export-debug "Android" build/Silas_Crowe_Shadow_and_Rain.apk
if %ERRORLEVEL% EQU 0 (
    echo [BASARILI] APK basariyla olusturuldu: build\Silas_Crowe_Shadow_and_Rain.apk
) else (
    echo [HATA] APK derleme sirasinda bir hata olustu.
)
