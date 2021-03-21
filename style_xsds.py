#from openpyxl.styles import NamedStyle
from openpyxl.styles import PatternFill, Border, Side, Alignment, Protection, Font
from openpyxl_templates.styles import NamedStyle, ExtendedStyle, DefaultStyleSet

xsd_c_style = NamedStyle(name="xsd_c_style")

font = Font(name='Calibri',
                size=8,
                bold=False,
                italic=False,
                vertAlign='baseline',#None,{‘superscript’, ‘subscript’, ‘baseline’}
                underline='none',#'u'
                strike=False,
                color='FF000000')
fill = PatternFill(fill_type='solid',#None,#{'darkTrellis', 'lightUp', 'darkDown', 'darkGrid', 'lightGrid', 'lightTrellis', 'lightVertical', 'solid', 'gray125', 'lightGray', 'lightHorizontal', 'mediumGray', 'darkHorizontal', 'darkGray', 'lightDown', 'gray0625', 'darkVertical', 'darkUp'}
                start_color='FFD9D9D9',
                end_color='FF000000')
border = Border(left=Side(border_style='thin',#None,
                          color='FF000000'),
                right=Side(border_style='thin',#None,
                           color='FF000000'),
                top=Side(border_style='thick',#None,
                         color='FF000000'),
                bottom=Side(border_style='thick',#None,
                            color='FF000000'),
                diagonal=Side(border_style=None,
                              color='FF000000'),
                diagonal_direction=0,
                outline=Side(border_style=None,
                             color='FF000000'),
                vertical=Side(border_style=None,
                              color='FF000000'),
                horizontal=Side(border_style=None,
                               color='FF000000')
               )
alignment=Alignment(horizontal='center',#'general',
                    vertical='center',#'bottom',
                    text_rotation=0,
                    wrap_text=True,#False,
                    shrink_to_fit=True,#False,
                    indent=0)
number_format = 'General'
protection = Protection(locked=True,
                        hidden=False)

xsd_c_style.font = font
xsd_c_style.fill = fill
xsd_c_style.border = border
xsd_c_style.alignment = alignment
xsd_c_style.number_format = number_format
xsd_c_style.protection = protection


xsd_h_style = ExtendedStyle(
    base="xsd_c_style",
    name="xsd_h_style",
    font={
        "color": "FFFF0000"
    },
    fill={
        "start_color": "FF00FF00"
    }
)
xsd_r_style = ExtendedStyle(
    base="xsd_c_style",
    name="xsd_r_style",
    font={
        "color": "FF0000FF"
    }
)


xsd_style = DefaultStyleSet(
    xsd_h_style,
    xsd_r_style
)


def apply_style_to_wb(wb, style=xsd_h_style):
    wb.add_named_style(style)
