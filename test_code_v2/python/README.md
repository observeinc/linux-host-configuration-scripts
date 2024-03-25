# Set up a python virtual environment and install requirements
python3.11 -m venv ./.test_env

source ./.test_env/bin/activate

pip3 install -r requirements.txt

# Set Observe Environment variables (using profile recommended)
    export OBSERVE_CUSTOMER=IF_YOU
    export OBSERVE_DOMAIN=DONT_KNOW
    export OBSERVE_USER_EMAIL=YOU_BETTER
    export OBSERVE_USER_PASSWORD=ASK_SOMEBODY

# Run local test - see python/Makefile for more commands
```
make test
```