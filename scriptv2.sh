#!/bin/bash
#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
YELLOW='\033[1;33m'
LIGHT_PURPLE='\033[1;35m'

#this is an include mechanism for
#our mini script to seperate section
#submissions
. seperate_sections.sh

######################
######VARIABLES#######
######################

#ONLY CHANGE THESE THREE VARIABLES
assignemnt_number=2
lab_letters=("A" "B" "C")
section_letter_you_are_grading="B" #this one will be prompted to you if you reset the program

#I WOULD NOT CHANGE THESE
assignment_file="/Set${assignemnt_number}/A${assignemnt_number}/main.cpp"
compileto="/Set${assignemnt_number}/A${assignemnt_number}/run"
lab_files=()
to_grade_path="./to_grade"
continue_grading_from=1 #number to continue_grading_from
student_number=1        #student we are currently on

# 0th element should always be name
# 1st element should always be submission naming school
# naming scheme should be imediatly followed by lab points
comments_index=32
program_code_points_indecies=(6 7 8 9 10 11)
program_random_functionality_indecies=(13 14 15) #skipped 12 to grep for that
program_classifications_indecies=(16 17 18 19 20)
program_stats_indecies=(21 22 23 24 25 26 27 28 29 30)
assignment_total_points_available=30
rubric_points_for_header=(
	# Censored rubric
)

#populate lab_files
for i in ${!lab_letters[@]}; do
	lab_files=("${lab_files[@]}" "/Set${assignemnt_number}/L${assignemnt_number}${lab_letters[$i]}/main.cpp")
done

######################
######FUNCTIONS#######
######################

#introduce and reset the program if ready to start a new round of grading
welcome() {
	echo -e "$LIGHT_PURPLE"
	cat welcome.txt
	echo -e "${NC}\n\nWelcome to Peyton Scherschel's 261 Grading Script"
	echo -e "This script is very much a ${YELLOW}WORK IN PROGRESS${NC}"
	echo -e "so feel free to provide feedback, edit, adapt, or improve it."
	echo -e "${YELLOW}"
	read -t 1 -n 10000 discard #clear input buffer
	read -p "Would you like to reset the program to start a new round of grading? (y/n): " yn
	echo -e "${NC}"
	if [ "$yn" == "y" ]; then
		rm -r ./to_grade/
		read -t 1 -n 10000 discard #clear input buffer
		read -p "Enter the capital section letter you are grading: " $section_letter_you_are_grading
	else
		echo "Continuing without resetting ./to_grade"
	fi
}

#applies rubric headers to grades file
apply_header_to_grades() {

	for i in ${!rubric_points_for_header[@]}; do
		echo -n ${rubric_points_for_header[$i]}"," >>grades.csv
	done
	echo "" >>grades.csv
}

#creates ./to_grade directory if needed, asks you to copy
#submissions file into the directory
create_to_grade_directory() {
	#create ./to_grade if it doesnt exist
	#this directory will hold our extracted files
	echo "Checking if to_grade directory already exists..."
	to_grade_path="./to_grade"
	#if it doenst exist create directory and pause program to allow user to copy
	#the needed files into the directory
	if [[ ! -e $to_grade_path ]]; then
		echo -e "to_grade/ directory does not exist. Creating to_grade/ directory..."
		mkdir -p $to_grade_path
		echo -e "${GREEN}CONFIRMED::    ${NC}Created to_grade directory"
		echo -e "${GREEN}Copying Submissions File....${NC}"
		cp -r ./put_submissions_file_here/submissions.zip ./to_grade/
	elif [[ ! -d $dir ]]; then
		echo -e "${GREEN}CONFIRMED::   ${NC}$to_grade_path already exists..."
	fi
}

#creates grades file if needed
#sets continue_grading_from number if needed
#calls apply_header_to_grades
check_or_create_grades_file() {
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
			touch grades.csv
			#initialize points for A1
			apply_header_to_grades
		else
			echo -e "${GREEN}Grade file not removed${NC}, do you have a student number you with to continue grading from?"
			read -t 1 -n 10000 discard #clear input buffer
			read -p "(y/n): " yn
			if [ "$yn" == "y" ]; then
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
		apply_header_to_grades
	fi
}

delete_and_reextract_student_submissions() {
	echo -e "${RED}"
	read -p "Press enter to DELETE files other than submissions folder"
	echo -e "${RED}----DELETING OLD FILES----"
	rm -r ./to_grade/unzipped1
	rm -r ./to_grade/ready_to_grade
	rm -r ./to_grade/sectionA
	rm -r ./to_grade/sectionB
	rm -r ./to_grade/sectionC
	rm -r ./to_grade/sectionD
	rm -r ./to_grade/sectionE

	#extract outer files
	extract_outter_files
	#extract inner files
	extract_individual_assignments
}

extract_outter_files() {
	#extract outer files
	echo -e "${PURPLE}EXTRACTING FILES..."
	echo -e "${RED}NAMES AND FILES THAT APPEAR AS ERRORS ARE TYPICALLY RESULT FROM INCORRECT FILE SUBMISSION. 'Set 1' vs 'Set1' FOR EXAMPLE${YELLOW}"
	unzip -q "./to_grade/submissions.zip" -d "./to_grade/unzipped1"
}

extract_individual_assignments() {

	#extract your section using seperate_sections
	seperate_sections $section_letter_you_are_grading
	echo -e "${YELLOW}"

	#confirm to user that this file contains everyone's submissions
	#this count should match the number of submissions downloaded from canvas
	count=0
	#extract individual assignment files
	for f in "./to_grade/section$section_letter_you_are_grading"/*; do
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
	echo -e "${NC}There are ${RED}$count ${NC}submissions found. Please confirm this matches the expected number of submissions from canvas"
}

check_files_in_grades_path_and_extract_if_necessary() {
	#count to delete old files to make sure nothing is out of date
	count=0
	for f in "$to_grade_path"/*; do
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
			delete_and_reextract_student_submissions
		else
			echo -e "${YELLOW}Proceeding without extracting new files"
		fi
	else
		echo -e "${GREEN}CONFRIMED::    ${NC}$count file found, checking \"Submissions\" file as expected..."
		if [ $filename == "submissions.zip" ]; then
			echo -e "${GREEN}CONFIRMED::    ${NC}Submissions file confirmed"
			extract_outter_files
			extract_individual_assignments
		else
			echo -e "${RED}WARNING::   ${NC}Submissions file not found"
			exit
		fi
	fi
}

#add a students grades to excel sheet
#takes $grade_string and $comment_string
add_grade_string_to_grades_csv() {

	for i in ${!grade_string[@]}; do
		echo -n ${grade_string[$i]}"," >>grades.csv
	done
	echo $comment_string >>grades.csv

}

#takes $name $student_number
print_name_and_student_number() {
	echo -e "\n\n${GREEN}Grading $1:${NC}"
	echo -e "Student Number: ${YELLOW}$2${NC}"
}

head_lab_files() {
	echo -e "${LIGHT_PURPLE}"
	head -5 $path$assignment_file
	echo -e "${YELLOW}"
	for i in ${!lab_files[@]}; do
		clear
		head -50 $path${lab_files[$i]}
		read -p "Viewing ${lab_files[$i]} Press Enter To Continue..."
	done
	echo -e "${NC}"
}

#takes $rubric_points_for_header prompt $grade_string $comment_string
add_to_grade() {

	local -n rubric=$1
	local -n gs=$2
	local -n comments=$3

	read -t 1 -n 10000 discard #clear input buffer
	####################################################################
	echo -e "${LIGHT_PURPLE}"
	read -p "$rubric: " points
	echo -e "${NC}"
	####################################################################
	gs=("${gs[@]}" "$points")

	read -p "Comment(y/n): " yn
	if [ "$yn" == "y" ]; then
		read -p "Comment: " comment
		comments="$comments $comment"
	else
		echo ""
	fi

}

iterate_through_student_submissions() {
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
		print_name_and_student_number $name $student_number
		grade_string=($name)
		echo -e "${PURPLE}FIRST GRADE STRING: ${grade_string[@]}${NC}"
		comment_string=""

		#list all files they submitted
		#make sure we only see the files we want,
		#if there are no files listed they probably named their assignemnt
		#wrong and we will just have to grade them at the end without the script
		ls $path -R -hL

		##########################
		###NAMING SCHEME GRADES###
		##########################
		print_name_and_student_number $name $student_number
		add_to_grade rubric_points_for_header[1] grade_string comment_string

		##########################
		######LAB GRADES##########
		##########################
		print_name_and_student_number $name $student_number
		head_lab_files
		#lab contentes
		for i in ${!lab_files[@]}; do
			echo -e "${YELLOW} LAB: ${lab_files[$i]}${NC}"
			add_to_grade rubric_points_for_header[$i+2] grade_string comment_string
		done

		#####################################################
		##ASK IF FILES WERE PRESENT AND SKIP STUDENT IF NOT##
		####################################################
		print_name_and_student_number $name $student_number
		read -t 1 -n 10000 discard #clear input buffer
		read -p "Were files present? (y/n): " yn
		if [ $yn == "n" ]; then
			echo -e "${RED}FILES NOT FOUND, CONTINUING TO NEXT STUDENT${NC}"
			comment_string="$comment_string NO FILES FOUND - POSSIBLY SUBMITTED WRONG"
			add_grade_string_to_grades_csv $grade_string $comment_string
			student_number=$(($student_number + 1))

			####TODO - WRITE TO FILE FOR STUDENT BEFORE CONTINUING TO NEXT STUDENT
			continue
		else
			echo ""
		fi

		#extra creddit points for A2
		add_to_grade rubric_points_for_header[5] grade_string comment_string

		##########################
		###Program Code Points####
		##########################
		print_name_and_student_number $name $student_number

		for i in ${program_code_points_indecies[@]}; do
			cat $path$assignment_file
			add_to_grade rubric_points_for_header[$i] grade_string comment_string
		done

		##########################
		###Functionality Points###
		##########################
		print_name_and_student_number $name $student_number

		echo -e "${CYAN}Ready to check if assignment compiles?"
		echo -e "${NC}If no messages given assignment compiles correctly, error message will be displayed otherwise"

		echo -e "\n\n${GREEN}Press enter to compile A1${NC}"
		read -p ""
		g++ -o $path$compileto $path$assignment_file

		#####################################################
		##ASK IF Assignment Compiles and Skip Student if Not#
		####################################################
		print_name_and_student_number $name $student_number
		read -t 1 -n 10000 discard #clear input buffer
		read -p "Did the assignment Compile? (y/n): " yn
		if [ $yn == "n" ]; then
			echo -e "${RED}Did not compile, CONTINUING TO NEXT STUDENT${NC}"
			comment_string="$comment_string ASSIGNMENT DID NOT COMPILE"
			add_grade_string_to_grades_csv $grade_string $comment_string
			student_number=$(($student_number + 1))
			continue
		else
			echo ""
		fi

		echo -e "${GREEN}Check for ${rubric_points_for_header[12]}${NC}"
		grep -C 5 "seed" $path$assignment_file
		grep -C 5 "srand" $path$assignment_file
		add_to_grade rubric_points_for_header[12] grade_string comment_string

		echo -e "${GREEN}Ready to run code?${NC}"
		echo -e "${CYAN}\nPress enter to run A$assignemnt_number${NC}"
		read -p ""

		#random Functionality points
		for i in ${program_random_functionality_indecies[@]}; do
			echo -e "${GREEN}Check for ${rubric_points_for_header[$i]}${NC}"
			./$path$compileto
			add_to_grade rubric_points_for_header[$i] grade_string comment_string
		done

		#classification points
		for i in ${program_classifications_indecies[@]}; do
			echo -e "${GREEN}Check for ${rubric_points_for_header[$i]}${NC}"
			./$path$compileto
			add_to_grade rubric_points_for_header[$i] grade_string comment_string
		done

		#stats points
		for i in ${program_stats_indecies[@]}; do
			echo -e "${GREEN}Check for ${rubric_points_for_header[$i]}${NC}"
			./$path$compileto
			add_to_grade rubric_points_for_header[$i] grade_string comment_string
		done

		echo -e "Grade string for ${GREEN}$name \n\n${grade_string[@]}\n\n${NC}"

		add_grade_string_to_grades_csv $grade_string $comment_string

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
			touch leftoff.txt
			echo $student_number >leftoff.txt
			exit
		fi

		#increment student number
		student_number=$(($student_number + 1))

		clear

	done
}

######################
####MAIN PROGRAM######
######################
clear
welcome
create_to_grade_directory
check_or_create_grades_file
check_files_in_grades_path_and_extract_if_necessary
iterate_through_student_submissions
