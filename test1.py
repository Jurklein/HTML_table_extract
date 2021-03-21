#%%

# importing the libraries
#from codecs import BOM_UTF8, encode
from bs4 import BeautifulSoup, NavigableString#, UnicodeDammit
import copy
import os
import re
import sys

#%%
#import requests
#import csv

class RetailXSD_HTMLTable:
    def __init__(self, file_name, base_input_path=None,base_output_path=None,recursive=False) -> None:
        self.file_name=file_name
        self.recursive=recursive
        self._input_folder="input"
        self._output_folder="output"
        self._thead_html_file="thead.html"
        self.__location__ = os.path.realpath(
            os.path.join(os.getcwd(), os.path.dirname(__file__)))
        if base_input_path is None:
            self._base_input_path=os.path.join(self.__location__,self._input_folder)
        else:
            self._base_input_path=base_input_path
        if base_output_path is None:
            self._base_output_path=os.path.join(self.__location__,self._output_folder)
        else:
            self._base_output_path=base_output_path
        
            self.html_base_url=html_base_url#"C:\\RRL_2020_2\\RRA\\ProductDomains\\EnterpriseIntegration\\ApiMappingReports\\rms\\AddrDesc.html"
# Step 1: Sending a HTTP request to a URL
#url = "https://en.wikipedia.org/wiki/List_of_countries_by_GDP_(nominal)"
# Make a GET request to fetch the raw HTML content
#html_content = requests.get(url).text


# Step 2: Parse the html content
    
    soup = BeautifulSoup(open(html_base_url), "lxml")
    thead = BeautifulSoup(open(os.path.join(__location__,_thead_html_file),encoding='utf8').read(),"html.parser")

def _xml_schema_name(tbl):
    return re.compile("XML-Schema Name").search(tbl)

def _get_tr_with_th(tbl):
    try:
        return (tbl.name=="tr" and tbl.find(name="th").name=="th")
    except AttributeError:
        return False

original_stdout = sys.stdout # Save a reference to the original standard output
xsd_names = []
i=0
soup.smooth()
for empty_row in soup.find_all(name="tr", attrs={}, string="", recursive=True,):
    if empty_row.string == "\n":
        empty_row.decompose()

xml_tables = soup.find_all("table",recursive=True)

for sop in soup.find_all(string=_xml_schema_name):
    xsd_table = sop.find_next(name="table")
    xsd_names.append(xsd_table.find_previous(name="a").get("name"))
    xsd_table["data-name"]=xsd_names[i]
    xsd_table.insert(0,copy.copy(thead.find("thead")))
    for leftover_th in xsd_table.find_next(name="tbody").find_all(_get_tr_with_th):
        leftover_th.decompose()
    xsd_table.wrap(soup.new_tag("html"))
    xsd_table.wrap(soup.new_tag("body"))
    xsd_table=xsd_table.find_previous("html")
    header=soup.new_tag("head")
    header.append(soup.new_tag("title"))
    header.title.append(NavigableString(xsd_names[i]))
    xsd_table.insert(0,header)
    xsd_table.smooth()
    out_html_name="out_"+xsd_names[i]+".html"
    out_file=os.path.join(__location__,out_html_name)
    with open(out_file, 'w') as f:
        sys.stdout = f # Change the standard output to the file we created.
        print(xsd_table.prettify())#,encode(BOM_UTF8))
        sys.stdout = original_stdout # Reset the standard output to its original value
    i+=1

