#!/bin/bash

project=targeting
filesubs=(cpp h hpp c)
target=CMakeLists.txt
target_temp=CMakeLists.txt.temp
echo "generate CMakeLists.txt begin"
echo > ${target_temp}
echo "cmake_minimum_required(VERSION 3.17)" >> "${target_temp}"
echo "project(${project})" >> "${target_temp}"
echo "set(CMAKE_CXX_STANDARD 14)" >> "${target_temp}"

cmd=''
_n=${#filesubs[@]}
for((i=0;i<"$_n";i++));
do
	if [ "$i" -eq 0 ]
	then
		cmd="-name *.${filesubs[$i]}"
    	else
		cmd=${cmd}" -o -name *.${filesubs[$i]}"
	fi

done

cmd="find ./ -type f "${cmd}
file_list=$(${cmd})
#file_num=$(echo "$file_list" | wc -l)
#echo "file_num:$file_num"
#echo "get file " "$file_list"
#find exec似乎不太好用,有些文件无法输出,似乎最后的输出只和最后的那个文件有关系,这个可能和exec的实现方式有关系
#include_files_with_path=\
#$(${cmd} -exec grep "^[ ]*#include" {} \; \
#| sed -e 's/ //g' -e 's/\/\/.*//g' -e 's/\/\*.*//g'| sort | uniq \
#| sed -e 's/#include<\(.*\)>/\1/g' -e 's/#include"\(.*\)"/\1/g'
#)
## 后续尝试通过编译器预处理来获取头文件
include_files_with_path=\
$(${cmd} | xargs grep -h "^[ ]*#include[ ]\+[<\"][a-z][a-z,0-9,_,\.,\/]\+[>\"]" \
| sed -e 's/ //g' -e 's/\/\/.*//g' -e 's/\/\*.*//g'| sort | uniq \
| sed -e 's/#include<\(.*\)>/\1/g' -e 's/#include"\(.*\)"/\1/g'
)
echo 1 "$include_files_with_path"
include_dirs=()
# 去重,提高效率,bash低版本不支持，需要升级，以后再说吧
#declare -A mymap=()
# 获取代码中所有的include头文件
for include_file_with_path in ${include_files_with_path}; do
  file_name=$(basename $include_file_with_path)
  file_path=$(dirname $include_file_with_path)
  echo 2 "${include_file_with_path}" "${file_path}" "${file_name}"
#  [ ${mymap[key]+abc} ] && echo "exists" && continue

  # 不必要每次都去访问文件系统
  # include_dir=$(find ./ -name "${file_name}" \
  include_dir=$(echo "$file_list" | grep "${file_name}" \
   | grep "${include_file_with_path}" \
   | sed "s/"$(echo "${include_file_with_path}" \
   | sed -e 's/\//\\\//g')"//g" | grep '\/$' | sed 's/\/$//g' | sed 's/^\.\/\///g')
  if [ -z "${include_dir}" ]; then
    include_dir="."
  fi
  if [ "./" = "${include_dir}" ];then
    include_dir="."
  fi
  echo 4 "${include_dir}" "${#include_dirs[@]}"
#  mymap["$file_path"]="1"
  include_dirs[${#include_dirs[@]}]=${include_dir}
  # 删除同一个目录的所有文件
#  file_list=$(echo "$file_list" | grep -v "$file_path")
#  file_num=$(echo "$file_list" | wc -l)
#  echo "file_num:$file_num"
#  echo "delete file " "$file_list"
#  exit 0
done
echo ${#include_dirs[@]}
# 去重后写入
include_dirs=($(echo "${include_dirs[*]}" | tr ' ' '\n' | sort | uniq))
for dir in ${include_dirs[*]}; do
  echo "include_directories(${dir})" >> ${target_temp}
done

# 获取所有文件
echo "add_executable(${project}" >> ${target_temp}
# 重新获取所有文件
file_list=$(${cmd})
for filename in ${file_list}
do
	echo "${filename}" >> ${target_temp}
done
echo ")" >> ${target_temp}
echo "successfully generate CMakeLists.txt"
sed -i '' 's/^\.\/\///' ${target_temp}
uniq ${target_temp} ${target}
rm -f ${target_temp}
exit 0
