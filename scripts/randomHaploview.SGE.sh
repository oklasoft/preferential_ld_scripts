java=`which java` # the path for java
Haploview=`which haploview` # the path for Haploview
R=`which R` # the path for R
email=$4 # your email address
basedir=$5

for var in "$java" "$Haploview" "$R"
do
	if [ ! -e "$var" ]
	then
		echo "Error: Can't find path $var!"
		exit
	fi
done

snplist=$1
nrandom=$2
randomcutoff=$3
pipeline=$(pwd | perl -F"/" -ane 'pop(@F); print join("/", @F)')
input=$pipeline/input/GWASsnps
output=$pipeline/output
tmpscript=$pipeline/scripts/tmpscript

cd $tmpscript
rm -f qsub.step3.sh rm.step3.sh
while read tag name ma maf geno hwe dirname array other
do
	wc -l $output/${dirname}_${tag}/targetSNV.2.map | perl -ane 'for ($i=1; $i<=$F[0]; $i+=2) {$end=$i+1; $end=$F[0] if ($end>$F[0]); print "$i\t$end\n"}' > numbers
	ntarget=$(wc -l $output/${dirname}_${tag}/targetSNV.2.ordered | perl -ane 'print "$F[0]"')

	n=$(wc -l numbers | perl -ane 'print "$F[0]"')
	echo -e "$tag\t$dirname\t$n"
	echo "#!/bin/bash" > checkstatus3.SGE.${dirname}_${tag}
	echo "#$ -S /bin/bash -cwd" >> checkstatus3.SGE.${dirname}_${tag}
	echo "#$ -M $email -m e" >> checkstatus3.SGE.${dirname}_${tag} # sending email to me when the job is done
	echo "#$ -o $tmpscript/checkstatus3.SGE.${dirname}_${tag}.log -j y -N ck3.${dirname}.${tag}" >> checkstatus3.SGE.${dirname}_${tag}
	echo -e "while [ 1 ]\ndo" >> checkstatus3.SGE.${dirname}_${tag}
	echo -e "\tsleep 1m\n\tn=\$(ls -al $output/${dirname}_${tag}/SNVrandomLD.* | wc -l | perl -ane 'print \"\$F[0]\"')\n\tm=\$(wc -l $output/${dirname}_${tag}/SNVrandomLD.* | perl -ane 'print \"\$F[0]\" if (\$F[1] eq \"total\")')\n\techo -e \"\$n\\\t\$m\"" >> checkstatus3.SGE.${dirname}_${tag}
	echo -e "\tif [ \$n -eq $n ] && [ \$m -eq $ntarget ]\n\tthen\n\t\tbreak\n\tfi\ndone" >> checkstatus3.SGE.${dirname}_${tag}	
	echo "$pipeline/scripts/collectSNVrandom.sh $dirname $tag $randomcutoff $pipeline" >> checkstatus3.SGE.${dirname}_${tag}
	echo "qsub -V $tmpscript/checkstatus3.SGE.${dirname}_${tag}" >> qsub.step3.sh
	echo "rm $tmpscript/checkstatus3.SGE.${dirname}_${tag} $tmpscript/checkstatus3.SGE.${dirname}_${tag}.log" >> rm.step3.sh
 
	i=0
	while read start stop
	do
		i=$((i+1))
		echo "#!/bin/bash" > randomHaploview.SGE.${dirname}_${tag}.$i
		echo "#$ -S /bin/bash -cwd -l mem_free=4G" >> randomHaploview.SGE.${dirname}_${tag}.$i
		echo "#$ -l scr_free=500M" >> randomHaploview.SGE.${dirname}_${tag}.$i
		echo "#$ -o $tmpscript/randomHaploview.SGE.${dirname}_${tag}.$i.log -j y -N r$i.$tag" >> randomHaploview.SGE.${dirname}_${tag}.$i
		echo 'mkdir '"${basedir}"'/Haploview.SGE.${dirname}_${tag}.$i
		echo 'echo "${basedir}/${USER}_${JOB_ID}"' >> randomHaploview.SGE.${dirname}_${tag}.$i
		echo 'echo "$HOSTNAME"' >> randomHaploview.SGE.${dirname}_${tag}.$i
		echo "$pipeline/scripts/randomHaploview.sh $i $dirname $tag $nrandom $start $stop $java $Haploview $R $pipeline" >> randomHaploview.SGE.${dirname}_${tag}.$i
		echo 'rm -fr '"${basedir}"'/${USER}_${JOB_ID}' >> randomHaploview.SGE.${dirname}_${tag}.$i
		echo "qsub -V $tmpscript/randomHaploview.SGE.${dirname}_${tag}.$i" >> qsub.step3.sh
	 
		echo "rm $tmpscript/randomHaploview.SGE.${dirname}_${tag}.$i $tmpscript/randomHaploview.SGE.${dirname}_${tag}.$i.log" >> rm.step3.sh
	done < numbers
done < $input/$snplist
chmod +x qsub.step3.sh rm.step3.sh
rm -f numbers tmp
