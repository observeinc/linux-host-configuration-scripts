import os
import logging
from decouple import config
import requests
import ndjson
from gql import Client
from gql.transport.requests import RequestsHTTPTransport

from enum import Enum

PYTHON_LOG_LEVEL = config("PYTHON_LOG_LEVEL", default="DEBUG")

logging.basicConfig(
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S %z",
    level=PYTHON_LOG_LEVEL,
)


class MACHINES(Enum):
    debian = 1
    rhel = 2
    windows = 3


class TASKS(Enum):
    """Enum for categorizing tasks to run"""

    INFRA_HOSTMON = 1
    OBSERVE_HOSTMON = 2
    OBSERVE_OTEL = 3
    INFRA_OTEL = 4


class authenticator:
    """
    Methods for environment variables and authenticating to Observe based on env vars
    """

    # Get environment variables for authenticating to Observe
    OBSERVE_CUSTOMER = config("OBSERVE_CUSTOMER")
    OBSERVE_DOMAIN = config("OBSERVE_DOMAIN")
    OBSERVE_USER_EMAIL = config("OBSERVE_USER_EMAIL")
    OBSERVE_USER_PASSWORD = config("OBSERVE_USER_PASSWORD")
    # If set get
    BEARER_TOKEN = config("OBSERVE_BEARERTOKEN", None)

    # Directories for terraform and creds
    cwd = os.getcwd()
    parent_dir = os.path.dirname(cwd)
    DIRECTORIES = {}
    DIRECTORIES["INFRA_HOSTMON"] = os.path.join(
        parent_dir, "aws/host_monitoring/ec2/terraform"
    )
    DIRECTORIES["OBSERVE_HOSTMON"] = os.path.join(
        DIRECTORIES["INFRA_HOSTMON"], "observe/host_mon"
    )
    DIRECTORIES["OBSERVE_OTEL"] = os.path.join(
        DIRECTORIES["INFRA_HOSTMON"], "observe/quickstart"
    )
    DIRECTORIES["HOME"] = config("HOME", "unknown_home_directory")

    # File names written by Terraform
    FILES = {}
    FILES["OBSERVE_HOSTMON"] = {}
    FILES["OBSERVE_HOSTMON"]["NAME_FORMAT"] = "observe_name_format_hostmon"
    FILES["OBSERVE_HOSTMON"]["TOKEN"] = "observe_datastream_token_hostmon"

    FILES["INFRA_HOSTMON"] = {}
    FILES["INFRA_HOSTMON"]["MACHINE_COUNT"] = "aws_machines_host_mon_count"

    # Environment for sending test results to
    O2_OBSERVE_CUSTOMER = config("O2_OBSERVE_CUSTOMER", default="102")
    O2_OBSERVE_TOKEN = config("O2_OBSERVE_TOKEN")
    O2_OBSERVE_DOMAIN = config("O2_OBSERVE_DOMAIN", default="observe-o2.com")

    def __init__(self):

        logging.debug(f"OBSERVE_CUSTOMER={self.OBSERVE_CUSTOMER}")
        logging.debug(f"OBSERVE_DOMAIN={self.OBSERVE_DOMAIN}")
        logging.debug(f"OBSERVE_USER_EMAIL={self.OBSERVE_USER_EMAIL}")

    @classmethod
    def IN_CI(self):
        ci = config("CI", default=None)

        return True if ci == None else False

    @classmethod
    def ROOT_PATH(self):
        """
        Create paths for executing queries
        """
        if ".com" not in self.OBSERVE_DOMAIN:
            return f"https://{self.OBSERVE_CUSTOMER}.{self.OBSERVE_DOMAIN}.com"
        else:
            return f"https://{self.OBSERVE_CUSTOMER}.{self.OBSERVE_DOMAIN}"

    def COLLECT_PATH(self):
        return (
            f"https://{self.O2_OBSERVE_CUSTOMER}.collect.{self.O2_OBSERVE_DOMAIN}.com"
            if ".com" not in self.O2_OBSERVE_DOMAIN
            else f"https://{self.O2_OBSERVE_CUSTOMER}.collect.{self.O2_OBSERVE_DOMAIN}"
        )

    @classmethod
    def META_URL(self):
        """GQL endpoint"""
        return f"https://{self.OBSERVE_CUSTOMER}.{self.OBSERVE_DOMAIN}/v1/meta"

    @classmethod
    def get_token(self):
        """
        Get bearer token from Observe
        """
        if self.BEARER_TOKEN != None:
            return self.BEARER_TOKEN

        url = f"{self.ROOT_PATH()}/v1/login"

        logging.debug(f"get_token url={url}")

        credentials = {
            "user_email": self.OBSERVE_USER_EMAIL,
            "user_password": self.OBSERVE_USER_PASSWORD,
            "tokenName": "Testing queries",
        }

        response = requests.post(url, json=credentials)

        return response.json(cls=ndjson.Decoder)[0]["access_key"]


class HostTester:
    """
    Provide methods for spin up and tear down of test resources
    """

    auth = authenticator()
    toke = auth.get_token()

    def __init__(self):

        logging.debug(f"HostTester Init")

    @classmethod
    def get_client(self):
        """
        Get GQL client
        """
        return Client(
            transport=RequestsHTTPTransport(
                url=self.META_URL(),
                retries=3,
                headers={
                    "Authorization": f"""Bearer {self.auth.OBSERVE_CUSTOMER} {self.auth.get_token()}"""
                },
            ),
            fetch_schema_from_transport=True,
        )

    @classmethod
    def get_headers(self):
        """Get auth headers"""
        return {
            "Authorization": f"Bearer {self.auth.OBSERVE_CUSTOMER} {self.auth.get_token()}",
            "Content-type": "application/json",
        }
