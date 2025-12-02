#!/bin/bash

Design="$1"

round() {
  printf "%.${2}f" "${1}"
}
comma_int() {
  local n="$1"
  local sign=""
  if [[ "$n" == -* ]]; then
    sign="-"
    n="${n#-}"
  fi
  local out=""
  while (( ${#n} > 3 )); do
    out=",${n: -3}${out}"
    n="${n:0:${#n}-3}"
  done
  echo "${sign}${n}${out}"
}
Cycle=`cat Report/${Design}.timing | grep "clock clk (rise edge)" | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | sed -n '4p'`
Area=`cat Report/${Design}.area | grep 'Total cell area:' | grep -Eo '[+-]?[0-9]+([.][0-9]+)?'`
Dynamic=`cat Report/${Design}.power | grep "Total Dynamic Power"`
Leakage=`cat Report/${Design}.power | grep "Cell Leakage Power"`
memory_area=`cat Report/${Design}.area | grep 'Macro/Black Box area'`
memory_area=$(echo $memory_area | tr -dc '0-9')
gate_count=$(echo "$Area/9.9792" | bc -l)
flag=0
echo -e "${YELLOW}============================${NO_COLOR}"
if grep -i -q 'Latch' 'syn.log'; then
	echo -e "${RED}--> X There is Latch in this design ---${NO_COLOR}"
    flag=1
else
    echo -e "${GREEN}--> V Latch Checked!${NO_COLOR}"
fi
if grep -i -q 'mismatch' 'syn.log'; then
	echo -e "${RED}--> X Width Mismatch Error !! ---${NO_COLOR}"
    flag=1
else
    echo -e "${GREEN}--> V Width Mismatch Checked!${NO_COLOR}"
fi
if grep -i -q 'Error' 'syn.log'; then
	echo  -e "${RED}--> X There is Error in this design !! ---${NO_COLOR}"
    flag=1
else
    echo -e "${GREEN}--> V No Error in syn.log!${NO_COLOR}"
fi
if grep -i -q 'violated' "Report/${Design}.timing"; then
	echo  -e "${RED}--> X Timing (violated) ---${NO_COLOR}"
    flag=1
else
    echo -e "${GREEN}--> V Timing (MET) Checked!${NO_COLOR}"
fi
if [ "$memory_area" = "0000000" ]; then
    : # memory check disabled
fi
echo -e "${YELLOW}============================${NO_COLOR}"
if [ $flag -eq 1 ] ; then
	echo -e "${RED}--> X 02_SYN Fail !! Please check out syn.log file.${NO_COLOR}"
else
    echo -e "${GREEN}--> V 02_SYN Success !!${NO_COLOR}"
fi
    echo -e "${YELLOW}============================${NO_COLOR}"
    echo -e "${YELLOW}Cycle: $Cycle ${NO_COLOR}"
    # Format Area as integer with comma separators, e.g., 2,322,197
    int_area=$(awk -v x="$Area" 'BEGIN{printf "%d", int(x)}')
    echo -e "${YELLOW}Area: $(comma_int "$int_area") ${NO_COLOR}"
    echo -e "${YELLOW}Gate count: $(round "$gate_count" 0) ${NO_COLOR}"
    echo -e "${YELLOW}Dynamic: $Dynamic ${NO_COLOR}"
    echo -e "${YELLOW}Leakage: $Leakage ${NO_COLOR}"
