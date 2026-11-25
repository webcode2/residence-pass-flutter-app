# Starts the Android emulator used for Residence mobile testing.
Start-Process -FilePath "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -ArgumentList "-avd","Medium_Phone_API_37.0"
