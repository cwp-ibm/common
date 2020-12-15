This repository contains all common tools, code, scripts, etc. used to perfom analysis on malware on wetlab machines.

Under the `scripts` folder, various scripts for preparing and running malware can be found.

## Scripts:  
### `single-docker-malware-analysis.sh` 
Performs a full analysis on the provided executable.

The analysis includes the following steps:

1. Create a user for the executable to analyze.
2. Create Docker image of the executable.
3. Start SysFlow Monitor in Docker Container.
4. Run Executable Docker Image in a Container.
5. Wait until the Executable Container stops.
6. Save the logs of the Executable Container.
7. Stop SysFlow Monitor docker container.
8. Parse the Sysflow output.
9. Prepare the analysis output for upload to Virus Total.
10. Upload analysis output to Virus Total.
11. Push Virus Total upload hash to Hash git Repo.

When running the script with an executable for the first time, one has to be a sudo user.
Consecutive runs with the same executable can be run without sudo.
  
The script is configurable with two parameters.
1. --max-duration How long should the executable run before it is stoped in seconds.
2. --output The base folder to save the analysis results