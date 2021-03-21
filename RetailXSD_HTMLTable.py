#%%

# importing the libraries
#from codecs import BOM_UTF8, encode
from bs4 import BeautifulSoup, NavigableString#, UnicodeDammit
import copy
import os
#import re
#import sys
from IO_DirFileHandler import IO_DirFileHandler

#import requests
#import csv

class RetailXSD_HTMLTable(IO_DirFileHandler):
    def __init__(self, input_file_name=None, output_file_name=None, input_file_extension=".html",output_file_extension=".html",base_path="html",base_input_path=None,base_output_path=None,input_folder="input",output_folder="output",log_file_name="html.log"):
        IO_DirFileHandler.__init__(self, input_file_name, output_file_name, input_file_extension=input_file_extension,output_file_extension=output_file_extension,base_path=base_path,base_input_path=base_input_path,base_output_path=base_output_path,input_folder=input_folder,output_folder=output_folder, log_file_name=log_file_name)
        self._thead_html_file="thead.html"
        self._desc_thead_html_file="desc_thead.html"
        self.soup=None
        if self.get_input_file_name() is not None:
            try:
                self.createSoup()
            except FileNotFoundError:
                pass
        self.thead=BeautifulSoup(open(os.path.join(self._thead_html_file),encoding='utf8').read(),"html.parser")
        self.desc_thead=BeautifulSoup(open(os.path.join(self._desc_thead_html_file),encoding='utf8').read(),"html.parser")

    #HTML parse functions:
    def createSoup(self, parser_or_markup="lxml"):
        """
        print("input_path")
        print(self.get_input_path())
        print("file_name:")
        print(self.get_input_file_name())
        print("fullinput:")
        print(self.full_input_path_and_file())
        """
        self.soup = BeautifulSoup(open(self.full_input_path_and_file()), parser_or_markup)
        self.soup.smooth()
    
    #def regex_search(self, tbl, expression):
    #    return re.compile(expression).search(tbl)
    
    def decompose_empty_tr(self):
        try:
            for empty_row in self.soup.find_all(name="tr", attrs={}, string="", recursive=True,):
                if empty_row.string == "\n":
                    empty_row.decompose()
        except:
            pass
    
    def insert_thead(self, tbl):
        tbl.insert(0,copy.copy(self.thead.find("thead")))
    
    def insert_desc_thead(self, tbl):
        tbl.insert(0,copy.copy(self.desc_thead.find("thead")))
    
    
    def generate_html_head_title_body(self, html_snippet, title=None):
        if html_snippet.html is None:
            html_snippet.wrap(self.soup.new_tag("html"))
        if html_snippet.body is None:
            html_snippet.wrap(self.soup.new_tag("body"))
        if html_snippet.html is None:
            html_snippet=html_snippet.find_previous("html")
        header=self.soup.new_tag("head")
        header.append(self.soup.new_tag("title"))
        if title is None and self.get_input_file_name() is not None:
            title=self.get_input_file_name()
        if title is not None:
            header.title.append(NavigableString(title))
            html_snippet.insert(0,header)
        html_snippet.smooth()
        return html_snippet
    
    def generate_output_file_name_based_on_title(self, html_snippet=None, prefix=None, suffix=None):
        if prefix is None:
            prefix=self._output_prefix
        if suffix is None:
            suffix=self._output_suffix
        if html_snippet is None:
            html_snippet=self.soup
        output_file_name=prefix+html_snippet.find(name="title").string.strip()+suffix+self.output_file_extension
        self.set_safe_output_file_name_only(output_file_name=output_file_name)
        return self.full_output_path_and_file()

    def regex_wrapper(self, element,expression):
        def regex_func(content=element):
            return self.regex_search(content, expression)
        return regex_func
    
    def gen_table_file(self, in_tbl, title_file_name, log_level=1):
        for leftover_th in in_tbl.find_next(name="tbody").find_all(self.get_tr_with_th):
            leftover_th.decompose()
        in_tbl=self.generate_html_head_title_body(html_snippet=in_tbl,title=title_file_name)
        self.generate_output_file_name_based_on_title(html_snippet=in_tbl)
        self.log(log_message="Generating file "+translator.full_output_path_and_file(),log_level=log_level)
        self.output_to_file(output=in_tbl.prettify())

    def get_tr_with_th(self, element):
        try:
            return (element.name=="tr" and element.find(name="th").name=="th")
        except AttributeError:
            return False
    
    def gen_func(self, input_path,output_path,input_file_name,first_time_in_folder):
        if self.get_input_file_name() is not None:
                self.createSoup()
        else:
            return
        app_name_folder=os.path.split(input_path)[-1]
        self.decompose_empty_tr()
        desc_tbl = None
        #desc_tbl = self.soup.find_next(string=target_name_space):
        for op in self.soup.find_all(string=self.regex_wrapper(...,expression="Target Name Space")):
            desc_tbl = op
            break #only using find_all+break here because, for some reason, find_next does not work as expected
        desc_tbl = desc_tbl.find_previous(name="table")
        desc_tbl["data-name"]="Desc_Tbl"
        self.insert_desc_thead(desc_tbl)
        title=(app_name_folder.upper()+"_"+desc_tbl["data-name"]+"_"+self.get_file_name_without_extension(self.get_input_file_name()))
        self.gen_table_file(in_tbl=desc_tbl,title_file_name=title,log_level=1)
        for sop in self.soup.find_all(string=self.regex_wrapper(...,expression="XML-Schema Name")):
            xsd_table = sop.find_next(name="table")
            xsd_table["data-name"]=xsd_table.find_previous(name="a").get("name")
            self.insert_thead(xsd_table)
            tetah=xsd_table.find_next(name="th",attrs={"colspan":"6"}, string=self.regex_wrapper(...,expression="Application:"))
            tetah.append(app_name_folder.upper())
            self.gen_table_file(in_tbl=xsd_table,title_file_name=(app_name_folder.upper()+"_"+xsd_table["data-name"]),log_level=2)

    
# Step 1: Sending a HTTP request to a URL
#url = "https://en.wikipedia.org/wiki/List_of_countries_by_GDP_(nominal)"
# Make a GET request to fetch the raw HTML content
#html_content = requests.get(url).text

translator = RetailXSD_HTMLTable(base_path="html")
#translator = RetailXSD_HTMLTable(input_file_name=["html","input","rms","XItemDesc.html"],output_folder="output_unit_test",log_file_name="html_unit_test.log")

translator.make_out_subfolder_from_in_file_name=True
translator.use_base_path_as_preffix_for_output_path=True


#translator.iter_io_paths_and_files(iter_func=iter_func)
translator.iter_io_paths_and_files(iter_func=translator.gen_func)
#translator.iter_io_paths_and_files(iter_func=iter_func,base_input_path=translator.get_input_path())
#iter_func(input_path=translator.get_input_path(),output_path=translator.get_output_path(),input_file_name=translator.get_input_file_name())



"""
def iter_func(input_path,output_path,input_file_name):
    if translator.get_input_file_name() is not None:
            translator.createSoup()
    else:
        return
    app_name_folder=os.path.split(input_path)[-1]
    translator.decompose_empty_tr()
    #app_name_file=translator.soup.find_next(name="th",attrs={"colspan":"6"},string=)
    #print(app_name_folder)
    desc_tbl = None
    #for op in translator.soup.find_all(string=target_name_space):
    for op in translator.soup.find_all(string=translator.regex_wrapper(...,expression="Target Name Space")):
        desc_tbl = op
        break #only using find_all+break here because, for some reason, find_next does not work as expected
    desc_tbl = desc_tbl.find_previous(name="table")
    desc_tbl["data-name"]="Desc_Tbl"
    translator.insert_desc_thead(desc_tbl)
    title=(app_name_folder.upper()+"_"+desc_tbl["data-name"]+"_"+translator.get_file_name_without_extension(translator.get_input_file_name()))
    translator.gen_table_file(in_tbl=desc_tbl,title_file_name=title,log_level=1)

    for sop in translator.soup.find_all(string=translator.regex_wrapper(...,expression="XML-Schema Name")):
        xsd_table = sop.find_next(name="table")
        xsd_table["data-name"]=xsd_table.find_previous(name="a").get("name")
        translator.insert_thead(xsd_table)
        tetah=xsd_table.find_next(name="th",attrs={"colspan":"6"}, string=translator.regex_wrapper(...,expression="Application:"))
        tetah.append(app_name_folder.upper())
        #print(tetah)
        #if tetah:
        #print(tetah.string)
        #print(tetah)
        translator.gen_table_file(in_tbl=xsd_table,title_file_name=(app_name_folder.upper()+"_"+xsd_table["data-name"]),log_level=2)
        """
"""
        for leftover_th in xsd_table.find_next(name="tbody").find_all(get_tr_with_th):
            leftover_th.decompose()
        xsd_table=translator.generate_html_head_title_body(html_snippet=xsd_table,title=(app_name_folder.upper()+"_"+xsd_table["data-name"]))
        translator.generate_output_file_name_based_on_title(html_snippet=xsd_table)
        translator.log(log_message="Generating file "+translator.full_output_path_and_file())
        translator.output_to_file(output=xsd_table.prettify())
        """


