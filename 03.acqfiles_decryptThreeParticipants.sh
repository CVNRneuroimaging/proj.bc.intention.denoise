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
         # create $outDir/SUBJECTS/INT2/INT2_$blind/$session/acqfiles/INT2_$blind_NONSTANDARDSESSIONID/$sequence
         # ...where $sequence is epi01...epi06, t1
         tar -C ${outDir} -zxvf ${outDir}/INT2_${blind}_${session}_acqfiles.tgz
      done
   done
   find ${outDir} | grep trega
}

fxnCollectAnats(){
   # if we already have ./acqfiles_possibleAnats_scrubbed.txt, ask if want to use existing or regenerate?
   # (TBD)
   #################################################################
   # Interactive selection of inputs files from many possible candidates:
   #################################################################
   # 
   # Appoint one and only one T1 anatomic for each participant X session
   # combination, though multiple files might have names that match the
   # participant X session combination.
   # 
   # creates a folder filled with text files: appointFiles-anat-YYYYMMDDHHMMSS

   # Write results to auditable text files:
   # seats.txt           - input: "seats" that need user's appointments (e.g., one anatomic image per participant X session combination)
   # candidates.txt      - input:  candidate files from which the user might fill (appoint) those seats
   # appointed.txt       - output: from the candidates, these are the files that the user appointed
   # rejected.txt        - output: from the candidates, these are the files that the user rejected
   # seatsUnfilled.txt   - output: from the seats list, the user did not select any candidates for these seats

   # Create output directory for appointFiles, or exit script if it already exists:
   afLabel=anat
   afDateTimeStamp="`date +%Y%m%d%H%M%S`"
   afOutDir=/tmp/appointFiles-${afLabel}-${afDateTimeStamp}
   if [ -d ${afOutDir} ]; then
      echo ""
      echo "Exiting...weirdly this directory already exists:"
      ls -al ${afOutdir}
      exit
   else
      mkdir -p ${afOutDir}
   fi

   # Step 1: for reference, identify and count the seats that need to be filled (particpant X session combos): 
   for blind in ${blinds}; do
      for session in ${sessions}; do
         echo $blind $session >> ${afOutDir}/seats.txt
      done
   done

   # Step 2: build a list of candidate files:
   find ${outDir}/SUBJECTS/ | grep -i t1 | grep TFESENSE | grep \/200 > ${afOutDir}/candidates.txt

   # Step 3: process each seat that needs filling (participants X session combo):
   while read -r -u 9 line; do
      blind=`echo ${line} | cut -f 1 -d \ `
      session=`echo ${line} | cut -f 2 -d \ `
      echo ""
      echo "field 1 is $blind and field 2 is $session"
      
      # Create a file just containing the matching candidates:
      # (TBD: generalize grep for n search tokens)
      matchingCandidates=/tmp/matchingCandidates_${blind}${session}.txt
      rm -f ${matchingCandidates}
      grep ${blind} ${afOutDir}/candidates.txt | grep ${session} > ${matchingCandidates}
      #qtyMatchingCandidates=`grep ${blind} ${afOutDir}/candidates.txt | grep ${session} | wc -l | sed 's/[ ^I]//g'`
      qtyMatchingCandidates=`cat ${matchingCandidates} | wc -l | sed 's/[ ^I]//g'`
      echo "qtyMatchingCandidates is $qtyMatchingCandidates"
      case "$qtyMatchingCandidates" in
         0)
            # No candidate files match the search pattern , so add the pattern to unfilledSeats.txt:
            echo "${line}" >> ${afOutDir}/unfilledSeats.txt
            #ls -al ${afOutDir}/unfilledSeats.txt
            #cat ${afOutDir}/unfilledSeats.txt
            ;;
         1)
            # Exactly one candidate file matched the search pattern, so add that candidate file to appointed.txt:
            # (thorough mode TBD: give user chance to reject even though one found)
            #grep ${blind} ${afOutDir}/candidates.txt | grep ${session} >> ${afOutDir}/appointed.txt
            cat ${matchingCandidates} >> ${afOutDir}/appointed.txt
            #ls -al ${afOutDir}/appointed.txt
            #cat ${afOutDir}/appointed.txt
            ;;
         *)
            # Multiple candidates match the search pattern, so give user a choice:

            # thorough mode TBD: give user chance to reject all candidates
            # send the appointed candidate to *appointed.txt:
            # send the rejected candidates to *rejected.txt:
            echo 
            echo "multiple candidates found for ${line}":
            #grep ${blind} ${afOutDir}/candidates.txt | grep ${session}
            echo ""
            echo "Type the number of the single candidate file that you would like to appoint for analysis, ignoring the other candidates:"
            echo ""
            cat -n ${matchingCandidates}
            echo ""
            echo -n "(file number, then enter:) "
            read fileNumber
            echo ""
            echo "You selected file number ${fileNumber}."
            # send the appointed candidate to *appointed.txt:
            sed -n "${fileNumber}p" ${matchingCandidates} >> ${afOutDir}/appointed.txt
            # send the rejected candidates to *rejected.txt:
            sed "${fileNumber}d" ${matchingCandidates} >> ${afOutDir}/rejected.txt

            ;;
      esac
   done 9< "${afOutDir}/seats.txt"

   ls -al ${afOutDir}/*
   # check: candidates found == appointed + rejected
   # check: seats identified == appointed + unfilled
   # TBD: allow for some of these to be zero:
   qtySeats=`wc -l ${afOutDir}/seats.txt | sed 's/[ ^I]//g'`
   qtyCandidates=`wc -l ${afOutDir}/candidates.txt | sed 's/[ ^I]//g'`
   qtyAppointed=`wc -l ${afOutDir}/appointed.txt | sed 's/[ ^I]//g'`
   qtyRejected=`wc -l ${afOutDir}/rejected.txt | sed 's/[ ^I]//g'`
   qtyUnfilledSeats=`wc -l ${afOutDir}/unfilledSeats.txt | sed 's/[ ^I]//g'`

   # If there are unfilledSeats, give advice (create a symlink with better name, or revise list of blinds and sessions)

   echo "Of the $qtySeats seats in the search space, $qtyAppointed received appointments and $qtyUnfilledSeats remain unfilled. (The second two should add up to the first.)"
   echo ""
   echo "Of the $qtyCandidates found, $qtyAppointed were appointed to seats and $qtyRejected were rejected. (The second two should add up to the first.)"
   echo ""

   # TBD: copy anats to new location, renaming them in the process:
}

#blinds='s01 s08 s16'
blinds='s06 s08 s16'
sessions='pre post 3mo'
encryptedParent=/data/birc/Atlanta/stowlerWIP/tempIntention/acqfiles
outDir=/data/stowlerLocalOnly/r01_testDenoise
mkdir -p $outDir

#fxnDecryptAcqfiles
#fxnUnzipAcqfiles
fxnCollectAnats
