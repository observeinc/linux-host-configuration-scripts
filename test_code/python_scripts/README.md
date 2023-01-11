# Fabric file

Run ```fab test -h ``` for options
 
## Setup and activate Python virtual env
```
python3 -m venv testenv

source testenv/bin/activate
```

### install dependencies
```pip3 install -r requirements.txt```

#### create output directory for archive files
```
mkdir file_outputs
mkdir log_outputs
```

### Run tests
-s flag determines how lon to wait before running and is used by ci to wait 5 minutes for machines to come online
-b flag specifies remote branch version to use (if not supplied defaults to main)
fab test -s 0 -b mybranch


