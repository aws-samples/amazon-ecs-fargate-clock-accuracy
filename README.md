# Amazon ECS Fargate clock accuracy

This code complementary to the [title](link) blog-post. For full context and reference please refer to the blog content directly.

Amazon Elastic Container Service [Amazon ECS](https://aws.amazon.com/ecs/) is a fully managed container orchestration service that allows organizations to deploy, manage and scale containerized workloads. It is deeply integrated with the AWS ecosystem in order to provide a secure and easy-to-use solution for managing applications.

Nowadays, more and more applications are being migrated to or are natively built for containers. Amazon Web Services (AWS) offers [AWS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html) as the convenient choice for running containerized workloads without having to manage servers or clusters of Amazon EC2 instances. AWS ECS made time accuracy metrics and calculations already available in the [Task Metadata endpoint version 4](https://docs.aws.amazon.com/AmazonECS/latest/userguide/task-metadata-endpoint-v4-fargate.html), which can be consumed directly by the containers. This sample will be demonstrating how to read these metrics and how to publish them into CloudWatch in ECS Fargate applications.


- [What does the solution offer ?](#what-does-the-solution-offer-)
- [How to deploy the solution](#how-to-deploy-the-solution)
- [Project structure](#project-structure)
- [Considerations](#considerations)
- [Contributing to the project](#contributing-to-the-project)
- [Changelog](#changelog)
- [License](#license)

#### Security disclosures

If you think you’ve found a potential security issue, please do not post it in the Issues.  Instead, please follow the instructions [here](https://aws.amazon.com/security/vulnerability-reporting/) or email AWS security directly at [aws-security@amazon.com](mailto:aws-security@amazon.com).

## What does the solution offer ?

The following exercise walks you through the steps to deploy a sample AWS Fargate task, measure and monitor time on it. We will deploy a containerized application with a helper container, following the side-car pattern. This will address two possible scenarios:

* On demand checking - The application itself queries the endpoint, checks the drift and decides how to proceed. For demonstration purposes, our application will be just fetching the current metric value and displaying it.
* A cron-job approach - For regularly publishing the values as a CloudWatch metric. Running corn-jobs within containers is an interesting topic to explore. It allows us to apply the concept of a side-car worker container which can be also extrapolated to other use cases and perfectly suits our scenario. We can use this worker as a cron-job manager for regularly executing a script to check the clock sync in our containerized application. This cron-job worker can be re-utilized in any other scenario where the main application relies on additional periodic tasks.



## How to deploy the solution

This sample deployment is fully automated with [CloudFormation](https://aws.amazon.com/cloudformation/). There are several resources that need to be provisioned before uploading our Docker images and deploying our containers. We are referring to resources such as an [Amazon ECS Cluster](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-cluster-console-v2.html), an [Amazon ECR private repository](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html), [Amazon ECS task definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html) and the required IAM roles and policies. For simplifying these steps, we have provided an Amazon CloudFormation template that will automate the process. 

### Step by step

1. Export relevant environment variables. Please replace the placeholders <your-aws-region> and <your-account-ID> with the AWS Region where you are working and your AWS Account ID respectively:

```
$> export REGION=<your-aws-region>
$> export ACCOUNTID=<your-account-ID>
```

2. Clone the repository

```
git clone https://github.com/aws-samples/ecs-fargate-clock-accuracy
```

... or [download](https://github.com/aws-samples/ecs-fargate-clock-accuracy/archive/master.zip) it directly as a zip.

3. Step into the repository folder

```
cd ecs-fargate-clock-accuracy
```

4. Deploy ...

The project includes a Makefile which will conveniently automate both CloudFormation deployment and Docker Image creation. You can simply run:

```
$> make all ACCOUNTID='123456789123' REGION='aa-bbbbb-X'
```


## Project structure

The project structure uses [CloudFormation Stacks](https://aws.amazon.com/cloudformation/) for seamlessly deploying the samples.

The project structure looks as follows:

```
.
├── app-python
│   ├── application.py
│   └── Dockerfile
├── cron-worker
│   ├── clockcheck.sh
│   └── Dockerfile
├── ecs-fargate-clock-accuracy.yaml
├── Makefile
├── Output
├── README.md
└── task-definition-template.json
```

The main application is a simple Python web engine, displaying a sample website. This serves to demonstrate how the main application itself can consume the metadata endpoint, fetch the current clock timing metrics and make a decision based on those values. For example, before starting a critical operation the application can perform this consultation in order to decide if the clock error bound is within the acceptable values and in sync before proceeding.

This worker runs alongside the main application and its function is to run periodic scripts by simply using cron. In our scenario, the periodic task is a shell script that will collect metadata and timing metrics from the ECS Fargate Tasks and then publish them as an [Amazon CloudWatch custom metric](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html).


## Considerations

We encourage everyone to report issues and feature requests in [this section](https://github.com/aws-samples/amazon-ecs-agent-connection-monitoring/issues). This will help to improve the solution and expand it to different use cases.

This solution works both for Linux and Windows ECS Fargate deployments.


## Contributing to the project

Contributions and feedback are welcome! Proposals and pull requests will be considered and responded. For more information, see the [CONTRIBUTING](./CONTRIBUTING.md) file.

Amazon Web Services does not currently provide support for modified copies of this software.


## License

The Amazon ECS agent connection monitoring solution is distributed under the [MIT-0 License](https://github.com/aws/mit-0). See [LICENSE](./LICENSE) for more information.
