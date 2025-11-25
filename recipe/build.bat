@echo on
@setlocal EnableDelayedExpansion

mkdir %LIBRARY_PREFIX%\bin
mkdir %LIBRARY_PREFIX%\share

set GOFLAGS=-modcacherw -trimpath
make VERSION=%PKG_VERSION% || goto :error
xcopy _output\bin\* %LIBRARY_PREFIX%\bin || goto :error
xcopy _output\share\* %LIBRARY_PREFIX%\share || goto :error

go-licenses save .\cmd\limactl --save_path=license-files --ignore github.com/linuxkit/virtsock || goto :error
xcopy /s %RECIPE_DIR%\license-files\* %SRC_DIR%\license-files || goto :error

goto :eof

:error
echo Failed with error #%errorlevel%.
exit 1
