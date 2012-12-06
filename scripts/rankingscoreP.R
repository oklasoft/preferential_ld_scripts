cmd_args = commandArgs()
args = c("^randomSNV=", "^targetSNV=", "output=")
args.value = c()
for (a in args) {
        ind = grep(a, cmd_args)
        if (is.na(ind)) {
                cat(paste("Missing", a), sep="\n")
                q()
        }
        args.value = c(args.value, sub(a, "", cmd_args[ind]))
}
randomSNV = as.numeric(read.table(args.value[1], header=F, as.is=T)[,2])
nrandom = length(randomSNV)
targetSNV = read.table(args.value[2], header=F, as.is=T)
p = mapply(function(x){sum(randomSNV>=x)/nrandom}, as.numeric(targetSNV[,2]))
write.table(cbind(targetSNV[,1], p, targetSNV[,2:ncol(targetSNV)]), file=args.value[3], row.names=F, col.names=F, quote=F, sep="\t", append=F)
