#!/bin/sh

# MB's reconstructed 4D EPIs have been deleted, so they must be recreated from
# the archived DICOMS.
#
# This command creates a list of the encrypted acqisition files from MB's
# Florida work:

#ssh stowler@pano.birc.emory.edu find /data/birc/Florida/RO1/SUBJECTS/INT2 | grep -i acqfiles | grep -i aes > acquisitionFileList.txt
ssh stowler@pano.birc.emory.edu 'cd /data/birc/Florida/RO1/SUBJECTS/INT2 && find . | grep -i acqfiles | grep -i aes' > acquisitionFileList.txt
