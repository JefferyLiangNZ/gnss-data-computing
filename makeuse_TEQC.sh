#!/bin/csh -f
#
# Script to make the rinex files be extracting information from the
# the raw DAT files
#
if( $#argv == 0 ) then
   echo ' ' 
   echo '--------------------------------------------------------------'
   echo 'Usage: sh_makerx <list of raw .DAT TRIMBLE files>'
   echo '--------------------------------------------------------------'
   echo 'Shell script makes a shell script file that creates RINEX files'
   echo 'from raw TRIMBLE files.  The names of the rinex files are based'
   echo 'on the station name stored in the raw file'
   echo ' '
   echo 'Example: sh_makerx *.DAT'
   echo 'Creates files raw.list and makerx.cmd'
   echo 'The makerx.cmd file may need modification if the raw files for'
   echo 'specific day are split into multiple files.  In these cases,'
   echo 'the multiple sessions are put in the one teqc command.  Example:'
   echo 'teqc -O.int 15 -O.obs L1L2C1P1P2S1S2 -tr 17 +obs ../rinex/swis1580.99o GPS.99/54141580.DAT GPS.99/54141580.D00'
   echo ' '
   echo 'Once makerx.cmd has been corrected, then use:'
   echo 'csh makerx.cmd'
   echo 'to generate the rinex files.  The raw.list file which contains'
   echo 'information about start and stop times in the rinex files can also'
   echo 'be saved a different name.  The file is overwritten each time the'
   echo 'script is run'
   echo ' '
   echo 'NOTE: This script requires the UNAVCO teqc program'
   echo ' '
endif

\rm raw.list
touch raw.list
foreach df (`echo $argv`)
   teqc +meta $df >&! t.d
   set dats = `grep 'start date' t.d | awk '{print substr($6,1,4),substr($6,6,2),substr($6,9,2)}'`
   set tims = `grep 'start date' t.d | awk '{print $7}'`
   set date = `grep 'final date' t.d | awk '{print substr($6,1,4),substr($6,6,2),substr($6,9,2)}'`
   set samp = `grep 'sample rate' t.d | awk '{print $3}'`
   set timz = `grep 'final date' t.d | awk '{print $7}'`
   set yr2 = `echo $dats | awk '{print substr($1,3,2)}'` 
   set doy = `doy $dats | head -1 | awk '{printf("%3d",$6)}'` 
   set doe = `doy $date | head -1 | awk '{printf("%3d",$6)}'` 
   set name = `grep 'station name' t.d | awk '{print tolower($3)}'` 
   set size = `grep 'file size' t.d | awk '{print $4/1024}'` 
   set rcv = `grep 'receiver ID' t.d | awk '{print $4}'`

   echo $df $name $doy $tims $doe $timz $rcv $size $yr2 $samp | awk '{printf("%20s %4s %3d %s %3d %s %6s %5d %2d %2d\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10)}' >> raw.list
end

sort -k 2 raw.list >! raw.sort
\rm makerx.cmd ; touch makerx.cmd

foreach rf (`awk '{print $1}' raw.sort`)
   set args = `grep $rf raw.sort`
   echo $args | awk '{printf("teqc -O.int %2d -O.obs L1L2C1P1P2S1S2 -tr 17 +obs ../rinex/%s%3.3d0.%2.2do %s\n",$10,$2,$3,$9,$1)}' >> makerx.cmd
end


