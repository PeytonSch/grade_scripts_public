#!/bin/bash
#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
YELLOW='\033[1;33m'
LIGHT_PURPLE='\033[1;35m'

#make sure we can compile / set path variable
#$PATH="$PATH:/c/mingw64/mingw64/bin"

#clear screen to start
clear

#open file with downloaded canvas output
#create ./to_grade if it doesnt exist
#this directory will hold our extracted files
echo "Checking if to_grade directory already exists..."
downloaded_path="./to_grade"
#if it doenst exist create directory and pause program to allow user to copy
#the needed files into the directory
if [[ ! -e $downloaded_path ]]; then
	mkdir -p $downloaded_path
	echo -e "${GREEN}CONFIRMED::    ${NC}Created to_grade directory"
	echo -e "${PURPLE}COPY \"submissions.zip\" into the ./to_grade directory"
	read -p "Press enter to continue"
elif [[ ! -d $dir ]]; then
	echo -e "${GREEN}CONFIRMED::   ${NC}$downloaded_path already exists..."
fi

continue_grading_from=1 #number to continue_grading_from

#test if csv file already exists:
if [ -f grades.csv ]; then
	echo -e "${RED}A grading file (grades.csv) allready exists. Do you want to remove this file?"
	echo -e "${YELLOW}You may want to backup this file${RED}"
	echo -e "Remove this file if you are starting a new round of grading and want to delete previouse grades"
	echo -e "If you with to CONTINUE grading the same assignment from where you left off previously, keep this file"
	echo -e "Enter 'DELETE' to delete this file, enter anything else to keep it${NC}"
	read -t 1 -n 10000 discard #clear input buffer
	read -p "Response: " yn
	if [ "$yn" == "DELETE" ]; then
		echo -e "${RED}DELETING GRADE FILE${NC}"
		rm grades.csv
	else
		echo -e "${GREEN}Grade file not removed${NC}, do you have a student number you with to continue grading from?"
		read -t 1 -n 10000 discard #clear input buffer
		read -p "(y/n): " yn
		if [ $yn == "y" ]; then
			echo -e "Please enter the student number to continue grading from"
			read -t 1 -n 10000 discard #clear input buffer
			read -p "Student number: " continue_grading_from
		else
			continue_grading_from=1
		fi
	fi
else
	echo "No grade file found, creating new grade file"
	#create csv file for grades
	echo -e "${GREEN}Creating grades.csv${NC}"
	touch grades.csv
	#initialize points for A1
	echo "Name,Are the expected files present(1=yes 2=extra files 3=no files),Are all labs complete?,4pts General Coding Points,2pts Did Everything Compile,2pts ascii art,8pts interesting facts with appropriate variables,Comments" >>grades.csv
fi

#count to delete old files to make sure nothing is out of date
count=0
for f in "$downloaded_path"/*; do
	filename=$(basename $f)
	count=$(($count + 1))
done

#confirm we only have the files we want
if [ $count != 1 ]; then
	echo -e "${RED}WARNING::    ${NC}There are ${YELLOW}$count ${NC}files in ./to_grade, only the ${GREEN}\"Submissions\"${NC} file was expected${YELLOW}"
	ls -hl ./to_grade

	echo -e "${NC}Would you like to delete the other files and re-extract student submissions?"
	read -t 1 -n 10000 discard #clear input buffer
	read -p "(y/n): " yn
	if [ $yn == "y" ]; then
		echo -e "${RED}"
		read -p "Press enter to DELETE files other than submissions folder"
		echo -e "${RED}----DELETING OLD FILES----"
		rm -r ./to_grade/unzipped1
		rm -r ./to_grade/ready_to_grade

		#extract outer files
		echo -e "${PURPLE}EXTRACTING FILES..."
		echo -e "${RED}NAMES AND FILES THAT APPEAR AS ERRORS ARE TYPICALLY RESULT FROM INCORRECT FILE SUBMISSION. 'Set 1' vs 'Set1' FOR EXAMPLE${YELLOW}"
		unzip -q "./to_grade/submissions.zip" -d "./to_grade/unzipped1"

		#confirm to user that this file contains everyone's submissions
		#this count should match the number of submissions downloaded from canvas
		count=0
		#extract individual assignment files
		for f in "./to_grade/unzipped1"/*; do
			name=$(basename "$f")
			#echo "Attempting to unzip: $f"
			#echo "Name: ${name%%.*}"
			path="./to_grade/ready_to_grade/"
			path="$path${name%%.*}"
			path=${path/ /}
			#echo "PATH: $path"
			mkdir -p "$path"
			unzip -q $f -d "$path"
			count=$(($count + 1))
		done
		echo -e "${NC}There are ${RED}$count ${NC}submissions found. Please confirm this matches the expected number of submissions from canvas(Y/N)"

	else
		echo -e "${YELLOW}Proceeding without extracting new files"
	fi

else
	echo -e "${GREEN}CONFRIMED::    ${NC}$count file found, checking \"Submissions\" file as expected..."
	if [ $filename == "submissions.zip" ]; then
		echo -e "${GREEN}CONFIRMED::    ${NC}Submissions file confirmed"

		#extract outer files
		echo -e "${PURPLE}EXTRACTING FILES..."
		echo -e "${RED}NAMES AND FILES THAT APPEAR AS ERRORS ARE TYPICALLY RESULT FROM INCORRECT FILE SUBMISSION. 'Set 1' vs 'Set1' FOR EXAMPLE${YELLOW}"
		unzip -q "./to_grade/submissions.zip" -d "./to_grade/unzipped1"

		#confirm to user that this file contains everyone's submissions
		#this count should match the number of submissions downloaded from canvas
		count=0
		#extract individual assignment files
		for f in "./to_grade/unzipped1"/*; do
			name=$(basename "$f")
			#echo "Attempting to unzip: $f"
			#echo "Name: ${name%%.*}"
			path="./to_grade/ready_to_grade/"
			path="$path${name%%.*}"
			path=${path/ /}
			#echo "PATH: $path"
			mkdir -p "$path"
			unzip -q $f -d "$path"
			count=$(($count + 1))
		done
		echo -e "${NC}There are ${RED}$count ${NC}submissions found. Please confirm this matches the expected number of submissions from canvas(Y/N)"
	else
		echo -e "${RED}WARNING::   ${NC}Submissions file not found"
		exit
	fi
fi

student_number=1
#iterate through every submission
for f in "./to_grade/ready_to_grade"/*; do
	#check if we are at the student_number we want
	if [ "$student_number" -ge "$continue_grading_from" ]; then
		echo ""
	else
		student_number=$(($student_number + 1))
		continue
	fi
	#setup file path and student name information
	name=$(basename "$f")
	name="${name%%.*}"
	path="./to_grade/ready_to_grade/"
	path="$path${name%%.*}"
	path=${path/ /}
	echo -e "\n\n${GREEN}Grading $name:${NC}"
	echo -e "Student Number: ${YELLOW}$student_number${NC}"
	grade_string=$name","

	#list all files they submitted
	#make sure we only see the files we want,
	#if there are no files listed they probably named their assignemnt
	#wrong and we will just have to grade them at the end without the script
	ls $path -R -hL

	echo -e "\n\n${GREEN}Grading $name:${NC}"
	echo -e "Student Number: ${YELLOW}$student_number${LIGHT_PURPLE}"

	head -5 $path/Set1/A1/main.cpp
	echo -e "${YELLOW}"
	head -5 $path/Set1/L1A/main.cpp
	echo -e "${NC}"

	echo -e "${RED}RUBRIC: <censored>"
	echo -e "${CYAN}Are the expected files present?"
	echo -e "${CYAN}Enter ${RED} 1 ${CYAN} if yes"
	echo -e "${CYAN}Enter ${RED} 2 ${CYAN} if extra files ${RED}Rubric: <censored>"
	echo -e "${CYAN}Enter ${RED} 3 ${CYAN} if no files ${RED}Rubric: <censored>"
	read -t 1 -n 10000 discard #clear input buffer
	read -p "Grade: " yn
	if [ $yn == 3 ]; then
		echo -e "${RED}FILES NOT FOUND, CONTINUING TO NEXT STUDENT${NC}"
		grade_string="${grade_string}${yn},,,,,,NO FILES FOUND - POSSIBLY SUBMITTED WRONG"
		echo $grade_string >>grades.csv
		student_number=$(($student_number + 1))
		continue
	else
		grade_string="${grade_string}${yn},"
	fi

	#The first argument of our grade string is going to tell us if all code was submitted
	#correctly and if there are no extra files. If there are no files we will have to
	#check later because they either submitted with incorrect file names or they
	#submitted no code

	#next we are going to check if there is code in the files or if they are emtpy
	echo -e "\n\n${GREEN}Grading $name:${NC}"
	echo -e "${PURPLE}Ready to check contents of file? From rubric check:"
	echo -e "${CYAN}All labs complete (is there code present?)"
	echo -e "${CYAN}Comments used?"
	echo -e "${CYAN}Appropriate variable names, constants, and data types used."
	echo -e "${CYAN}Instructions followed?"

	echo -e "\n\n${GREEN}Press enter to view L1A${NC}"
	read -p ""
	cat $path/Set1/L1A/main.cpp
	echo -e "\n\n${GREEN}Press enter to view L1B${NC}"
	read -p ""
	cat $path/Set1/L1B/main.cpp
	echo -e "\n\n${GREEN}Press enter to view L1C${NC}"
	read -p ""
	cat $path/Set1/L1C/main.cpp
	echo -e "\n\n${GREEN}Press enter to view A1${NC}"
	read -p ""
	cat $path/Set1/A1/main.cpp

	echo -e "\n\n${GREEN}Grading $name:${NC}"
	echo -e "${CYAN}<censored>"
	read -t 1 -n 10000 discard #clear input buffer
	read -p "Grade: " yn
	grade_string="${grade_string}${yn},"

	echo -e "${NC}General Coding:"
	echo -e "${GREEN}1pts ${CYAN}<censored>"
	echo -e "${GREEN}1pts ${CYAN}<censored>"
	echo -e "${GREEN}1pts ${CYAN}<censored>"
	echo -e "${GREEN}1pts ${CYAN}<censored>"
	read -t 1 -n 10000 discard #clear input buffer
	read -p "Grade: " yn
	grade_string="${grade_string}${yn},"

	echo -e "\n\n${GREEN}Grading $name:${NC}"
	echo -e "${CYAN}<censored>"
	echo -e "${NC}If no messages given assignment compiles correctly, error message will be displayed otherwise"

	echo -e "\n\n${GREEN}Press enter to compile L1A${NC}"
	read -p ""
	g++ -o $path/Set1/L1A/run $path/Set1/L1A/main.cpp
	echo -e "\n\n${GREEN}Press enter to compile L1B${NC}"
	read -p ""
	g++ -o $path/Set1/L1B/run $path/Set1/L1B/main.cpp
	echo -e "\n\n${GREEN}Press enter to compile L1C${NC}"
	read -p ""
	g++ -o $path/Set1/L1C/run $path/Set1/L1C/main.cpp
	echo -e "\n\n${GREEN}Press enter to compile A1${NC}"
	read -p ""
	g++ -o $path/Set1/A1/run $path/Set1/A1/main.cpp

	echo -e "\n\n${GREEN}Grading $name:${NC}"
	echo -e "${GREEN}2pts ${CYAN}Did all submitted files compile?${NC}"
	read -t 1 -n 10000 discard #clear input buffer
	read -p "Grade: " yn
	grade_string="${grade_string}${yn},"

	echo -e "${GREEN}Ready to run code?${NC}"
	echo -e "RUBRIC POINTS TO LOOK FOR:"
	echo -e "${GREEN}2pts ${CYAN}<censored>"
	echo -e "${GREEN}8pts ${CYAN}<censored>"
	echo -e "${CYAN}\nPress enter to run L1A${NC}"
	read -t 1 -n 10000 discard #clear input buffer
	read -p ""
	./$path/Set1/L1A/run
	echo -e "${CYAN}\nPress enter to run L1B${NC}"
	read -p ""
	./$path/Set1/L1B/run
	echo -e "${CYAN}\nPress enter to run L1C${NC}"
	read -p ""
	./$path/Set1/L1C/run
	echo -e "${CYAN}\nPress enter to run A1${NC}"
	read -p ""
	./$path/Set1/A1/run

	echo -e "\n\n${GREEN}Grading $name:${NC}"
	read -t 1 -n 10000 discard #clear input buffer
	echo -e "${GREEN}2pts ${CYAN}<censored>"
	read -p "Grade: " yn
	grade_string="${grade_string}${yn},"
	echo -e "${GREEN}8pts ${CYAN}<censored>"
	read -p "Grade: " yn
	grade_string="${grade_string}${yn},"

	echo -e "${GREEN}A1 Reprinted:${LIGHT_PURPLE}"
	cat $path/Set1/A1/main.cpp

	echo -e "${NC}  <censored>"

	echo -e "${CYAN}Enter any comments:${NC}"
	read -p "Comments: " yn
	grade_string="${grade_string}${yn}"

	echo -e "Grade string for ${GREEN}$name \n\n$grade_string\n\n${NC}"
	echo $grade_string >>grades.csv
	echo -e "${GREEN}Appended to csv file"

	echo -e "You have finished grading Student Number: ${YELLOW}$student_number${NC}"
	echo -e "Would you like to grade another student?"

	read -t 1 -n 10000 discard #clear input buffer
	read -p "(y/n): " yn
	if [ "$yn" == "y" ]; then
		echo -e "${YELLOW}PRESS ENTER WHEN YOU ARE READY TO CLEAR THE SCREEN AND MOVE ON TO THE NEXT STUDENT"
		read -t 1 -n 10000 discard #clear input buffer
		read -p ""
	else
		student_number=$(($student_number + 1))
		echo -e "${YELLOW}When you return you may continue grading the next student by entering student number ${RED}$student_number"
		exit
	fi

	#increment student number
	student_number=$(($student_number + 1))

	clear

done
