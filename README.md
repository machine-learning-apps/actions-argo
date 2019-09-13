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

This action is the third step in the below example: `Submit Argo Workflow from the examples/ folder in this repo`

```yaml
name: ML Workflows Via Actions
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:

    # This copies the files in this repo, particulary the yaml workflow spec needed for Argo.
    - name: Step One - checkout files in repo
      uses: actions/checkout@master

    # Get credentials (the kubeconfig file) the k8 cluster. Copies kubeconfig into /github/workspace/.kube/config
    - name: Step Two - Get kubeconfig file from GKE
      uses: machine-learning-apps/gke-kubeconfig@master
      with:
        application_credentials: ${{ secrets.APPLICATION_CREDENTIALS }}
        project_id: ${{ secrets.PROJECT_ID }}
        location_zone: ${{ secrets.LOCATION_ZONE }}
        cluster_name: ${{ secrets.CLUSTER_NAME }}

      ###################################################
      # This is the action that submits the Argo Workflow 
    - name: Step Three - Submit Argo Workflow from the examples/ folder in this repo
      id: argo
      uses: machine-learning-apps/actions-argo@master
      with:
        argo_url: ${{ secrets.ARGO_URL }}
        # below is a reference to a YAML file in this repo that defines the workflow.
        workflow_yaml_path: "examples/coinflip.yaml"
        parameter_file_path: "examples/arguments-parameters.yaml"
      env:
        # KUBECONFIG tells kubectl where it can find your authentication information.  A config file was saved to this path in Step Two.
        KUBECONFIG: '/github/workspace/.kube/config'

      # This step displays the Argo URL, and illustrates how you can use the output of the previous Action.
    - name: test argo outputs
      run: echo "Argo URL $WORKFLOW_URL"
      env:
        WORKFLOW_URL: ${{ steps.argo.outputs.WORKFLOW_URL }}
```

### Mandatory Inputs

1. `ARGO_URL`: The endpoint where your Argo UI is hosted.  This is used to build the link for dashboard of unique runs.
2. `WORKFLOW_YAML_PATH`: The full path name including the filename of the YAML file that describes the workflow you want to run on Argo.  This should be relative to the root of the GitHub repository where the Action is triggered.

### Optional Inputs

1. `PARAMETER_FILE_PATH`: Parameter file that allows you to change variables in your workflow file.  One common use for this file in an Action is to append additional arguments with the output of other Actions.  For more dicussion on parameter files, see [the Argo docs](https://argoproj.github.io/docs/argo/examples/readme.html).

### Outputs

You can reference the outputs of an action using [expression syntax](https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions), as illustrated in the last step in the example Action workflow above.

1. `WORKFLOW_URL`: URL that is a link to the dashboard for the current run in Argo.  The dashboard looks like this:
