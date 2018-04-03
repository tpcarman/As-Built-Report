#region Nutanix Document Style
DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Arial' -MarginLeftAndRight 71 -MarginTopAndBottom 71

Style -Name 'Title' -Size 24 -Color '024DA1' -Align Center
Style -Name 'Title 2' -Size 18 -Color 'AFD135' -Align Center
Style -Name 'Title 3' -Size 12 -Color 'AFD135' -Align Left
Style -Name 'Heading 1' -Size 16 -Color '024DA1' 
Style -Name 'Heading 2' -Size 14 -Color '024DA1' 
Style -Name 'Heading 3' -Size 12 -Color '024DA1' 
Style -Name 'Heading 4' -Size 11 -Color '024DA1' 
Style -Name 'Heading 5' -Size 10 -Color '024DA1' -Italic
Style -Name 'H1 Exclude TOC' -Size 16 -Color '024DA1' 
Style -Name 'Normal' -Size 10 -Default
Style -Name 'TOC' -Size 16 -Color '024DA1' 
Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '4C4C4E' 
Style -Name 'TableDefaultRow' -Size 10 
Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'DDDDDD' 
Style -Name 'Critical' -Size 10 -BackgroundColor 'FFB38F'
Style -Name 'Warning' -Size 10 -BackgroundColor 'FFE860'
Style -Name 'Info' -Size 10 -BackgroundColor 'A6D8E7'
Style -Name 'OK' -Size 10 -BackgroundColor 'AADB1E'

TableStyle -Id 'TableDefault' -HeaderStyle 'TableDefaultHeading' -RowStyle 'TableDefaultRow' -AlternateRowStyle 'TableDefaultAltRow' -BorderColor '4C4C4E' -Align Left -BorderWidth 0.5 -Default
    
# Cover Page
BlankLine -Count 11
Paragraph -Style Title $Report.Name
if ($Company.Name) {
    Paragraph -Style Title2 $Company.Name
    BlankLine -Count 27
    Paragraph -Style Title3 "Author: $Author"
    BlankLine
    Paragraph -Style Title3 "Version: $Version"
    PageBreak
}
else {
    BlankLine -Count 28
    Paragraph -Style Title3 "Author: $Author"
    BlankLine
    Paragraph -Style Title3 "Version: $Version"
    PageBreak
}
# Table of Contents
TOC -Name 'Table of Contents'
PageBreak

#endregion Nutanix Document Style