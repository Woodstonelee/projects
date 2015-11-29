#!/bin/bash
#$ -pe omp 4
#$ -l mem_total=8
#$ -l h_rt=24:00:00
#$ -N dwel-multiscan-trkctr-gold0101-20130803
#$ -V
#$ -m ae
#$ -t 1

ML="/usr/local/bin/matlab -nodisplay -nojvm -singleCompThread -r "

# Input point cloud file
INFILES=( \
"/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/Aug3_BFP_Merged_Cube_NadirCorrect_Aligned_dual_cube_bsfix_pxc_update_atp2_ptcl_points.txt" \
)

# a temporary folder to store all intermediate files, no trailing path seperator.
TMPDIR="/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/tmp-ties-tls"

MLSCRIPT="/usr3/graduate/zhanli86/Programs/TIES-TLS/Script_MultiScanAsciiPts2TrkCtr.m"

$ML "ScanPtsFile='${INFILES[$SGE_TASK_ID-1]}'; TmpDir='$TMPDIR'; run $MLSCRIPT;"