#%%
from os.path import basename
from pathlib import PurePath, Path
import os
import sys
import re


class IO_DirFileHandler:
    #file_and_dir handle functions:
    def __init__(self, input_file_name=None, output_file_name=None, input_file_extension=".html",output_file_extension=".html",base_path="",base_input_path=None,base_output_path=None,input_folder="input",output_folder="output", log_file_name=None):
        self.input_file_extension=input_file_extension
        self.output_file_extension=output_file_extension
        self._input_folder=input_folder
        self._output_folder=output_folder
        self._output_prefix=""
        self._output_suffix=""
        self._use_only_abs_paths=False
        self.__location__ = os.path.realpath(
            os.path.join(os.getcwd(), os.path.dirname(__file__)))
        if base_path == "" or base_path is None or base_path == "." or base_path == "./" or base_path == ".\\":
            self._base_path=self.__location__
        else:
            self._base_path=base_path
        self._base_path=self.get_safe_path_from_path(self._base_path)[0]
        self.set_safe_input_file_name_only(input_file_name)
        self.use_input_sub_folder_as_output_file_name=False
        self.set_safe_output_file_name_only(output_file_name)
        self.set_safe_log_file_name_only(log_file_name,self.get_input_file_name())
        self.set_input_path(base_input_path=base_input_path,input_file_name=input_file_name)
        self.set_root_input_path(self.get_input_path())
        self.use_base_path_as_preffix_for_output_path=True#set fixed to True as it does not make any sense do disassociate the base_path from the base_output_path, which should always be a subdir from the former.
        self.make_out_subfolder_from_in_file_name = False
        self.use_input_path_suffixes=True
        self.set_output_path(base_output_path=base_output_path)#,file_name=file_name)
        self.set_root_output_path(self.get_output_path())
        self.set_log_path(base_log_path=self.get_base_path())
        self.set_root_log_path(self.get_log_path())
        
        self._file_ref=None
        
        
    def set_safe_input_file_name_only(self, input_file_name=None):
        self.input_file_name=self._set_safe_file_name_only(file_name=input_file_name,default=None)#os.path.join("test"+self.input_file_extension))
    
    def set_safe_output_file_name_only(self, output_file_name=None, file_name_extension=None,
                                       use_input_sub_folder_as_output_file_name=None):
        if file_name_extension is None:
            file_name_extension=self.output_file_extension
        if use_input_sub_folder_as_output_file_name is None:
            use_input_sub_folder_as_output_file_name=self.use_input_sub_folder_as_output_file_name
        if use_input_sub_folder_as_output_file_name and output_file_name is None:
            output_file_name=os.path.basename(self.get_input_path())+self.output_file_extension
        self.output_file_name=self._set_safe_file_name_only(file_name=output_file_name,file_name_extension=file_name_extension,default=os.path.join("test"+self.output_file_extension))
    
    def set_safe_log_file_name_only(self, log_file_name=None, input_file_name=None):
        #print("LOG_FILE_NAME:")
        #print(log_file_name)
        if log_file_name is None and input_file_name is not None:
            log_file_name=os.path.basename(self.get_base_path())+"_"+self.get_file_name_without_extension(input_file_name)+"_unit_test.log"
            #log_file_name=os.path.join(self.get_base_path(),)
        self.log_file_name=self._set_safe_file_name_only(file_name=log_file_name,default=self.get_base_path()+".log")
    
    def _set_safe_file_name_only(self,file_name=None,file_name_extension=None,default=None):
        #print(file_name)
        if file_name is not None:# and os.path.isfile(file_name):
            if type(file_name) in [list,tuple]:
                out_file = os.path.basename(os.path.join(*file_name))
            else:
                out_file = os.path.basename(file_name)
            if file_name_extension is not None:
                out_file_name = self.get_file_name_without_extension(out_file)
                #out_file=os.path.join(out_file_name,file_name_extension)
                out_file=out_file_name+file_name_extension
                #print("NOVO FORMATOOOOOOOOOO:")
                #print(out_file)
            ####print(out_file)
            return out_file
        else:
            return default
    
    class InvalidInputPath(Exception):
        """Raised when the resolved base_input_path does not point to
         a valid location"""
        pass
    
    def set_root_input_path(self, input_path):
        self.original_input_path=input_path
    
    def get_root_input_path(self):
        return self.original_input_path
    
    def set_input_path(self, base_input_path=None, input_file_name=None):
        if base_input_path is None:
            base_input_path=self.get_only_path_from_file(file_name=input_file_name,default_path=self._input_folder)#there can't be a suffix if file_name is given
        if base_input_path is None or base_input_path == "":
            base_input_path=self._input_folder
        #if base_input_path == "":
        #    base_input_path=self.get_base_path()
        #base_input_path=os.path.normpath(os.path.join(self.get_base_path(),base_input_path))
        #print("set_input_path")
        #print(base_input_path)
        self._base_input_path=self.get_safe_path_from_path(ref_path=base_input_path)[0]
    
    def set_root_output_path(self, output_path):
        self.original_input_path=output_path
    
    def get_root_output_path(self):
        return self.original_output_path
    
    def set_output_path(self, base_output_path=None):#, file_name=None):
        if base_output_path is None:
            base_output_path=self.get_output_path_from_input_path(use_base_path_as_preffix_for_output_path=self.use_base_path_as_preffix_for_output_path,
                                                                  make_out_subfolder_from_in_file_name=self.make_out_subfolder_from_in_file_name,
                                                                  use_input_path_suffixes=self.use_input_path_suffixes
                                                                  )
        self._base_output_path=self.get_safe_path_from_path(base_output_path)[0]
        os.makedirs(self._base_output_path, exist_ok=True)
    
    class NullInputPath(Exception):
        """Raised when the base_input_path and base_path are both null,
        inside function get_output_path_from_input_path"""
        pass

    def get_output_path_from_input_path(self, input_path_label=None, output_path_label=None,
                                        base_input_path=None,
                                        use_base_path_as_preffix_for_output_path=True,
                                        make_out_subfolder_from_in_file_name=False,
                                        use_input_path_suffixes=True):
        if base_input_path is None or base_input_path == "":
            base_input_path=self.get_input_path()
        if input_path_label is None or input_path_label == "":
            input_path_label=self._input_folder
        if output_path_label is None or output_path_label == "":
            output_path_label=self._output_folder
        #path = Path(base_input_path)
        path=os.path.normpath(base_input_path)
        idx = -1
        #for i,part in enumerate(path.parts):
        path_parts=path.split(os.sep)
        for i,part in enumerate(path_parts):
            #print(part)
            if part == input_path_label:
                idx = i
                break
        if idx == -1:
            if base_input_path == "":
                if self._base_path != "":
                    raise self.NullInputPath
                else:
                    output_path=output_path_label
            else:
                output_path=None#output_path_label
        else:
            if use_base_path_as_preffix_for_output_path:
                pre_path = self.get_base_path()
            else:
                #pre_path = os.path.join(*path.parts[:idx])
                pre_path = os.path.join(*path_parts[:idx])
            #post_path = os.path.join(*path.parts[idx+1:])
            #print("path_parts:")
            #print(path_parts)
            if use_input_path_suffixes:
                try:
                    post_path = os.path.join(*path_parts[idx+1:])
                except TypeError:
                    post_path = ""
            else:
                post_path=""
            """
            print("pre_path:")
            print(pre_path)
            print("output_path_label:")
            print(output_path_label)
            print("post_path:")
            print(post_path)
            """
            output_path = os.path.join(pre_path, output_path_label, post_path)
            if make_out_subfolder_from_in_file_name:
                try:
                    sub_folder_based_on_file_name=self.get_file_name_without_extension(self.get_input_file_name())
                except TypeError:
                    sub_folder_based_on_file_name=""
                output_path = os.path.join(output_path,sub_folder_based_on_file_name)
        """
        print("output_path")
        print(output_path)
        """
        return output_path
    
    def set_root_log_path(self, log_path):
        self.original_log_path=log_path
    
    def get_root_log_path(self):
        return self.original_log_path
    
    def set_log_path(self, base_log_path=None):#, log_file_name=None):
        if base_log_path is None:
            base_log_path=self.get_base_path()
        self._base_log_path=self.get_safe_path_from_path(ref_path=base_log_path)[0]
    
    
    def get_safe_path_from_path(self, ref_path, use_only_abs_paths=None):
        path_exists=False
        if type(ref_path) in [list,tuple]:
            safe_path=os.path.join(*ref_path)
        else:
            safe_path=ref_path
        if safe_path == "" or not safe_path:
            safe_path=self.get_base_path()
        if os.path.isfile(safe_path):
            safe_path=self.get_only_path_from_file(file_name=safe_path)
        if os.path.exists(safe_path):
            #print("Caraio existe 0")
            path_exists=True
        elif os.path.exists(os.path.join(self._base_path,safe_path)):
            safe_path=os.path.join(self._base_path,safe_path)
            path_exists=True
        elif os.path.exists(os.path.join(self.__location__,safe_path)):
            safe_path=os.path.join(self.__location__,safe_path)
            path_exists=True
        #print("get_safe_path_from_path")
        #print(safe_path)
        safe_path=os.path.normpath(safe_path)
        #print(safe_path)
        if use_only_abs_paths is None:
            use_only_abs_paths=self._use_only_abs_paths
        if use_only_abs_paths:# and safe_path != os.path.abspath(safe_path):
            safe_path = os.path.abspath(safe_path)
            if not path_exists and os.path.exists(safe_path):
                path_exists=True
        #print(safe_path)
        return (safe_path, path_exists)
    
    def is_path_child_of_root_output_path(self, child_path):
        return self._is_path_child_of_base_path(child_path,parent_path=self.get_root_output_path())
    
    def is_path_child_of_root_input_path(self, child_path):
        return self._is_path_child_of_base_path(child_path,parent_path=self.get_root_input_path())
    
    def _is_path_child_of_base_path(self, child_path, parent_path=None,use_only_abs_paths=None):
        # Smooth out relative path names, note: if you are concerned about symbolic links, you should use os.path.realpath too
        if parent_path is None:
            parent_path = self._base_path #os.path.abspath(self._base_path)
        if use_only_abs_paths is None:
            use_only_abs_paths=self._use_only_abs_paths
        if use_only_abs_paths:
            child_path = os.path.abspath(child_path)
        # Compare the common path of the parent and child path with the common path of just the parent path.
        # Using the commonpath method on just the parent path will regularise the path name in the same way
        # as the comparison that deals with both paths, removing any trailing path separator
        return os.path.commonpath([parent_path]) == os.path.commonpath([parent_path, child_path])
    
    def get_only_path_from_file(self, file_name=None, default_path=""):
        if file_name is None:
            return default_path
        else:
            if type(file_name) in [list,tuple]:
                return os.path.dirname(os.path.join(*file_name))
            else:
                return os.path.dirname(file_name)
    
    def full_output_path_and_file(self):
        return os.path.join(self.get_output_path(),self.get_output_file_name())
    
    def full_input_path_and_file(self):
        return os.path.join(self.get_input_path(),self.get_input_file_name())
    
    def full_log_path_and_file(self):
        return os.path.join(self.get_log_path(),self.get_log_file_name())
    
    def get_input_path(self):
        return self._base_input_path
    
    def get_output_path(self):
        return self._base_output_path
    
    def get_log_path(self):
        return self._base_log_path
    
    def get_base_path(self):
        return self._base_path
    
    def get_input_file_name(self):
        return self.input_file_name
    
    def get_output_file_name(self):
        return self.output_file_name
    
    def get_log_file_name(self):
        return self.log_file_name
    
    def get_file_name_without_extension(self, file_name):
        file_name_without_ext, _ = os.path.splitext(file_name)
        return file_name_without_ext
    
    def get_extension_from_file_name(self, file_name):
        _, extension = os.path.splitext(file_name)
        return extension
    
    def open_file(self, path_to_file=None, encoding='utf8'):
        if path_to_file is None:
            path_to_file = self.full_input_path_and_file()
        else:
            self._base_input_path=self.set_input_path(path_to_file)
            self.input_file_name=self.set_safe_file_name_only(path_to_file)
        self._file_ref=open(path_to_file,encoding)
    
    def close_file(self):
        self._file_ref.close()
    
    def output_to_file(self, output, output_path_and_file=None, mode='w'):#, file_name=None):
        original_stdout = sys.stdout # Save a reference to the original standard output
        if not output_path_and_file:
            output_path_and_file=self.full_output_path_and_file()
        try:
            with open(output_path_and_file, mode) as f:
                sys.stdout = f # Change the standard output to the file we created.
                print(output)#,encode(BOM_UTF8))
        except Exception as e:
            print(e)
        finally:
            sys.stdout = original_stdout # Reset the standard output to its original value

    def log(self, log_message, log_path=None, log_file_name=None, log_level=1):
        if log_path is not None:
            log_path=self.get_safe_path_from_path(ref_path=log_path)[0]
            self.set_log_path(base_log_path=log_path)
        if log_file_name is not None:
            self.set_safe_log_file_name_only(log_file_name=log_file_name)
        log_level_spaces=' '*log_level
        log_message=log_level_spaces+log_message
        self.output_to_file(output=log_message,output_path_and_file=self.full_log_path_and_file(),mode='a+')
    
    def get_path_and_files(self,base_input_path=None):
        if base_input_path is None:
            base_input_path=self._base_input_path
        root_list=[]
        dirs_list=[]
        files_list=[]
        for (root,dirs,files) in os.walk(base_input_path,topdown=True):
            root_list.append(root)
            dirs_list.append(dirs)
            files_list.append(files)
        #TODO: Filtrar os output paths
        return zip(root_list,dirs_list,files_list)
    
    def _check_if_path_is_input(self,path,input_folder=None,output_folder=None):
        return True

    def iter_io_paths_and_files(self,iter_func=None,base_input_path=None,input_folder=None,output_folder=None):
        if base_input_path is None:
            base_input_path=self._base_input_path
        if input_folder is None:
            input_folder=self._input_folder
        if output_folder is None:
            output_folder=self._output_folder
        #if base_input_path is None:
        #    base_input_path=self._base_input_path
        root_list=[]
        dirs_list=[]
        files_list=[]
        full_input_path_and_files=[]
        full_output_path_and_files=[]
        for (root,dirs,files) in os.walk(base_input_path,topdown=True):
            #print("groot:")
            #print(root)
            if not self.is_path_child_of_root_input_path(root):
                pass
            if files:
                self.set_input_path(base_input_path=root)
                if not self.get_output_path_from_input_path():
                    self.log("Could not resolve output path from input path "+self.get_input_path())
                    pass
                first_time_in_folder=True
                for file in files:
                    if not file:
                        pass
                    self.set_safe_input_file_name_only(input_file_name=file)
                    self.set_output_path()
                    """
                    print("orig_file:")
                    print(file)
                    print("file_name:")
                    print(self.input_file_name)
                    print("input_path:")
                    print(self._base_input_path)
                    print("output_path:")
                    print(self._base_output_path)
                    """
                    if iter_func is not None:
                        log_message="Processing "+self.full_input_path_and_file()
                        print(log_message)
                        self.log(log_message,log_level=0)
                        iter_func(input_path=self.get_input_path(),output_path=self.get_output_path(),input_file_name=self.get_input_file_name(),first_time_in_folder=first_time_in_folder)
                    first_time_in_folder=False
                    #else:
                        #print("full_output_path_and_file:")
                        #print(self.full_output_path_and_file())
        #    root_list.append(root)
        #    dirs_list.append(dirs)
        #    files_list.append(files)
        #TODO: Filtrar os output paths
        #return zip(root_list,dirs_list,files_list)
    
        #return self.get_path_and_files()
    
    def regex_search(self, content, expression):
        return re.compile(expression).search(content)

#opa=IO_DirFileHandler(base_path="html")#, file_name=["html","input","rms","AddrDesc.html"])

#opa.iter_io_paths_and_files()



# %%
