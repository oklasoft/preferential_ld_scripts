plink=`which plink` # the path for plink program
email=$2 # your email address
basedir=$3

if [ ! -e "$plink" ]
then
	echo "Error: Please specify the correct path for plink program!"
	exit
fi
if [ -z "$email" ]
then 
	echo "Error: Please specify your email address. You will receive an email when the job is done."
	exit
fi

snplist=$1
pipeline=$(pwd | perl -F"/" -ane 'pop(@F); print join("/", @F)')
tmpscript=$pipeline/scripts/tmpscript

cd $tmpscript
echo "#!/bin/bash" > GWASsnp.info.$snplist.SGE
echo "#$ -S /bin/bash -cwd -l mem_free=4G" >> GWASsnp.info.$snplist.SGE
echo "#$ -M $email -m e" >> GWASsnp.info.$snplist.SGE
echo "#$ -o $tmpscript/GWASsnp.info.$snplist.log -j y -N i$snplist" >> GWASsnp.info.$snplist.SGE
echo 'mkdir '"${basedir}"'/${USER}_${JOB_ID}' >> GWASsnp.info.$snplist.SGE
echo 'echo "$HOSTNAME"' >> GWASsnp.info.$snplist.SGE
echo "$pipeline/scripts/GWASsnp.info.sh $snplist $plink $pipeline" >> GWASsnp.info.$snplist.SGE
echo 'rm -fr '"${basedir}"'/${USER}_${JOB_ID}' >> GWASsnp.info.$snplist.SGE
qsub -V GWASsnp.info.$snplist.SGE
echo "rm -f $tmpscript/GWASsnp.info.$snplist.SGE $tmpscript/GWASsnp.info.$snplist.log" > rm.GWASsnpinfo.sh
chmod +x rm.GWASsnpinfo.sh
