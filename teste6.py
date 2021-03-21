
import win32com.client as win32
import os

excel = win32.gencache.EnsureDispatch('Excel.Application')
wb = excel.Workbooks.Add()

#for f in [os.path.join(os.getcwd(), ".xlsx"), os.path.join(os.getcwd(), "CM2.xlsx")]: 
for f in [os.path.join(os.getcwd(),'modelos\\capa.xlsx'),
          os.path.join(os.getcwd(),'modelos\\overview_funcional.xlsx'),
          os.path.join(os.getcwd(),'modelos\\mapeamento_header.xlsx'),
          os.path.join(os.getcwd(),'modelos\\regras_de_negocio.xlsx')#,
          #os.path.join(os.getcwd(),'reda_abuera.xlsx'),
          ]:
    w = excel.Workbooks.Open(f) 
    w.Sheets(1).Copy(wb.Sheets(1))

wb.SaveAs(os.path.join(os.getcwd(), "CM.xlsx"))
excel.Application.Quit()
