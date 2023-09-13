# superchain-ops

This repo contains execution code and artifacts related to superchain deployments and other tasks.

This repo is structured with each network having a high level directory which contains sub directories of any "tasks" which have occured on that network.

Tasks include:

- new contract deployments
- contract upgrades
- onchain configuration changes

Effectively any significant change to the state of the network, requiring authorization to execute, should be considered a task.

## Directory structure

Each task will have a directory structure similar to the following:

- `task-name.json`: A json file which defines the task to be executed. This file may either be generated automatically or manually created.
- `.env`: a place to store env variables specific to this task
- `/records/`: foundry will autogenerate files here as a result of executing the task
- `/script/`: (optional) for storing one-off scripts
