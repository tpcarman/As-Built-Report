#region Pure Storage Document Style
DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Arial' -MarginLeftAndRight 71 -MarginTopAndBottom 71

Style -Name 'Title' -Size 24 -Color 'F05423' -Align Center
Style -Name 'Title 2' -Size 18 -Color '2F2F2F' -Align Center
Style -Name 'Title 3' -Size 12 -Color '2F2F2F' -Align Left
Style -Name 'Heading 1' -Size 16 -Color 'F05423' 
Style -Name 'Heading 2' -Size 14 -Color 'F05423' 
Style -Name 'Heading 3' -Size 12 -Color 'F05423' 
Style -Name 'Heading 4' -Size 11 -Color 'F05423' 
Style -Name 'Heading 5' -Size 10 -Color 'F05423' -Italic
Style -Name 'H1 Exclude TOC' -Size 16 -Color 'F05423' 
Style -Name 'Normal' -Size 10 -Default
Style -Name 'TOC' -Size 16 -Color 'F05423' 
Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '2F2F2F' 
Style -Name 'TableDefaultRow' -Size 10 
Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'DDDDDD' 
Style -Name 'Critical' -Size 10 -BackgroundColor 'FFB38F'
Style -Name 'Warning' -Size 10 -BackgroundColor 'FFE860'
Style -Name 'Info' -Size 10 -BackgroundColor 'A6D8E7'
Style -Name 'OK' -Size 10 -BackgroundColor 'AADB1E'

TableStyle -Id 'TableDefault' -HeaderStyle 'TableDefaultHeading' -RowStyle 'TableDefaultRow' -AlternateRowStyle 'TableDefaultAltRow' -BorderColor '464547' -Align Left -BorderWidth 0.5 -Default
TableStyle -Id 'Borderless' -BorderWidth 0

# Pure Storage Cover Page
BlankLine -Count 11
Paragraph -Style Title $Report.Name
if ($Company.FullName) {
    Paragraph -Style Title2 $Company.FullName
    BlankLine -Count 27
    Table -Name 'Cover Page' -List -Style Borderless -Width 0 -Hashtable ([Ordered] @{
            'Author:'  = $Author
            'Date:'    = Get-Date -Format 'dd MMMM yyyy'
            'Version:' = $Version
        })
    PageBreak
}
else {
    BlankLine -Count 28
    Table -Name 'Cover Page' -List -Style Borderless -Width 0 -Hashtable ([Ordered] @{
            'Author:'  = $Author
            'Date:'    = Get-Date -Format 'dd MMMM yyyy'
            'Version:' = $Version
        })
    PageBreak
}
# Table of Contents
TOC -Name 'Table of Contents'
PageBreak

#endregion Pure Storage Document Style