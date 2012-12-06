plink= # the path for plink program
java= # the path for java
Haploview= # the path for Haploview
R= # the path for R
email= # your email address

for var in "$plink" "$java" "$Haploview" "$R"
do
	if [ ! -e "$var" ]
	then
		echo "Error: Can't find path $var!"
		exit
	fi
done

snplist=$1
distcutoff=$2
mafcutoff=$3
rarethangwas=$4
hwecutoff=$5
r2cutoff=$6
pipeline=$(pwd | perl -F"/" -ane 'pop(@F); print join("/", @F)')
input=$pipeline/input/GWASsnps
output=$pipeline/output
tmpscript=$pipeline/scripts/tmpscript

cd $tmpscript
rm -f qsub.step1.sh rm.step1.sh
while read tag name ma maf geno hwe dirname array gwasmafcutoff gwashwecutoff other
do
	echo -e "$dirname\t$tag"
	if [ ! -e $output/${dirname}_${tag} ]
	then
		mkdir $output/${dirname}_${tag} 
	fi
	echo -e "$name\t$ma\t$maf\t$geno\t$hwe\t$tag" > $output/${dirname}_${tag}/discoverySNP.anno
	echo "#!/bin/bash" > targetSNV.SGE.${dirname}_${tag}
	echo "#$ -S /bin/bash -cwd -l mem_free=4G" >> targetSNV.SGE.${dirname}_${tag}
	echo "#$ -l scr_free=500M" >> targetSNV.SGE.${dirname}_${tag} 
	echo "#$ -M $email -m e" >> targetSNV.SGE.${dirname}_${tag} # inform me when job is done 
	echo "#$ -o $tmpscript/targetSNV.SGE.${dirname}_${tag}.log -j y -N s1.${dirname}.$tag" >> targetSNV.SGE.${dirname}_${tag}
	echo 'mkdir /scratch/${USER}_${JOB_ID}' >> targetSNV.SGE.${dirname}_${tag}
	echo 'echo "/scratch/${USER}_${JOB_ID}"' >> targetSNV.SGE.${dirname}_${tag}
	echo 'echo "$HOSTNAME"' >> targetSNV.SGE.${dirname}_${tag}
	echo "$pipeline/scripts/targetSNV.sh $tag $dirname $array \"$name\" $distcutoff $maf $mafcutoff $rarethangwas $hwecutoff $r2cutoff $gwasmafcutoff $gwashwecutoff $plink $java $Haploview $R $pipeline" >> targetSNV.SGE.${dirname}_${tag}
	echo 'rm -fr /scratch/${USER}_${JOB_ID}' >> targetSNV.SGE.${dirname}_${tag}
	echo "qsub $tmpscript/targetSNV.SGE.${dirname}_${tag}" >> qsub.step1.sh
	echo "rm $tmpscript/targetSNV.SGE.${dirname}_${tag}" >> rm.step1.sh
	echo "mv $tmpscript/targetSNV.SGE.${dirname}_${tag}.log $output/${dirname}_${tag}/" >> rm.step1.sh
done < $input/$snplist
chmod +x qsub.step1.sh rm.step1.sh
#
