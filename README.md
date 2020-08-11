# EDCAT
Computerized adaptive test for eating disorders.

The survey is specified by the files in the data directory, which were extracted from MultiCATinput_EPSI_09-21-18.RData in the demo Shiney app.

## PiLR Calculated Content API
PiLR EMA surveys can delegate their content to a service implement the API defined in
[KU Cat Design - Remote Calculation Card](https://docs.google.com/document/d/1fC8kag54Ttm9Yy0vm3oayHKyk5jLnvHw9e5MOqrkZJo).
The function pilrContentApi() implments the API when invoked via openCPU.

## openCPU libray path
 curl -d '' -H 'content-type: application/json' https://ocpu.pilrhealth.com/ocpu/library/base/R/.libPaths/json

["/usr/lib/R/library", "/usr/local/lib/opencpu/site-library", "/usr/local/lib/R/site-library", "/usr/lib/R/site-library", "/usr/lib/opencpu/library"]

* /usr/lib/R/library - base R
* /usr/local/lib/opencpu/site-library - empty
* /usr/local/lib/R/site-library - pilr.dpu stuff (not used)
* /usr/lib/R/site-library - KU installs here
* /usr/lib/opencpu/library - openCPU

Note, however, that the openCPU install performs the abomination of replacing some directories in /usr/lib/R/library
with symbolic links to packages in /usr/lib/opencpu/library. So those pacakges can't be overridden by isntalls into
the other library directories.

## Install on openCPU server
Install on ocpu.pilrhealth.com:

    TOKEN="<your github personal access token>"
    install() {
      sudo R_LIB='/usr/lib/R/site-library:/usr/lib/opencpu/library' Rscript --slave --no-save --no-restore-history -e "library(devtools) ; install_github(repo='$1', auth_token='$TOKEN')"
    }
    install MeiResearchLtd/EDCAT

Newer

    THis is what you have to do. Unfortunately you have to use 'sudo R' and paste each commmand.  I don't know why script fails

    REF=${1:-"master"}
    sudo Rscript --slave --no-save --no-restore-history -e "
      lib='/usr/lib/R/site-library'
      .libPaths(c(lib, '/usr/lib/R/library', '/usr/local/lib/opencpu/site-library', '/usr/local/lib/R/site-library', '/usr/lib/R/site-library', '/usr/lib/opencpu/library'))
      library(remotes)
      remove.packages(intersect(installed.packages(), c('mirt', 'mirtCAT', 'EDCAT')), lib=lib)
      install_github(repo='https://github.com/philchalmers/mirt.git', ref='v1.30', force=TRUE)
      install_github(repo='https://github.com/philchalmers/mirtCAT.git', ref='v1.9.3', force=TRUE)
      install_github(repo='https://github.com/MeiResearchLtd/EDCAT.git', ref='$REF')
      "

Note that install_github won't install dependencies IF you don't use the 'lib' parameter!

## Testing with Curl

There are some sample JSON requests in the tests/testthat/ directory that were captured from the EMA
console. They can be submitted with the following command.

    curl -H"Content-Type":"application/json" -d @request.json \
          https://ocpu.pilrhealth.com/ocpu/library/EDCAT/R/pilrContentApi/json


## JSON to R Translation

openCPU's translation from JSON to R data structures is unpredictable and changes depending on the version of
openCPU. I have been unable to find any documentation.  It appears to use the jsonlite package, but not with
unknown settings.

So to create data for unit tests, use the curl command in the previous section, but replace the function
'pilrContentAPI' with 'dumper'.  This will return a string containain an R expression that constructs a list
of the input parameters as decoded by openCPU.
