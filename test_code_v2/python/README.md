# Set up a python virtual environment and install requirements
python3.11 -m venv ./.test_env

source ./.test_env/bin/activate

pip3 install -r requirements.txt

# Set Observe Environment variables (using profile recommended)
    export OBSERVE_CUSTOMER=IF_YOU
    export OBSERVE_DOMAIN=DONT_KNOW
    export OBSERVE_USER_EMAIL=YOU_BETTER
    export OBSERVE_USER_PASSWORD=ASK_SOMEBODY

# Run local test - see python for more commands
```

```


# To clean up failed tests
```

./.test_env/bin/python3 -c "from main import *; runner = RunTerraform(); runner.run_docker(TASKS.INFRA_HOSTMON, destroy=True); runner.run_docker(TASKS.OBSERVE_HOSTMON, destroy=True);"


```