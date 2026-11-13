$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter test test/widget_test.dart test/auth_flow_test.dart --timeout 30s
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter analyze lib/screens/sign_in_screen.dart test/widget_test.dart test/auth_flow_test.dart
exit $LASTEXITCODE