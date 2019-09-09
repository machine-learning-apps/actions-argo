![Actions Status](https://github.com/machine-learning-apps/actions-argo/workflows/Build/badge.svg)

## This Action Submits Workflows To [Argo](https://argoproj.github.io/) From GitHub Actions

The purpose of this action is to allow automatic testing of [Argo Workflows](https://argoproj.github.io/argo).  Argo is a mechanism you can leverage to accomplish [CI/CD of Machine Learning](https://blog.paperspace.com/ci-cd-for-machine-learning-ai/).   This Action facilitates instantiating model training runs on the compute of your choice running on K8s.  

What are Argo Workflows?  

From [the docs](https://argoproj.github.io/docs/argo/readme.html):

- Argo Workflows is an open source container-native workflow engine for orchestrating parallel jobs on Kubernetes. Argo Workflows is implemented as a Kubernetes CRD (Custom Resource Definition).

- Define workflows where each step in the workflow is a container.
Model multi-step workflows as a sequence of tasks or capture the dependencies between tasks using a graph (DAG).
- Easily run compute intensive jobs for machine learning or data processing in a fraction of the time using Argo Workflows on Kubernetes.
- Run CI/CD pipelines natively on Kubernetes without configuring complex software development products.

## Usage

### Example Workflow That Uses This Action

This action is the third step in the below example: `Submit Argo Deployment`

```yaml
name: ML Workflow Via Actions
on:
  pull_request:
    types:
      - labeled

jobs:
  gke-auth:
    name: Argo Submit
    runs-on: ubuntu-latest
    steps:
    
    # Copy the contents of the current branch into the Actions context
    - name: Copy Repo Files
      uses: actions/checkout@master
      
    # This Step Sets the Variable ARGO_TEST_RUN='True' if an open PR is labeled with `argo/run-test`
    - name: Filter For PR Label
      id: validate
      run: python gke-argo-action/validate_payload.py

    # The workflow is submitted to Argo only if ARGO_TEST_RUN='True'
    - name: Submit Argo Deployment
      id: argo
      if: steps.validate.outputs.ARGO_TEST_RUN == 'True'
      uses: machine-learning-apps/gke-argo@master #reference this Action
      with:  # most of the inputs below are used to obtain authentication credentials for GKE
        ARGO_URL: ${{ secrets.ARGO_URI }}
        APPLICATION_CREDENTIALS: ${{ secrets.GOOGLE_APPLICATION_CREDENTIALS }}
        PROJECT_ID: ${{ secrets.GCLOUD_PROJECT_ID }}
        LOCATION_ZONE: "us-west1-a"
        CLUSTER_NAME: "github-actions-demo"
        WORKFLOW_YAML_PATH: argo/nlp-model.yaml # the argo workflow file relative to the repo's root.
        PARAMETER_FILE_PATH: argo/arguments-parameters.yml # optional parameter file.  This can be built dynamically inside the action or appended to from an existing file in the repo.
        
    # A comment is made on the PR with the URL to the Argo dashboard for the run.
    - name: PR Comment - Argo Workflow URL
      if: steps.validate.outputs.ARGO_TEST_RUN == 'True'
      run: bash gke-argo-action/pr_comment.sh "The workflow can be viewed at $WORKFLOW_URL"
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        ISSUE_NUMBER: ${{ steps.validate.outputs.ISSUE_NUMBER }}
        WORKFLOW_URL: ${{ steps.argo.outputs.WORKFLOW_URL }}
```

### Mandatory Arguments

1. `ARGO_URL`: The endpoint where your Argo UI is hosted.  This is used to build the link for dashboard of unique runs.
2. `WORKFLOW_YAML_PATH`: The full path name including the filename of the YAML file that describes the workflow you want to run on Argo.  This should be relative to the root of the GitHub repository where the Action is triggered.

### Optional Arguments

1. `PARAMETER_FILE_PATH`: Parameter file that allows you to change variables in your workflow file.  One common use for this file in an Action is to append additional arguments with the output of other Actions.  For more dicussion on parameter files, see [the Argo docs](https://argoproj.github.io/docs/argo/examples/readme.html).

### Outputs

You can reference the outputs of an action using [expression syntax](https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions), as illustrated in the last step in the example Action workflow above.

1. `WORKFLOW_URL`: URL that is a link to the dashboard for the current run in Argo.  The dashboard looks like this: