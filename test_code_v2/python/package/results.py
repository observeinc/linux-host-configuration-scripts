from package.utils import logging, authenticator
import os


class Results:
    auth = authenticator()

    # create markdown for test results
    sum_results = f"""
# TEST RUN \n
|Integration| Event | Time |
|----------|----------|----------|
    """

    def __init__(self):
        logging.debug("Results init")

    @classmethod
    def summarize_results(self, test_results):
        for integration in test_results:
            logging.debug(f"----------- {integration} --------------------")
            for test in test_results[integration]:
                logging.debug("-----------Run Time-------------")

                logging.debug(
                    f'StartTime = {test_results[integration]["test_run_time"]["start_time"]}'
                )
                logging.debug(
                    f'EndTime = {test_results[integration]["test_run_time"]["end_time"]}'
                )
                logging.debug(
                    f'Difference = {test_results[integration]["test_run_time"]["delta_time"]}'
                )
                logging.debug("--------------------------------")

        # determine if all tests passed with boolean string that is appended to by loop
        agg_results = "True"

        # queries file has tests by integration - test_results is returned by main()
        for integration in test_results:
            # write to markdown file
            self.sum_results += f"""|{integration}| StartTime | {test_results[integration]["test_run_time"]["start_time"]}' |
            |{integration}| EndTime | {test_results[integration]["test_run_time"]["end_time"]}' |
            |{integration}| Difference | {test_results[integration]["test_run_time"]["delta_time"]}' |

| Test      | Result |
|----------|----------|\n"""
            # loop each test for integration
            for test in test_results[integration]:

                if test != "all_tests_passed" and test != "test_run_time":
                    type = {}
                    type["pass_fail"] = {}
                    type["pass_fail"]["result"] = test_results[integration][test][
                        "result"
                    ]

                    type["expected_actual"] = {}
                    type["expected_actual"]["expected"] = test_results[integration][
                        test
                    ]["expected_row_count"]
                    type["expected_actual"]["actual"] = test_results[integration][test][
                        "result_count"
                    ]

                    self.write_row(test, type)
                elif test == "all_tests_passed":
                    agg_results += f" and {eval(test_results[integration][test])}"
                else:
                    None
        logging.debug(agg_results)
        return agg_results, self.sum_results

    @classmethod
    def write_row(self, test, type):
        keys = type.keys()

        for key in keys:
            if key == "pass_fail":
                if type[key]["result"]:
                    self.sum_results += f"| {test} |'Pass ✅' |\n"
                else:
                    self.sum_results += f"| {test} |'Fail ❌' |\n"

            if key == "expected_actual":
                self.sum_results += f'| expected: {type[key]["expected"]} | actual: {type[key]["actual"]}  |\n'

        return None

    @classmethod
    def write_agg_results_to_gitHubActions_environment_variable(self, agg_result):
        """Write to environment variable file in Github actions or local file"""
        # Check if script executing in GitHub Actions
        am_i_in_ci = os.getenv("CI")

        # file paths for local development
        env_file = "envfile.md"

        if am_i_in_ci == "true":
            env_file = os.getenv("GITHUB_ENV")

        # Set TEST_RESULT environment variable in GitHub Actions
        with open(env_file, "w") as environmentFile:
            environmentFile.write(f"TEST_RESULT={agg_result}")

    @classmethod
    def write_results_to_gitHubActions_summary_file(self, sumfile):
        # file paths for local development
        gha_sum_file = "summaryfile.md"

        # Check if script executing in GitHub Actions
        if self.auth.IN_CI == "true":
            gha_sum_file = os.getenv("GITHUB_STEP_SUMMARY")

        # open both files
        with open(gha_sum_file, "w") as gitHubActionsSummaryFile:
            gitHubActionsSummaryFile.seek(0)
            gitHubActionsSummaryFile.write(sumfile)
