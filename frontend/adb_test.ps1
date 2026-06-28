param(
  [string]$DeviceId = "f0fb9875"
)

$adb = "C:\Users\FANNNDI\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$script:prevDump = ""

function adb {
  param([string]$cmd)
  & $adb -s $DeviceId $cmd.Split(' ', 2)
}

function WaitForScreen {
  Start-Sleep -Seconds 2
  DismissKeyboard
  adb "shell uiautomator dump /sdcard/ui.xml" | Out-Null
  Start-Sleep -Milliseconds 500
}

function DismissKeyboard {
  adb "shell input keyevent KEYCODE_BACK"
  Start-Sleep -Milliseconds 500
}

function FindByText {
  param([string]$text)
  WaitForScreen
  $xml = adb "shell cat /sdcard/ui.xml" 2>$null
  $pattern = 'content-desc="([^"]*' + [Regex]::Escape($text) + '[^"]*)"[^>]*bounds="(\[.*?\])"'
  $m = [regex]::Match($xml, $pattern)
  if ($m.Success) {
    $bounds = $m.Groups[2].Value
    $coords = $bounds -replace '\[(\d+),(\d+)\]\[(\d+),(\d+)\]', '$1+$3/2, $2+$4/2'
    $x = [int](Invoke-Expression $coords.Split(',')[0])
    $y = [int](Invoke-Expression $coords.Split(',')[1])
    Write-Host "  Found '$text' at ($x, $y)"
    return @($x, $y)
  }
  # Try EditText with text attribute
  $pattern2 = 'text="([^"]*' + [Regex]::Escape($text) + '[^"]*)"[^>]*bounds="(\[.*?\])"'
  $m2 = [regex]::Match($xml, $pattern2)
  if ($m2.Success) {
    $bounds = $m2.Groups[2].Value
    $coords = $bounds -replace '\[(\d+),(\d+)\]\[(\d+),(\d+)\]', '$1+$3/2, $2+$4/2'
    $x = [int](Invoke-Expression $coords.Split(',')[0])
    $y = [int](Invoke-Expression $coords.Split(',')[1])
    Write-Host "  Found text='$text' at ($x, $y)"
    return @($x, $y)
  }
  Write-Host "  NOT FOUND: '$text'"
  return $null
}

function FindByDesc {
  param([string]$desc)
  WaitForScreen
  $xml = adb "shell cat /sdcard/ui.xml" 2>$null
  $pattern = 'content-desc="' + [Regex]::Escape($desc) + '"[^>]*bounds="(\[.*?\])"'
  $m = [regex]::Match($xml, $pattern)
  if ($m.Success) {
    $bounds = $m.Groups[1].Value
    $coords = $bounds -replace '\[(\d+),(\d+)\]\[(\d+),(\d+)\]', '$1+$3/2, $2+$4/2'
    $x = [int](Invoke-Expression $coords.Split(',')[0])
    $y = [int](Invoke-Expression $coords.Split(',')[1])
    Write-Host "  Found '$desc' at ($x, $y)"
    return @($x, $y)
  }
  Write-Host "  NOT FOUND: '$desc'"
  return $null
}

function Tap {
  param([int]$x, [int]$y)
  DismissKeyboard
  adb "shell input tap $x $y"
  Start-Sleep -Milliseconds 800
}

function Type {
  param([string]$text)
  DismissKeyboard
  # Use individual keyevents for special chars, simple for plain text
  adb "shell input text '$text'"
  Start-Sleep -Milliseconds 300
}

function ScrollDown {
  DismissKeyboard
  adb "shell input swipe 500 1600 500 400"
  Start-Sleep -Seconds 1
}

function LogScreen {
  WaitForScreen
  $xml = adb "shell cat /sdcard/ui.xml" 2>$null
  Write-Host "--- Visible elements ---"
  Select-String -InputObject $xml -Pattern 'content-desc="([^"]*)"' | ForEach-Object { 
    $desc = $_.Matches[0].Groups[1].Value
    if ($desc.Trim().Length -gt 0) { Write-Host "  [$desc]" }
  }
}

# ===== High-level actions =====
function TapText {
  param([string]$text)
  $pos = FindByText $text
  if ($pos) { Tap $pos[0] $pos[1] }
}

function TapDesc {
  param([string]$desc)
  $pos = FindByDesc $desc
  if ($pos) { Tap $pos[0] $pos[1] }
}

function FillField {
  param([string]$label, [string]$value)
  $pos = FindByText $label
  if (-not $pos) { $pos = FindByDesc $label }
  if ($pos) { Tap $pos[0] $pos[1]; Start-Sleep -Milliseconds 500; Type $value }
}

# ===== Test Suites =====
function Test-StoreRegister {
  Write-Host "`n=== STORE REGISTER ==="
  TapDesc "Daftarkan Toko Baru"; WaitForScreen
  ScrollDown # Scroll to see fields
  FillField "Nama Toko" "Toko Rafa"
  ScrollDown; FillField "Alamat" "Jl. Testing No 1"
  ScrollDown; FillField "No HP Toko" "081111111111"
  ScrollDown; FillField "Nama Admin" "Admin Rafa"
  ScrollDown; FillField "No HP Admin" "081111111112"
  ScrollDown; TapDesc "Kirim Pendaftaran"
  Start-Sleep -Seconds 3
  LogScreen
}

function Test-GuestBooking {
  Write-Host "`n=== GUEST BOOKING ==="
  TapDesc "Ajukan Servis"; WaitForScreen
  
  # Step 1: Pilih Perangkat
  TapDesc "Android"; Start-Sleep -Seconds 1
  # Try to find and tap brand
  $brand = FindByDesc "Samsung"
  if (-not $brand) { 
    Write-Host "  No brands loaded - SKIP (needs data)"
    return 
  }
  Tap $brand[0] $brand[1]
  Start-Sleep -Seconds 1
  
  # Step 2: would continue with more taps...
  Write-Host "  Full flow needs device_models RPC data"
}

function Test-AdminLogin {
  Write-Host "`n=== ADMIN LOGIN ==="
  TapDesc "Pelanggan"; WaitForScreen
  FillField "Nomor HP" "08123456789"
  FillField "Kata Sandi" "admin123"
  TapDesc "Masuk"
  Start-Sleep -Seconds 3
  LogScreen
}

# ===== Main =====
Write-Host @"

╔══════════════════════════════════╗
║   ADB Test Helper - ServisGadget ║
╚══════════════════════════════════╝

Commands:
  Test-StoreRegister  - Register new store
  Test-GuestBooking   - Guest service booking
  Test-AdminLogin     - Customer login test
  LogScreen          - Show visible elements
  TapText <text>     - Tap by text content
  WaitForScreen      - Wait for UI to settle

"@
