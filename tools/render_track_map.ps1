Add-Type -AssemblyName System.Drawing
$data = Get-Content -LiteralPath '.godot/map_geometry_ops.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$bitmap = New-Object System.Drawing.Bitmap([int]$data.width, [int]$data.height)
$g = [System.Drawing.Graphics]::FromImage($bitmap)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
foreach ($o in $data.ops) {
    $brush = $null; $pen = $null
    if ($o.fill) { $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($o.fill)) }
    if ($o.stroke) {
        $width = if ($o.width) { [single]$o.width } else { [single]1 }
        $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml($o.stroke), $width)
        if ($o.dash) { $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash }
    }
    switch ($o.t) {
        'rect' {
            $r = New-Object System.Drawing.RectangleF([single]$o.x,[single]$o.y,[single]$o.w,[single]$o.h)
            if ($brush) { $g.FillRectangle($brush,$r) }
            if ($pen) { $g.DrawRectangle($pen,$r.X,$r.Y,$r.Width,$r.Height) }
        }
        'ellipse' {
            $r = New-Object System.Drawing.RectangleF([single]$o.x,[single]$o.y,[single]$o.w,[single]$o.h)
            if ($brush) { $g.FillEllipse($brush,$r) }
            if ($pen) { $g.DrawEllipse($pen,$r) }
        }
        'poly' {
            $points = [System.Drawing.PointF[]]@($o.points | ForEach-Object { New-Object System.Drawing.PointF([single]$_[0],[single]$_[1]) })
            if ($brush) { $g.FillPolygon($brush,$points) }
            if ($pen) { $g.DrawPolygon($pen,$points) }
        }
        'line' { $g.DrawLine($pen,[single]$o.x,[single]$o.y,[single]$o.x2,[single]$o.y2) }
        'text' {
            $style = if ($o.bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
            $font = New-Object System.Drawing.Font('Segoe UI',[single]$o.size,$style,[System.Drawing.GraphicsUnit]::Pixel)
            $g.DrawString([string]$o.text,$font,$brush,[single]$o.x,[single]($o.y-$o.size*1.05))
            $font.Dispose()
        }
    }
    if ($brush) { $brush.Dispose() }; if ($pen) { $pen.Dispose() }
}
$bitmap.Save((Join-Path $PWD 'docs/mapa-geometrico-valle-ventoso.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bitmap.Dispose()
