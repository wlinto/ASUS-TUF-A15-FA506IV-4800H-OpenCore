# ============================================================
#  修复 Windows / macOS 双系统时间不一致（差 8 小时）
#  原理：macOS 把主板时钟(RTC)当 UTC 写，Windows 默认把它当本地时间读。
#        这里让 Windows 也按 UTC 解释主板时钟，两边就一致了。
#  用法：右键本文件 →「使用 PowerShell 运行」，或
#        以管理员身份打开 PowerShell 后执行本文件
#  想还原：删掉注册表值 RealTimeIsUniversal 即可（脚本末尾有命令）
# ============================================================

$ErrorActionPreference = 'Continue'

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "本脚本需要管理员权限，请右键 →「使用 PowerShell 运行」，" -ForegroundColor Red
    Write-Host "或者用管理员身份打开 PowerShell 再执行它。" -ForegroundColor Red
    Write-Host ""
    Read-Host "按回车退出"
    exit 1
}

$key = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'

Write-Host ""
Write-Host "修改前的时间: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"

# 1) 让 Windows 按 UTC 解释主板时钟
Set-ItemProperty -Path $key -Name 'RealTimeIsUniversal' -Value 1 -Type DWord
Write-Host "[1/3] 已写入 RealTimeIsUniversal = 1" -ForegroundColor Green

# 2) 立刻按新规则重新同步一次网络时间
try {
    Restart-Service w32time -ErrorAction Stop
    Start-Sleep -Seconds 2
    w32tm /resync /force | Out-Null
    Write-Host "[2/3] 已重新同步网络时间" -ForegroundColor Green
} catch {
    Write-Host "[2/3] 网络时间服务同步失败（不影响，重启后会自动同步）: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3) 显示结果
Write-Host "[3/3] 修改后的时间: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host ""
Write-Host "现在时间应该已经正确（北京时间为准）。重启一次再确认。" -ForegroundColor Cyan
Write-Host ""
Write-Host "说明：" -ForegroundColor DarkGray
Write-Host "  · 主板 BIOS 里显示的时间以后会比北京时间早 8 小时，这是正常的。" -ForegroundColor DarkGray
Write-Host "  · 想还原成原样，用管理员 PowerShell 执行：" -ForegroundColor DarkGray
Write-Host "      Remove-ItemProperty -Path '$key' -Name RealTimeIsUniversal" -ForegroundColor DarkGray
Write-Host ""
Read-Host "按回车退出"
