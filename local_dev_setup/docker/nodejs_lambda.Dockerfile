# Environment variables needed to be passed

#LAMBDA_TASK_ROOT=/var/task
#LAMBDA_RUNTIME_DIR=/var/runtime
# https://docs.aws.amazon.com/lambda/latest/dg/images-create.html
FROM public.ecr.aws/lambda/nodejs:14
# Alternatively, you can pull the base image from Docker Hub: amazon/aws-lambda-nodejs:12

# Assumes your function is named "app.js", and there is a package.json file in the app directory 
COPY app.js package.json  ${LAMBDA_TASK_ROOT}

# Install NPM dependencies for function
RUN npm install

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "app.handler" ]
