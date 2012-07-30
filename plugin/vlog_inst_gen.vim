""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       File Name       : vlog_inst_gen.vim
"       Author(s)       : ZhangLeiming
"       Contact Us      : mingforregister@163.com
"       Creat On        : 2012-07-02 17:12
"       Description     :                                                           
"
"                           hot-key
"
"       reversion 1.0   20120702    ming
"                       file creation
"          
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('b:vlog_inst_gen') || &cp || version < 700
    finish
endif
let b:vlog_inst_gen = 1




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       varibales
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"golobal variables

"local variables
let s:non_comment_lines = []        " store the non-comment lines
let s:module_number = 0             " how many modules in this *.v
let s:module_info_list = []         " each module has 3 elements:
                                    "   1) module line
                                    "   2) module declare end line
                                    "   3) endmodule line
let s:module_inst_list = []         " it has 3 elements:
                                    "   1) file has inst flag
                                    "   2) inst start line
                                    "   3) inst end line
"let s:inst                          " inst




"multi-value return test
let g:test_list = []
"method 1: parameter is a list
fun! Multi_value_return_test(test_list)
    call add(a:test_list, 'x')
    echo g:test_list
endfun
"method 2: return a list
fun! Multi_value_return_test_2()
    call add(g:test_list, 'x')
    return g:test_list
endfun

"restore this script
"if maparg("<F12>") != ""
    "silent! unmap <F12>
"endif
"map <F12> :unlet b:vlog_inst_gen<CR>:source C:/Program\ Files/Vim/vlog_inst_gen.vim<CR>

"if maparg("<C-F12>") != ""
    "silent! unmap <C-F12>
"endif
"method 1: it works ok
"map <C-F12> :call Multi_value_return_test(g:test_list)<CR>
"method 2: return a list
"map <C-F12> :echo Multi_value_return_test_2()<CR>
"test Filter Comment Line function
let g:g_non_comment_lines = []
"map <C-F12> :let g:g_non_comment_lines=[]<CR>:call <SID>Filter_Comment_Lines(1, line("$"), g:g_non_comment_lines)<CR>
"map <C-F12> :call <SID>Filter_Comment_Lines(1, line("$"), g:g_non_comment_lines)<CR>





""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"      step 1: remove comment lines & find previous inst location
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Filter_Comment_Lines(start_line, end_line, non_comment_lines)
    let cur = a:start_line
    let end_line = a:end_line
    let mline_comment_flag = 0      "initial multi-line comment flag
    "check and clear non-comment line list
    if empty(a:non_comment_lines) == 0
        call remove(a:non_comment_lines, 0, -1)
    endif
    "start search
    while cur <= end_line
        "move cursor to spacified line and colum
        "call cursor(cur, 1)        "don't need to move cursor
        let cur_line_content = getline(cur)
        "Is in multi-line comment
        if mline_comment_flag
            if cur_line_content =~ '^.*\*/\s*$'     "end of multi-line comment
                let cur = cur + 1
                let mline_comment_flag = 0
                continue
            else
                let cur = cur + 1
                continue
            endif
        "Not in multi-line comment
        else
            if cur_line_content =~ '\(^\s*//.*$\|^\s*/\*.*\*/\s*$\)'    "single line comment
                let cur = cur + 1
                continue
            elseif cur_line_content =~ '^\s*/\*.*$'                     "detect start of mcomment
                let cur = cur + 1
                let mline_comment_flag = 1
                continue
            elseif cur_line_content =~ '^\s*$'                          "remove empty lines
                let cur = cur + 1
                continue
            else                                                        "Non-comment lines
                call add(a:non_comment_lines, cur)
                let cur = cur + 1
                continue
            endif
        endif
    endw
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"      step 2: search modules and record module location infomation
"               module_info_list的结构
"                   module_start_line   : 模块开始行
"                   module_declare_line : 模块声明结束行
"                   module_end_line     : 模块结束行
"           注：模块声明结束行是以紧跟module关键字的第一个";"为标志的。
"               模块结束行是以紧跟module的第一个"endmodule"关键字为标志的。
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Search_Module(non_comment_lines, module_info_list)
    let line_num = len(a:non_comment_lines)     "number of lines
    let module_num = 0
    let i = 0
    "clear module_info_list
    if empty(a:module_info_list) == 0   "if not empty
        call remove(a:module_info_list, 1, -1)
    endif
    "search modules
    let in_module_flag = 0
    let find_declare_flag = 0
    let module_start_line = 0
    let module_declare_line = 0
    let module_end_line = 0
    while i < line_num
        let cur_line = a:non_comment_lines[i]   "get current search line
        let line_content = getline(cur_line)
        "search module start line
        if in_module_flag == 0
            if line_content =~ '^\s*\<module\>.*$'
                let module_start_line = cur_line
                let in_module_flag = 1
                let find_declare_flag = 0
            endif
            "incase declare in the same line
            if in_module_flag == 1
                if find_declare_flag == 0
                    if line_content =~ '^.*;.*$'        "the first semicolon is end of declareation
                        let module_declare_line = cur_line
                        let find_declare_flag = 1
                    endif
                endif
            endif
        "search module declare info and end module info
        else
            if find_declare_flag == 0       "find declare first
                if line_content =~ '^.*);.*$'
                    let module_declare_line = cur_line
                    let find_declare_flag = 1
                endif
            else
                if line_content =~ '^\s*\<endmodule\>\(\s*$\|\s*//.*$\|\s*/\*.*\*/\s*$\)'
                    let module_end_line = cur_line
                    call add(a:module_info_list, [module_start_line, module_declare_line, module_end_line])
                    let module_num = module_num + 1
                    let in_module_flag = 0
                endif
            endif
        endif
        let i = i+1
    endw
    return module_num
endfun


fun! Ming_Test_Search_Module()
    "search non-comment lines
    let nc_lines = []
    call <SID>Filter_Comment_Lines(1, line("$"), nc_lines)
    "search module
    let module_info = []
    let module_num = <SID>Search_Module(nc_lines, module_info)
    "output message
    if module_num == 0
        echo 'None module in this file.'
    else
        let i = 0
        while i < module_num
            "echo 'Module '.i.' '.module_info[i]
            echo 'Module '.i.' '
            echo module_info[i]
            let i = i+1
        endw
    endif
endfun

"test reload script
"map <C-F12> :echo 'Test reload script.'<CR>
"map <C-F12> :call Ming_Test_Search_Module()<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"      step 3: analysis module 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 提取 module xx(i1, i2, q1, q2);中端口列表i1, i2, q1, q2
" 并判断是verilog95/2001格式
" 输入：模块数目，模块位置信息
" 输出: 模块ID
"       参数列表([[para1, val1], [para2, val2], ...])
"       vlog_95_2001_flag(0/1)
"       端口列表信息([i1, i2, i3, q1, q2, ...])
"       inout端口([io1, io2, ...])
"       input端口([i1, i2, ...])
"       output端口([q1, q2, ...])
" 返回值:   0 能从提供的输入中找到所有模块对应的端口信息
"           1 不能从提供的输入中找到(某个或全部都找不到)。。
"
" 考虑的module格式
" 1. 单行型
"       module xx #(parameter para1=1, ...)(i1, i2, q1, q2);
" 2. 多行verilog 95型
"       module xx #(parameter para1=1, ...)(
"                   i1, 
"                   i2,
"                   q1,
"                   q2);
" 3. 多行verilog 2001型
"       module xx #(parameter para1=1, ...)(
"           input   i1,
"           input   i2,
"           output  q1,
"           output  q2);
" 4. 其他变种
"       module xx 
"           #(parameter para1=1, ...)
"           (
"           input   i1,
"           input   i2, i3, output q1,
"           output  q2
"           );
"
"
"   实现方法
"       1. 将module头中，所有行的有效信息合并成一行，以便处理；
"       2. 按步骤分离并储存信息；
"           1) 寻找module identifier
"           2) 判断是否是顶层模块，是则置位标志结束；否则转3)
"           3) 寻找并存储参数信息
"           4) 寻找并存储端口信息
"       



fun! <SID>Line_Pre_Process(line_content)
    let lc = a:line_content
    "del the spaces at the beginning of line
    let lc = substitute(lc, '^\s*', '', '')
    "del comment at the end of line
    let lc = substitute(lc, '\s*\(//.*$\|/\*.*\*/\s*$\)', '', '')
    "del unused keyword: reg wire
    let lc = substitute(lc, '\(\<reg\>\|\<wire\>\)', '', 'g')
    "del vector identifier (eg: [1:0])
    let lc = substitute(lc, '\[.\{-}\]', '', 'g')
    "del attributes
    let lc = substitute(lc, '(\*.\{-}\*)', '', 'g')
    return lc
endfun



"test Line_Pre_Process function
"map <C-F12> :echo <SID>Line_Pre_Process(getline(".")).'$'<CR>





"merge module head to one line
"
"   输入: 模块数目，模块位置信息
"   输出: 模块头合并成一行
"   调用的子函数: Line_Pre_Process()
"   返回值: 0       操作成功
"           non_0   操作失败
"
fun! <SID>Merge_Module_Head(non_comment_lines, module_num, module_info_list, module_merged_list)
    let mnum = a:module_num
    let minfo = a:module_info_list
    "check parameter ok
    if len(minfo) != mnum
        return 1                "Error 1: parameter not matched
    endif
    "check has module
    if mnum == 0
        return 2                "Error 2: not contained module
    endif
    "parameter pre process
    if empty(a:module_merged_list) == 0
        call remove(a:module_merged_list, 0, -1)
    endif
    "merge module head
    let i = 0
    while i < mnum
        "get info
        let line_index = index(a:non_comment_lines, a:module_info_list[i][0])
        let line_index_end = index(a:non_comment_lines, a:module_info_list[i][1])
        "initial variable
        let module_merged_line = ""
        let line_content = ""
        while line_index <= line_index_end
            "get line content
            let line_content = getline(a:non_comment_lines[line_index])
            "line content pre process
            let line_content = <SID>Line_Pre_Process(line_content)
            "merge line
            let module_merged_line = module_merged_line.line_content
            "increase the index
            let line_index = line_index+1
        endw
        "del spaces between charactor
        "   1. 非input/output/inout后面的空格全部删除
        "   1. input/output/inout后面的空格保留一个
        let module_merged_line = substitute(module_merged_line, '\(\<module\>\|\<parameter\>\|\<input\>\|\<output\>\|\<inout\>\)\@<!\s\+', '', 'g')
        "store merged module info
        call add(a:module_merged_list, module_merged_line)
        let i = i+1
    endw
endfun



"test function Merged_Module_Head
fun! <SID>Test_Merged_Module_Head()
    "search non-comment lines
    let nc_lines = []
    call <SID>Filter_Comment_Lines(1, line("$"), nc_lines)
    "search module
    let module_info = []
    let module_num = <SID>Search_Module(nc_lines, module_info)
    if module_num == 0
        echo "None module found."
        return 0
    endif
    "merge module head
    let module_merged_list = []
    let merge_result = <SID>Merge_Module_Head(nc_lines, module_num, module_info, module_merged_list)
    if merge_result == 0
        echo module_merged_list
    else
        echo "Error when merging module head."
    endif
endfun
















fun! <SID>Clear_Parameter_List(para_list)
    if empty(a:para_list) == 0
        call remove(a:para_list, 0, -1)
    endif
endfun

" Analysis_Module_Head
"   分析合并后的module头信息，并对信息进行存储
"   输入: 模块数目，合并后的list
"   输出: 模块名，参数列表，vlog头格式95/2001，端口列表，IO列表信息
"   返回值: 0       正常
"           非0     处理错误
fun! <SID>Analysis_Module_Head(module_num, module_merged_list, module_name, para, vlog_95_flag, port, port_i, port_o, port_io)
    "check input parameter
    if len(a:module_merged_list) != a:module_num
        return 1            "parameter not match
    endif
    if a:module_num == 0
        return 2            "none module found
    endif
    "initiciate parameters
    call <SID>Clear_Parameter_List(a:module_name)
    call <SID>Clear_Parameter_List(a:para)
    call <SID>Clear_Parameter_List(a:vlog_95_flag)
    call <SID>Clear_Parameter_List(a:port)
    call <SID>Clear_Parameter_List(a:port_i)
    call <SID>Clear_Parameter_List(a:port_o)
    call <SID>Clear_Parameter_List(a:port_io)



    "begin analysis



    let i = 0
    while i < a:module_num
        let module_head = a:module_merged_list[i]
        "***********************************************
        "step 1: search module identifier
        "***********************************************
        let mname = ""
        "del key word: module
        if module_head =~ '^\<module\>\s'
            let module_head = substitute(module_head, '^\<module\>\s', '', '')
        else
            return 3            "Error 3: can't find keyword
        endif
        let mname = substitute(module_head, '^[a-zA-Z_][a-zA-Z_0-9]*\zs.*$', '', '')        "get module name
        let module_head = substitute(module_head, '^[a-zA-Z_][a-zA-Z_0-9]*', '', '')       "delete module name
        "add info to list
        call add(a:module_name, mname)



        "***********************************************
        "step 2: judge weather this is a top module
        "***********************************************
        if module_head =~ '^;$'     "end of module
            call add(a:para, [])
            call add(a:vlog_95_flag, 2)
            call add(a:port, [])
            call add(a:port_i, [])
            call add(a:port_o, [])
            call add(a:port_io, [])
            let i = i+1
            continue
        endif





        "***********************************************
        "step 3: get parameter info
        "***********************************************
        if module_head =~ '^#(.*$'
            let para_key = ''
            let para_val = ''
            let para_list = []
            let module_head = substitute(module_head, '\<parameter\>\s*', '', 'g')   "del keyword: parameter and the following sapce
            let module_head = substitute(module_head, '^#(', '', '')            "del #(
            while 1
                if module_head =~ '^)'      "parameter fetch end
                    let module_head = substitute(module_head, '^)', '', '')     "del )
                    break
                elseif module_head =~ '^,'  "del ,
                    let module_head = substitute(module_head, '^,', '', '')
                    continue
                elseif module_head =~ '^[a-zA-Z_][a-zA-Z0-9_]*=.*[,)]'   "find para
                    let para_key = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*\zs.*$', '', '')
                    let module_head = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*=', '', '')
                    let para_val = substitute(module_head, '^.\{-}\zs[,)].*$', '', '')  "match the first , or )
                    let module_head = substitute(module_head, '^.\{-}\ze[,)]', '', '')
                    call add(para_list, [para_key, para_val])
                    continue
                else
                    return 4            "Error 4: when find parameter
                endif
            endw
            call add(a:para, para_list)     "store parameter list
        else        "if has none parameter, then fullfill the position of module in list with empty value
            call add(a:para, [])
        endif




        "***********************************************
        "step 4: judge vlog version 95 or 2001
        "***********************************************
        if module_head =~ '\(\<input\>\|\<output\>\|\<inout\>\)'
            call add(a:vlog_95_flag, 0)
        else
            call add(a:vlog_95_flag, 1)
        endif




        "***********************************************
        "step 5: analysis port
        "***********************************************
        if module_head !~ '^('
            return 5            "Error 5: start of analysis port
        endif
        let module_head = substitute(module_head, '^(', '', '')
        let p_dir = 0        " 0 none     1 input     2 output    3 inout
        let pid = ''
        let p_list = []
        let pi_list = []
        let po_list = []
        let pio_list = []
        while 1
            "echo module_head        "for debug
            if module_head =~ '^);'     "end of analysis
                break
            elseif module_head =~ '^,'     "del ,
                let module_head = substitute(module_head, '^,', '', '')
                continue
            elseif module_head =~ '^\(\<input\>\|\<output\>\|\<inout\>\)'       "find port direction
                if module_head =~ '^\<input\>'
                    let p_dir = 1
                elseif module_head =~ '^\<output\>'
                    let p_dir = 2
                elseif module_head =~ '^\<inout\>'
                    let p_dir = 3
                endif
                let module_head = substitute(module_head, '^\(\<input\>\|\<output\>\|\<inout\>\)\s*', '', '')
                continue
            elseif module_head =~ '^[a-zA-Z_][a-zA-Z0-9_]*[,)]'                    "find port
                let pid = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*\zs[,)].*$', '', '')
                let module_head = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*', '', '')
                call add(p_list, pid)
                if p_dir == 1
                    call add(pi_list, pid)
                elseif p_dir == 2
                    call add(po_list, pid)
                elseif p_dir == 3
                    call add(pio_list, pid)
                endif
                continue
            else
                return 6        "Error 6: when analysising port
            endif
        endw
        call add(a:port, p_list)
        call add(a:port_i, pi_list)
        call add(a:port_o, po_list)
        call add(a:port_io, pio_list)




        "call add(a:port, module_head)      "for test
        let i = i+1
    endw

    if          len(a:module_name)      != a:module_num     || 
            \   len(a:para)             != a:module_num     || 
            \   len(a:vlog_95_flag)     != a:module_num     || 
            \   len(a:port)             != a:module_num     || 
            \   len(a:port_i)           != a:module_num     || 
            \   len(a:port_o)           != a:module_num     || 
            \   len(a:port_io)          != a:module_num
        return 7                "Error 7: invalid return value
    endif
    return 0
endfun


"test function Merged_Module_Head
fun! <SID>Test_Analysis_Module_Head()
    "search non-comment lines
    let nc_lines = []
    call <SID>Filter_Comment_Lines(1, line("$"), nc_lines)
    "search module
    let module_info = []
    let module_num = <SID>Search_Module(nc_lines, module_info)
    if module_num == 0
        echo "None module found."
        return 0
    endif
    "merge module head
    let module_merged_list = []
    let merge_result = <SID>Merge_Module_Head(nc_lines, module_num, module_info, module_merged_list)
    if merge_result != 0
        echo "Error when merging module head."
    endif
    "analysis module head
    let module_name_list = []
    let para_list = []
    let vlog_95_flag_list = []
    let port_list = []
    let port_i_list = []
    let port_o_list = []
    let port_io_list = []
    let analysis_result = <SID>Analysis_Module_Head(module_num, module_merged_list, module_name_list, para_list, vlog_95_flag_list, port_list, port_i_list, port_o_list, port_io_list)
    if analysis_result != 0
        echo "Error ".analysis_result.": when analysis module head."
        "echo port_list
        echo vlog_95_flag_list
    else
        echo module_name_list
        echo para_list
        echo port_list
        echo port_i_list
        echo port_o_list
        echo port_io_list
    endif
endfun

"if maparg("<C-F12>") != ""
    "silent! unmap <C-F12>
"endif
"map <C-F12> :call <SID>Test_Analysis_Module_Head()<CR>
"map <C-F12> :call <SID>Test_Merged_Module_Head()<CR>



" Analysis_Module_Body
"   只作用于vlog-95格式，搜索port declareation，并存储
"   输入: 非注释行列表，模块数目，模块位置信息列表，vlog_95_flag
"   输出: port, port_i, port_o, port_io
"   返回值: 0       正常
"           非0     处理错误
fun! <SID>Analysis_Module_Body(non_comment_lines, module_num, module_info_list, vlog_95_flag, port_declare, port_i, port_o, port_io)
    "check input parameter
    if (len(a:module_info_list) != a:module_num) || (len(a:module_info_list) != a:module_num)
        return 1            "parameter not match
    endif
    if a:module_num == 0
        return 2            "none module found
    endif
    "initiciate parameters
    call <SID>Clear_Parameter_List(a:port_declare)
    "call <SID>Clear_Parameter_List(a:port_i)
    "call <SID>Clear_Parameter_List(a:port_o)
    "call <SID>Clear_Parameter_List(a:port_io)
    "start analysis
    let i = 0
    while i < a:module_num
        let pid = ''
        let p_dir = 0       " 0 none    1 input     2 output    3 inout
        let p_list = []
        let pi_list = []
        let po_list = []
        let pio_list = []
        if a:vlog_95_flag[i] == 1   "need analysis
            let line_index = index(a:non_comment_lines, a:module_info_list[i][1])
            let line_index_end = index(a:non_comment_lines, a:module_info_list[i][2])
            while line_index <= line_index_end
                let line_content = getline(a:non_comment_lines[line_index])
                let line_content = <SID>Line_Pre_Process(line_content)          "remove unused parts
                if line_content =~ '^\s*\(\<input\>\|\<output\>\|\<inout\>\)\s*'
                    let line_content = substitute(line_content, '\(\<input\>\|\<output\>\|\<inout\>\)\@<!\s\+', '', 'g') "remove spaces
                    if line_content =~ '^\<input\>'
                        let p_dir = 1
                    elseif line_content =~ '^\<output\>'
                        let p_dir = 2
                    elseif line_content =~ '^\<inout\>'
                        let p_dir = 3
                    else
                        let p_dir = 0
                    endif
                    let line_content = substitute(line_content, '^\(\<input\>\|\<output\>\|\<inout\>\)\s*', '', '')
                    while 1
                        if line_content =~ '^;'
                            break
                        elseif line_content =~ '^,'
                            let line_content = substitute(line_content, '^,', '', '')
                            continue
                        elseif line_content =~ '^[a-zA-Z_][a-zA-Z0-9_]*[,;]'
                            "get pid
                            let pid = substitute(line_content, '^[a-zA-Z_][a-zA-Z0-9_]*\zs[,;].*$', '', '')
                            "store pid
                            call add(p_list, pid)
                            if p_dir == 1
                                call add(pi_list, pid)
                            elseif p_dir == 2
                                call add(po_list, pid)
                            elseif p_dir == 3
                                call add(pio_list, pid)
                            endif
                            "del this pid
                            let line_content = substitute(line_content, '^[a-zA-Z_][a-zA-Z0-9_]*\ze[,;]', '', '')
                        else
                            return 4        "Error 4: when processing port declare line.
                        endif
                    endw
                endif
                let line_index = line_index+1
            endw
        endif
        call add(a:port_declare, p_list)
        let a:port_i[i] = pi_list
        let a:port_o[i] = po_list
        let a:port_io[i] = pio_list
        let i = i+1
    endw
    "check output list
    if          len(a:port_declare)     != a:module_num     || 
            \   len(a:port_i)           != a:module_num     || 
            \   len(a:port_o)           != a:module_num     || 
            \   len(a:port_io)          != a:module_num
        return 7                "Error 7: invalid return value
    endif
    return 0
endfun


"test function Merged_Module_Head
fun! <SID>Test_Analysis_Module_Body()
    "search non-comment lines
    let nc_lines = []
    call <SID>Filter_Comment_Lines(1, line("$"), nc_lines)
    "search module
    let module_info = []
    let module_num = <SID>Search_Module(nc_lines, module_info)
    if module_num == 0
        echo "None module found."
        return 0
    endif
    "merge module head
    let module_merged_list = []
    let merge_result = <SID>Merge_Module_Head(nc_lines, module_num, module_info, module_merged_list)
    if merge_result != 0
        echo "Error when merging module head."
    endif
    "analysis module head
    let module_name_list = []
    let para_list = []
    let vlog_95_flag_list = []
    let port_list = []
    let port_i_list = []
    let port_o_list = []
    let port_io_list = []
    let analysis_head_result = <SID>Analysis_Module_Head(module_num, module_merged_list, module_name_list, para_list, vlog_95_flag_list, port_list, port_i_list, port_o_list, port_io_list)
    if analysis_head_result != 0
        echo "Error ".analysis_head_result.": when analysis module head."
    endif



    "
    let port_declare_list = []
    let analysis_body_result = <SID>Analysis_Module_Body(nc_lines, module_num, module_info, vlog_95_flag_list, port_declare_list, port_i_list, port_o_list, port_io_list)
    if analysis_body_result != 0
        echo "Error ".analysis_body_result.": when analysis module body."
    endif
    echo module_name_list
    echo para_list
    echo port_list
    echo port_i_list
    echo port_o_list
    echo port_io_list
    echo port_declare_list
    "echo debug_list
endfun












"check port match
" 功能: 检查module_head和module_body中port_list和port_declare_list是否一致
" 输入: module_num, port_head_list, port_body_list
" 输出: match_flag_list
" 返回值:   0       match
"           none-0  has dismatch(value is the sum of dismatch modules)
"
"
"   注: 因为不匹配时要进行错误处理，所以这里用函数不能输出信息。就不用函数了。




"inst format
"
"/*****************************************************************************
"**************     INST GENERATED BY VLOG_INST_GEN PLUGIN     ****************
"******************************************************************************
"module_name #(
"    .PARA1                      ( para1                     ),
"    .PARA2                      ( para_test_2               ),
"    .PARA3                      ( para_test_2               ))
"U_MODULE_NAME(
"    .zyxa                       (                           ),
"    .zyxa                       (                           ),
"    .zyxa                       (                           ),
"    .zyxa                       (                           ),
"    .zyxa                       (                           )
");
"*****************************************************************************/




"Locate_Inst_Position()
"   功能: 搜索文件是否已经存在生成的INST，是则删除之，并返回插入位置；否则返回位置。
"   输入: 第一个module出现的行
"   输出: INST起始行，INST结束行
"   返回值:     0       success     找不到INST时inst_start/inst_end为空，否则有值
"               non-0   fail

fun! <SID>Locate_Inst_Position(first_module_line, inst_start, inst_end)
    "init parameter
    call <SID>Clear_Parameter_List(a:inst_start)
    call <SID>Clear_Parameter_List(a:inst_end)
    let line_flag = 0
    let exist_flag = 0
    "search given lines
    let i = 1
    while i < a:first_module_line
        let line_content = getline(i)
        if line_flag == 0       "find none of the inst
            if line_content =~ '/\*\{77}'
                call add(a:inst_start, i)
                let line_flag = 1
            else
                call <SID>Clear_Parameter_List(a:inst_start)
            endif
        elseif line_flag == 1
            if line_content =~ '\*\{14}\s\{5}INST\sGENERATED\sBY\sVLOG_INST_GEN\sPLUGIN\s\{5}\*\{16}'
                let line_flag = 2
            else
                let line_flag = 0
            endif
        elseif line_flag == 2
            if line_content =~ '\*\{78}'
                let line_flag = 3
            else
                let line_flag = 0
            endif
        elseif line_flag == 3
            if line_content =~ '\*\{77}/'
                call add(a:inst_end, i)
                let exist_flag = 1
                break
            endif
        else
            return 1        "unknown flag
        endif
        let i = i+1
    endw
    "return value
    if exist_flag == 1
        if empty(a:inst_start)!=0 || empty(a:inst_end)!=0 || a:inst_start[0]>=a:inst_end[0]
            return 2
        endif
    endif
    return 0
    "analysis result and process
    "if exist_flag == 1      "delete existing instance
        "silent exe line_1.",".line_e."d"
        "return line_1-1
    "else
        "return a:first_module_line-1
    "endif
endfun


"test function Merged_Module_Head
fun! <SID>Test_Locate_Inst_Position()
    "search non-comment lines
    let nc_lines = []
    call <SID>Filter_Comment_Lines(1, line("$"), nc_lines)
    "search module
    let module_info = []
    let module_num = <SID>Search_Module(nc_lines, module_info)
    if module_num == 0
        echo "None module found."
        return 0
    endif
    "Locate_Inst_Position
    let inst_start = []
    let inst_end = []
    let inst_locate_result = <SID>Locate_Inst_Position(module_info[0][0], inst_start, inst_end)
    if inst_locate_result != 0
        echohl ErrorMsg
        echo "Error ".inst_locate_result.": when locate inst.."
        echohl None
    endif
    echo inst_start inst_end
endfun






"Insert_Inst()
"功能: 在指定位置，根据提供的模块端口信息插入INST
"输入: 插入位置，模块数目，模块名，端口列表
"输出: 无
"返回值：   0           success
"           non-0       fail

fun! <SID>Insert_Inst(insert_location, module_num, module_name, port_list)
    "check parameter
    if len(a:port_list)!=a:module_num || len(a:module_name)!=a:module_num
        return 1        "parameter unavaliable
    endif
    let insert_content = ""
    let insert_line = a:insert_location
    let i = 0
    call append(insert_line+0, "/*****************************************************************************")
    call append(insert_line+1, "**************     INST GENERATED BY VLOG_INST_GEN PLUGIN     ****************")
    call append(insert_line+2, "******************************************************************************")
    let insert_line = insert_line + 3
    while i < a:module_num
        if empty(a:port_list[i])  "has none port
            let i = i+1
            continue
        endif
        "insert module name and insert name
        call append(insert_line, a:module_name[i]." U_".toupper(a:module_name[i])."_0(")
        let insert_line = insert_line+1
        "insert port_list
        for port in a:port_list[i]
            let insert_content = "    .".port
            "insert spaces the first time
            while strwidth(insert_content) < 32
                let insert_content = insert_content." "
            endw
            "insert spaces the second time
            let insert_content = insert_content."( ".port
            while strwidth(insert_content) < 59
                let insert_content = insert_content." "
            endw
            let insert_content = insert_content."),"
            call append(insert_line, insert_content)
            let insert_line = insert_line+1
        endfor
        "delete the last port's ,
        let line_content = getline(insert_line)
        let line_content = substitute(line_content, ',$', '', '')
        exe insert_line.",".insert_line."d"
        call append(insert_line-1, line_content)
        "add );
        call append(insert_line+0, ");")
        call append(insert_line+1, "")
        let insert_line = insert_line+2
        let i = i+1
    endw
    call append(insert_line, "*****************************************************************************/")
endfun



"Insert_Inst()
"功能: 在指定位置，根据提供的模块端口信息插入INST
"输入: 模块数目，模块名，参数列表，端口列表
"输出: 无
"返回值：   inst_part


fun! <SID>Inst_Part_Format(module_num, module_name, para_list, port_list)
    let inst = ""
    let has_para_flag = 0
    let i = 0
    while i < a:module_num
        "parameter process
        if empty(a:para_list[i])    "has no parameter
            let has_para_flag = 0
            let inst = inst.a:module_name[i]." U_".toupper(a:module_name[i])."_0(\n"
        else                        "has parameters
            let has_para_flag = 1
            let inst = inst.a:module_name[i]." #(\n"
            let list_len = len(a:para_list[i])
            let list_index = 0
            while 1
                let para = a:para_list[i][list_index]
                let line_content = "    .".para[0]
                while strwidth(line_content) < 36
                    let line_content = line_content." "
                endw
                let line_content = line_content."( ".para[1]
                while strwidth(line_content) < 68
                    let line_content = line_content." "
                endw
                if list_index == list_len-1     "the last item
                    let line_content = line_content."))\n"
                    let inst = inst.line_content
                    break
                else
                    let line_content = line_content."),\n"
                    let inst = inst.line_content
                    let list_index = list_index+1
                    continue
                endif
            endw
        endif
        "port process
        if has_para_flag == 1           "has parameter
            let inst = inst."U_".toupper(a:module_name[i])."_0(\n"
        endif
        if empty(a:port_list[i]) == 0   "has port
            let list_len = len(a:port_list[i])
            let list_index = 0
            while 1
                let port = a:port_list[i][list_index]
                let line_content = "    .".port
                "insert spaces the first time
                while strwidth(line_content) < 36
                    let line_content = line_content." "
                endw
                "insert spaces the second time
                let line_content = line_content."( ".port
                while strwidth(line_content) < 68
                    let line_content = line_content." "
                endw
                if list_index == list_len-1     "the last item
                    let line_content = line_content.")\n"
                    let inst = inst.line_content
                    break
                else
                    let line_content = line_content."),\n"
                    let inst = inst.line_content
                    let list_index = list_index+1
                    continue
                endif
            endw
        endif
        "add );
        let inst = inst.");\n\n"
        "next module
        let i = i+1
    endw
    return inst
endfun


" Vlog_Inst_Gen()
" 功能: 主处理函数，产生verilog实体
" 输入: 无
" 输出: 无
" 返回值: 


let g:check_port_declaration = 1
let g:vlog_inst_gen_mode = 0
"   supported mode: 0, 1, 2, 3
"       mode 0(default): 
"           copy to clipboard and echo inst in commandline
"       mode 1:
"           only copy to clipboard
"       mode 2:
"           copy to clipboard and echo inst in split window
"       mode 3:
"           copy to clipboard and update inst_comment to file
        

"hi  Vlog_Inst_Gen_Msg_0     gui=bold        guifg=#2E0CED       "lan tai liang
hi  Vlog_Inst_Gen_Msg_0     gui=bold        guifg=#1E56DB       "lan
"hi  Vlog_Inst_Gen_Msg_1     gui=NONE        guifg=#A012BA       "zi
"hi  Vlog_Inst_Gen_Msg_1     gui=NONE        guifg=#DB26D2       "fen
hi  Vlog_Inst_Gen_Msg_1     gui=NONE        guifg=#10E054       "lv


fun! Vlog_Inst_Gen()
    "step 1:    search non-comment lines
    let non_comment_lines = []
    call <SID>Filter_Comment_Lines(1, line("$"), non_comment_lines)
    "step 2:    search module
    let module_info = []
    let module_num = <SID>Search_Module(non_comment_lines, module_info)
    if module_num == 0
        echohl ErrorMsg
        echo "None module found."
        echohl None
        return 1
    endif
    "step 3:    merge module head
    let merged_head_list = []
    let merge_result = <SID>Merge_Module_Head(non_comment_lines, module_num, module_info, merged_head_list)
    if merge_result != 0
        echohl ErrorMsg
        echo "Error ".merge_result.": when merging module head."
        echohl None
        return 2
    endif
    "step 4:    analysis module head
    let module_name_list = []
    let para_list = []
    let vlog_95_flag_list = []
    let port_list = []
    let port_i_list = []
    let port_o_list = []
    let port_io_list = []
    let analysis_head_result = <SID>Analysis_Module_Head(module_num, merged_head_list, module_name_list, 
                \   para_list, vlog_95_flag_list, port_list, port_i_list, port_o_list, port_io_list)
    if analysis_head_result != 0
        echohl ErrorMsg
        echo "Error ".analysis_head_result.": when analysis module head."
        echohl None
        return 3
    endif
    "step 5: check port declaration(optional by g:check_port_declaration)
    if g:check_port_declaration == 1
        let port_declare_list = []
        let analysis_body_result = <SID>Analysis_Module_Body(non_comment_lines, module_num, module_info, 
                    \   vlog_95_flag_list, port_declare_list, port_i_list, port_o_list, port_io_list)
        if analysis_body_result != 0
            echohl ErrorMsg
            echo "Error ".analysis_body_result.": when analysis module body."
            echohl None
            return 4
        endif
        "start compare between port_list, port_declare_list
        let module_index = 0
        while module_index < module_num
            if vlog_95_flag_list[module_index] == 1
                for mp in port_list[module_index]
                    if count(port_declare_list[module_index], mp) < 1
                        echohl ErrorMsg
                        echo "Port ".mp.": has no declaration."
                        echohl None
                        return 5
                    endif
                endfor
                for mpc in port_declare_list[module_index]
                    if count(port_list[module_index], mpc) < 1
                        echohl ErrorMsg
                        echo "Port ".mpc.": not appeared in port list."
                        echohl None
                        return 6
                    endif
                endfor
            endif
            let module_index = module_index+1
        endw
    endif
    "step 6: get inst part and copy to clipboard
    let inst_part = <SID>Inst_Part_Format(module_num, module_name_list, para_list, port_list)
    let @+ = inst_part
    "step 6: get inst insert location
    if g:vlog_inst_gen_mode == 0
        echohl Vlog_Inst_Gen_Msg_0
        echo "\n"
        echo module_num." insts as follows has been copyed to clipboard:"
        echo "\n"
        echohl Vlog_Inst_Gen_Msg_1
        echo inst_part
        echohl Vlog_Inst_Gen_Msg_0
        echohl None
    elseif g:vlog_inst_gen_mode == 1
        echohl Vlog_Inst_Gen_Msg_0
        echo module_num." insts has been copyed."
        echohl None
    elseif g:vlog_inst_gen_mode == 2
        exe "split __Instance_File__"
        silent put! =inst_part
        exe "normal gg"
        "set buffer
        setlocal noswapfile
        setlocal buftype=nofile
        setlocal bufhidden=delete
        setlocal filetype=verilog
    elseif g:vlog_inst_gen_mode == 3
        "get inst update location
        let inst_start = []
        let inst_end = []
        let inst_locate_result = <SID>Locate_Inst_Position(module_info[0][0], inst_start, inst_end)
        if inst_locate_result != 0
            echohl ErrorMsg
            echo "Error ".inst_locate_result.": when locate inst postion."
            echohl None
        endif
        if empty(inst_start)==1 && empty(inst_end)==1   "no inst exists
            let inst_loc = module_info[0][0]
        else                                            "delete existing instance
            silent exe inst_start[0].",".inst_end[0]."d"
            let inst_loc = inst_start[0]
        endif
        call append(inst_loc-1, "/*****************************************************************************")
        call append(inst_loc+0, "**************     INST GENERATED BY VLOG_INST_GEN PLUGIN     ****************")
        call append(inst_loc+1, "******************************************************************************")
        call append(inst_loc+2, "*****************************************************************************/")
        "update instance
        exe inst_loc+3
        exe "ks"
        silent put! =inst_part
        exe "'s"
        echohl Vlog_Inst_Gen_Msg_0
        echo module_num." insts has been copyed and updated."
        echohl None
    endif
endfun


fun! <SID>Silent_Echo_Test()
    silent exe "ks"
    echo "Hello."
    silent exe "ks"
endfun




fun! Vlog_Inst_Gen_Mode_Change()
    if g:vlog_inst_gen_mode == 0
        let g:vlog_inst_gen_mode = 1
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 1: only copy to clipboard."
        echohl None
    elseif g:vlog_inst_gen_mode == 1
        let g:vlog_inst_gen_mode = 2
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 2: copy to clipboard and display in split window."
        echohl None
    elseif g:vlog_inst_gen_mode == 2
        let g:vlog_inst_gen_mode = 3
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 3: copy to clipboard and update in file."
        echohl None
    elseif g:vlog_inst_gen_mode == 3
        let g:vlog_inst_gen_mode = 0
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 0: copy to clipboard and echo in commandline."
        echohl None
    else
        let g:vlog_inst_gen_mode = 0
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 0: copy to clipboard and echo in commandline."
        echohl None
    endif
endfun







"Key Mapping
if maparg("<C-F11>") != ""
    silent! unmap <C-F11>
endif
if maparg("<F11>") != ""
    silent! unmap <F11>
endif
"map <C-F12> :call Ming_Test_Search_Module()<CR>
"map <C-F12> :call <SID>Test_Merged_Module_Head()<CR>
"map <C-F12> :call <SID>Test_Analysis_Module_Head()<CR>
"map <C-F12> :call <SID>Test_Analysis_Module_Body()<CR>
"map <C-F12> :call <SID>Test_Locate_Inst_Position()<CR>
map <C-F11> :call Vlog_Inst_Gen()<CR>
"map <C-F12> :call <SID>Silent_Echo_Test()<CR>
map <F11> :call Vlog_Inst_Gen_Mode_Change()<CR>
