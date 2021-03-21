#%%
import os

base_path = "html_to_xlsx"
base_path=os.path.abspath(base_path)
base_input_path = "..\\html"
base_input_path=""

opa = os.path.normpath(os.path.join(base_path,base_input_path))
epa=os.path.join(base_path,base_input_path)
print(os.path.exists(opa))
print(os.path.exists(epa))

filfil="hopa.html"
isfi = os.path.isfile(filfil)

print(isfi)


