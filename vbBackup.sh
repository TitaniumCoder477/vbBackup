#!/bin/bash

WORKING="${HOME}/vbBackup"
DST="${WORKING}/vms"
RESULTS="${WORKING}/results.log"
SUCCESS="${WORKING}/success.log"
FAIL="${WORKING}/fail.log"
VMOPT=1
SPECVM=""
COMP=0
STOP=0

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
			1) echo "  (1) Set source(s).........all that are powered off" ;;
			2) echo "  (1) Set source(s).........vbBackupList.txt" ;;
			3) echo "  (1) Set source(s).........last attempt, failed/skipped" ;;
			4) echo "  (1) Set source(s).........specific VM = ${SPECVM}" ;;
		esac
		
		echo "  (2) Set destination.......${DST}"
		
		case "$COMP" in
			0) echo "  (3) Set compression.......Disabled ($COMP)" ;;
			1) echo "  (3) Set compression.......Enabled ($COMP)" ;;
		esac

		case "$STOP" in
			0) echo "  (4) Set action if on.......Skip ($STOP)" ;;
			1) echo "  (4) Set action if on.......Stop-Start ($STOP)" ;;
		esac
		
		echo "  (5) Run backup"
		echo "  (6) Peek at backup files"
		echo 
		echo "  (7) View log file"
		echo "  (8) View successes"
		echo "  (9) View failures"
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
					echo "  (1) All that are powered off"
					echo "  (2) vbBackupList.txt"
					echo "  (3) Last attempt, failed/skipped"
					echo "  (4) Specific VM"
					echo
					echo "  (b) Return"
					echo "  (q) Quit"						
				
					read choice
					case "$choice" in
						1) #All that are powered off
							let VMOPT=1
							let ENDLOOP-=1
						;;
						2) #vbBackupList.txt
							let VMOPT=2
							let ENDLOOP-=1
						;;
						3) #Last attempt, failed/skipped
							let VMOPT=3
							let ENDLOOP-=1
						;;
						4) #Specific VM
							let VMOPT=4
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
				
			;;
			3) #Set compression.......Disabled/Enabled ($COMP)"
			
				echo "Type 0 to disable and 1 to enable compression: "
				read COMP
				
			;;
			4) #Set action if on.......Skip/Stop-Start ($STOP)"
			
				echo "Type 0 to skip and 1 to stop-start: "
				read STOP
				
			;;
			5) #Run backup
			
				case "$VMOPT" in
					1) #All that are powered off
						
						mkdir "${DST}"
						
						if [ -n "${DST}" ]; then
						
							rm "${SUCCESS}"
							rm "${FAIL}"

							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | All that are powered off" | cat >> "${RESULTS}"	
							echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | All that are powered off"

							vboxmanage list vms | cat > "${WORKING}/vms.log"

							grep -oh -P '(?!")(.+)(?=")' "${WORKING}/vms.log" | while read vmname ; do 
							
								vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
								RESULT=$?
								if [ $RESULT -gt 0 ]; then
									# LOGGING
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Backing it up now..." | cat >> "${RESULTS}"	
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Backing it up now..."
									
									DATE=`date +%Y%m%d-%H%M%S`
									ODIR="${DST}/${vmname}"									
									OFILE="${ODIR}/${DATE}_${vmname}.ova"
									mkdir "${ODIR}"
									
									vboxmanage export "${vmname}" -o "${OFILE}"
									RESULT=$?
									if [ $RESULT -eq 0 ]; then
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success" | cat >> "${RESULTS}"
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success"
										echo "${vmname}" | cat >> "${SUCCESS}"
										FILESIZE=$(stat -c%s "${OFILE}")
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE" | cat >> "${RESULTS}"
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE"
										
										if [ $COMP -eq 1 ]; then										
											tar czvf "${OFILE}.tar.gz" "${OFILE}"
											RESULT=$?
											if [ $RESULT -eq 0 ]; then
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed" | cat >> "${RESULTS}"	
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed"
												rm "${OFILE}"
												FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE"
											fi
										fi
										
									else
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail" | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail"
										echo "${vmname}" | cat >> "${FAIL}"	
									fi
								else									
									if [ $STOP -eq 1 ]; then
										# LOGGING
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Stopping it prior to backup..." | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Stopping it prior to backup..."
										/usr/bin/VBoxManage controlvm "${vmname}" savestate
										
										DATE=`date +%Y%m%d-%H%M%S`
										ODIR="${DST}/${vmname}"									
										OFILE="${ODIR}/${DATE}_${vmname}.ova"
										mkdir "${ODIR}"
									
										vboxmanage export "${vmname}" -o "${OFILE}"
										RESULT=$?
										if [ $RESULT -eq 0 ]; then
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success" | cat >> "${RESULTS}"
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success"
											echo "${vmname}" | cat >> "${SUCCESS}"
											FILESIZE=$(stat -c%s "${OFILE}")
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE" | cat >> "${RESULTS}"
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE"
										
											if [ $COMP -eq 1 ]; then										
												tar czvf "${OFILE}.tar.gz" "${OFILE}"
												RESULT=$?
												if [ $RESULT -eq 0 ]; then
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed" | cat >> "${RESULTS}"	
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed"
													rm "${OFILE}"
													FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE"
												fi
											fi
										
										else
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail" | cat >> "${RESULTS}"	
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail"
											echo "${vmname}" | cat >> "${FAIL}"	
										fi

										# LOGGING
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Restarting it after backup..." | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Restarting it after backup..."
										/usr/bin/VBoxManage startvm "${vmname}" --type headless
									else
										# LOGGING
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is running. Skipping..." | cat >> "${RESULTS}"
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is running. Skipping..."
										echo "${vmname}" | cat >> "${RESULTS}"	
									fi
								fi							
							done
							
							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run." | cat >> "${RESULTS}"
							echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run."
							echo "(Press Enter to return)"
							read
						else					
							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}" | cat >> "${RESULTS}"
							echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}"
							echo "(Press Enter to return)"
							read
						fi
				
					;;
					2) #vbBackupList.txt
						
						mkdir "${DST}"
						
						if [ -n "${DST}" ]; then
						
							rm "${SUCCESS}"
							rm "${FAIL}"						

							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | vbBackupList.txt" | cat >> "${RESULTS}"	
							echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | vbBackupList.txt"

							grep -oh -P '^(?!#).+$' "vbBackupList.txt" | while read vmname ; do 
							
								vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
								RESULT=$?
								if [ $RESULT -gt 0 ]; then
									# LOGGING
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Backing it up now..." | cat >> "${RESULTS}"	
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Backing it up now..."								
									
									DATE=`date +%Y%m%d-%H%M%S`
									ODIR="${DST}/${vmname}"									
									OFILE="${ODIR}/${DATE}_${vmname}.ova"
									mkdir "${ODIR}"
									
									vboxmanage export "${vmname}" -o "${OFILE}"
									RESULT=$?
									if [ $RESULT -eq 0 ]; then
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success" | cat >> "${RESULTS}"
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success"
										echo "${vmname}" | cat >> "${SUCCESS}"
										FILESIZE=$(stat -c%s "${OFILE}")
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE" | cat >> "${RESULTS}"
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE"
										
										if [ $COMP -eq 1 ]; then										
											tar czvf "${OFILE}.tar.gz" "${OFILE}"
											RESULT=$?
											if [ $RESULT -eq 0 ]; then
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed" | cat >> "${RESULTS}"	
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed"
												rm "${OFILE}"
												FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE"
											fi
										fi
										
									else
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail" | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail"
										echo "${vmname}" | cat >> "${FAIL}"	
									fi
								else
									if [ $STOP -eq 1 ]; then
										# LOGGING
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Stopping it prior to backup..." | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Stopping it prior to backup..."
										/usr/bin/VBoxManage controlvm "${vmname}" savestate					
									
										DATE=`date +%Y%m%d-%H%M%S`
										ODIR="${DST}/${vmname}"									
										OFILE="${ODIR}/${DATE}_${vmname}.ova"
										mkdir "${ODIR}"
									
										vboxmanage export "${vmname}" -o "${OFILE}"
										RESULT=$?
										if [ $RESULT -eq 0 ]; then
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success" | cat >> "${RESULTS}"
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success"
											echo "${vmname}" | cat >> "${SUCCESS}"
											FILESIZE=$(stat -c%s "${OFILE}")
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE" | cat >> "${RESULTS}"
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE"
										
											if [ $COMP -eq 1 ]; then										
												tar czvf "${OFILE}.tar.gz" "${OFILE}"
												RESULT=$?
												if [ $RESULT -eq 0 ]; then
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed" | cat >> "${RESULTS}"	
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed"
													rm "${OFILE}"
													FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE"
												fi
											fi
										
										else
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail" | cat >> "${RESULTS}"	
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail"
											echo "${vmname}" | cat >> "${FAIL}"	
										fi

										# LOGGING
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Restarting it after backup..." | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Restarting it after backup..."
										/usr/bin/VBoxManage startvm "${vmname}" --type headless
									else
										# LOGGING
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is running. Skipping..." | cat >> "${RESULTS}"
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is running. Skipping..."
										echo "${vmname}" | cat >> "${RESULTS}"	
									fi
								fi							
							done
							
							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run." | cat >> "${RESULTS}"
							echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run."
							echo "(Press Enter to return)"
							read
						else					
							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}" | cat >> "${RESULTS}"
							echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}"
							echo "(Press Enter to return)"
							read
						fi
				
					;;
					3) #Last attempt, failed/skipped
					
						if [ -n "${FAIL}" ]; then
						
							mkdir "${DST}"
							
							if [ -n "${DST}" ]; then
							
								rm "${SUCCESS}"						
								cp "${FAIL}" "${FAIL}.tmp" #Make a tmp copy that we can work off
								rm "${FAIL}"								

								# LOGGING
								echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Last attempt, failed/skipped" | cat >> "${RESULTS}"	
								echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Last attempt, failed/skipped"

								while read -r vmname ; do 
								
									vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
									RESULT=$?
									if [ $RESULT -gt 0 ]; then
										# LOGGING
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Backing it up now..." | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Backing it up now..."
										
										DATE=`date +%Y%m%d-%H%M%S`
										ODIR="${DST}/${vmname}"									
										OFILE="${ODIR}/${DATE}_${vmname}.ova"
										mkdir "${ODIR}"
									
										vboxmanage export "${vmname}" -o "${OFILE}"
										RESULT=$?
										if [ $RESULT -eq 0 ]; then
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success" | cat >> "${RESULTS}"	
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success"
											echo "${vmname}" | cat >> "${SUCCESS}"	
											FILESIZE=$(stat -c%s "${OFILE}")
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE" | cat >> "${RESULTS}"
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE"
											
											if [ $COMP -eq 1 ]; then										
												tar czvf "${OFILE}.tar.gz" "${OFILE}"
												RESULT=$?
												if [ $RESULT -eq 0 ]; then
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed" | cat >> "${RESULTS}"	
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed"
													rm "${OFILE}"
													FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
													echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE"
												fi
											fi
										
										else
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail" | cat >> "${RESULTS}"	
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail"
											echo "${vmname}" | cat >> "${FAIL}"	
										fi
									else
										if [ $STOP -eq 1 ]; then
											# LOGGING
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Stopping it prior to backup..." | cat >> "${RESULTS}"	
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Stopping it prior to backup..."
											/usr/bin/VBoxManage controlvm "${vmname}" savestate			
											
											DATE=`date +%Y%m%d-%H%M%S`
											ODIR="${DST}/${vmname}"									
											OFILE="${ODIR}/${DATE}_${vmname}.ova"
											mkdir "${ODIR}"
									
											vboxmanage export "${vmname}" -o "${OFILE}"
											RESULT=$?
											if [ $RESULT -eq 0 ]; then
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success" | cat >> "${RESULTS}"	
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success"
												echo "${vmname}" | cat >> "${SUCCESS}"	
												FILESIZE=$(stat -c%s "${OFILE}")
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE" | cat >> "${RESULTS}"
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE"
											
												if [ $COMP -eq 1 ]; then										
													tar czvf "${OFILE}.tar.gz" "${OFILE}"
													RESULT=$?
													if [ $RESULT -eq 0 ]; then
														echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed" | cat >> "${RESULTS}"	
														echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed"
														rm "${OFILE}"
														FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
														echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
														echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE"
													fi
												fi
										
											else
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail" | cat >> "${RESULTS}"	
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail"
												echo "${vmname}" | cat >> "${FAIL}"	
											fi

											# LOGGING
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Restarting it after backup..." | cat >> "${RESULTS}"	
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Restarting it after backup..."
											/usr/bin/VBoxManage startvm "${vmname}" --type headless
										else
											# LOGGING
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is running. Skipping..." | cat >> "${RESULTS}"
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is running. Skipping..."
											echo "${vmname}" | cat >> "${RESULTS}"	
										fi
									fi															
								done < "${FAIL}.tmp"
								
								# LOGGING
								echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run." | cat >> "${RESULTS}"
								echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run."
								echo "(Press Enter to return)"
								read
							else					
								# LOGGING
								echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}" | cat >> "${RESULTS}"
								echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}"
								echo "(Press Enter to return)"
								read
							fi
						
						else
							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | ${FAIL} does not exist" | cat >> "${RESULTS}"
							echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | ${FAIL} does not exist"
							echo "(Press Enter to return)"
							read
						fi
					
					;;
					4) #Specific VM
											
						mkdir "${DST}"
							
						if [ -n "${DST}" ]; then
						
							rm "${SUCCESS}"						
							rm "${FAIL}"

							vmname=${SPECVM}
							
							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Specific VM = ${vmname}" | cat >> "${RESULTS}"	
							echo "`date +%Y%m%d-%H%M%S` | *** NEW BACKUP RUN *** | Specific VM = ${vmname}"
												
							vboxmanage showvminfo "${vmname}" | grep -c "running (since" > /dev/null
							RESULT=$?
							if [ $RESULT -gt 0 ]; then
								# LOGGING
								echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Backing it up now..." | cat >> "${RESULTS}"	
								echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Backing it up now..."
								
								DATE=`date +%Y%m%d-%H%M%S`
								ODIR="${DST}/${vmname}"									
								OFILE="${ODIR}/${DATE}_${vmname}.ova"
								mkdir "${ODIR}"
										
								vboxmanage export "${vmname}" -o "${OFILE}"
								RESULT=$?
								if [ $RESULT -eq 0 ]; then
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success" | cat >> "${RESULTS}"	
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success"
									echo "${vmname}" | cat >> "${SUCCESS}"
									FILESIZE=$(stat -c%s "${OFILE}")
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE" | cat >> "${RESULTS}"
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE"
									
									if [ $COMP -eq 1 ]; then										
										tar czvf "${OFILE}.tar.gz" "${OFILE}"
										RESULT=$?
										if [ $RESULT -eq 0 ]; then
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed" | cat >> "${RESULTS}"	
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed"
											rm "${OFILE}"
											FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
											echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE"
										fi
									fi
											
								else
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail" | cat >> "${RESULTS}"	
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail"
									echo "${vmname}" | cat >> "${FAIL}"	
								fi
							else
								if [ $STOP -eq 1 ]; then
									# LOGGING
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Stopping it prior to backup..." | cat >> "${RESULTS}"	
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is off. Stopping it prior to backup..."
									/usr/bin/VBoxManage controlvm "${vmname}" savestate			

									DATE=`date +%Y%m%d-%H%M%S`
									ODIR="${DST}/${vmname}"									
									OFILE="${ODIR}/${DATE}_${vmname}.ova"
									mkdir "${ODIR}"
										
									vboxmanage export "${vmname}" -o "${OFILE}"
									RESULT=$?
									if [ $RESULT -eq 0 ]; then
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success" | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Success"
										echo "${vmname}" | cat >> "${SUCCESS}"
										FILESIZE=$(stat -c%s "${OFILE}")
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE" | cat >> "${RESULTS}"
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | File size = $FILESIZE"
									
										if [ $COMP -eq 1 ]; then										
											tar czvf "${OFILE}.tar.gz" "${OFILE}"
											RESULT=$?
											if [ $RESULT -eq 0 ]; then
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed" | cat >> "${RESULTS}"	
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Successfully compressed"
												rm "${OFILE}"
												FILESIZE=$(stat -c%s "${OFILE}.tar.gz")
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE" | cat >> "${RESULTS}"
												echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Compressed file size = $FILESIZE"
											fi
										fi
											
									else
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail" | cat >> "${RESULTS}"	
										echo "`date +%Y%m%d-%H%M%S` | ${vmname} | Fail"
										echo "${vmname}" | cat >> "${FAIL}"	
									fi
								else
									# LOGGING
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is running. Skipping..." | cat >> "${RESULTS}"
									echo "`date +%Y%m%d-%H%M%S` | ${vmname} | This VM is running. Skipping..."
									echo "${vmname}" | cat >> "${RESULTS}"	
								fi
							fi
							
							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run." | cat >> "${RESULTS}"
							echo "`date +%Y%m%d-%H%M%S` | *** FINISHED *** | End of backup run."
							echo "(Press Enter to return)"
							read
						else					
							# LOGGING
							echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}" | cat >> "${RESULTS}"
							echo "`date +%Y%m%d-%H%M%S` | CRITICAL FAILURE | Could not create destination ${DST}"
							echo "(Press Enter to return)"
							read
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
			;;
			l) #View license agreement
			;;
			q) #Quit
			
				exit 0
				
			;;
		esac
	done

exit 0

