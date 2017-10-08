#!/bin/bash

#Global variables

WORKING="${HOME}/vbBackup"
DST="${WORKING}/vms"
RESULTS="${WORKING}/results.log"
SUCCESS="${WORKING}/success.log"
FAIL="${WORKING}/fail.log"
VMOPT=2
SPECVM=""
COMP=1
STOP=1

# This function is the main body of the program but won't be run until AFTER all the other functions it relies on are declared.

main() {

	#Create a working directory

	mkdir "${WORKING}"

	clear

	HEADER="---------------------------------------------------------------\n vbBackup.sh							                    \n  Created by James Wilmoth, WilmothIT.us                   \n  Sunday, June 11, 2017                               \n---------------------------------------------------------------\n\n** Please DO NOT run as root or sudo! **\n\n"

	echo "----------------------------------------------------------"
	echo " vbBackup                                                 "
	echo " Created by James Wilmoth, WilmothIT.us                   "
	echo " Sunday, June 11, 2017                                    "
	echo "----------------------------------------------------------"
	echo
	echo "** Please DO NOT run as root or sudo! **"
	echo
	echo
		ENDLOOP=1 #menu level 1		
		while [ $ENDLOOP -ge 1 ]; do
			clear
			echo -e $HEADER
			echo "--MENU>MAIN----------------------------------------------------"
			echo

			case "$VMOPT" in
				1) echo "  (1) Set source(s).........All VMs" ;;
				2) echo "  (1) Set source(s).........Running VMs *" ;;
				3) echo "  (1) Set source(s).........Stopped VMs" ;;
				4) echo "  (1) Set source(s).........vbBackupList.txt" ;;
				5) echo "  (1) Set source(s).........Last attempt, failed" ;;
				6) echo "  (1) Set source(s).........Specific VM = ${SPECVM}" ;;
				*) echo "  (1) Set source(s).........Running VMs *" ;;
			esac

			echo "  (2) Set destination.......${DST}"

			case "$COMP" in
				0) echo "  (3) Set compression.......Disabled ($COMP)" ;;
				1) echo "  (3) Set compression.......Enabled ($COMP) *" ;;
				*) echo "  (3) Set compression.......Enabled ($COMP) *" ;;
			esac

			case "$STOP" in
				0) echo "  (4) Set action if on......Skip ($STOP)" ;;
				1) echo "  (4) Set action if on......Stop-Start ($STOP) *" ;;
				*) echo "  (4) Set action if on......Stop-Start ($STOP) *" ;;
			esac

			echo "  (5) Run backup"
			echo "  (6) Peek at backup files"
			echo 
			echo "  (7) View log file"
			echo "  (8) View successes"
			echo "  (9) View failures"
			echo
			echo "  (* = default)"
			echo
			echo "  (r) Configure retention"
			echo
			echo "  (l) View license agreement"
			echo "  (q) Quit"
			echo				

			read choice
			case "$choice" in
				1) #Set source(s).........all that are powered off

					let ENDLOOP+=1
					while [ $ENDLOOP -ge 2 ]; do
						clear
						echo -e $HEADER
						echo "--MENU>MAIN>Set source(s).........?"
						echo
						echo "  (1) All VMs"
						echo "  (2) Running VMs *"
						echo "  (3) Stopped VMs"
						echo "  (4) vbBackupList.txt"
						echo "  (5) Last attempt, failed"
						echo "  (6) Specific VM"
						echo
						echo "  (* = default)"
						echo
						echo "  (b) Return"
						echo "  (q) Quit"
						

						read choice
						case "$choice" in
							1) #All VMs
								let VMOPT=1
								let ENDLOOP-=1
							;;
							2) #Running VMs
								let VMOPT=2
								let ENDLOOP-=1
							;;
							3) #Stopped VMs
								let VMOPT=3
								let ENDLOOP-=1
							;;
							4) #vbBackupList.txt
								let VMOPT=4
								let ENDLOOP-=1
							;;
							5) #Last attempt, failed
								let VMOPT=5
								let ENDLOOP-=1
							;;
							6) #Specific VM
								let VMOPT=6
								vboxmanage list vms
								echo
								echo "Type full VM name: "
								read SPECVM
								let ENDLOOP-=1
							;;
							b) #Return
								let ENDLOOP-=1
							;;
							q) #Quit
								exit 0
							;;
						esac
					done				

				;;
				2) #Set destination.......${HOME}/vbBackups/vms/

					echo "Please type full path: "
					read DST
					
					if ! [ -d "${DST}" ]; then
						echo "Path does not exist. It will be created once you start the job."
						echo "(Press Enter to return)"
						read
					fi
					

				;;
				3) #Set compression.......Disabled/Enabled ($COMP)"

					echo "Type 0 to disable and 1 to enable compression: "
					read COMP
					if [ $COMP < 0 ] || [ $COMP > 1 ]; then
						let COMP=1
					fi

				;;
				4) #Set action if on.......Skip/Stop-Start ($STOP)"

					echo "Type 0 to skip and 1 to stop-start: "
					read STOP
					if [ $STOP < 0 ] || [ $STOP > 1 ]; then
						let STOP=1
					fi

				;;
				5) #Run backup

					case "$VMOPT" in
						1) #All VMs

							mkdir "${DST}"

							if [ -d "${DST}" ]; then

								rm "${SUCCESS}"
								rm "${FAIL}"

								logStartJob

								vboxmanage list vms | cat > "${WORKING}/vms.log"

								grep -oh -P '(?!")(.+)(?=")' "${WORKING}/vms.log" | while read vmname ; 
								do 

									vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
									RESULT=$?
									if [ $RESULT -gt 0 ]; then
										exportVM "${vmname}"
									else									
										if [ $STOP -eq 1 ]; then										
											saveVM "${vmname}"						
											exportVM "${vmname}"
											startVM "${vmname}"
										else
											skipVM "${vmname}"
										fi
									fi							
								done

								logJobEnd
							else					
								logDestFail
							fi

						;;
						2) #Running VMs

							mkdir "${DST}"

							if [ -d "${DST}" ]; then

								rm "${SUCCESS}"
								rm "${FAIL}"

								# LOGGING
								echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Running VMs" | cat >> "${RESULTS}"	
								echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Running VMs"

								vboxmanage list vms | cat > "${WORKING}/vms.log"

								grep -oh -P '(?!")(.+)(?=")' "${WORKING}/vms.log" | while read vmname ; 
								do 

									vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
									RESULT=$?
									if [ $RESULT -gt 0 ]; then									
										skipVM "${vmname}"
									else				
										if [ $STOP -eq 1 ]; then										
											saveVM "${vmname}"						
											exportVM "${vmname}"
											startVM "${vmname}"
										else
											skipVM "${vmname}"
										fi
									fi							
								done

								logJobEnd
							else					
								logDestFail
							fi

						;;
						3) #Stopped VMs

							mkdir "${DST}"

							if [ -d "${DST}" ]; then

								rm "${SUCCESS}"
								rm "${FAIL}"

								# LOGGING
								echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Stopped VMs" | cat >> "${RESULTS}"	
								echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Stopped VMs"

								vboxmanage list vms | cat > "${WORKING}/vms.log"

								grep -oh -P '(?!")(.+)(?=")' "${WORKING}/vms.log" | while read vmname ; 
								do 

									vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
									RESULT=$?
									if [ $RESULT -gt 0 ]; then									
										exportVM "${vmname}"
									else									
										skipVM "${vmname}"
									fi							
								done

								logJobEnd
							else					
								logDestFail
							fi

						;;
						4) #vbBackupList.txt

							mkdir "${DST}"

							if [ -d "${DST}" ]; then

								rm "${SUCCESS}"
								rm "${FAIL}"

								if [ -f "vbBackupList.txt" ]; then

									# LOGGING
									echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | vbBackupList.txt" | cat >> "${RESULTS}"	
									echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | vbBackupList.txt"

									grep -oh -P '^(?!#).+$' "vbBackupList.txt" | while read vmname ; 
									do 			

										vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
										RESULT=$?
										if [ $RESULT -gt 0 ]; then
											exportVM "${vmname}"
										else
											if [ $STOP -eq 1 ]; then											
												saveVM "${vmname}"			
												exportVM "${vmname}"
												startVM "${vmname}"											
											else
												skipVM "${vmname}"
											fi
										fi		
									done

									logJobEnd
								else
									# LOGGING
									echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not locate vbBackupList.txt. Please create this file!" | cat >> "${RESULTS}"
									echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not locate vbBackupList.txt. Please create this file!"
									echo "(Press Enter to return)"
									read
								fi
							else					
								logDestFail
							fi				
						;;
						5) #Last attempt, failed

							if [ -n "${FAIL}" ]; then

								mkdir "${DST}"

								if [ -d "${DST}" ]; then

									rm "${SUCCESS}"						
									cp "${FAIL}" "${FAIL}.tmp" #Make a tmp copy that we can work off
									rm "${FAIL}"								

									# LOGGING
									echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Last attempt, failed" | cat >> "${RESULTS}"	
									echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Last attempt, failed"

									while read -r vmname ; 
									do 

										vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
										RESULT=$?
										if [ $RESULT -gt 0 ]; then
											exportVM "${vmname}"
										else
											if [ $STOP -eq 1 ]; then											
												saveVM "${vmname}"									
												exportVM "${vmname}"
												startVM "${vmname}"											
											else
												skipVM "${vmname}"
											fi
										fi															
									done < "${FAIL}.tmp"

									logJobEnd
								else					
									logDestFail
								fi

							else
								# LOGGING
								echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | ${FAIL} does not exist" | cat >> "${RESULTS}"
								echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | ${FAIL} does not exist"
								echo "(Press Enter to return)"
								read
							fi

						;;
						6) #Specific VM

							mkdir "${DST}"

							if [ -d "${DST}" ]; then

								rm "${SUCCESS}"						
								rm "${FAIL}"

								vmname=${SPECVM}

								# LOGGING
								echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Specific VM = ${vmname}" | cat >> "${RESULTS}"	
								echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Specific VM = ${vmname}"

								vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
								RESULT=$?
								if [ $RESULT -gt 0 ]; then
									exportVM "${vmname}"
									read
								else
									if [ $STOP -eq 1 ]; then									
										saveVM "${vmname}"
										exportVM "${vmname}"									
										startVM "${vmname}"
									else
										skipVM "${vmname}"
									fi
								fi

								logJobEnd
							else					
								logDestFail
							fi

						;;

					esac

				;;
				6) #Peek at backup files

					ls -l "${DST}"
					echo
					echo "(Press Enter to return)"
					read

				;;
				7) #View log file

					vi "${RESULTS}"

				;;
				8) #View successes

					vi "${SUCCESS}"

				;;
				9) #View failures

					vi "${FAIL}"

				;;
				r) #Configure retention

					echo
					echo "This feature is not implemented yet!"
					echo "(Press Enter to return)"
					read

				;;
				l) #View license agreement

					echo
					more LICENSE
					echo
					echo "(Press Enter to return)"
					read

				;;
				q) #Quit

					exit 0

				;;
			esac
		done
} #end of main

#Actual functions used in main

saveVM() {
	# LOGGING
	echo "`date +%Y%m%d-%H%M%S` | ${1} | This VM is running. Stopping it prior to backup..." | cat >> "${RESULTS}"	
	echo "`date +%Y%m%d-%H%M%S` | ${1} | This VM is running. Stopping it prior to backup..."
	/usr/bin/VBoxManage controlvm "${1}" savestate	
}

exportVM() {	
	# LOGGING
	echo "`date +%Y%m%d-%H%M%S` | ${1} | This VM is off. Backing it up now..." | cat >> "${RESULTS}"	
	echo "`date +%Y%m%d-%H%M%S` | ${1} | This VM is off. Backing it up now..."
									
	DATE=`date +%Y%m%d-%H%M%S`
	ODIR="${DST}/${1}"									
	OFILE="${ODIR}/${DATE}_${1}.ova"
	mkdir "${ODIR}"
										
	vboxmanage export "${1}" -o "${OFILE}"
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		echo "`date +%Y%m%d-%H%M%S` | ${1} | Success" | cat >> "${RESULTS}"
		echo "`date +%Y%m%d-%H%M%S` | ${1} | Success"
		echo "${1}" | cat >> "${SUCCESS}"
		FILESIZE=$(stat -c%s "${OFILE}")
		echo "`date +%Y%m%d-%H%M%S` | ${1} | File size = $FILESIZE" | cat >> "${RESULTS}"
		echo "`date +%Y%m%d-%H%M%S` | ${1} | File size = $FILESIZE"

		if [ $COMP -eq 1 ]; then										
			tar czvf "${OFILE}.tar.gz" "${OFILE}"
			RESULT=$?
			if [ $RESULT -eq 0 ]; then
				echo "`date +%Y%m%d-%H%M%S` | ${1} | Successfully compressed" | cat >> "${RESULTS}"	
				echo "`date +%Y%m%d-%H%M%S` | ${1} | Successfully compressed"
				rm "${OFILE}"
				FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
				echo "`date +%Y%m%d-%H%M%S` | ${1} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
				echo "`date +%Y%m%d-%H%M%S` | ${1} | Compressed file size = $FILESIZE"
			fi
		fi

	else
		echo "`date +%Y%m%d-%H%M%S` | ${1} | Fail" | cat >> "${RESULTS}"	
		echo "`date +%Y%m%d-%H%M%S` | ${1} | Fail"
		echo "${1}" | cat >> "${FAIL}"	
	fi
}

startVM() {
	# LOGGING
	echo "`date +%Y%m%d-%H%M%S` | ${1} | This VM was running prior to backup. Starting it up again..." | cat >> "${RESULTS}"	
	echo "`date +%Y%m%d-%H%M%S` | ${1} | This VM was running prior to backup. Starting it up again..."
	/usr/bin/VBoxManage startvm "${1}" --type headless
}

skipVM() {
	# LOGGING
	echo "`date +%Y%m%d-%H%M%S` | ${1} | This VM is running. Skipping..." | cat >> "${RESULTS}"
	echo "`date +%Y%m%d-%H%M%S` | ${1} | This VM is running. Skipping..."
	echo "${1}" | cat >> "${RESULTS}"	
}

logJobEnd() {
	# LOGGING
	echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run." | cat >> "${RESULTS}"
	echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run."
	echo "(Press Enter to return)"
	read
}

logDestFail() {
	# LOGGING
	echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}" | cat >> "${RESULTS}"
	echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}"
	echo "(Press Enter to return)"
	read
}

#Start running this program

main "$@"

