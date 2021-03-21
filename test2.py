from tablepyxl import tablepyxl

from style_xsds import xsd_h_style,apply_style_to_wb

input_file = 'C:\\Users\\ljdasilv\\Documents\\DBMS\\HTML_table_extract\\html\\output\\rms\\RMS_AddrDesc.html'#AddrDesc.html'
output_filename = 'C:\\Users\\ljdasilv\\Documents\\DBMS\\HTML_table_extract\\hopa.xlsx'



doc = open(input_file, "r")
table = doc.read()



#tablepyxl.documents_to_xl(output_file, 'C:\\Users\\ljdasilv\\Documents\\DBMS\\HTML_table_extract\\')
#wb = tablepyxl.documents_to_workbook('C:\\Users\\ljdasilv\\Documents\\DBMS\\HTML_table_extract\\')
#tablepyxl.document_to_xl(table, output_filename)
wb=tablepyxl.document_to_workbook(doc=table, base_url=output_filename)
wb.add_named_style()
ws = wb.active
#ws.title = "Mapeamento-Integracao-Aplicacao"
apply_style_to_wb(wb,xsd_h_style)

i=0
k=0
for row in ws.rows:
    j=0
    i+=1
    for cell in row:
        j+=1
        #print('row='+str(i)+' cell_no='+str(j)+' cell.value='+str(cell.value))
        if cell.value is not None:
            if k==0:
                k+=1
                print('dir(cell)::')
                print(dir(cell))
                print(cell.style)
                print(cell.style_id)
                print(cell.parent)
                print(cell.col_idx)
                print(cell.column)
                print(cell.column_letter)
                print(cell.row)
            cell.style = 'xsd_h_style'



wb.save(output_filename)

