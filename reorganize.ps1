$ErrorActionPreference = 'Stop'
Set-Location 'c:\Users\Tizia\Documents\GitHub\zugspiel-3'

$folders = 'scripts','scenes','assets/models','assets/textures'
foreach ($d in $folders) { if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null } }

$moves = @(
  @{ From='forest.gd'; To='scripts/forest.gd' },
  @{ From='path_3d.gd'; To='scripts/path_3d.gd' },
  @{ From='path_follow_3d.gd'; To='scripts/path_follow_3d.gd' },
  @{ From='schiene.gd'; To='scripts/schiene.gd' },
  @{ From='train.gd'; To='scripts/train.gd' },
  @{ From='Tree.tscn'; To='scenes/tree.tscn' },
  @{ From='Zugspiel 2.0.tscn'; To='scenes/zugspiel_2_0.tscn' },
  @{ From='218.obj'; To='assets/models/218.obj' },
  @{ From='218.mtl'; To='assets/models/218.mtl' },
  @{ From='schiene.obj'; To='assets/models/schiene.obj' },
  @{ From='schiene.mtl'; To='assets/models/schiene.mtl' },
  @{ From='führerstand.blend'; To='assets/models/fuehrerstand.blend' },
  @{ From='grass.bmp'; To='assets/textures/grass.bmp' },
  @{ From='grass.jpg'; To='assets/textures/grass.jpg' },
  @{ From='gravel.png'; To='assets/textures/gravel.png' },
  @{ From='fuhrerstand.png'; To='assets/textures/fuhrerstand.png' }
)

foreach ($item in $moves) {
  if (Test-Path $item.From -PathType Leaf -ErrorAction SilentlyContinue) {
    if (!(Test-Path $item.To)) {
      Move-Item -Path $item.From -Destination $item.To
    }
  }
}

foreach ($item in $moves) {
  foreach ($ext in '.uid','.import') {
    $src = $item.From + $ext
    $dst = $item.To + $ext
    $srcExists = Test-Path $src -PathType Leaf -ErrorAction SilentlyContinue
    $dstExists = Test-Path $dst -PathType Leaf -ErrorAction SilentlyContinue
    if ($srcExists -and -not $dstExists
    $dstExists = Test-Path $dst -PathType Leaf -ErrorAction SilentlyContinue
    if ($srcExists -and -not $dstExists) {
      Move-Item -Path $src -Destination $dst
    }
  }
}

Write-Host 'reorganization complete'
