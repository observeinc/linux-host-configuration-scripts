import time

# import logging
from datetime import datetime

# from queries import integration_tests
from pprint import pprint
from package.utils import logging, TASKS
from package.terraform import RunTerraform
from package.queries import ObserveQueries

from package.results import Results


def main():
    observeQ = ObserveQueries(
        WAIT_FOR_DATA_MINUTES=15, QUERY_TIMEFRAME="24h", LOOP_SLEEP_SECONDS=30
    )
    start_time = time.time()
    minutes = float(observeQ.values["WAIT_FOR_DATA_MINUTES"]) * 60
    sleep_seconds = observeQ.values["LOOP_SLEEP_SECONDS"]
    end_time = start_time + minutes

    tests_results = {}

    # datetime object containing current date and time
    test_start_time = datetime.now()
    # dd/mm/YY H:M:S
    test_start_time_fmt = test_start_time.strftime("%d/%m/%Y %H:%M:%S")
    logging.debug(f"start_time =={test_start_time_fmt}")

    while time.time() < end_time:
        tests = observeQ.integration_tests()
        for integration in tests:
            tests_results[integration] = observeQ.make_query(
                test_start_time, integration
            )

            logging.debug(pprint(tests_results))
            if eval(tests_results[integration]["all_tests_passed"]):

                logging.debug(
                    f'all_tests_passed = {eval(tests_results[integration]["all_tests_passed"])}. Exiting loop.'
                )
                return tests_results

            logging.debug(f"Sleeping {sleep_seconds} seconds")

            time.sleep(sleep_seconds)  # Sleep for 1 second to avoid busy waiting

    else:
        logging.debug(f"{minutes} minutes elapsed. Exiting loop.")
        return tests_results


if __name__ == "__main__":

    # get runner for Terraform
    runner = RunTerraform()

    # create Observe Hostmon content on target environment
    runner.run_docker(TASKS.OBSERVE_HOSTMON)
    # create virtual machines with agents installed using token from Observe
    runner.run_docker(TASKS.INFRA_HOSTMON)

    # runner.run_docker(TASKS.INFRA_HOSTMON, outputs=True)

    test_results = main()
    logging.debug(pprint(test_results))

    agg_results, sum_results = Results.summarize_results(test_results)

    Results.write_agg_results_to_gitHubActions_environment_variable(
        "PASS" if eval(agg_results) else "FAIL"
    )

    Results.write_results_to_gitHubActions_summary_file(sum_results)

    ObserveQueries.post_results_to_observe(test_results)

    logging.debug(print(sum_results))

    runner.run_docker(TASKS.INFRA_HOSTMON, destroy=True)
    runner.run_docker(TASKS.OBSERVE_HOSTMON, destroy=True)
