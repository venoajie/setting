
## General troubleshootings:
- Check .env file for any account update/ram-disk size change
- File crash after resizing ram-disk
```shell 
git fetch origin
git reset --hard origin/main
git pull
``` 

```shell 
cd MyApp/src/configuration
# re-attach .env file here
``` 
- Fail to install Python dependencies (specific for Ubuntu 20). Downgrade setup tools:
```shell 
pip3 install --upgrade --user setuptools==58.3.0
``` 
