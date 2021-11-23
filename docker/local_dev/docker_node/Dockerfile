FROM node:16-buster AS base
RUN apt-get update --fix-missing \
      && apt-get install vim bash make --yes

FROM base AS base2
RUN npm install -g npm
RUN npm install -g @aws-amplify/cli

FROM base2 AS dependancies

WORKDIR /code

ADD . /code

FROM dependancies AS test
CMD ["./local_dev/gitlab_test_node/script_run.sh"]
