# Starts the Android emulator used for local Residence mobile testing.
# Usage: powershell -ExecutionPolicy Bypass -File .\mobile\scripts\start_emulator.ps1

$ErrorActionPreference = "Stop"

$emulatorId = "Medium_Phone_API_37.0"

Write-Host "Launching Android emulator: $emulatorId"
flutter emulators --launch $emulatorId

Write-Host "Waiting for device to come online..."
flutter devices
Write-Host "If the emulator is still booting, run: flutter devices"