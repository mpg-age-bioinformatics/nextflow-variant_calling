#!/bin/bash

source variantCalling.config

## usage:
## $1 : `release` for latest nextflow/git release; `checkout` for git clone followed by git checkout of a tag ; `clone` for latest repo commit
## $2 : profile

set -e

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

PROFILE=$2
LOGS="work"
PARAMS="params.json"

mkdir -p ${LOGS}

if [[ "$1" == "release" ]] ; 
  then

    ORIGIN="mpg-age-bioinformatics/"
    
    FASTQC_RELEASE=$(get_latest_release ${ORIGIN}nf-fastqc)
    echo "${ORIGIN}nf-fastqc:${FASTQC_RELEASE}" >> ${LOGS}/software.txt
    FASTQC_RELEASE="-r ${FASTQC_RELEASE}"

    KALLISTO_RELEASE=$(get_latest_release ${ORIGIN}nf-kallisto)
    echo "${ORIGIN}nf-kallisto:${KALLISTO_RELEASE}" >> ${LOGS}/software.txt
    KALLISTO_RELEASE="-r ${KALLISTO_RELEASE}"

    BWA_RELEASE=$(get_latest_release ${ORIGIN}nf-bwa)
    echo "${ORIGIN}nf-bwa:${BWA_RELEASE}" >> ${LOGS}/software.txt
    BWA_RELEASE="-r ${BWA_RELEASE}"

    DEEPVARIANT_RELEASE=$(get_latest_release ${ORIGIN}nf-deepvariant)
    echo "${ORIGIN}nf-deepvariant:${DEEPVARIANT_RELEASE}" >> ${LOGS}/software.txt
    DEEPVARIANT_RELEASE="-r ${DEEPVARIANT_RELEASE}"
    
    FEATURECOUNTS_RELEASE=$(get_latest_release ${ORIGIN}nf-featurecounts)
    echo "${ORIGIN}nf-featurecounts:${FEATURECOUNTS_RELEASE}" >> ${LOGS}/software.txt
    FEATURECOUNTS_RELEASE="-r ${FEATURECOUNTS_RELEASE}"
    
    MULTIQC_RELEASE=$(get_latest_release ${ORIGIN}nf-multiqc)
    echo "${ORIGIN}nf-multiqc:${MULTIQC_RELEASE}" >> ${LOGS}/software.txt
    MULTIQC_RELEASE="-r ${MULTIQC_RELEASE}"

    VEP_RELEASE=$(get_latest_release ${ORIGIN}nf-vep)
    echo "${ORIGIN}nf-vep:${VEP_RELEASE}" >> ${LOGS}/software.txt
    VEP_RELEASE="-r ${VEP_RELEASE}"
    
    uniq ${LOGS}/software.txt ${LOGS}/software.txt_
    mv ${LOGS}/software.txt_ ${LOGS}/software.txt
    
else

  for repo in nf-fastqc nf-kallisto nf-bwa nf-deepvariant nf-featurecounts nf-multiqc nf-vep ; 
    do

      if [[ ! -e ${repo} ]] ;
        then
          git clone git@github.com:mpg-age-bioinformatics/${repo}.git
      fi

      if [[ "$1" == "checkout" ]] ;
        then
          cd ${repo}
          git pull
          RELEASE=$(get_latest_release ${ORIGIN}${repo})
          git checkout ${RELEASE}
          cd ../
          echo "${ORIGIN}${repo}:${RELEASE}" >> ${LOGS}/software.txt
      else
        cd ${repo}
        COMMIT=$(git rev-parse --short HEAD)
        cd ../
        echo "${ORIGIN}${repo}:${COMMIT}" >> ${LOGS}/software.txt
      fi

  done

  uniq ${LOGS}/software.txt >> ${LOGS}/software.txt_ 
  mv ${LOGS}/software.txt_ ${LOGS}/software.txt

fi

get_images() {
  echo "- downloading images"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-bwa ${BWA_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deepvariant ${DEEPVARIANT_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow RUN ${ORIGIN}nf-vep ${VEP_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1
}

run_fastqc() {
  echo "- running fastqc"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
}

run_kallisto_get_genome() {
  echo "- getting genome files"
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry get_genome -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1
}

run_bwa() {
  echo "- mapping raw data"
  nextflow run ${ORIGIN}nf-bwa ${BWA_RELEASE} -params-file ${PARAMS} -entry index -profile ${PROFILE} >> ${LOGS}/bwa.log 2>&1 && \
  nextflow run ${ORIGIN}nf-bwa ${BWA_RELEASE} -params-file ${PARAMS} -entry map_reads -profile ${PROFILE} >> ${LOGS}/bwa.log 2>&1
}

run_deepVariant() {
  echo "- calling varinats"
  nextflow run ${ORIGIN}nf-deepvariant ${DEEPVARIANT_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/deepVariant.log 2>&1
}

run_featureCounts() {
  echo "- feature counts"
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -params-file ${PARAMS} -entry exomeGTF -profile ${PROFILE} >> ${LOGS}/featureCounts.log 2>&1 && \
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/featureCounts.log 2>&1
}

run_multiqc() {
  echo "- multiqc"
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1
}

run_vep() {
  echo "- annotating variants"
  nextflow run ${ORIGIN}nf-vep ${VEP_RELEASE} -params-file ${PARAMS} -entry cache -profile ${PROFILE} >> ${LOGS}/vep.log 2>&1 && \
  nextflow run ${ORIGIN}nf-vep ${VEP_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/vep.log 2>&1 && \
  nextflow run ${ORIGIN}nf-vep ${VEP_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/vep.log 2>&1 
}

get_images && sleep 1
run_fastqc & RUN_fastqc_PID=$!
sleep 1

run_kallisto_get_genome & RUN_kallisto_PID=$!
sleep 1

run_bwa & RUN_bwa_PID=$!
sleep 1

for PID in $RUN_fastqc_PID $RUN_kallisto_PID $RUN_bwa_PID ; 
    do
        wait $PID
        CODE=$?
        if [[ "$CODE" != "0" ]] ; 
            then
                echo "exit $CODE"
                exit $CODE
        fi   
done

run_deepVariant & RUN_deepvariant_PID=$!
sleep 1

for PID in $RUN_deepvariant_PID ; 
    do
        wait $PID
        CODE=$?
        if [[ "$CODE" != "0" ]] ; 
            then
                echo "exit $CODE"
                exit $CODE
        fi
done

run_featureCounts & RUN_featureCounts_PID=$!
sleep 1

for PID in $RUN_featureCounts_PID ; 
    do
        wait $PID
        CODE=$?
        if [[ "$CODE" != "0" ]] ; 
            then
                echo "exit $CODE"
                exit $CODE
        fi
done

run_vep & RUN_vep_PID=$!
sleep 1

run_multiqc & RUN_multiqc_PID=$!
sleep 1

for PID in $RUN_multiqc_PID $RUN_vep_PID ; 
    do
        wait $PID
        CODE=$?
        if [[ "$CODE" != "0" ]] ; 
            then
                echo "exit $CODE"
                exit $CODE
        fi
done


rm -rf ${project_folder}/upload.txt
cat $(find ${project_folder}/ -name upload.txt) > ${project_folder}/upload.txt
sort -u ${LOGS}/software.txt > ${LOGS}/software.txt_
mv ${LOGS}/software.txt_ ${LOGS}/software.txt
cp ${LOGS}/software.txt ${project_folder}/software.txt
cp Material_and_Methods.md ${project_folder}/Material_and_Methods.md
echo "main $(readlink -f ${project_folder}/software.txt)" >> ${project_folder}/upload.txt
echo "main $(readlink -f ${project_folder}/Material_and_Methods.md)" >> ${project_folder}/upload.txt
cp ${project_folder}/upload.txt ${upload_list}
echo "- done" && sleep 1

exit
