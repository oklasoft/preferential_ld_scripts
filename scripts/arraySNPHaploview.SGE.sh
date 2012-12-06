plink= # the path for plink program
java= # the path for java
Haploview= # the path for Haploview
email= # your email address

for var in "$plink" "$java" "$Haploview"
do
	if [ ! -e "$var" ]
	then
		echo "Error: Can't find path $var!"
	exit
	fi
done

snplist=$1
arraysnpcutoff=$2
pipeline=$(pwd | perl -F"/" -ane 'pop(@F); print join("/", @F)')
snpinfo=$pipeline/input/GWASsnps
output=$pipeline/output
tmpscript=$pipeline/scripts/tmpscript

cd $tmpscript
rm -f qsub.step2.sh rm.step2.sh
while read tag name ma maf geno hwe dirname array other
do
	wc -l $output/${dirname}_${tag}/$array.bim | perl -ane 'for ($i=1; $i<=$F[0]; $i+=400) {$end=$i+399; $end=$F[0] if ($end>$F[0]); print "$i\t$end\n"}' > numbers
	ntarget=$(wc -l $output/${dirname}_${tag}/extractSNV.1.map | perl -ane 'print "$F[0]"')
	n=$(wc -l numbers | perl -ane 'print "$F[0]"')
	echo -e "${dirname}_${tag}\t$array\t$name\t$n"
	echo "#!/bin/bash" > checkstatus2.SGE.${dirname}_${tag}
	echo "#$ -S /bin/bash -cwd" >> checkstatus2.SGE.${dirname}_${tag}
	echo "#$ -M $email -m e" >> checkstatus2.SGE.${dirname}_${tag} # sending email to me when the job is done
	echo "#$ -o $tmpscript/checkstatus2.SGE.${dirname}_${tag}.log -j y -N ck2.${dirname}.${tag}" >> checkstatus2.SGE.${dirname}_${tag}
	echo -e "while [ 1 ]\ndo" >> checkstatus2.SGE.${dirname}_${tag}
	echo -e "\tsleep 1m\n\tn=\$(wc -l $output/${dirname}_${tag}/arraySNPHaploview.* | perl -ane 'next if (\$F[1] eq \"total\" || \$F[0] != $ntarget); \$i++; print \"\$i\\\n\"' | tail -1 )\n\techo \"\$n\"" >> checkstatus2.SGE.${dirname}_${tag}
	echo -e "\tif [ \$n -eq $n ]\n\tthen\n\t\tbreak\n\tfi\ndone" >> checkstatus2.SGE.${dirname}_${tag}
	echo "$pipeline/scripts/collectArraySNPHaploview.sh ${dirname}_${tag} $array $arraysnpcutoff $plink $pipeline" >> checkstatus2.SGE.${dirname}_${tag}
	echo "qsub $tmpscript/checkstatus2.SGE.${dirname}_${tag}" >> qsub.step2.sh
	echo "rm $tmpscript/checkstatus2.SGE.${dirname}_${tag} $tmpscript/checkstatus2.SGE.${dirname}_${tag}.log" >> rm.step2.sh

	sub=0
	while read start stop
	do
		sub=$((sub+1))
		echo "#!/bin/bash" > arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo "#$ -S /bin/bash -cwd -l mem_free=4G" >> arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo "#$ -l scr_free=500M" >> arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo "#$ -o $tmpscript/arraySNPHaploview.SGE.${dirname}_${tag}.$sub.log -j y -N $tag.$sub" >> arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo 'mkdir /scratch/${USER}_${JOB_ID}' >> arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo 'echo "/scratch/${USER}_${JOB_ID}"' >> arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo 'echo "$HOSTNAME"' >> arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo "$pipeline/scripts/arraySNPHaploview.sh $sub $start $stop $array ${dirname}_${tag} $plink $java $Haploview $pipeline" >> arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo 'rm -fr /scratch/${USER}_${JOB_ID}' >> arraySNPHaploview.SGE.${dirname}_${tag}.$sub
		echo "qsub $tmpscript/arraySNPHaploview.SGE.${dirname}_${tag}.$sub" >> qsub.step2.sh
		echo "rm $tmpscript/arraySNPHaploview.SGE.${dirname}_${tag}.$sub $tmpscript/arraySNPHaploview.SGE.${dirname}_${tag}.$sub.log" >> rm.step2.sh
	done < numbers
done < $snpinfo/$snplist
rm -f numbers 
chmod +x qsub.step2.sh rm.step2.sh
