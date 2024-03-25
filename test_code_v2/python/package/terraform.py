from package.utils import authenticator, logging, TASKS
from decouple import config
import os
from python_on_whales import docker


class RunTerraform:
    """
    Methods for running terraform tasks
    """

    auth = authenticator()

    @classmethod
    def run_docker(self, task: TASKS, destroy: bool = False, outputs: bool = False):

        env_vars = self.get_env_vars()
        volumes = self.get_volumes()

        name = f"docker_run_not_ci"

        # Check if running in CI environment
        if self.auth.IN_CI == True:
            name = f"docker_run_ci"
            self.set_override_file(task)

        tf_command = (
            ["destroy", "-auto-approve"]
            if destroy == True
            else ["output", "-json"] if outputs == True else ["apply", "-auto-approve"]
        )

        commands = {}
        commands["INFRA_HOSTMON"] = [["init"], tf_command]
        commands["OBSERVE_HOSTMON"] = [["init"], tf_command]
        commands["OBSERVE_OTEL"] = [["init"], tf_command]

        for command in commands[task.name]:

            docker.run(
                "hashicorp/terraform:1.6",
                command,
                name=name,
                envs=env_vars[task.name],
                detach=False,
                volumes=volumes[task.name],
                workdir="/workspace",
                remove=True,
                interactive=True,
                tty=True,
            )

    @classmethod
    def get_volumes(self):
        """Volume mounts by task name."""
        auth = authenticator()
        volumes = {}
        volumes["INFRA_HOSTMON"] = [
            (auth.DIRECTORIES[TASKS.INFRA_HOSTMON.name], "/workspace"),
            (f'{auth.DIRECTORIES["HOME"]}/.aws', "/aws_creds"),
        ]
        volumes["OBSERVE_HOSTMON"] = [
            (auth.DIRECTORIES[TASKS.OBSERVE_HOSTMON.name], "/workspace")
        ]
        volumes["OBSERVE_OTEL"] = [
            (auth.DIRECTORIES[TASKS.OBSERVE_OTEL.name], "/workspace")
        ]

        return volumes

    @classmethod
    def get_env_vars(self):
        """Environment variables by task name and whether in CI environment"""
        IN_CI = config("CI", default=None)

        auth = authenticator()

        env_vars = {}
        env_vars["ci_env_vars"] = {}

        env_vars["INFRA_HOSTMON"] = {}
        env_vars["OBSERVE_HOSTMON"] = {}
        env_vars["OBSERVE_OTEL"] = {}

        if IN_CI != None:
            ################################
            # INFRA_HOSTMON
            ################################
            env_vars["INFRA_HOSTMON"]["AWS_ACCESS_KEY_ID"] = config(
                "AWS_ACCESS_KEY_ID", default=None
            )
            env_vars["INFRA_HOSTMON"]["AWS_DEFAULT_REGION"] = config(
                "AWS_DEFAULT_REGION", default=None
            )
            env_vars["INFRA_HOSTMON"]["AWS_SECRET_ACCESS_KEY"] = config(
                "AWS_SECRET_ACCESS_KEY", default=None
            )
            env_vars["INFRA_HOSTMON"]["AWS_SESSION_TOKEN"] = config(
                "AWS_SESSION_TOKEN", default=None
            )
            ################################

        else:
            ################################
            # INFRA_HOSTMON
            ################################
            env_vars["INFRA_HOSTMON"][
                "AWS_SHARED_CREDENTIALS_FILE"
            ] = "/aws_creds/credentials"
            env_vars["INFRA_HOSTMON"]["AWS_PROFILE"] = "dce -w /workspace"
            ################################

        ################################
        # INFRA_HOSTMON
        ################################
        env_vars["INFRA_HOSTMON"]["AWS_REGION"] = "us-west-2"
        file_path = f"{auth.DIRECTORIES[TASKS.OBSERVE_HOSTMON.name]}/observe_datastream_token_hostmon"
        logging.debug(f"Path to observe_datastream_token_hostmon file - {file_path}")
        if os.path.isfile(file_path):
            with open(
                file_path,
                "r",
                encoding="utf-8",
            ) as outfile:
                env_vars["INFRA_HOSTMON"][
                    "TF_VAR_OBSERVE_TOKEN_HOST_MONITORING"
                ] = outfile.read()
                logging.debug(
                    env_vars["INFRA_HOSTMON"]["TF_VAR_OBSERVE_TOKEN_HOST_MONITORING"]
                )

        # env_vars["TF_VAR_OBSERVE_TOKEN_OTEL"] = ""$$(cat $(QUICKSTART_OUTPUT_NAME))"
        env_vars["INFRA_HOSTMON"]["TF_VAR_OBSERVE_CUSTOMER"] = auth.OBSERVE_CUSTOMER
        env_vars["INFRA_HOSTMON"]["TF_VAR_OBSERVE_DOMAIN"] = auth.OBSERVE_DOMAIN
        env_vars["INFRA_HOSTMON"]["TF_VAR_FULL_PATH"] = auth.DIRECTORIES[
            TASKS.INFRA_HOSTMON.name
        ]
        env_vars["INFRA_HOSTMON"]["TF_VAR_CREATE_HOST_MON"] = "true"
        ################################
        # OBSERVE_HOSTMON
        ################################
        env_vars["OBSERVE_HOSTMON"]["OBSERVE_CUSTOMER"] = auth.OBSERVE_CUSTOMER
        env_vars["OBSERVE_HOSTMON"]["OBSERVE_DOMAIN"] = auth.OBSERVE_DOMAIN
        env_vars["OBSERVE_HOSTMON"]["OBSERVE_USER_EMAIL"] = auth.OBSERVE_USER_EMAIL
        env_vars["OBSERVE_HOSTMON"][
            "OBSERVE_USER_PASSWORD"
        ] = auth.OBSERVE_USER_PASSWORD
        env_vars["OBSERVE_HOSTMON"]["AWS_ACCESS_KEY_ID"] = config(
            "AWS_ACCESS_KEY_ID", default=None
        )
        env_vars["OBSERVE_HOSTMON"]["AWS_DEFAULT_REGION"] = config(
            "AWS_DEFAULT_REGION", default=None
        )
        env_vars["OBSERVE_HOSTMON"]["AWS_SECRET_ACCESS_KEY"] = config(
            "AWS_SECRET_ACCESS_KEY", default=None
        )
        env_vars["OBSERVE_HOSTMON"]["AWS_SESSION_TOKEN"] = config(
            "AWS_SESSION_TOKEN", default=None
        )
        ################################

        ################################
        # OBSERVE_OTEL
        ################################
        env_vars["OBSERVE_OTEL"]["OBSERVE_CUSTOMER"] = auth.OBSERVE_CUSTOMER
        env_vars["OBSERVE_OTEL"]["OBSERVE_DOMAIN"] = auth.OBSERVE_DOMAIN
        env_vars["OBSERVE_OTEL"]["OBSERVE_USER_EMAIL"] = auth.OBSERVE_USER_EMAIL
        env_vars["OBSERVE_OTEL"]["OBSERVE_USER_PASSWORD"] = auth.OBSERVE_USER_PASSWORD
        env_vars["OBSERVE_OTEL"]["AWS_ACCESS_KEY_ID"] = config(
            "AWS_ACCESS_KEY_ID", default=None
        )
        env_vars["OBSERVE_OTEL"]["AWS_DEFAULT_REGION"] = config(
            "AWS_DEFAULT_REGION", default=None
        )
        env_vars["OBSERVE_OTEL"]["AWS_SECRET_ACCESS_KEY"] = config(
            "AWS_SECRET_ACCESS_KEY", default=None
        )
        env_vars["OBSERVE_OTEL"]["AWS_SESSION_TOKEN"] = config(
            "AWS_SESSION_TOKEN", default=None
        )
        ################################
        return env_vars

    @classmethod
    def set_override_file(self, task: TASKS):
        """Set overide files for state if running in CI environment"""
        auth = authenticator()
        GITHUB_REF = config("GITHUB_REF", default=None)

        if task.name == "OBSERVE_HOSTMON":
            with open(
                f"{auth.OBSERVE_HOSTMON_DIRECTORY}/override.tf", "w", encoding="utf-8"
            ) as outfile:
                outfile.write(
                    f"""
                    terraform {{
                        backend "s3" {{
                            bucket = "thunderdome-terraform-state"
                            region = "us-west-2"
                            key    = "content-eng/gha/host_test/OBSERVE_HOSTMON{GITHUB_REF}"
                        }}
                        required_providers {{
                            random = {{
                                version = ">= 3"
                            }}
                        observe = {{
                            source  = "terraform.observeinc.com/observeinc/observe"
                            version = "~> 0.13"
                        }}
                        }}
                        required_version = ">= 0.13"
                        }}       
                        """
                )
        elif task.name == "INFRA_HOSTMON":
            with open(
                f"{auth.INFRA_DIRECTORY}/override.tf", "w", encoding="utf-8"
            ) as outfile:
                outfile.write(
                    f"""
                    terraform {{
                        backend "s3" {{
                            bucket = "thunderdome-terraform-state"
                            region = "us-west-2"
                            key    = "content-eng/gha/host_test/infra{GITHUB_REF}"
                        }}
                        required_providers {{
                            aws = {{
                                source  = "hashicorp/aws"
                                version = "~> 4.11"
                        }}

                        random = {{
                            source  = "hashicorp/random"
                            version = ">= 3.4.3"
                        }}
                        }}
                        required_version = ">= 1.2"
                    }}    
                        """
                )
        elif task.name == "OBSERVE_OTEL":
            with open(
                f"{auth.INFRA_DIRECTORY}/override.tf", "w", encoding="utf-8"
            ) as outfile:
                outfile.write(
                    f"""
                            terraform {{
                                backend "s3" {{
                                    bucket = "thunderdome-terraform-state"
                                    region = "us-west-2"
                                    key    = "content-eng/gha/host_test/infra{GITHUB_REF}"
                                }}
                                required_providers {{
                                    aws = {{
                                        source  = "hashicorp/aws"
                                        version = "~> 4.11"
                                }}

                                random = {{
                                    source  = "hashicorp/random"
                                    version = ">= 3.4.3"
                                }}
                                }}
                                required_version = ">= 1.2"
                            }}    
                                """
                )
