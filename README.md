# Coworking Space Service Extension
The Coworking Space Service is a set of APIs that enables users to request one-time tokens and administrators to authorize access to a coworking space. This service follows a microservice pattern and the APIs are split into distinct services that can be deployed and managed independently of one another.

For this project, you are a DevOps engineer who will be collaborating with a team that is building an API for business analysts. The API provides business analysts basic analytics data on user activity in the service. The application they provide you functions as expected locally and you are expected to help build a pipeline to deploy it in Kubernetes.

The project is done as part of the CloudDevOps refresher courses for Udacity.

### Dependencies

As the workspace in the Udacity classroom is not working I have worked locally using the AWS account provided by AWS.

#### Local Environment
1. Python Environment - run Python 3.6+ applications and install Python dependencies via `pip`
2. Docker CLI - build and run Docker images locally
3. `kubectl` - run commands against a Kubernetes cluster
4. `helm` - apply Helm Charts to a Kubernetes cluster
5. `terraform` - automatically create the required infrastructure for the project

#### Remote Resources
1. AWS CodeBuild - build Docker images remotely
2. AWS ECR - host Docker images
3. Kubernetes Environment with AWS EKS - run applications in k8s
4. AWS CloudWatch - monitor activity and logs in EKS
5. GitHub - pull and clone code
6. Terraform - create infra

## Getting Started

### Setup
#### 1. Add the AWS Gateway credentials to your `~/.aws/credentials`

```
[default]
aws_access_key_id = Your access key
aws_secret_access_key = Your secret access key
aws_session_token = Your AWS session token
```

Also, export these variables and the AWS credentials and config to be used by `terraform`

```
export AWS_SESSION_TOKEN=<your-token>
export AWS_SECRET_ACCESS_KEY=<your-access-key>
export AWS_ACCESS_KEY_ID=<oyur-access-key>

export AWS_SHARED_CREDENTIALS_FILE=~/.aws/credentials 
export AWS_CONFIG_FILE=~/.aws/config
```

#### 2. Create the infrastructure
I have tried two approaches here, first by manually creating the infrastructure, however, I decided that using `terraform` will be easier for other developers to re-create it.

In order to create the infrastructure you need to `cd deployment/terraform`. You will need to update the GitHub [location](https://github.com/Welith/cd12354-Movie-Picture-Pipeline/blob/0857d230c4498f7bacc2bafeeafdbcf48569d1d7/setup/terraform/main.tf#L278) line with your GitHub repository (also, change the `terraform` [version](https://github.com/Welith/cd12354-Movie-Picture-Pipeline/blob/0857d230c4498f7bacc2bafeeafdbcf48569d1d7/setup/terraform/versions.tf#L6) if you have installed a different one). Now, presuming you have installed `terraform` locally, you need to run `terraform init` to set-up your backend. Afterwards, you need to run `terraform apply`, which will deploy the following AWS components:

- EKS Cluster (with a name of `cluster`)
- ECR (repo with a name `coworking`)
- IAM Role
- CodeBuild (with a name of `udacity`)

#### 3. Connect your `kubectl` with aws by running `aws eks update-kubeconfig --region us-east-1  --name cluster`

This will set your `kubectl` commands to directly communicate with the newly created EKS Cluster

#### 4. Set-up the Bitnami Help Repo

In order to properly set-up the Helm repo, I created a local `PersistentVolume`, which requires to configure the internal DNS of the kubernetes cluster. In order to do so you will need to update [this](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/1313925604ddefc9afebc7530be890c01c3c697d/deployment/local-pv.yaml#L29) confiugration with the output of the following command:

`kubectl get nodes -o jsonpath='{ $.items[*].status.addresses[?(@.type=="InternalDNS")].address }`

Now, you need to apply the `PersistentVolume` -> `cd ..` -> `helm install postgresql bitnami/postgresql --set global.storageClass=local-storage`

This will create a `postgresql` pod and service in your cluster. This can be verified with the `kubectl get pods` and `kubectl get svc` commands.

The newly created service, will have a randomly generated password, which can be obtained with the following command:

```
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

echo $POSTGRES_PASSWORD
```

#### 5. Seed your database

To do this the easiest way is to use port forwarding (go to the `db\` folder):

```
kubectl port-forward --namespace default svc/postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < 1_create_tables.sql

kubectl port-forward --namespace default svc/postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < 2_seed_users.sql

kubectl port-forward --namespace default svc/postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < 3_seed_tokens.sql
```

However, I have noticed that sometimes this does not work, so a manual approach can be taken to log into the database with the following:

```
ubectl exec -it <pod_name> -- psql -U postgres -d postgres

Enter the $POSTGRES_PASSWORD when prompted
```

When logged in, you can now manually apply the SQL commands from the seed files.


#### 6. Run CodeBuilder to deploy the coworking Docker image to ECR

This can be done automatically, by pushing your changes to GitHub (as the CodeBuilder project is connected to your repository), or manually by running it in the AWS dashboard. This will deploy the python application to AWS ECR.

#### 7. Deploy the coworking application

Now, all thats left is to deploy the acutal application to the cluster. In order to do so, you will need to change the [repo name](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/1313925604ddefc9afebc7530be890c01c3c697d/analytics/k8s/node-deployment.yaml#L17) with you own. Now run the following command, after `cd deployment\k8s`:

`kubectl apply -f node-deployment.yaml`

This will deploy the application which will be accessible on:

`export BASE_URL=$(kubectl get services coworking --output jsonpath='{.status.loadBalancer.ingress[0].hostname})'`

#### 8. Test the application
* Generate report for check-ins grouped by dates
`curl <BASE_URL>/api/reports/daily_usage`

```
{
  "2023-02-07": 40,
  "2023-02-08": 202,
  "2023-02-09": 179,
  "2023-02-10": 158,
  "2023-02-11": 146,
  "2023-02-12": 176,
  "2023-02-13": 196,
  "2023-02-14": 142
}
```

* Generate report for check-ins grouped by users
`curl <BASE_URL>/api/reports/user_visits`

```
{
  "1": {
    "joined_at": "2023-01-20 03:23:39.757813",
    "visits": 6
  },
  "2": {
    "joined_at": "2023-02-02 16:23:39.757830",
    "visits": 5
  },
  "3": {
    "joined_at": "2023-01-31 10:23:39.757836",
    "visits": 5
  },
  "4": {
    "joined_at": "2023-02-13 05:23:39.757840",
    "visits": 2
  },
  "5": {
    "joined_at": "2023-02-11 22:23:39.757844",
    "visits": 7
  },
  "6": {
    "joined_at": "2023-02-07 18:23:39.757848",
    "visits": 3
  },
  "7": {
    "joined_at": "2022-12-26 05:23:39.757852",
    "visits": 5
  },
  "8": {
    "joined_at": "2023-01-10 15:23:39.757855",
    "visits": 7
  },
  "9": {
    "joined_at": "2023-01-18 17:23:39.757859",
    "visits": 2
  },
  "10": {
    "joined_at": "2023-01-16 04:23:39.757862",
    "visits": 4
  },
  "11": {
    "joined_at": "2023-01-02 03:23:39.757866",
    "visits": 3
  },
  ...
}
```

### Deliverables
1. [`Dockerfile`](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/analytics/Dockerfile)
2. [Screenshot of AWS CodeBuild pipeline](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/code_builder_success.png)
3. [Screenshot of AWS ECR repository for the application's repository](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/ecr_repo.png)
4. [Image in ECR](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/pushed_to_ecr.png)
5. [Screenshot of `kubectl get svc`](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/get_svc.png)
6. [Screenshot of `kubectl get pods`](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/get_pods.png)
7. [Screenshot of `kubectl describe svc postgresql`](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/psql_svc_describe.png)
8. [Screenshot of `kubectl describe svc coworking`](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/get_svc_coworking.png)
9. [Screenshot of `kubectl describe deployment coworking`](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/describe_deployment_coworking.png)
10. [All Kubernetes config files used for deployment (ie YAML files)](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/analytics/k8s/node-deployment.yaml)
11. [Screenshot of AWS CloudWatch logs for the application](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/required_screenshots/cloudwatch.png)
12. [`README.md`](https://github.com/Welith/cd12355-microservices-aws-kubernetes-project-starter/blob/main/README.md)


