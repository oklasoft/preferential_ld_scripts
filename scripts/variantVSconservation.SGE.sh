R=`which R` # the path for R
phastCons=$3 # the directory contains phastCons scores
email=$4 # your email address
basedir=$5

for var in "$R" "$phastCons"
do
	if [ ! -e "$var" ]
	then
		echo "Error: Can't find path $var!"
		exit
	fi
done

snplist=$1
pcutoff=$2
pipeline=$(pwd | perl -F"/" -ane 'pop(@F); print join("/", @F)')
input=$pipeline/input/GWASsnps
tmpscript=$pipeline/scripts/tmpscript

cd $tmpscript
rm -f qsub.step4.sh rm.step4.sh
while read tag name ma maf geno hwe dirname array other
do
	echo -e "$dirname\t$tag"
	chr=$(echo $name | sed 's/\:.*//')
	echo "#!/bin/bash" > variantVSconservation.SGE.${dirname}_${tag}
	echo "#$ -S /bin/bash -cwd" >> variantVSconservation.SGE.${dirname}_${tag}
	echo "#$ -l scr_free=2M" >> variantVSconservation.SGE.${dirname}_${tag}
	echo "#$ -M $email -m e" >> variantVSconservation.SGE.${dirname}_${tag} # inform me when job is done 
	echo "#$ -o $tmpscript/variantVSconservation.SGE.${dirname}_${tag}.log -j y -N s4.${dirname}.$tag" >> variantVSconservation.SGE.${dirname}_${tag}
	echo 'mkdir '"${basedir}"'/${USER}_${JOB_ID}' >> variantVSconservation.SGE.${dirname}_${tag}
	echo 'echo "${basedir}/${USER}_${JOB_ID}"' >> variantVSconservation.SGE.${dirname}_${tag}
	echo 'echo "$HOSTNAME"' >> variantVSconservation.SGE.${dirname}_${tag}
	echo "$pipeline/scripts/variantVSconservation.sh ${dirname}_${tag} $chr $phastCons $pcutoff $R $pipeline" >> variantVSconservation.SGE.${dirname}_${tag}
	echo 'rm -fr '"${basedir}"'/${USER}_${JOB_ID}' >> variantVSconservation.SGE.${dirname}_${tag}
	echo "qsub -V $tmpscript/variantVSconservation.SGE.${dirname}_${tag}" >> qsub.step4.sh
	echo "rm $tmpscript/variantVSconservation.SGE.${dirname}_${tag} $tmpscript/variantVSconservation.SGE.${dirname}_${tag}.log" >> rm.step4.sh
done < $input/$snplist
chmod +x qsub.step4.sh rm.step4.sh
