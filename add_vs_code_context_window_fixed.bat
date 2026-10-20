@echo off
:: Batch script to add "Open with Code" to context menu (proper escaping)
:: Covers: files, folders, folder background (empty space), drives
:: Optionally restores the classic (full) context menu on Windows 11
:: Automatically elevates to Admin if needed

:: Check for admin rights
fltmc >nul 2>&1 || (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~0'"
    exit /b
)

:: Detect VS Code path (checks both default locations)
set "vscode_path="
for %%d in (
    "E:\Microsoft VS Code\Code.exe",
    "%LocalAppData%\Programs\Microsoft VS Code\Code.exe"
) do if exist "%%~d" set "vscode_path=%%~d"

if not defined vscode_path (
    echo Error: VS Code not found in:
    echo - "E:\Microsoft VS Code\Code.exe"
    echo - "%LocalAppData%\Programs\Microsoft VS Code\Code.exe"
    pause
    exit /b 1
)

echo Found VS Code at: %vscode_path%

:: Generate .reg file with CORRECT escaping (like your original)
:: %%1 = clicked file/folder, %%V = current folder when clicking on empty space
(
    echo Windows Registry Editor Version 5.00
    echo;
    echo [-HKEY_CLASSES_ROOT\Directory\shell\OpenWithCode]
    echo [-HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWithCode]
    echo [-HKEY_CLASSES_ROOT\Drive\shell\OpenWithCode]
    echo [-HKEY_CLASSES_ROOT\*\shell\OpenWithCode]
    echo;
    echo [HKEY_CLASSES_ROOT\Directory\shell\OpenWithCode]
    echo @="Open with Code"
    echo "Icon"="\"%vscode_path:\=\\%\",0"
    echo;
    echo [HKEY_CLASSES_ROOT\Directory\shell\OpenWithCode\command]
    echo @="\"%vscode_path:\=\\%\" \"%%1\""
    echo;
    echo [HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWithCode]
    echo @="Open with Code"
    echo "Icon"="\"%vscode_path:\=\\%\",0"
    echo;
    echo [HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWithCode\command]
    echo @="\"%vscode_path:\=\\%\" \"%%V\""
    echo;
    echo [HKEY_CLASSES_ROOT\Drive\shell\OpenWithCode]
    echo @="Open with Code"
    echo "Icon"="\"%vscode_path:\=\\%\",0"
    echo;
    echo [HKEY_CLASSES_ROOT\Drive\shell\OpenWithCode\command]
    echo @="\"%vscode_path:\=\\%\" \"%%1\""
    echo;
    echo [HKEY_CLASSES_ROOT\*\shell\OpenWithCode]
    echo @="Open with Code"
    echo "Icon"="\"%vscode_path:\=\\%\",0"
    echo;
    echo [HKEY_CLASSES_ROOT\*\shell\OpenWithCode\command]
    echo @="\"%vscode_path:\=\\%\" \"%%1\""
) > "%temp%\OpenWithCode.reg"

:: Apply changes silently
regedit /s "%temp%\OpenWithCode.reg"

:: Windows 11 shows registry entries only under "Show more options".
:: Restoring the classic menu puts "Open with Code" right on the first right click.
echo;
choice /c YN /m "Use the classic (full) context menu so you never need 'Show more options'"
if errorlevel 2 (
    reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
    echo Keeping the Windows 11 context menu.
) else (
    reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul
    echo Classic context menu enabled.
)

:: Restart File Explorer to apply changes
taskkill /f /im explorer.exe >nul
start explorer.exe

echo Success! "Open with Code" added to context menu.
pause
