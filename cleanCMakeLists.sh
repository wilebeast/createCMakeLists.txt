#!/bin/bash
CMakeListsFile=CMakeLists.txt
include_dir_lines=$(grep '^include_directories(.*include)' $CMakeListsFile)
for include_dir_line in $include_dir_lines
  do
    echo 1 "$include_dir_line"
    include_dir=$(echo "$include_dir_line"|cut -d  '('  -f2|cut -d  ')'  -f1)
    echo 2 "$include_dir"
    parent_dir=$(echo "$include_dir"|sed -e 's/\/include$//')
    echo 3 "$parent_dir"
    parent_dir_line='include_directories('$(echo "${parent_dir}" | sed -e 's/\//\\\//g')')'
    echo 4 "$parent_dir_line"
    echo 5 's/^'"${parent_dir_line}"'/#'"${parent_dir_line}"'/g'
    sed -i '' 's/^'"${parent_dir_line}"'/#'"${parent_dir_line}"'/g' $CMakeListsFile
    include_sub_dir_line='include_directories('$(echo "${include_dir}"'/' | sed -e 's/\//\\\//g')'.*)'
    echo 6 "$include_sub_dir_line"
    echo 7 's/\(^'"${include_sub_dir_line}"'\)/#\1/g'
    sed -i '' 's/\(^'"${include_sub_dir_line}"'\)/#\1/g' $CMakeListsFile
  done

src_dir_lines=$(grep '^include_directories(.*src.*)' $CMakeListsFile)
for src_dir_line in $src_dir_lines
  do
    echo 11 "$src_dir_line"
    echo 12 's/\(include_directories\)(\(.*\/src\)\/.*)/\1(\2)/g'
    sed -i '' 's/\(include_directories\)(\(.*\/src\)\/.*)/\1(\2)/g' $CMakeListsFile
  done

uniq < $CMakeListsFile > temp
mv temp $CMakeListsFile
echo 'clean job done'

