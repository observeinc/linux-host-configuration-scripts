from package.utils import authenticator, logging, HostTester, TASKS
from decouple import config
from pprint import pprint
from datetime import datetime
import requests
import ndjson
import os

HostTest = HostTester()


class ObserveQueries:
    auth = authenticator()

    values = {}
    # How long to wait for successful test result
    values["WAIT_FOR_DATA_MINUTES"] = None
    # Sleep time in between queries
    values["LOOP_SLEEP_SECONDS"] = None
    # timeframe for queries to Observe
    values["QUERY_TIMEFRAME"] = None
    # Number of machines to multiply expected rows by
    values["HOST_MON_MACHINE_COUNT"] = 1
    values["QUICKSTART_MACHINE_COUNT"] = 1
    values["HOST_MON_PREFIX"] = None
    values["QUICKSTART_PREFIX"] = None

    def __init__(
        self,
        WAIT_FOR_DATA_MINUTES: int = 10,
        LOOP_SLEEP_SECONDS: int = 30,
        QUERY_TIMEFRAME: str = "60m",
    ):

        self.set_values(TASKS.OBSERVE_HOSTMON)
        self.set_values(TASKS.INFRA_HOSTMON)
        self.values["WAIT_FOR_DATA_MINUTES"] = WAIT_FOR_DATA_MINUTES
        self.values["LOOP_SLEEP_SECONDS"] = LOOP_SLEEP_SECONDS
        self.values["QUERY_TIMEFRAME"] = QUERY_TIMEFRAME
        self.values["QUERY_URL"] = (
            f"{self.auth.ROOT_PATH()}/v1/meta/export/query?interval={self.get_values('QUERY_TIMEFRAME')}"
        )

        logging.debug(
            "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
        )
        # logging.debug(f"WAIT_FOR_DATA_MINUTES={self.WAIT_FOR_DATA_MINUTES}")
        # logging.debug(f"LOOP_SLEEP_SECONDS={self.LOOP_SLEEP_SECONDS}")
        # logging.debug(f"QUERY_TIMEFRAME={self.QUERY_TIMEFRAME}")
        for k, v in self.values.items():
            logging.debug(f"{k}={v}")
        # logging.debug(f"HOST_MON_MACHINE_COUNT={self.values["HOST_MON_MACHINE_COUNT"]}")
        logging.debug(f"O2_OBSERVE_CUSTOMER={self.auth.O2_OBSERVE_CUSTOMER}")
        logging.debug(f"O2_OBSERVE_DOMAIN={self.auth.O2_OBSERVE_DOMAIN}")
        logging.debug(f'HOST_MON_PREFIX={self.get_values("HOST_MON_PREFIX")}')
        logging.debug(
            "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
        )

    @classmethod
    def get_values(self, value):
        return self.values[value]

    @classmethod
    def set_values(self, task: TASKS):
        if task in (TASKS.OBSERVE_HOSTMON, TASKS.OBSERVE_OTEL):
            file_path_name_format_ = f'{self.auth.DIRECTORIES[task.name]}/{self.auth.FILES[task.name]["NAME_FORMAT"]}'
            # file_path_token = f'{self.auth.DIRECTORIES[task.name]}/{self.auth.FILES[task.name]["TOKEN"]}'

            logging.debug(
                f'Path to {self.auth.FILES[task.name]["TOKEN"]} file - {file_path_name_format_}'
            )
            # Prefix for datasets to query
            if os.path.isfile(file_path_name_format_):
                with open(file_path_name_format_, "r", encoding="utf-8") as outfile:
                    if task == TASKS.OBSERVE_HOSTMON:
                        self.values["HOST_MON_PREFIX"] = outfile.read().replace(
                            "/%s", ""
                        )
                        logging.debug(self.values["HOST_MON_PREFIX"])
                    if task == TASKS.OBSERVE_OTEL:
                        self.values["QUICKSTART_PREFIX"] = outfile.read().replace(
                            "/%s", ""
                        )
                        logging.debug(self.values["QUICKSTART_PREFIX"])

        if task in (TASKS.INFRA_HOSTMON, TASKS.INFRA_OTEL):
            file_path_machine_count = f'{self.auth.DIRECTORIES[task.name]}/{self.auth.FILES[task.name]["MACHINE_COUNT"]}'

            logging.debug(
                f'Path to {self.auth.FILES[task.name]["MACHINE_COUNT"]} file - {file_path_machine_count}'
            )

            if os.path.isfile(file_path_machine_count):
                with open(file_path_machine_count, "r", encoding="utf-8") as outfile:
                    if task == TASKS.INFRA_HOSTMON:
                        self.values["HOST_MON_MACHINE_COUNT"] = int(outfile.read())
                        logging.debug(
                            "Machine Count = ", self.values["HOST_MON_MACHINE_COUNT"]
                        )
                    if task == TASKS.INFRA_OTEL:
                        self.QUICKSTART_MACHINE_COUNT = int(outfile.read())
                        logging.debug("Machine Count = ", self.QUICKSTART_MACHINE_COUNT)

    @classmethod
    def make_query(self, test_start_time, integration):

        # Test dictionary
        tests = self.integration_tests()

        url = self.values["QUERY_URL"]
        logging.debug(f"make_query url={url}")

        all_tests_passed = "True"

        result = {}

        for test in tests[integration]:
            result[test] = {}
            headers = HostTest.get_headers()
            logging.debug(headers)

            response = requests.post(
                url,
                json=tests[integration][test]["query"],
                headers=HostTest.get_headers(),
            )
            items = response.json(cls=ndjson.Decoder)

            logging.debug("###############################################")
            logging.debug(f"# integration name =   {integration} #")
            logging.debug(f"# test name =   {test} #")
            logging.debug(tests[integration][test]["query"])
            logging.debug("-----------------------------------------------")
            logging.debug(pprint(items))
            logging.debug("###############################################")

            result[test]["expected_row_count"] = int(
                tests[integration][test]["expected_row_count"]
            ) * int(self.values["HOST_MON_MACHINE_COUNT"])

            result[test]["result"] = len(items) == result[test]["expected_row_count"]

            result[test]["result_count"] = len(items)
            all_tests_passed += f' and {str(result[test]["result"])}'

        result["all_tests_passed"] = all_tests_passed

        result["test_run_time"] = {}

        # dd/mm/YY H:M:S
        start_time_fmt = test_start_time.strftime("%d/%m/%Y %H:%M:%S")
        logging.debug(f"start_time_fmt =={start_time_fmt}")

        # datetime object containing current date and time
        end_time = datetime.now()
        end_time_fmt = end_time.strftime("%d/%m/%Y %H:%M:%S")
        logging.debug(f"end_time =={end_time_fmt}")

        # get difference
        delta = end_time - test_start_time
        delta_time_fmt = str(delta)
        logging.debug(f"delta_time_fmt =={delta_time_fmt}")

        # time difference in seconds
        logging.debug(f"Time difference is {delta.total_seconds()} seconds")

        result["test_run_time"]["start_time"] = start_time_fmt
        result["test_run_time"]["end_time"] = end_time_fmt
        result["test_run_time"]["delta_time"] = delta_time_fmt

        return result

    @classmethod
    def post_results_to_observe(self, results):

        timestamp = {}
        timestamp["hostmon"] = {}
        timestamp["hostmon"]["fluent_min_timestamp"] = {}
        timestamp["hostmon"]["fluent_min_timestamp"]["expected_row_count"] = 1
        timestamp["hostmon"]["fluent_min_timestamp"]["query"] = {
            "query": {
                "outputStage": "count",
                "stages": [
                    {
                        "input": [
                            {
                                "inputName": "fluentevents",
                                "datasetPath": f"Default.{self.get_values('HOST_MON_PREFIX')}/Fluentbit Events",
                            },
                        ],
                        "stageID": "count",
                        "pipeline": f"""
                            statsby min(timestamp), group_by(name)
                         """,
                    }
                ],
            },
            "rowCount": "1000",
        }

        headers = HostTest.get_headers()
        logging.debug(headers)
        url = self.values["QUERY_URL"]
        response = requests.post(
            url,
            json=timestamp["hostmon"]["fluent_min_timestamp"]["query"],
            headers=HostTest.get_headers(),
        )
        items = response.json(cls=ndjson.Decoder)

        results["timestamp"] = items

        ################################################################

        url = f"{self.auth.COLLECT_PATH()}/v1/http/host-mon"

        headers = {
            "Authorization": f"Bearer {self.auth.O2_OBSERVE_TOKEN}",
            "Content-type": "application/json",
        }

        response = requests.post(url, json=results, headers=headers)
        status_code = response.status_code
        logging.debug(f"Response status code =  {status_code}")

    @classmethod
    def integration_tests(self):
        tests = {}
        tests["hostmon"] = {}
        tests["hostmon"]["install_complete"] = {}
        tests["hostmon"]["install_complete"]["expected_row_count"] = 1
        tests["hostmon"]["install_complete"]["query"] = {
            "query": {
                "outputStage": "count",
                "stages": [
                    {
                        "input": [
                            {
                                "inputName": "fluentlogs",
                                "datasetPath": f"Default.{self.get_values('HOST_MON_PREFIX')}/Fluentbit Logs",
                            },
                        ],
                        "stageID": "count",
                        "pipeline": f"""
filter label(^logfile) = "/tmp/hostmon_install_complete.log"

merge_events match_regex(message, /^\d{{4}}-\d{{2}}-\d{{2}}/),
    options(max_size: 1000, max_interval: 1m),
    logMessageMultiline:string_agg(message, '\\n'),
    order_by(timestamp),
    group_by(^Host...)
    """,
                    }
                ],
            },
            "rowCount": "1000",
        }
        tests["hostmon"]["fluent"] = {}
        tests["hostmon"]["fluent"]["expected_row_count"] = 4
        tests["hostmon"]["fluent"]["query"] = {
            "query": {
                "outputStage": "count",
                "stages": [
                    {
                        "input": [
                            {
                                "inputName": "fluentevents",
                                "datasetPath": f"Default.{self.get_values('HOST_MON_PREFIX')}/Fluentbit Events",
                            },
                        ],
                        "stageID": "count",
                        "pipeline": f"""
                            make_col ec2_instance_id:string(tags.ec2_instance_id)\n
                            statsby lines: count(1), group_by(inputType,ec2_instance_id)
                         """,
                    }
                ],
            },
            "rowCount": "1000",
        }

        tests["hostmon"]["osquery"] = {}
        tests["hostmon"]["osquery"]["expected_row_count"] = 11
        tests["hostmon"]["osquery"]["query"] = {
            "query": {
                "outputStage": "count",
                "stages": [
                    {
                        "input": [
                            {
                                "inputName": "osquery",
                                "datasetPath": f"Default.{self.get_values('HOST_MON_PREFIX')}/OSQuery Events",
                            },
                        ],
                        "stageID": "count",
                        "pipeline": f"""
                            make_col ec2_instance_id:string(tags.ec2_instance_id)\n
                            filter not name = "shell_history"\n
                            statsby lines: count(1), group_by(name,ec2_instance_id)
                            """,
                    }
                ],
            },
            "rowCount": "1000",
        }

        tests["hostmon"]["telegraf"] = {}
        tests["hostmon"]["telegraf"]["expected_row_count"] = 11
        tests["hostmon"]["telegraf"]["query"] = {
            "query": {
                "outputStage": "count",
                "stages": [
                    {
                        "input": [
                            {
                                "inputName": "telegrafvents",
                                "datasetPath": f"Default.{self.get_values('HOST_MON_PREFIX')}/Telegraf Events",
                            },
                        ],
                        "stageID": "count",
                        "pipeline": f"""
                            make_col host:string(tags.host)\n
                            statsby lines: count(1), group_by(name,host)
                            """,
                    }
                ],
            },
            "rowCount": "1000",
        }
        return tests
