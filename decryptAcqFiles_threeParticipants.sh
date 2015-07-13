#!/bin/sh

fxnDecryptAcqfiles(){
   # decrypt acqfiles:
   for blind in $blinds; do
      for session in $sessions; do
         echo ""
         ls -al ${encryptedParent}/INT2_${blind}/${session}/acqfiles.tgz.aes
         openssl enc -d -aes-256-cbc \
         -in  ${encryptedParent}/INT2_${blind}/${session}/acqfiles.tgz.aes \
         -out ${outDir}/INT2_${blind}_${session}_acqfiles.tgz
      done
   done
   du -h $outDir/*.tgz
}

fxnUnzipAcqfiles(){
   # unzip acqfiles:
   for blind in $blinds; do
      for session in $sessions; do
         #ls -al ${encryptedParent}/INT2_${blind}/${session}/acqfiles.tgz.aes
         tar -C ${outDir} -zxvf ${outDir}/INT2_${blind}_${session}_acqfiles.tgz
      done
   done
   find ${outDir} | grep trega
}


#blinds='s01 s08 s16'
blinds='s06 s08 s16'
sessions='pre post 3mo'
encryptedParent=/data/birc/Atlanta/stowlerWIP/tempIntention/acqfiles
outDir=/data/stowlerLocalOnly/r01_testDenoise
mkdir -p $outDir

#fxnDecryptAcqfiles
fxnUnzipAcqfiles
