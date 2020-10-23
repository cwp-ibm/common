This repository contains all common tools, code, scripts, etc. used to perfom analysis on malware on wetlab machines.

Under the `scripts` folder, various scripts for preparing and running malware can be found.

## Scripts:  
### `create-malware-user.sh` 
Creates a new user account. To run this script, one has to be a sudo user.  

To create a user account which is not part of the docker group, run the following:  
```
sudo create-malware-user.sh --host-user <USERNAME>
```  
The generated account, will have the name `<USERNAME>-host`.

To create a user account which is part of the docker group, run the following:  
```
sudo create-malware-user.sh --docker-user <USERNAME>
```
The generated account, will have the name `<USERNAME>-docker`. 

The account generated, has its password remove, i.e. no password is needed to access the account. 


### `copy_to_user.sh`
Copies a file/directory to user home directory. To run this script, one has to be a sudo user.   

To copy a file/directory, run the following:  
```
sudo copy_to_user.sh --account <ACCOUNT> --source <SOURCE>
```
Where `<ACCOUNT>` is the account name.
Where `<SOURCE>` is the file/directory location.

### `create_docker_image.sh` 
Creates a Docker image where an executable can run in. To run this script, one has to be a docker user.  
To create an Docker image which wraps an executable, run the following:  
```
create_docker_image.sh <EXECUTABLE_PATH> [<BASE_IMAGE>] [<BASE_IMAGE_VERSION>]
```
The `<EXECUTABLE_PATH>` is mandatory. If `<BASE_IMAGE>` `<BASE_IMAGE_VERSION>` are not defined, the script defaults to `ubuntu:20.04`.  
The script generates an image with the name `<EXECUTABLE>:<BASE_IMAGE>_<BASE_IMAGE_VERSION>`    

### `start_sysflow_monitor_and_target_docker.sh`  
Starts the Sysflow monitoring by initializing Sysflow in a Docker container and also starts a Docker image to monitor.
To run the script, run the following:
```
start_sysflow_monitor_and_target_docker.sh <DOCKER_IMAGE>
``` 

### `start_sysflow_monitor.sh`  
Starts the Sysflow monitoring by initializing Sysflow in a Docker container.
To run the script, run the following:
```
start_sysflow_monitor_and_target_docker.sh <OUTPUT_FOLDER>
``` 

### `stop_sysflow_monitor.sh`
Stops the Sysflow monitoring and a running Docker container.   
```
stop_sysflow_monitor.sh <DOCKER_CONTAINER_NAME>
```
The `<DOCKER_CONTAINER_NAME>` is the name of the container name to stop.

### `parse_sysflow_monitor_result.sh`
Parse the Sysflow result to JSON format.
```
parse_sysflow_monitor_result.sh <SYSFLOW_RESULT_PATH>
```
The `<SYSFLOW_RESULT_PATH>` is the full path of the Sysflow result.
