# Hello-world

NGINX webserver that servers a simple page containing a simple hello world


To be able to deploy the infrastructure we only need to provide a valida AWS profile in providers file.

Then we just need to run the following commands:
```
terraform init
terraform plan
terraform apply
```

Then we need to manually create the docker image and publish it to ECR with the following commands.

#login to ECR
```
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

#build docker image
```
docker build -t hello-world-ecr .
```

#tag image
```
docker tag hello-world-ecr:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/hello-world-ecr:latest
```

#upload to ECR
```
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/hello-world-ecr:latest
```

How to run locally:
```
docker run -p 80:80 -d hello-world-ecr
```