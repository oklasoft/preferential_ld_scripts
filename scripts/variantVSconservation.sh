dirname=$1
chr=$2
phastCons=$3
pcutoff=$4
R=$5
pipeline=$6
extract=$pipeline/scripts/extract.pl
getscore=$pipeline/scripts/getConservationScore.pl
Rscript=$pipeline/scripts
dir=$pipeline/output/${dirname}
tmpdir=/scratch/${USER}_${JOB_ID}
echo $tmpdir

cd $tmpdir
perl -ane 'if ($F[0]=~/(\w+):(\d+)\w\w/){print "$F[0]\t$1\t$2\n";} else {die "Error $_: Incorrect format!\n"}' $dir/targetSNV.3.ordered $dir/randomSNV.2.ordered $dir/discoverySNP.anno | sort -t"	" -k3 -n | uniq > que # items in <query> are in the order of increasing positions
$getscore que $phastCons/chr$chr.phastCons44way.primates.wigFix conservationscore
$extract que conservationscore 1 out 0 0
perl -ane 'chomp($F[$#F]); if (@F<2){print "$F[0]\tNA\n";} else {print "$_"}' out > data.all
for file in discoverySNP.anno randomSNV.2.ordered targetSNV.3.ordered
do
	$extract $dir/$file data.all 1 out 0 1
	if [ "$file" = "targetSNV.3.ordered" ]
	then
		perl -ane '$score=0.3*$F[1]+0.7*(1-$F[4]/0.05); if ($F[0]=~/(\w+):(\d+)\w\w/) {print "$F[0]\t$score\t"; shift(@F); print join("\t", @F), "\n";}else {die "Error $_: Incorrect format!\n";}' out | sort -t"	" -k2 -g -r > targetSNV.4.ordered
	else
		if [ "$file" = "randomSNV.2.ordered" ]
		then
			perl -ane '$score=0.3*$F[1]+0.7*(1-$F[2]/0.05); if ($F[0]=~/(\w+):(\d+)\w\w/) {print "$F[0]\t$score\t"; shift(@F); print join("\t", @F), "\n";}else { die "Error $_: Incorrect format!\n";}' out | sort -t"	" -k2 -g -r > randomSNV.4.ordered
		else 
			mv out $file
		fi
	fi
done
$R --no-save --slave --args randomSNV=randomSNV.4.ordered targetSNV=targetSNV.4.ordered output=targetSNV.4.ordered < $Rscript/rankingscoreP.R # generate p-value of the sorting score
sed "s/^/$pcutoff\t/" targetSNV.4.ordered > tmp
perl -ane 'if ($F[2]<=$F[0]){shift(@F); print join("\t", @F), "\n"}' tmp > $dir/targetSNV.4.ordered
perl -ane 'if ($F[2]>$F[0]){shift(@F); print join("\t", @F), "\n"}' tmp > $dir/targetSNV.highP
mv randomSNV.4.ordered discoverySNP.anno $dir

