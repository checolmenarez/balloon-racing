# Reproducible crops from the supplied reference sheets. No external packages.
# Coordinates and limitations are documented in the world's README.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;
public static class ValleCrop {
    static bool Background(Color c) {
        return c.R > 170 && c.G > 180 && c.B > 190 && Math.Max(c.R, Math.Max(c.G,c.B))-Math.Min(c.R,Math.Min(c.G,c.B)) < 75;
    }
    public static void Save(string source, string target, int x, int y, int w, int h, bool cutout, bool fade) {
        using (var original = new Bitmap(source))
        using (var crop = original.Clone(new Rectangle(x,y,w,h), PixelFormat.Format32bppArgb)) {
            if (cutout) {
                var seen = new bool[w*h];
                var queue = new Queue<int>();
                for(int px=0;px<w;px++){ queue.Enqueue(px); queue.Enqueue((h-1)*w+px); }
                for(int py=0;py<h;py++){ queue.Enqueue(py*w); queue.Enqueue(py*w+w-1); }
                while(queue.Count>0) {
                    int i=queue.Dequeue(); if(seen[i]) continue; seen[i]=true;
                    int px=i%w, py=i/w;
                    if(!Background(crop.GetPixel(px,py))) continue;
                    crop.SetPixel(px,py,Color.Transparent);
                    if(px>0) queue.Enqueue(i-1); if(px<w-1) queue.Enqueue(i+1);
                    if(py>0) queue.Enqueue(i-w); if(py<h-1) queue.Enqueue(i+w);
                }
                int minx=w, miny=h, maxx=0, maxy=0;
                for(int py=0;py<h;py++) for(int px=0;px<w;px++) if(crop.GetPixel(px,py).A>0) {
                    minx=Math.Min(minx,px); miny=Math.Min(miny,py); maxx=Math.Max(maxx,px); maxy=Math.Max(maxy,py);
                }
                if(minx<=maxx) {
                    using(var trimmed=new Bitmap(maxx-minx+9,maxy-miny+9,PixelFormat.Format32bppArgb)) {
                        using(var g=Graphics.FromImage(trimmed)) g.DrawImage(crop,new Rectangle(4,4,maxx-minx+1,maxy-miny+1),new Rectangle(minx,miny,maxx-minx+1,maxy-miny+1),GraphicsUnit.Pixel);
                        trimmed.Save(target,ImageFormat.Png);
                    }
                    return;
                }
            }
            if(fade) for(int py=0;py<h;py++) for(int px=0;px<w;px++) {
                Color c=crop.GetPixel(px,py);
                double alpha=Math.Min(1.0,Math.Min(py/(h*.28),(h-1-py)/(h*.18)));
                crop.SetPixel(px,py,Color.FromArgb((int)(255*Math.Max(0,alpha)),c.R,c.G,c.B));
            }
            if(target.EndsWith("rock_fill.png")) {
                using(var tile = new Bitmap(w*2,h*2,PixelFormat.Format32bppArgb)) {
                    using(var g = Graphics.FromImage(tile)) {
                        g.DrawImageUnscaled(crop,0,0);
                        crop.RotateFlip(RotateFlipType.RotateNoneFlipX); g.DrawImageUnscaled(crop,w,0);
                        crop.RotateFlip(RotateFlipType.RotateNoneFlipY); g.DrawImageUnscaled(crop,w,h);
                        crop.RotateFlip(RotateFlipType.RotateNoneFlipX); g.DrawImageUnscaled(crop,0,h);
                    }
                    tile.Save(target,ImageFormat.Png);
                }
            } else crop.Save(target,ImageFormat.Png);
        }
    }
}
'@
$world = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets/worlds/valle_ventoso'
foreach ($folder in @('source','parallax','terrain/base','terrain/vertical','terrain/connectors','props/decor','gameplay/signage','gameplay/hazards','gameplay/wind','ui')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $world $folder) | Out-Null
}
# Preserve the originals, including their existing names, at the root.
foreach ($source in Get-ChildItem -LiteralPath $world -Filter '*.png.png') {
    Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $world ('source/' + $source.Name.Substring(0,$source.Name.Length-4)))
}
$kit = (Get-ChildItem (Join-Path $world 'source') -Filter 'kit*.png').FullName
$guide = (Get-ChildItem (Join-Path $world 'source') -Filter 'gu*.png').FullName
$landscape = (Get-ChildItem (Join-Path $world 'source') -Filter 'paisaje*.png').FullName
$entries = Get-Content (Join-Path $PSScriptRoot 'valle_crops.json') -Raw | ConvertFrom-Json
foreach ($entry in $entries) {
    $source = if ($entry.source -eq 'guide') { $guide } elseif ($entry.source -eq 'landscape') { $landscape } else { $kit }
    $target = Join-Path $world ($entry.path + '.png')
    $r = $entry.rect
    [ValleCrop]::Save($source,$target,$r[0],$r[1],$r[2],$r[3],$entry.cutout,$entry.fade)
}
Write-Output "Extracted $($entries.Count) PNG files; source sheets preserved."
