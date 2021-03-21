


# importing the libraries
#from codecs import BOM_UTF8, encode
from bs4 import BeautifulSoup, NavigableString#, UnicodeDammit
import copy
import os
import re
#import sys
from tablepyxl import tablepyxl
import glob

from IO_DirFileHandler import IO_DirFileHandler


class HTML_to_XLSX_Table_Handler(IO_DirFileHandler):
    def __init__(self, input_file_name=None, output_file_name=None, input_file_extension=".html",output_file_extension=".xlsx",base_path="html_to_xlsx",base_input_path=None,base_output_path=None,input_folder="input",output_folder="output",log_file_name="html_to_xlsx.log"):
        IO_DirFileHandler.__init__(self, input_file_name, output_file_name, input_file_extension=input_file_extension,output_file_extension=output_file_extension,base_path=base_path,base_input_path=base_input_path,base_output_path=base_output_path,input_folder=input_folder,output_folder=output_folder, log_file_name=log_file_name)
        self.wb = None

    #LJK001-Begin
    def documents_to_workbook(self):
        html_list = glob.glob(self.get_input_path() +'./*'+self.input_file_extension)
        out_wb=None
        for html_file in html_list:
            self.set_safe_input_file_name_only(file_name=html_file)
            doc = open(self.full_input_path_and_file(), "r")
            table_list = doc.read()
            doc.close()
            out_wb = tablepyxl.document_to_workbook(doc=table_list,wb=out_wb,base_url=self.get_base_path())
        return out_wb

    """
    def output_to_file(self, output, output_path_and_file, mode):
        if self.wb:
            self.wb.save(self.full_output_path_and_file())
        return super().output_to_file(output, output_path_and_file=output_path_and_file, mode=mode)
    """

    def documents_to_xl(self, output_file_name):
        wb = self.documents_to_workbook()
        self.set_safe_output_file_name_only(output_file_name=output_file_name)
        wb.save(self.full_output_path_and_file())
        #return wb
    #LJK001-End


translator = HTML_to_XLSX_Table_Handler(base_path="html_to_xlsx",base_input_path=["html","output"],base_output_path=["html_to_xlsx","output"],input_folder="output",output_folder="output")
translator.use_input_sub_folder_as_output_file_name=True

def iter_func(input_path,output_path,input_file_name,first_time_in_folder):
    doc = open(translator.full_input_path_and_file(), "r")
    html_table = doc.read()
    doc.close()
    translator.set_safe_output_file_name_only()#output_file_name=input_file_name)
    if first_time_in_folder:
        #print("FIRST_TIME_IN_FOLDER:")
        #print(translator.get_input_path())
        try:
            translator.wb.close()
            translator.wb = None
        except AttributeError:
            pass
    #print("File_being_analyzed:")
    #print(translator.full_input_path_and_file())
    #print("file being saved:")
    #print(translator.full_output_path_and_file())
    if translator.full_input_path_and_file() == 'html\\output\\rfm\\ASNOutDesc\\RFM_Desc_Tbl_ASNOutDesc.html':
        print("opa stop!")
    translator.wb = tablepyxl.document_to_workbook(doc=html_table,wb=translator.wb,base_url="")#translator.full_input_path_and_file())# get_base_path())#get_base_path, nao get_input_path, pq os css devem estar no base_path
    translator.wb.save(filename=translator.full_output_path_and_file())




translator.iter_io_paths_and_files(iter_func=iter_func)


