
import win32com.client as win32
import os

excel = win32.gencache.EnsureDispatch('Excel.Application')
wb = excel.Workbooks.Add()
destination_ws=wb.Sheets(1)
i=0
#for f in [os.path.join(os.getcwd(), ".xlsx"), os.path.join(os.getcwd(), "CM2.xlsx")]: 
for f in [os.path.join(os.getcwd(),'modelos\\capa.xlsx'),
          os.path.join(os.getcwd(),'modelos\\overview_funcional.xlsx')#,
          #os.path.join(os.getcwd(),'modelos\\mapeamento_header.xlsx')#,
          #os.path.join(os.getcwd(),'modelos\\regras_de_negocio.xlsx')#,
          #os.path.join(os.getcwd(),'reda_abuera.xlsx'),
          ]:
    source_ws = excel.Workbooks.Open(f).Sheets(1)
    source_ws.Range('a1:k50').Copy()
    rango="k"+str(i*10+10)
    print(rango)
    destination_ws.Paste(destination_ws.Range(rango))
    i+=1
    #w.Sheets(1).Copy(Before=wb.Sheets(1))

wb.SaveAs(os.path.join(os.getcwd(), "CM.xlsx"))
excel.Application.Quit()

"""
source_ws = wb.Sheets("SheetContainingData")
destination_ws = wb.Sheets("SheetWhereItNeedsToGo")
source_ws.Range('a1:k%s' % row).Copy()
destination_ws.Paste(destination_ws.Range('a7'))
"""