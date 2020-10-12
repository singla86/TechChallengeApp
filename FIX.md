## Summary

I have chosen docker/docker-compose and Terraform to deploy web and DB to AWS ECS.

* Dockerfile: This is used to create an image to be used for cloud deployment.
* Docker compose yaml file: This is used to manage multiple container images and its configurations.
* Terraform: IAC to provision and manage cloud and services. This app has been deployed to AWS.

## Followed files have been changed
1. **conf.toml**

    * Updated DbHost value to postgres and ListenHost value to 0.0.0.0.
  
2. **Dockerfile**

    * Installed missing golang dependencies
    * Updated `ENTRYPOINT` to run the DB and the application.

3. **Introduced Terraform**

    * Docker Image created by docker-compose is pushed to AWS ECR. 
    * Created separate AWS ECS service and task definition for application as well as postgres to utilise the images 
    pushed to ECR and to bring the application up.
    * Defined IAM roles and policies for user to be able to pull images from ECR and execute tasks
    * Defined Application load balancer pointing to 3 subnets for high availability 

### Running Solution Locally

* Env Variables
```shell script
export AWS_ACCESS_KEY_ID = <value>
export AWS_SECRET_ACCESS_KEY= <value>
```

* Docker Compose
 ```shell script
docker-compose up
 ```

### Running Solution on AWS

* Tag and Push Docker Image to ECR.
Solution assumes that the required docker container image
for application and DB has been pushed to ECR repo using below commands.
```shell script
docker tag <App/DB Image name>  <ECR Repo>
docker push <ECR Image URI>
```
* Terraform
Below commands were used to initialise the config, plan and apply changes
```shell script
terraform init
terraform plan
terraform apply
```

## Solution pointers

1. I have tried to extract all configurations into config files like `database.env`
2. This solution is simple to run on local machine or any cloud platform.
3. This solution is served from AWS, hence it is highly available and resilient. 
4. As I am using terraform, state of the infrastructure can be easily managed.

## Challenges:

Application is able to connect to Postgres successfully on my local machine, however app is unable to connect to DB 
on AWS due to config issues.
Please refer below screenshots of working application in the development environment:

**Application UI along with DB on local**
![app_local](./solution_screenshots/local_frontend.png?raw=true)

**Successful Health check on Local**
![hcheck_local](./solution_screenshots/local_healthcheck_up.png?raw=true)

**Swagger on AWS**
![Swagger_Aws](./solution_screenshots/aws_lb_swagger.png?raw=true)

**Application Interface on AWS**
![App_Aws](./solution_screenshots/aws_lb_frontend.png?raw=true)


## Important Links to various app endpoints on AWS :

* LB url for app on AWS: http://techapp-lb-tf-1600178618.ap-southeast-1.elb.amazonaws.com
* Swagger url: http://techapp-lb-tf-1600178618.ap-southeast-1.elb.amazonaws.com/swagger/
* Health check url : http://techapp-lb-tf-1600178618.ap-southeast-1.elb.amazonaws.com/healthcheck/
* Docker-hub url: https://hub.docker.com/repository/docker/singla86/techchallengeapp

