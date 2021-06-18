from IO_DirFileHandler import IO_DirFileHandler

translator = IO_DirFileHandler(base_path=''
                               ,base_input_path="C:\\ora19c\\WINDOWS.X64_193000_db_home\\db-sample-schemas-19.2"#"C:\\APEX\\apex\\images\\themes\\theme_42\\1.6\\css"
                               ,base_output_path='output')
#translator = RetailXSD_HTMLTable(input_file_name=["html","input","rms","XItemDesc.html"],output_folder="output_unit_test",log_file_name="html_unit_test.log")

translator.use_input_file_name_as_output_sub_folder=False
translator.use_input_path_suffixes=False
translator.use_input_sub_folder_as_output_file_name=False


def gen_func(input_path,output_path,input_file_name,first_time_in_folder):
    translator.open_file()
    content=translator.read_file()
    if content:
        epa=translator.regex_search(content=content,expression="__SUB__CWD__")#"js-pageStickyMobileHeader")
        if epa:
            log_message='Expression found in file '
            log_message+=translator._resolve_to_abs_path(translator.full_input_path_and_file())
            print(translator.get_log_level_separator()*3 + log_message)
            translator.log(log_message=log_message)
            translator.close_file()
            translator.replace_string_in_file(string_to_replace='__SUB__CWD__',replacement_string='C:\\ora19c\\WINDOWS.X64_193000_db_home\\db-sample-schemas-19.2')
           # translator.save_file()
    #translator.output
    
    

translator.iter_io_paths_and_files(iter_func=gen_func)
