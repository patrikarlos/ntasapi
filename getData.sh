#!/bin/bash

. infolib
tmpfile=$(mktemp)
#searchstring=$1

#logdir=$1
#platf=${2:-all}
minExp=3020;
minCount=5

platf="all"

while getopts "e:u:l:p:t:m:s:" opt; do
    echo "opt = $opt"
    case $opt in
	e)
#	    echo "-e was fired,  $OPTARG"
	    minExp=$OPTARG
	    ;;
	u)
#	    echo "-u was fired,  $OPTARG"
	    maxExp=$OPTARG
	    ;;
	l)
#	    echo "-l was fired,  $OPTARG"
	    logdir=$OPTARG
	    ;;
	p) 
	    platf=$OPTARG
	    ;;
	t)
	    tmpfile=$OPTARG
	    ;;
	s) 
	    searchstring=$OPTARG
	    ;;
	m)
	    minCount=$OPTARG
	    ;;

	\?)
	    echo "Invalid option -$OPTARG"
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires argument"
	    exit 1
	    ;;
    esac
done


echo "Grabbing $searchstring on $platf platform(s), from $minExp ($minCount), saving data into $logdir"
#mkdir $logdir

if [ -z ${maxExp+x} ]; 
then
    echo "Unset"
    maxExp=100000; ## Should be changed if expid grows beyond this.
else 
    echo "Set"
    #Use what ever we got.
fi


for exp in $(find_exp "$searchstring"); do 
    if [[ "$exp" -ge $minExp && "$exp" -le $maxExp ]];
    then
	expStatus=$(get_exp_status $exp)
	platform=$(get_platform_name $exp)
	runCnt=$(get_valid_runs $exp  | wc -w)
	#	echo -n "$exp has $runCnt "
	if [[ "$expStatus" == "SUCCESS" ]]
	then
	    if [ "$runCnt" -ge "$minCount" ]; then
		echo "$exp with enough runs ($runCnt vs $minCount)"
		if [[ "$platf" == "all" || "$platf" == "$platform" ]]; then
		    echo "$exp" >> $tmpfile
		else
		    echo "$platf does not match "
		fi
	    else
		echo "$exp too few runs ($runCnt vs $minCount)"
	    fi
	else
	    echo "$exp was not a SUCCESS ($expStatus)";
	fi
    fi
done


echo "Experiment ids are found in $tmpfile"

tfile=$(mktemp)	
echo "tfile =  $tfile tfile2 =  $tfile2"
cat $tmpfile | while read line; do
    echo -e "$line:\t " $(get_platform_name $line) " " $(get_valid_runs $line | wc -w )
    echo -e "\t " $(get_exp_command $line)
    
    echo $(get_platform_name $line)  > $logdir/$line.txt
    echo $(get_valid_runs $line | wc -w )  >> $logdir/$line.txt
    echo $(get_exp_command $line)  >> $logdir/$line.txt
	## Bummer; need to avoid using invalid runs.
	#principle; make a copy of original file
	#grep away bad runs (grep -v), then once done, resume operations

	echo -e "\t Working on valid runs  ";
	for grun in $(get_valid_runs $line); do 
	    echo -e "\t Do something with $line $grun"
	    dlTime=$(get_run_log $line $grun | grep 'Runtime' | awk '{print $6}')
	    cmd=$(get_exp_command $line)
	    delay=$(echo "$cmd" | tr ' ' '\n' | grep 'Shaper:Delay=' | awk -F'=' '{print $2}')
	    jitter=$(echo "$cmd" | tr ' ' '\n' | grep 'Shaper:Jitter=' | awk -F'=' '{print $2}')
	    
	    echo "$delay $jitter $dlTime" >> $logdir/result.txt
	done
done

##
## The logfiles columns are
## RunId, Duration (s), energy (Ws)
#cd $logdir
#gnuplot <<EOF
#FILES = system("ls -1 *.txt")
#LABLE = system("ls -1 *.txt | sed -e 's/.txt//'")
#set ylabel "Energy [Ws]"
#set xlabel "Time [s]"
#set key outside
#set term png
#set output "../${logdir}.png"
#plot for [i=1:words(FILES)] word(FILES,i) u 2:3 title word(LABLE,i)
#EOF
cd ..
