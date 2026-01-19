# GATK_germlineSV_pipeline
Calls germline SVs from NGS data

## Run GATK_germlineSV_pipeline on a local HPC
GATK-SV pipeline is orchestrated by [Cromwell](https://github.com/broadinstitute/cromwell), a Workflow Management System developed by Broad Institute to execute WDL (Workflow Description Language) files. Thus, we first need to download [cromwell executable](https://github.com/broadinstitute/cromwell/releases/). Example to download the release 91:
```bash
wget [https://github.com/broadinstitute/cromwell/releases/download/91/cromwell-91.jar](https://github.com/broadinstitute/cromwell/releases/download/91/cromwell-91.jar)
```

Then, we need to clone the GATK-SV github repository:
```bash
git clone [https://github.com/broadinstitute/gatk-sv.git](https://github.com/broadinstitute/gatk-sv.git)
cd gatk-sv
```

And create zipped file of all dependency WDL files:
```bash
cd wdl && zip ../deps.zip *.wdl && cd
```

Now we are ready to execute GATK-SV pipeline using GATK_SV_exe.sh script which you will find in directory GATK_germlineSV_pipeline:
```bash
git clone https://github.com/balayev1/GATK_germlineSV_pipeline.git
cd GATK_germlineSV_pipeline
```

Follow the script and adjust the parameters accordingly.