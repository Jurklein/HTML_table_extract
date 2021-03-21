import os


_home_folder="html"
_input_folder="input"
_output_folder="output"


__location__ = os.path.realpath(
    os.path.join(os.getcwd(), os.path.dirname(__file__)))
mypath=__location__

_input_path=os.path.join(__location__,_home_folder,_input_folder)
_output_path=os.path.join(__location__,_home_folder,_output_folder)
print("_input_path:")
print(_input_path)
""" print("os.getcwd():")
print(os.getcwd())
print("\n__file__:")
print(__file__)
print("\nos.path.dirname(__file__):")
print(os.path.dirname(__file__))
print("\nos.path.join(os.getcwd(), os.path.dirname(__file__)):")
print(os.path.join(os.getcwd(), os.path.dirname(__file__)))
print("\n__location__:")
print(__location__)
 """

#print("\nDIRNAMES:")
#dirnames=next(os.walk(_input_path))
#print(dirnames)
_segments_folders=[f for f in os.listdir(_input_path)
    if os.path.isdir(os.path.join(_input_path, f))]
for seg_folder in _segments_folders:
    _input_seg_path=os.path.join(_input_path,seg_folder)
    _segments_files=[f for f in os.listdir(_input_seg_path)
        if os.path.isfile(os.path.join(_input_seg_path,f))]
    #for seg_file in _segments_files:
        

f = []
for (_, _, filenames) in os.walk(_input_path,topdown=True):
    f.extend(filenames)
    #break

#soup = BeautifulSoup(open(url), "lxml")
#thead = BeautifulSoup(open(os.path.join(__location__,"thead.html"),encoding='utf8').read(),"html.parser")

print("\nf:")
print(f)