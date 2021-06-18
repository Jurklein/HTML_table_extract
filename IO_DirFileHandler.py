#%%
from os.path import basename, isfile
from pathlib import PurePath, Path
import os

import sys
import re

import fileinput

class IO_DirFileHandler:
    #file_and_dir handle functions:
    def __init__(self, input_file_name=None, output_file_name=None, input_file_extension=None,output_file_extension=None,base_path="",base_input_path=None,base_output_path=None,input_folder=None,output_folder=None, log_file_name=None):
        self.input_file_extension=input_file_extension
        self.output_file_extension=output_file_extension
        self._set_input_folder(input_folder)
        self._set_output_folder(output_folder)
        self._output_prefix=""
        self._output_suffix=""
        self.set_abs_paths_flag(False)
        self.set_file_location()
        self.set_root_of_base_path(base_path)
        self.set_base_path(base_path)
        self.set_safe_input_file_name_only(input_file_name)
        self.use_input_sub_folder_as_output_file_name=False
        self.use_input_file_name_as_output_file_name = False
        self.set_safe_output_file_name_only(output_file_name)
        self.set_safe_log_file_name_only(log_file_name,self.get_input_file_name())
        self._original_input_path=None
        self.set_input_path(base_input_path=base_input_path if base_input_path else input_file_name)
        self.set_root_of_input_path(self.get_input_path())
        #self.set_input_folder(input_folder)#TODO: corrigir essa função (testar com RetailXSDHTML_Table.py) (por enquanto tive q comentar e deixar apenas self._input_folder=input_folder)
        self.use_base_path_as_preffix_for_output_path=True#set fixed to True as it does not make any sense do disassociate the base_path from the base_output_path, which should always be a subdir from the former.
        self.use_input_file_name_as_output_sub_folder = False
        self.use_input_path_suffixes=True # 'use_input_path_suffixes' can also be given a number (positive integer) value, which represents the input folder suffixes sublevel to inherit for the output folder
        self.use_suffix_for_output_path=False
        #self.set_output_folder(output_folder) #TODO: corrigir essa função (testar com RetailXSDHTML_Table.py)
        self._original_output_path=None
        self.set_output_path(base_output_path=base_output_path)#,file_name=file_name)
        self.set_root_of_output_path(self.get_output_path())
        self.set_log_path(base_log_path=self.get_base_path())
        self.set_root_log_path(self.get_log_path())
        
        self._file_ref=None
    
    
    def get_abs_paths_flag(self):
        return self._use_only_abs_paths
    
    def set_abs_paths_flag(self, use_only_abs_paths=False):
        self._use_only_abs_paths=use_only_abs_paths
        self.update_input_path()
        self.update_output_path()
    
    def set_file_location(self):
        self.__location__ = os.path.realpath(
            os.path.join(os.getcwd(), os.path.dirname(__file__)))
    
    def get_file_location(self):
        return self.__location__
    
    def get_root_of_base_path(self):
        return self._root_of_base_path

    def set_root_of_base_path(self,abs_path=None):
        self._root_of_base_path,path_exists,abs_path_exists=self._get_safe_root_path_from_path(root_path=abs_path)
        return abs_path_exists
    
    class InvalidBasePath(Exception):
        """Raised when the resolved base_path does not point to
         a valid location"""
        pass
    
    def _set_base_path(self, base_path):
        if not self.get_abs_paths_flag():
            self._base_path=os.path.basename(base_path)
            if self._base_path == os.path.basename(self.get_file_location()):
                self._base_path=''
        else:
            self._base_path=base_path
    
    def set_base_path(self, base_path, create_folder_if_not_exists=False):
        if not base_path or base_path == "." or base_path == "\\." or base_path == "./" or base_path == ".\\" or base_path == os.sep:
            safe_path=self.get_file_location()
        else:
            if '..' in base_path:
                base_path=os.path.realpath(base_path)
            safe_path=os.path.abspath(self.serialize_path(base_path))
            #base_path=os.path.dirname(self.__location__)
        #print(base_path)
        #self._base_path=safe_path
        if not self._is_path_child_of_base_path(child_path=safe_path,
                                                parent_path=self.get_file_location(),
                                                use_only_abs_paths=True):
            self.set_abs_paths_flag(True)
        
        if not self._is_path_child_of_base_path(child_path=safe_path,
                parent_path=self.get_root_of_base_path(),
                use_only_abs_paths=self.get_abs_paths_flag()):
            abs_path_exists=self.set_root_of_base_path(abs_path=safe_path)
            if not abs_path_exists:
                if create_folder_if_not_exists and safe_path:
                    os.makedirs(self._resolve_to_abs_path(safe_path), exist_ok=False)
                else:
                    raise self.InvalidBasePath
            self.set_abs_paths_flag(True)
        
        self._set_base_path(self.serialize_path(safe_path))
        self.update_input_path()
        self.update_output_path()
                
    class InvalidInputFileName(Exception):
        """Raised when the resolved input file name does not exist"""
        def __init__(self, input_filename):
            self.input_filename = input_filename

        def __str__(self):
            return 'The resolved input file could not be found: {}'.format(self.input_filename)
    
    def set_safe_input_file_name_only(self, input_file_name=None):
        if input_file_name is not None:
            input_file_name,file_exists=self.check_if_file_and_exists(input_file_name,self.get_input_path())
            if not file_exists:
                input_file_name,file_exists=self.check_if_file_and_exists(os.path.join(self.get_input_path(),input_file_name))
                raise self.InvalidInputFileName(input_file_name)
            else:
                self.input_file_name=self._set_safe_file_name_only(file_name=input_file_name,default=None)#os.path.join("test"+self.input_file_extension))
        else:
            self.input_file_name=None
    
    def set_safe_output_file_name_only(self, output_file_name=None, file_name_extension=None,
                                       use_input_sub_folder_as_output_file_name=None,use_input_file_name_as_output_file_name=None):
        if file_name_extension is None:
            file_name_extension=self.output_file_extension
        if use_input_sub_folder_as_output_file_name is None:
            use_input_sub_folder_as_output_file_name=self.use_input_sub_folder_as_output_file_name
        if use_input_sub_folder_as_output_file_name:
            if output_file_name is None:
                output_file_name=os.path.basename(self.get_input_path())+self.output_file_extension
        elif output_file_name is None:
            if use_input_file_name_as_output_file_name is None:
                use_input_file_name_as_output_file_name=self.use_input_file_name_as_output_file_name
            if use_input_file_name_as_output_file_name:
                output_file_name=self.get_file_name_without_extension(self.get_input_file_name())+file_name_extension
        self.output_file_name=self._set_safe_file_name_only(file_name=output_file_name,file_name_extension=file_name_extension,default=None)#os.path.join("test"+(self.output_file_extension if not None else '.txt')))
    
    def set_safe_log_file_name_only(self, log_file_name=None, input_file_name=None):
        #print("LOG_FILE_NAME:")
        #print(log_file_name)
        if log_file_name is None and input_file_name is not None:
            log_file_name=os.path.basename(self.get_base_path())+"_"+self.get_file_name_without_extension(input_file_name)+"_unit_test.log"
            #log_file_name=os.path.join(self.get_base_path(),)
        
        self.log_file_name=self._set_safe_file_name_only(file_name=log_file_name,default=self.get_deserialized_element(self.deserialize_path(self.get_base_path()))+".log")
    
    def _set_safe_file_name_only(self,file_name=None,file_name_extension=None,default=None):
        #print(file_name)
        if file_name is not None:# and os.path.isfile(file_name):
            out_file=os.path.basename(self.serialize_path(file_name))
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
        def __init__(self, path):
            self.path = path

        def __str__(self):
            return 'The resolved input path is invalid: {}'.format(self.path)
        
    def _set_root_of_input_path(self, input_path):
        self._original_input_path=self.get_safe_path_from_path(input_path)[0]
    
    def set_root_of_input_path(self, input_path):
        self._set_root_of_input_path(self.serialize_path(input_path))
        if not self.is_path_child_of_root_input_path(self.get_input_path()):
            self.set_input_path(base_input_path=self.get_root_of_input_path())
    
    def get_root_of_input_path(self):
        return self._original_input_path
    
    def update_input_path(self):
        try:
            self._set_input_path(self.get_input_path())
        except AttributeError:
            pass
            """
            this is raised when the object is initialized. At this stage, self._input_path
            and self._output_path are still not defined, so the exception is raised.
            """
    
    def _set_input_path(self, base_input_path):
        base_input_path,path_exists=self.get_safe_path_from_path(ref_path=base_input_path)
        if not path_exists:
            raise self.InvalidInputPath(base_input_path)
        else:
            self._base_input_path=base_input_path
    
    def set_input_path(self, base_input_path=None):
        if not base_input_path:
            base_input_path=self.get_input_folder()
        self._set_input_path(base_input_path)
        if self.pathfinder(parent_path=self.get_input_path(),
                           pattern=self.get_input_folder()) is None:
            self._set_input_folder(self.get_deserialized_element(self.deserialize_path(self.get_input_path())))
        if not self.is_path_child_of_root_input_path(self.get_input_path()):
            self._set_root_of_input_path(self.get_input_path())
    
    def get_input_folder(self):
        return self._input_folder
    
    def get_output_folder(self):
        return self._output_folder
    
    class InvalidInputFolder(Exception):
        """Raised when the given input_folder does not match any folder
        in the input_path"""
        pass
    
    def _set_input_folder(self, input_folder):
        self._input_folder=input_folder
    
    def set_input_folder(self, input_folder=None):
        if not input_folder:
            input_folder=self.get_deserialized_element(self.deserialize_path(self.get_input_path()))
        else:
            input_folder=self.pathfinder(parent_path=self.get_input_path()
                                         ,pattern=input_folder
                                         ,prefer_child_match=True
                                         )
        if not input_folder:
            raise self.InvalidInputFolder
        self._set_input_folder(self.serialize_path(input_folder))
    
    class InvalidOutputFolder(Exception):
        """Raised when the resolved output_folder is empty
        """
        pass
    
    def _set_output_folder(self, output_folder):
        self._output_folder=output_folder
    
    def set_output_folder(self, output_folder=None
                        ,create_folder_if_not_exists=True
                        ):
        if not output_folder:
            if not self.get_output_path():
                self.set_output_path(create_folders_if_not_exist=create_folder_if_not_exists)
            else:
                self._set_output_folder(self.get_deserialized_element(self.deserialize_path(self.get_output_path())))
        elif self.get_output_path():
            output_path_candidate=self.pathdetacher(parent_path=self.get_output_path()
                                                    ,pattern=self.get_output_folder()
                                                    ,from_base_to_match=True
                                                    ,include_match=False
                                                    ,from_match_to_end=True
                                                    ,prefer_child_match=False
                                                    ,pattern_to_insert_before_match=None
                                                    ,pattern_to_insert_after_match=output_folder)
            self._set_output_folder(self.serialize_path(output_folder))
            self.set_output_path(output_path_candidate,create_folders_if_not_exist=create_folder_if_not_exists)
        else:
            self._set_output_folder(self.serialize_path(output_folder))
            self.set_output_path(create_folders_if_not_exist=create_folder_if_not_exists)
    
    def _set_root_of_output_path(self, output_path):
        self._original_output_path=self.get_safe_path_from_path(output_path)[0]
    
    def set_root_of_output_path(self, output_path):
        self._set_root_of_output_path(self.serialize_path(output_path))
        if not self.is_path_child_of_root_output_path(self.get_root_of_output_path()):
            self.set_output_path(base_output_path=self.get_root_of_output_path())
    
    def get_root_of_output_path(self):
        return self._original_output_path
    
    def update_output_path(self):
        try:
            self._set_output_path(self.get_output_path())
        except AttributeError:
            pass
            """
            this is raised when the object is initialized. At this stage, self._input_path
            and self._output_path are still not defined, so the exception is raised.
            """
    
    def _set_output_path(self, base_output_path):
        #print(base_output_path)
        self._base_output_path=self.get_safe_path_from_path(base_output_path)[0]
        #print(self._base_output_path)
    
    def set_output_path(self, base_output_path=None, create_folders_if_not_exist=True):#, file_name=None):
        if base_output_path is None:
            base_output_path=self.get_output_path_from_input_path(use_base_path_as_preffix_for_output_path=self.use_base_path_as_preffix_for_output_path,
                                                                  use_input_file_name_as_output_sub_folder=self.use_input_file_name_as_output_sub_folder,
                                                                  use_input_path_suffixes=self.use_input_path_suffixes
                                                                  )
        self._set_output_path(base_output_path)
        if create_folders_if_not_exist and base_output_path:
            os.makedirs(self._resolve_to_abs_path(self.get_output_path()), exist_ok=True)
        if self.pathfinder(parent_path=self.get_output_path(),
                           pattern=self.get_output_folder()) is None:
            self._set_output_folder(self.get_deserialized_element(self.deserialize_path(self.get_output_path())))
        if not self.is_path_child_of_root_output_path(self.get_output_path()):
            self._set_root_of_output_path(self.get_output_path())
    
    class NullInputPath(Exception):
        """Raised when the base_input_path and base_path are both null,
        inside function get_output_path_from_input_path"""
        pass

    def get_output_path_from_input_path(self, input_path_label=None, output_path_label=None,
                                        base_input_path=None,
                                        use_base_path_as_preffix_for_output_path=None,
                                        use_input_file_name_as_output_sub_folder=False,
                                        use_input_path_suffixes=True):
        if base_input_path is None or base_input_path == "":
            base_input_path=self.get_input_path()
        if input_path_label is None or input_path_label == "":
            input_path_label=self.get_input_folder()
        if output_path_label is None:
            if use_base_path_as_preffix_for_output_path:
                output_path_label=''
            else:
                output_path_label=self.get_output_folder()
            if output_path_label is None:
                 output_path_label = ''
        
        #print('\n\n\ninput_path in get_output_path: '+base_input_path)
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
                if self.get_base_path() != "":
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
                if idx > 0:
                    pre_path = os.path.join(*path_parts[:idx])
                else:
                    pre_path=''
            #post_path = os.path.join(*path.parts[idx+1:])
            #print("path_parts:")
            #print(path_parts)
            if use_input_path_suffixes:
                try:
                    end_idx=None
                    if use_input_path_suffixes is True:
                        end_idx=None
                    else:
                        try:
                            #gotdata=path_parts[idx+use_input_path_suffixes]
                            end_idx=len(path_parts)-2+use_input_path_suffixes
                            #print(end_idx)
                        except IndexError:
                            end_idx=None
                    #print("END_IDX:::::::::")
                    #print(end_idx)
                    post_path = os.path.join(*path_parts[idx+1:end_idx])
                    #print(post_path)
                except TypeError:
                    post_path = ""
            else:
                post_path=""
            if self.use_suffix_for_output_path and self._output_suffix is not None:
                post_path=os.path.join(post_path,self._output_suffix)
            """
            print("pre_path:")
            print(pre_path)
            print("output_path_label:")
            print(output_path_label)
            print("post_path:")
            print(post_path)
            """
            output_path = os.path.join(pre_path, output_path_label, post_path)
            #print("output_path: "+output_path)
            if use_input_file_name_as_output_sub_folder:
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
    
    def get_missing_path_to_folder(self, ref_path, folder,topdown=True,default_path=None):
        path_to_folder=default_path
        path_exists=False
        ref_path=self.serialize_path(ref_path)
        for (root,_,_) in os.walk(ref_path,topdown=topdown):
            if self._is_path_child_of_base_path(child_path=folder, parent_path=root,use_only_abs_paths=False):
                path_to_folder=root
                path_exists=True
                break
        return (path_to_folder,path_exists)
                
    resolution_from_ref_path_and_invalid_folder={
        "RETURN_NONE": None,
        "RETURN_REF_PATH": 1,
        "RETURN_PATH_WITH_FOLDER": 2,
        "CREATE_FOLDER_AND_RETURN_PATH": 3
    }

    def navigate_to_child_folder(self, folder,ref_path=None,get_first_match_only=True,recursive=True,use_only_abs_paths=None):
        ref_path,path_exists=self.get_safe_path_from_path(ref_path,use_only_abs_paths)
        if not path_exists:
            return (ref_path,path_exists,[])
        start_path=Path(ref_path)
        if not recursive:
            pattern='*'+os.sep
        else:
            pattern='**'+os.sep
        possible_paths=[]
        for subpath in start_path.glob(pattern):
            if (subpath.is_dir() and 
            self.pathfinder(
            subpath,
            folder,
            prefer_child_match=True)):
                if subpath is not None:
                    possible_paths.append(self.resolve_abs_or_rel_path(abs_or_rel_path=self.serialize_path(subpath),use_only_abs_paths=use_only_abs_paths))
                    if get_first_match_only:
                        break
                
        if len(possible_paths)==0:
            path_exists=False
            elected_path=None
        else:
            path_exists=True
            elected_path=possible_paths.pop(0)
        return (elected_path,path_exists,possible_paths)
    
    
    class InvalidPathFormat(Exception):
        """Raised when the path type does not follow a supported format.
        Supported formats are 'tuple', 'list', 'Path' and 'str'
        """
        pass
    
    def serialize_path(self, path):
        if not path:
            return ''
        if isinstance(path,list):
            return os.path.join(*path)
        if isinstance(path, tuple):
            return os.path.join(*path)
        if isinstance(path,Path):
            return os.path.join(path.resolve())
        if isinstance(path, str):
            return path 
        raise self.InvalidPathFormat
    
    def get_deserialized_element(self,deserialized_path,index=-1):
        if not deserialized_path:
            return ''
        return deserialized_path[index]
    
    def deserialize_path(self,path): # returns a tuple with each level of the path
        if isinstance(path,tuple):
            return path
        if not path:
            return ()
        if isinstance(path,Path):
            return path.parts
        if isinstance(path,list):
            return Path(os.path.join(*path)).parts
        if isinstance(path,str):
            return Path(path).parts
        raise self.InvalidPathFormat

    def pathsfinder(self,parent_path, pattern):
        if not pattern or not parent_path:
            return None
        match_positions=[]
        for i in range(len(parent_path)):
            if parent_path[i] == pattern[0] and parent_path[i:i+len(pattern)] == pattern:
                match_positions.append(i)
        return match_positions
    
    def _pathfinder_mismatch_saver(self,parent_path,pattern):
        if not pattern or not parent_path:
            return (None,None)
        if (not type(parent_path)==type(pattern)) or isinstance(parent_path,(str,Path)) or isinstance(pattern,(str,Path)):
            parent_path=self.deserialize_path(parent_path)
            pattern=self.deserialize_path(pattern)
        return (parent_path,pattern)
    
    def pathfinder(self,parent_path, pattern,prefer_child_match=True):#parent_path and pattern must be of the same type (e.g.: list and list, or tuple and tuple, etc.)
        parent_path,pattern=self._pathfinder_mismatch_saver(parent_path,pattern)
        match_positions=self.pathsfinder(parent_path,pattern)
        return (None if not match_positions else
                parent_path[0:match_positions[-1*prefer_child_match]+len(pattern)]
                )

    def pathdetacher(self,parent_path, pattern,from_base_to_match=True,
                     include_match=True,from_match_to_end=False,prefer_child_match=True,
                     pattern_to_insert_before_match=None,pattern_to_insert_after_match=None):
        #parent_path and pattern must be of the same type (e.g.: list and list, or tuple and tuple, etc.)
        path=None
        parent_path,pattern=self._pathfinder_mismatch_saver(parent_path,pattern)
        match_positions=self.pathsfinder(parent_path,pattern)
        if not match_positions:
            return None
        i=match_positions[-1*prefer_child_match]
        path=parent_path[
            i*(not from_base_to_match):max(
                (i+len(pattern))*include_match,
                len(parent_path)*from_match_to_end,
                i*from_base_to_match)
            ]
        path=list(path)
        if pattern_to_insert_before_match:
                _,pattern_to_insert_before_match=self._pathfinder_mismatch_saver(parent_path=path,pattern=pattern_to_insert_before_match)
                path.insert(i,pattern_to_insert_before_match)
                i+=len(pattern_to_insert_before_match)
        if pattern_to_insert_after_match:
                _,pattern_to_insert_after_match=self._pathfinder_mismatch_saver(parent_path=path,pattern=pattern_to_insert_after_match)
                path.insert(i+len(pattern),pattern_to_insert_after_match)
        if not include_match:
            del path[i:i+len(pattern)]
        path=tuple(path)
        return path
    
    def navigate_to_parent_folder(self, ref_path=None, folder=None, go_above_base_path=True):
        ref_path,path_exists=self.get_safe_path_from_path(ref_path,use_only_abs_paths=go_above_base_path)
        if not path_exists:
            return (ref_path,path_exists)
        if not folder:
            folder=os.path.dirname(ref_path)
            if not folder:
                folder = '..'
            return (folder,path_exists)
        parent_path=self.resolve_abs_or_rel_path(
            abs_or_rel_path=self.pathfinder(parent_path=ref_path,pattern=folder,prefer_child_match=True), use_only_abs_paths=go_above_base_path)
        if parent_path is None:
            path_exists=False
        return (parent_path,path_exists)
        
    def navigate_to_sibling_folder(self, folder=None, ref_path=None, go_above_base_path=None,create_folder_if_not_exists=False):
        ref_path,path_exists=self.get_safe_path_from_path(ref_path,use_only_abs_paths=go_above_base_path)
        if not path_exists:
            return (ref_path,False,None)
        path=Path(ref_path)
        if not folder:
            path_matches=[self.resolve_abs_or_rel_path(abs_or_rel_path=(self.serialize_path(x)
                          for x in path.glob('..'+os.sep+'*')
                            if x.is_dir()),use_only_abs_paths=go_above_base_path)]
            return (None,None,path_matches)
        folder=Path(folder)
        folder_path_length=len(folder.parts)
        path_matches = [
            self.resolve_abs_or_rel_path(abs_or_rel_path=self.serialize_path(x),use_only_abs_paths=go_above_base_path)
            for x in path.glob('..'+os.sep+'*')
                    if (x.is_dir() and 
                        self.pathfinder(
                            #self.serialize_path(x.resolve().parts[-folder_path_length:])
                            x.resolve()
                            #,self.serialize_path(folder)
                            ,folder
                            ))]
        if path_matches == [] or path_matches is None:
            path_exists=False
            path_match = os.path.join(path.parent,folder)
            if create_folder_if_not_exists and path_match:
                os.makedirs(self._resolve_to_abs_path(path_match), exist_ok=True)
                #path_exists=True #Maybe it's useful to not return path_exists as True if the folder does not initially exist.
        else:
            path_exists=True
            path_match=path_matches.pop(0)
        return (path_match,path_exists,path_matches)
        
    def navigate_to_closest_ancestor_folder(self,folder=None,ref_path=None,max_descent=2,go_above_base_path=True):
        ref_path,path_exists=self.get_safe_path_from_path(ref_path,use_only_abs_paths=go_above_base_path)
        if not path_exists:
            return (ref_path,False,[])
        if not folder:
            folder=os.path.dirname(ref_path)
            if not folder:
                folder='..'
            return (folder,True,[])
        path=Path(ref_path)
        #folder=Path(folder)
        #folder_path_length=len(folder.parts)
        #folder=self.serialize_path(folder)
        path_match=None
        path_matches=None
        for parent_level in range(max_descent):
            parent_path=path.parent
            (path_match,path_exists,path_matches)=self.navigate_to_sibling_folder(folder=folder, ref_path=parent_path,go_above_base_path=go_above_base_path)
            if not path_exists:
                continue
        return (path_match,path_exists,path_matches)
    
    def _get_safe_root_path_from_path(self,root_path):
        path_exists=False
        abs_path_exists=False
        if root_path == "" or not root_path:
            root_path=self.get_file_location()
        safe_path=self.serialize_path(root_path)
        if os.path.isfile(safe_path):
            safe_path=self.get_only_path_from_file(file_name=safe_path)
        if os.path.exists(safe_path):
            path_exists=True
        if os.path.exists(os.path.join(self.get_file_location(),safe_path)):
            safe_path = os.path.join(self.get_file_location(),safe_path)
            abs_path_exists=True
        safe_path=os.path.normpath(safe_path)
        return (safe_path, path_exists, abs_path_exists)
        
    def get_safe_path_from_path(self, ref_path, use_only_abs_paths=None):
        path_exists=False
        safe_path=self.serialize_path(ref_path)
        if not safe_path:
            safe_path=self.get_root_of_base_path()
            path_exists=True
        else:
            safe_path,is_file=self.check_if_file_and_exists(safe_path)
            if is_file:
                safe_path=self.get_only_path_from_file(file_name=safe_path)
                path_exists=True
            elif os.path.exists(os.path.join(self.get_root_of_base_path(),safe_path)):
                safe_path=os.path.join(self.get_root_of_base_path(),safe_path)
                path_exists=True
            elif os.path.exists(os.path.join(self.get_file_location(),safe_path)):
                safe_path=os.path.join(self.get_file_location(),safe_path)
                path_exists=True
            elif os.path.exists(safe_path) and os.path.abspath(safe_path)==safe_path:
                path_exists=True
            else:
                return (safe_path, False)
        #safe_path=os.path.normpath(safe_path)
        safe_path=self.resolve_abs_or_rel_path(abs_or_rel_path=safe_path,use_only_abs_paths=use_only_abs_paths)
        return (safe_path, path_exists)
    
    
    def _resolve_to_rel_path(self, abs_or_rel_path):
        if abs_or_rel_path != self.get_root_of_base_path():
            rel_path=os.path.join(
                        self.get_base_path(),
                        os.path.relpath(abs_or_rel_path,self.get_root_of_base_path()))
        else:
            rel_path=self.get_base_path()
        return rel_path
    
    def _resolve_to_abs_path(self, abs_or_rel_path):
        return os.path.abspath(abs_or_rel_path)
    
    def _resolve_abs_or_rel_path(self, abs_or_rel_path):
        abs_path=self._resolve_to_abs_path(abs_or_rel_path)
        return self._resolve_to_rel_path(abs_path) if not self.get_abs_paths_flag() else abs_path
    
    def resolve_abs_or_rel_path(self, abs_or_rel_path, use_only_abs_paths=None):
        if use_only_abs_paths is None:
            use_only_abs_paths=self.get_abs_paths_flag()
        abs_path=self._resolve_to_abs_path(abs_or_rel_path)
        return self._resolve_to_rel_path(abs_path) if not use_only_abs_paths else abs_path
    
    def is_path_child_of_root_output_path(self, child_path):
        return self._is_path_child_of_base_path(child_path,parent_path=self.get_root_of_output_path())
    
    def is_path_child_of_root_input_path(self, child_path):
        return self._is_path_child_of_base_path(child_path,parent_path=self.get_root_of_input_path())
    
    def _is_path_child_of_base_path(self, child_path, parent_path=None,use_only_abs_paths=None):
        # Smooth out relative path names, note: if you are concerned about symbolic links, you should use os.path.realpath too
        if use_only_abs_paths is None:
            use_only_abs_paths=self.get_abs_paths_flag()
        if use_only_abs_paths or os.path.isabs(child_path):
            #print(1)
            if parent_path is None:
                #print(2)
                parent_path = self.get_root_of_base_path() #os.path.abspath(self._base_path)
            if os.path.exists(os.path.abspath(child_path)):
                #print(3)
                child_path = os.path.abspath(child_path)
        else:
            #print(4)
            if parent_path is None:
                #print(5)
                parent_path = self.get_base_path() #os.path.abspath(self._base_path)
                #print(parent_path)
                #print(child_path)
        # Compare the common path of the parent and child path with the common path of just the parent path.
        # Using the commonpath method on just the parent path will regularise the path name in the same way
        # as the comparison that deals with both paths, removing any trailing path separator
        return os.path.commonpath([parent_path]) == os.path.commonpath([parent_path, child_path])
    
    def get_only_path_from_file(self, file_name=None, default_path=""):
        if file_name is None:
            return default_path
        else:
            return os.path.dirname(self.serialize_path(file_name))
    
    def full_output_path_and_file(self):
        return os.path.join(self.get_output_path(),self.get_output_file_name())
    
    def full_input_path_and_file(self):
        return (os.path.join(self.get_input_path(),self.get_input_file_name())
                if self.get_input_file_name() is not None else None)
    
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
    
    def read_file(self):
        try:
            self._file_ref_content=self._file_ref.read()
            return self._file_ref_content
        except UnicodeDecodeError:
            return False
    
    def open_file(self, path_to_file=None, encoding='utf8',mode='r'):
        if path_to_file is None:
            path_to_file = self.full_input_path_and_file()
        else:
            self._base_input_path=self.set_input_path(path_to_file)
            self.input_file_name=self.set_safe_file_name_only(path_to_file)
        self._file_ref=open(file=path_to_file,mode=mode,encoding=encoding)
    
    def close_file(self):
        self._file_ref.close()
    
    def replace_string_in_file(self,string_to_replace,replacement_string,filename_with_path=None):
        if filename_with_path is None:
            filename_with_path=self.full_input_path_and_file()
        with fileinput.FileInput(filename_with_path, inplace=True, backup='.bak') as file:
            for line in file:
                print(line.replace(string_to_replace, replacement_string), end='')
    
    def output_to_file(self, output, output_path_and_file=None, mode='w'):#, file_name=None):
        original_stdout = sys.stdout # Save a reference to the original standard output
        if not output_path_and_file:
            output_path_and_file=self.full_output_path_and_file()
        message="Saving "+output_path_and_file
        print(message)
        self.log(log_message=message)
        try:
            with open(output_path_and_file, mode) as f:
                sys.stdout = f # Change the standard output to the file we created.
                print(output)#,encode(BOM_UTF8))
        except Exception as e:
            print(e)
        finally:
            sys.stdout = original_stdout # Reset the standard output to its original value

    def get_log_level_separator(self):
        return ' '

    def log(self, log_message, log_path=None, log_file_name=None, log_level=1):
        if log_path is not None:
            log_path=self.get_safe_path_from_path(ref_path=log_path)[0]
            self.set_log_path(base_log_path=log_path)
        if log_file_name is not None:
            self.set_safe_log_file_name_only(log_file_name=log_file_name)
        log_level_spaces=self.get_log_level_separator()*log_level
        log_message=log_level_spaces+log_message
        
        original_stdout = sys.stdout # Save a reference to the original standard output
        try:
            with open(self.full_log_path_and_file(), mode='a+') as f:
                sys.stdout = f # Change the standard output to the file we created.
                print(log_message)#,encode(BOM_UTF8))
        except Exception as e:
            print(e)
        finally:
            sys.stdout = original_stdout # Reset the standard output to its original value
    
    
    def get_path_and_files(self,base_input_path=None):
        if base_input_path is None:
            base_input_path=self.get_input_path()
        root_list=[]
        dirs_list=[]
        files_list=[]
        for (root,dirs,files) in os.walk(base_input_path,topdown=True):
            root_list.append(root)
            dirs_list.append(dirs)
            files_list.append(files)
        #TODO: Filtrar os output paths
        return zip(root_list,dirs_list,files_list)
    
    
    def check_if_file_and_exists(self, filename, base_folder=None):
        if os.path.isfile(filename):
            return (filename,True)
        if base_folder is not None:
            if os.path.isfile(os.path.join(base_folder,filename)):
                return (os.path.join(base_folder,filename),True)
            else:
                return (filename,False)
        elif os.path.isfile(os.path.join(self.get_base_path(),filename)):
            return (os.path.join(self.get_base_path(),filename),True)
        elif os.path.isfile(os.path.join(self.__location__,filename)):
            return (os.path.join(self.__location__,filename),True)
        return (filename,False)
    
    def _check_if_path_is_input(self,path,input_folder=None,output_folder=None):
        return True

    def iter_io_paths_and_files(self,iter_func=None,base_input_path=None):
        if base_input_path is None:
            base_input_path=self.get_input_path()
        #-----------Posso remover isso!---------
        # if input_folder is None:
        #     input_folder=self._input_folder
        # if output_folder is None:
        #     output_folder=self._output_folder
        #---------------------------------------
        
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
                    self.set_safe_input_file_name_only(input_file_name=os.path.join(self.get_input_path(),file))
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
        #print("content:")
        #print(content)
        #print("expression:")
        #print(expression)
        if content is None:
            return False
        return re.compile(expression).search(content)

#opa=IO_DirFileHandler(base_path=["html"])#, file_name=["html","input","rms","AddrDesc.html"])

#print("opa")
#print(opa.navigate_to_sibling_folder(folder='html_to_xlsx',go_above_base_path=True))
#opa.iter_io_paths\_and_files()



# %%
