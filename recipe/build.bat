mkdir %LIBRARY_PREFIX%\bin
mkdir %LIBRARY_PREFIX%\share

rm pkg\cidata\cloud-config.yaml || goto :error
copy pkg\cidata\cidata.TEMPLATE.d\user-data pkg\cidata\cloud-config.yaml || goto :error
make VERSION=%PKG_VERSION% || goto :error
xcopy _output\bin\* %LIBRARY_PREFIX%\bin || goto :error
xcopy _output\share\* %LIBRARY_PREFIX%\share || goto :error

go-licenses save .\cmd\limactl --save_path=license-files || goto :error

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit 1
