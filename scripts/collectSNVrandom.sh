dirname=$1
tag=$2
randomcutoff=$3
pipeline=$4
output=$pipeline/output/${dirname}_${tag}
extract=$pipeline/scripts/extract.pl

if [ ! -d "$output" ]
then
	echo "Error: $output doesn't exist!"
	exit
fi
cd $output
cat SNVrandomLD.* > tmp
$extract targetSNV.2.ordered tmp 1 out 0 1
echo "$randomcutoff" > tmp
cat out >> tmp
perl -ane '$i++; if ($i==1){$cutoff=$F[0]; next;} $frac=$F[1]/$F[2]; if ($frac<=$cutoff){print "$F[0]\t$frac\t$F[1]/$F[2]\t"; foreach (1..3){shift(@F);} print join("\t", @F), "\n";}' tmp | sort -t"	" -k2 -k4 -g > targetSNV.3.ordered
perl -ane '$i++; if ($i==1){$cutoff=$F[0]; next;} $frac=$F[1]/$F[2]; if ($frac>$cutoff){print "$F[0]\t$frac\t$F[1]/$F[2]\t"; foreach (1..3){shift(@F);} print join("\t", @F), "\n";}' tmp | sort -t"	" -k2 -k4 -g > targetSNV.randomRM
rm -f SNVrandomLD.* tmp out  
