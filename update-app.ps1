# 팀원이 새 "Cycle AI Coach.md"를 주면:
#   1) app 폴더의 "Cycle AI Coach.md"를 새 파일로 덮어쓰고
#   2) 이 스크립트를 실행하면 app/index.html, app/chuncheon_base.json 이 새로 만들어집니다.
# 실행:  powershell -ExecutionPolicy Bypass -File .\update-app.ps1

$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot 'app'
$md  = [IO.File]::ReadAllText((Join-Path $dir 'Cycle AI Coach.md'), [Text.UTF8Encoding]::new($false))
$sha = [Security.Cryptography.SHA256]::Create()
$fence = '`' * 5

foreach ($name in 'index.html', 'chuncheon_base.json') {
    $n   = [regex]::Escape($name)
    $pat = "<!-- FILE: $n BEGIN -->\r?\n$fence[a-z]*\r?\n(.*?)\r?\n$fence\r?\n<!-- FILE: $n END -->"
    $m   = [regex]::Match($md, $pat, 'Singleline')
    if (-not $m.Success) { throw "$name 블록을 md에서 찾지 못했습니다." }

    $bytes = [Text.Encoding]::UTF8.GetBytes($m.Groups[1].Value)
    [IO.File]::WriteAllBytes((Join-Path $dir $name), $bytes)
    $hash = -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })

    # md 안의 표에 적힌 SHA-256과 비교
    $row = [regex]::Match($md, "\| ``$n`` \| \d+ \| ``([0-9a-f]{64})`` \|")
    if ($row.Success -and $row.Groups[1].Value -ne $hash) {
        Write-Warning "$name : md 표의 SHA-256과 다릅니다 (팀원에게 확인 필요)"
    } else {
        Write-Host "$name  $($bytes.Length) bytes  OK"
    }
}
