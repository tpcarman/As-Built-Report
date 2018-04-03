#region Nutanix Document Style
DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Arial' -MarginLeftAndRight 71 -MarginTopAndBottom 71

if (!$StyleName) {
    Style -Name 'Title' -Size 24 -Color '024DAF' -Align Center
    Style -Name 'Title 2' -Size 18 -Color 'B0D235' -Align Center
    Style -Name 'Title 3' -Size 12 -Color 'B0D235' -Align Left
    Style -Name 'Heading 1' -Size 16 -Color '024DAF' 
    Style -Name 'Heading 2' -Size 14 -Color '024DAF' 
    Style -Name 'Heading 3' -Size 12 -Color '024DAF' 
    Style -Name 'Heading 4' -Size 11 -Color '024DAF' 
    Style -Name 'Heading 5' -Size 10 -Color '024DAF' -Italic
    Style -Name 'H1 Exclude TOC' -Size 16 -Color '024DAF' 
    Style -Name 'Normal' -Size 10 -Default
    Style -Name 'TOC' -Size 16 -Color '024DAF' 
    Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '4D4D4F' 
    Style -Name 'TableDefaultRow' -Size 10 
    Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'DDDDDD' 
    Style -Name 'Critical' -Size 10 -BackgroundColor 'EA5054'
    Style -Name 'Warning' -Size 10 -BackgroundColor 'FFFF00'
    Style -Name 'Info' -Size 10 -BackgroundColor '9CC2E5'
    Style -Name 'OK' -Size 10 -BackgroundColor '92D050'

    TableStyle -Id 'TableDefault' -HeaderStyle 'TableDefaultHeading' -RowStyle 'TableDefaultRow' -AlternateRowStyle 'TableDefaultAltRow' -BorderColor '4D4D4F' -Align Left -BorderWidth 0.5 -Default
    
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
}
#endregion Nutanix Document Style