
#%%

# importing the libraries
#from codecs import BOM_UTF8, encode
from bs4 import BeautifulSoup, NavigableString#, UnicodeDammit
import copy
import os
import re
#import sys
from IO_DirFileHandler import IO_DirFileHandler

#import requests
#import csv

class XLSX_Handler(IO_DirFileHandler):
    def __init__(self, file_name=None, base_path="html",base_input_path=None,base_output_path=None,input_folder="input",output_folder="output"):
        IO_DirFileHandler.__init__(self,file_name,file_extension=".html",base_path=base_path,base_input_path=base_input_path,base_output_path=base_output_path,input_folder=input_folder,output_folder=output_folder)
        self._thead_html_file="thead.html"
        self.soup=None
        if self.get_file_name() is not None:
            self.createSoup()
        self.thead=BeautifulSoup(open(os.path.join(self._thead_html_file),encoding='utf8').read(),"html.parser")


    #HTML parse functions:
    def createSoup(self, parser_or_markup="lxml"):
        self.soup = BeautifulSoup(open(self.full_input_path_and_file()), parser_or_markup)
        self.soup.smooth()
    
    def regex_search(self, tbl, expression):
        return re.compile(expression).search(tbl)
    
    def decompose_empty_tr(self):
        try:
            for empty_row in self.soup.find_all(name="tr", attrs={}, string="", recursive=True,):
                if empty_row.string == "\n":
                    empty_row.decompose()
        except:
            pass
    
    def insert_thead(self, tbl):
        tbl.insert(0,copy.copy(self.thead.find("thead")))
    
    def generate_html_head_title_body(self, html_snippet, title=None):
        if html_snippet.html is None:
            html_snippet.wrap(self.soup.new_tag("html"))
        if html_snippet.body is None:
            html_snippet.wrap(self.soup.new_tag("body"))
        if html_snippet.html is None:
            html_snippet=html_snippet.find_previous("html")
        header=self.soup.new_tag("head")
        header.append(self.soup.new_tag("title"))
        if title is None and self.file_name is not None:
            title=self.file_name
        if title is not None:
            header.title.append(NavigableString(title))
            html_snippet.insert(0,header)
        html_snippet.smooth()
        return html_snippet
    
    def generate_file_name_based_on_title(self, html_snippet=None, prefix=None, suffix=None):
        if prefix is None:
            prefix=self._output_prefix
        if suffix is None:
            suffix=self._output_suffix
        if html_snippet is None:
            html_snippet=self.soup
        self.file_name=prefix+html_snippet.find(name="title").string.strip()+suffix+".html"
        return self.full_output_path_and_file()

    
# Step 1: Sending a HTTP request to a URL
#url = "https://en.wikipedia.org/wiki/List_of_countries_by_GDP_(nominal)"
# Make a GET request to fetch the raw HTML content
#html_content = requests.get(url).text


# Step 2: Parse the html content
#translator = RetailXSD_HTMLTable(file_name=["html","input","rms","AddrDesc.html"])
translator = RetailXSD_HTMLTable()

def xml_schema_name(element):
    return translator.regex_search(element, "XML-Schema Name")

#def application_name(element):
#    return translator.regex_search(element, "XML-Schema Name")

def thead_application_tag(element):
    return translator.regex_search(element, "Application:")


def get_tr_with_th(element):
        try:
            return (element.name=="tr" and element.find(name="th").name=="th")
        except AttributeError:
            return False

#translator.soup.fin

def iter_func(input_path,output_path,file_name):
    if translator.get_file_name() is not None:
            translator.createSoup()
    else:
        return
    app_name_folder=os.path.split(input_path)[-1]
    log="Processing "+translator.full_input_path_and_file()
    log_path=os.path.join(translator._base_path,"html.log")
    translator.output_to_file(output=log,output_path=log_path,mode='a')
    translator.decompose_empty_tr()
    #app_name_file=translator.soup.find_next(name="th",attrs={"colspan":"6"},string=)
    #print(app_name_folder)
    for sop in translator.soup.find_all(string=xml_schema_name):
        xsd_table = sop.find_next(name="table")
        xsd_table["data-name"]=xsd_table.find_previous(name="a").get("name")
        translator.insert_thead(xsd_table)
        tetah=xsd_table.find_next(name="th",attrs={"colspan":"6"}, string=thead_application_tag)
        tetah.append(app_name_folder.upper())
        #print(tetah)
        #if tetah:
        #print(tetah.string)
        #print(tetah)
        for leftover_th in xsd_table.find_next(name="tbody").find_all(get_tr_with_th):
            leftover_th.decompose()
        xsd_table=translator.generate_html_head_title_body(html_snippet=xsd_table,title=(app_name_folder.upper()+"_"+xsd_table["data-name"]))
        translator.generate_file_name_based_on_title(html_snippet=xsd_table)
        translator.output_to_file(xsd_table.prettify())




translator.iter_io_paths_and_files(iter_func=iter_func)


