#!/bin/bash

#This file retrieves GKE credentials and submits an Argo Workflow on K8s

set -e

############ Helper Functions ############

function check_env() {
    if [ -z $(eval echo "\$$1") ]; then
        echo "Variable $1 not found.  Exiting..."
        exit 1
    fi
}

function check_file_exists() {
    if [ ! -f $1 ]; then
        echo "File $1 was not found"
        echo "Here are the contents of the current directory:"
        ls
        exit 1
    fi
}

function yaml_get_generateName {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }' | grep metadata_generateName= | cut -d \" -f2
}

randomstring(){
    cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z' | fold -w 7 | head -n 1
}

############ Validate Inputs ############

# Check the presence of all required environment variables and files
check_env "INPUT_ARGO_URL"
check_env "INPUT_WORKFLOW_YAML_PATH"
cd $GITHUB_WORKSPACE
check_file_exists $INPUT_WORKFLOW_YAML_PATH

# Validate the contents of the Argo Workflow File for the generateName field
RUN_NAME_PREFIX=$(yaml_get_generateName $INPUT_WORKFLOW_YAML_PATH)
if [ -z "${RUN_NAME_PREFIX-}" ]; then
   echo "You must specify the metadata.generateName (not metadata.name) field in your yaml workflow for this Action."
   exit 1
fi

############ Construct the Run ID ############

# run id is {metadata.generateName}-{shortSHA}-{randomstring}
shortSHA=$(echo "${GITHUB_SHA}" | cut -c1-7)
WORKFLOW_NAME=${RUN_NAME_PREFIX}-${shortSHA}-$(randomstring)

############ Instantiate Argo Workflow ############

# If the optional argument PARAMETER_FILE_PATH is supplied, add additional -f <filename> argument to `argo submit` command
if [ ! -z "$INPUT_PARAMETER_FILE_PATH" ]; then
    echo "Parameter file path provided: $INPUT_PARAMETER_FILE_PATH"
    check_file_exists $INPUT_PARAMETER_FILE_PATH
    PARAM_FILE_CMD="-f $INPUT_PARAMETER_FILE_PATH"
else
    PARAM_FILE_CMD=""
fi

# Execute the command
ARGO_CMD="argo submit $INPUT_WORKFLOW_YAML_PATH --name $WORKFLOW_NAME $PARAM_FILE_CMD"
echo "executing command: $ARGO_CMD"
eval $ARGO_CMD

#emit the outputs
echo "::set-output name=WORKFLOW_URL::$INPUT_ARGO_URL/$WORKFLOW_NAME"