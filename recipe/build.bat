@echo on
@setlocal EnableDelayedExpansion

:: Lima ships several source files as symlinks (e.g. pkg\cidata\cloud-config.yaml and
:: templates\*.yaml). These do not survive tarball extraction on Windows and end up as
:: dangling reparse points that `make` cannot resolve, failing the build early with:
::   make: *** No rule to make target 'pkg/cidata/cloud-config.yaml', ...  Stop.
::
:: Replace every symlink under the source tree with a real copy of its target. The target
:: is read from `dir` output (the bracketed value) instead of being hard-coded, so this
:: keeps working when upstream bumps versioned targets (e.g. ubuntu-26.04.yaml). The outer
:: loop repeats until no symlinks remain so that chains are resolved one hop per pass, e.g.
:: templates\opensuse.yaml -> opensuse-leap.yaml -> opensuse-leap-16.yaml.
set /a DEREF_PASS=0
:deref_symlinks
set /a DEREF_PASS+=1
if !DEREF_PASS! GTR 20 (
    echo Failed to resolve all source symlinks after !DEREF_PASS! passes.
    goto :error
)
set "DEREF_FOUND="
for /f "delims=" %%L in ('dir /a:l /s /b "%SRC_DIR%" 2^>nul') do (
    set "DEREF_FOUND=1"
    call :deref_one "%%L"
)
if defined DEREF_FOUND goto :deref_symlinks

mkdir %LIBRARY_PREFIX%\bin
mkdir %LIBRARY_PREFIX%\share

set GOFLAGS=-modcacherw -trimpath
make VERSION=%PKG_VERSION% binaries || goto :error
xcopy _output\bin\* %LIBRARY_PREFIX%\bin || goto :error
xcopy _output\share\* %LIBRARY_PREFIX%\share || goto :error

go-licenses save .\cmd\limactl --save_path=license-files --ignore github.com/linuxkit/virtsock || goto :error
xcopy /s %RECIPE_DIR%\license-files\* %SRC_DIR%\license-files || goto :error

goto :eof

:deref_one
:: %1 = full path to a symlink. Replace it with a real copy of its (relative) target.
set "LINK=%~1"
set "LINKTGT="
for /f "tokens=2 delims=[]" %%T in ('dir /a:l "%LINK%" 2^>nul ^| findstr /c:"["') do set "LINKTGT=%%T"
if not defined LINKTGT goto :eof
set "LINKTGT=!LINKTGT:/=\!"
:: Copy the target next to the link first; only if that succeeds do we swap it in, so a
:: not-yet-resolved chained target just fails quietly and is retried on the next pass.
copy /y "%~dp1!LINKTGT!" "%LINK%.deref" >nul 2>&1 || goto :eof
del /f /q "%LINK%" >nul 2>&1
move /y "%LINK%.deref" "%LINK%" >nul
goto :eof

:error
echo Failed with error #%errorlevel%.
exit 1
