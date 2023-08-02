#!/usr/bin/env python3


from multiprocessing.pool import ThreadPool as Pool
import json
import configparser
import pprint
import os
import glob
import time
import traceback

from fabric import Connection
from fabric import task

import logging
import sys



def mask_password(data):
    masked_data = data.copy()
    password = masked_data.get("password")
    if password:
        masked_data["password"] = "*" * 5
    return masked_data

def getPowerShellScript(service_name):
    powershell_script = f'''
    $serviceName = "{service_name}"

    $service = Get-Service -Name $serviceName

    if ($service -ne $null -and $service.Status -eq "Running") {{
        Write-Output "PASS"
    }} else {{
        Write-Output "FAIL"
    }}
    '''

    return powershell_script


def getObserveConfig(config, environment):
    """Fetches config file"""
    # Set your Observe environment details in config\configfile.ini
    configuration = configparser.ConfigParser()
    configuration.read("config.ini")
    observe_configuration = configuration[environment]

    return observe_configuration[config]


def getCurlCommand(options):
    """Create command for running install script"""
    OBSERVE_CUSTOMER = getObserveConfig("customer_id", options["ENVIRONMENT"])
    OBSERVE_TOKEN = getObserveConfig(
        "datastream_token", options["ENVIRONMENT"]
    )
    DOMAIN = getObserveConfig("domain", options["ENVIRONMENT"])

    FLAGS = {
        "config_files_clean": "TRUE",
        "ec2metadata": "TRUE",
        "datacenter": "FAB_DATA_CENTER",
        "appgroup": "FAB_APP_GROUP",
        "cloud_metadata": "TRUE",
    }

    if "FLAGS" in options:
        FLAGS.update(options["FLAGS"])
    if options["IS_WINDOWS"]:
        curl_command = f'[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"; Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/observeinc/windows-host-configuration-scripts/{options["WINDOWS_BRANCH"]}/agents.ps1" -outfile .\\agents.ps1; .\\agents.ps1  -ingest_token {OBSERVE_TOKEN} -customer_id {OBSERVE_CUSTOMER}  -observe_host_name https://{OBSERVE_CUSTOMER}.collect.{DOMAIN}.com/ -config_files_clean {FLAGS["config_files_clean"]} -ec2metadata {FLAGS["ec2metadata"]} -datacenter {FLAGS["datacenter"]} -appgroup {FLAGS["appgroup"]} -cloud_metadata {FLAGS["cloud_metadata"]} -force TRUE'
    else:
        curl_command = f'curl "https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/{options["BRANCH"]}/observe_configure_script.sh" | bash -s -- --customer_id {OBSERVE_CUSTOMER} --ingest_token {OBSERVE_TOKEN} --observe_host_name https://{OBSERVE_CUSTOMER}.collect.{DOMAIN}.com/ --config_files_clean {FLAGS["config_files_clean"]} --ec2metadata {FLAGS["ec2metadata"]} --datacenter {FLAGS["datacenter"]} --appgroup {FLAGS["appgroup"]} --cloud_metadata {FLAGS["cloud_metadata"]} --branch_input {options["BRANCH"]}'

    logging.info(
        "curl command = %s", curl_command.replace(OBSERVE_TOKEN, "*****")
    )


    return curl_command


# your "parallelness"
pool_size = 20
pool = Pool(pool_size)

# folder to write files to
outputs_folder_name = "file_outputs"

logs_folder_name = "log_outputs"


# files
tf_apply_error_output = f"python_scripts/{outputs_folder_name}/tf_apply_error.txt"
tf_destroy_error_output = f"python_scripts/{outputs_folder_name}/tf_destroy_error.txt"
tf_apply_output = f"python_scripts/{outputs_folder_name}/tf_apply.txt"
tf_destroy_output = f"python_scripts/{outputs_folder_name}/tf_destroy.txt"
test_results_file_name = f"{outputs_folder_name}/test_results.json"

test_fail_message = "FAIL"
test_pass_message = "PASS"


def folderCleanup():
    """Clean out file ouputs on each run"""
    files = glob.glob(f"{outputs_folder_name}/*")
    for f in files:
        os.remove(f)


def terraformOutput(fileName="tf_hosts.json"):
    """Run terraform output command"""
    # run output to file that is read by test
    logging.info("Running terraform output")
    os.system(
        f"cd ../; terraform output -json | jq -r '.fab_host_all.value' > python_scripts/{fileName}"
    )


seperator = "################################"


def log_file_name(path_pattern):
    """
    Naive (slow) version of next_path
    """
    i = 1
    while os.path.exists(path_pattern % i):
        i += 1
    return path_pattern % i


@task
def test(
    ctx,
    fileName="tf_hosts.json",
    branch="main",
    windowsBranch="main",
    runTerraform="false",
    sleep=300,
    runTerraformDestroy="false",
    runTerraformOutput="true",
    failMe="false",
    outPutTitleAppend="1",
    log_level="INFO",
    config_ini_environment="target-stage-tenant",
):
    """Run a test of install script"""

    # Level
    ## DEBUG - Detailed information, typically of interest only when diagnosing problems
    ## INFO - Confirmation that things are working as expected.
    ## WARNING - An indication that something unexpected happened, or indicative of some problem in the near future (e.g. ‘disk space low’). The software is still working as expected.
    ## ERROR - Due to a more serious problem, the software has not been able to perform some function.
    ## CRITICAL - A serious error, indicating that the program itself may be unable to continue running.

    log_levels = {}
    log_levels["DEBUG"] = logging.DEBUG
    log_levels["INFO"] = logging.INFO
    log_levels["WARNING"] = logging.WARNING
    log_levels["ERROR"] = logging.ERROR
    log_levels["CRITICAL"] = logging.CRITICAL

    log_path_pattern = f"{logs_folder_name}/test-log-%s.log"
    log_path = log_file_name(log_path_pattern)

    logging.basicConfig(
        # filename=log_path,
        format="%(asctime)s %(levelname)s %(filename)s:%(lineno)d %(message)s",
        datefmt="%m/%d/%Y %I:%M:%S %p",
        # encoding="utf-8",
        level=log_levels[log_level],
        handlers=[logging.FileHandler(log_path), logging.StreamHandler(sys.stdout)],
    )

    logging.info(
        f"STARTING: log_level={log_level}"
    )  # will print a message to the console

    # delete files from last run
    folderCleanup()

    if runTerraform == "true":
        try:
            # run terraform appy to create infrastructure
            logging.info(
                f"Running terraform apply: stderr_file={tf_apply_error_output} stdout_file={tf_apply_output}"
            )

            os.system(
                f'cd ../; export TF_LOG="ERROR"; terraform apply -auto-approve 2> {tf_apply_error_output} 1> {tf_apply_output}'
            )

            logging.info("Terraform apply complete")

            # Give compute instances a minute (TODO - Move this into test runs as different os vary - can it be deterministic?)
            logging.info(f"Wait {sleep} seconds for machines to instantiate ...")
            time.sleep(sleep)

        except Exception as e:
            logging.error("Terraform Flamed")  # will print a message to the console
            logging.error(e.message)
            logging.error(e.args)
            traceback.print_exception(e)
            logging.error(f"Error output written to {tf_apply_error_output}")
            exit()

    try:
        logging.info(f"Wait {sleep} seconds for machines to instantiate ...")
        time.sleep(sleep)

        if runTerraformOutput == "true":
            terraformOutput(fileName)
        # open output
        with open(fileName) as json_file:
            hosts = json.load(json_file)

            # dict for results of commands
            test_results = {}

            # loop through machines
            for key in hosts:
                # add connect info for host to results
                test_results[key] = {}
                test_results[key]["public_ssh_link"] = hosts[key]["public_ssh_link"]

                sleep = 1

                ec2metadata = "FALSE"
                datacenter = "FAB_DC"
                appgroup = "FAB_APP_GROUP"
                config_files_clean = "TRUE"
                is_windows = True if "WINDOWS" in key.upper() else False


                if "GCP" in key:
                    datacenter = "GCP"

                if "AWS" in key:
                    ec2metadata = "TRUE"
                    datacenter = "AWS"

                if "AZURE" in key:
                    datacenter = "AZURE"

                # create command for install of linux host script
                curl_cmd = getCurlCommand(
                    {
                        "ENVIRONMENT": config_ini_environment,
                        "BRANCH": branch,
                        "WINDOWS_BRANCH": windowsBranch,
                        "FLAGS": {
                            "config_files_clean": config_files_clean,
                            "ec2metadata": ec2metadata,
                            "datacenter": datacenter,
                            "appgroup": appgroup,
                        },
                        "IS_WINDOWS": is_windows
                    }
                )

                linux_test_commands = {
                   "tofile_curl": curl_cmd,
                   "fluent/tdagent": "if systemctl is-active --quiet td-agent-bit || systemctl is-active --quiet fluent-bit; then echo PASS; else echo FAIL; fi",
                   "osquery": "if systemctl is-active --quiet osqueryd; then echo PASS; else echo FAIL; fi",
                   "telegraf": "if systemctl is-active --quiet telegraf; then echo PASS; else echo FAIL; fi",
                   "tofile_telegraf_status": "sudo service telegraf status  | cat",
                   "tofile_osqueryd_status": "sudo service osqueryd status  | cat",
                   "tofile_td-agent-fluent-bit_status": "sudo service td-agent-bit status || true && sudo service fluent-bit status || true | cat"
                }



                windows_test_commands = {
                    "tofile_curl": curl_cmd,
                    "fluent/tdagent": getPowerShellScript('fluent-bit'),
                    "osquery": getPowerShellScript('osqueryd'),
                    "telegraf": getPowerShellScript('telegraf'),
                    "tofile_telegraf_status": "Get-Service telegraf ",
                    "tofile_osqueryd_status": "Get-Service osqueryd",
                    "tofile_td-agent-fluent-bit_status": "Get-Service fluent-bit"
                }

                if is_windows:
                    test_commands = windows_test_commands
                else:
                    test_commands = linux_test_commands

                # multitask pool - call doTest with parameters
                pool.apply_async(
                    doTest,
                    (
                        {
                            "host": hosts[key]["host"],
                            "user": hosts[key]["user"],
                            "connect_kwargs": hosts[key]["connect_kwargs"],
                            "commands": test_commands,
                            "key": key,
                            "sleep": sleep,
                            "log_level": log_level,
                        },
                        test_results,
                    ),
                )

            # wait for jobs to complete
            pool.close()
            pool.join()

            small_result = {}

            logging.debug(seperator)
            logging.debug("##### test_results #######")
            logging.debug(seperator)
            logging.debug(json.dumps(test_results, indent=4))
            logging.debug(seperator)

            # loop test results and detrmine if overall pass or fail
            # analyze results
            agg_result = test_pass_message
            agg_result = process_result(test_results, small_result, failMe)

            # file for producing markdown output for github actions
            sum_file = f"{outputs_folder_name}/small_result.md"

            write_to_local_summary_results_file(
                sum_file, small_result, outPutTitleAppend
            )

            write_agg_results_to_gitHubActions_environment_variable(agg_result)

            write_results_to_gitHubActions_summary_file(sum_file)

            logging.info(seperator)
            logging.info("########### TEST RESULTS ##############")
            logging.info(seperator)
            logging.info("###########  AGGREGATE   ##############")
            logging.info(agg_result)

            logging.info(json.dumps(small_result, indent=4))

            logging.info("###########  DETAIL   ##############")
            logging.info(json.dumps(test_results, indent=4))
            logging.info(seperator)
            logging.info(seperator)
            logging.info(seperator)

            # write results to file
            write_test_results_to_file(test_results_file_name, test_results)

    except Exception as e:
        logging.error(seperator)
        logging.error("Tests Flamed")
        traceback.print_exception(e)
        sum_file = f"{outputs_folder_name}/no_result.md"
        logging.error(seperator)

        with open(sum_file, "w+") as myfile:
            myfile.write(f"### Test Run Error\n")
            myfile.write(f"{e}")

        write_agg_results_to_gitHubActions_environment_variable("FAIL")

        write_results_to_gitHubActions_summary_file(sum_file)

    finally:
        if runTerraform == "true" and runTerraformDestroy == "true":
            logging.info("Running terraform destroy ...")

            logging.info(f"Error output written to {tf_destroy_error_output}")
            logging.info(f"Standard output written to {tf_destroy_output}")
            os.system(
                f'cd ../; export TF_LOG="ERROR"; terraform destroy -auto-approve 2> {tf_destroy_error_output} 1> {tf_destroy_output}'
            )

        logging.info(seperator)
        logging.info("FINISHED")  # will print a message to the console


################
################
def write_agg_results_to_gitHubActions_environment_variable(agg_result):
    """Write to environment variable file"""
    # Check if script executing in GitHub Actions
    am_i_in_ci = os.getenv("CI")

    # file paths for local development
    env_file = "file_outputs/envfile.md"

    if am_i_in_ci == "true":
        env_file = os.getenv("GITHUB_ENV")

    # Set TEST_RESULT environment variable in GitHub Actions
    with open(env_file, "a") as environmentFile:
        environmentFile.write(f"TEST_RESULT={agg_result}")


################
################
def write_results_to_gitHubActions_summary_file(sumfile):
    # Check if script executing in GitHub Actions
    am_i_in_ci = os.getenv("CI")

    # file paths for local development
    gha_sum_file = "file_outputs/summaryfile.md"

    if am_i_in_ci == "true":
        gha_sum_file = os.getenv("GITHUB_STEP_SUMMARY")

    # open both files
    with open(sumfile, "r") as localSummaryFile, open(
        gha_sum_file, "w"
    ) as gitHubActionsSummaryFile:
        gitHubActionsSummaryFile.seek(0)
        # read content from first file
        for line in localSummaryFile:
            # write content to second file
            gitHubActionsSummaryFile.write(line)


################
################
def process_result(test_results, small_result, failMe):
    """Process test reslts"""
    logging.info(seperator)
    logging.info("STARTING process_result...")  # will print a message to the console

    agg_result = test_pass_message

    # loop test results
    for key in test_results:
        # add key to result dictionary
        small_result[key] = {}

        for cmd in test_results[key]:
            logging.info("Command = %s", cmd)
            logging.info("Result = %s", test_results[key][cmd])

            # if fail set agg results to fail
            if test_fail_message in test_results[key][cmd]:
                logging.info(test_fail_message)
                agg_result = test_fail_message
                logging.info("agg_result = %s", agg_result)
            # add result to dictionary
            small_result[key][cmd] = test_results[key][cmd]

    if failMe == "true":
        agg_result = "FAIL"

    logging.info(seperator)
    logging.info("FINISHED process_result")  # will print a message to the console
    return agg_result


################
################
def write_test_results_to_file(test_results_file_name, test_results):
    # write results to file
    with open(test_results_file_name, "w") as file:
        json_string = json.dumps(
            test_results, default=lambda o: o.__dict__, sort_keys=True, indent=2
        )
        file.write(json_string)
        file.close()


################
################
def write_to_local_summary_results_file(sum_file, small_result, outPutTitleAppend):
    # File for pass results
    sum_pass_file = f"{outputs_folder_name}/small_pass_result.md"
    # File for fail results
    sum_fail_file = f"{outputs_folder_name}/small_fail_result.md"
    # Temp file for determining pass or fail
    sum_temp_file = f"{outputs_folder_name}/small_temp_result.md"

    # open summary file for writing (create if not exists)
    with open(sum_file, "w+") as sumfile:
        # may have multiple test runs
        sumfile.write(f"# TEST RUN {outPutTitleAppend}\n")

        # loop small results
        for key in small_result:
            failed_test_in_key = False

            with open(sum_temp_file, "w+") as sumtempfile:

                sumtempfile.write(f"### {key}\n")
                sumtempfile.write(f"| Command      | Result |\n")
                sumtempfile.write(f"| ----------- | ----------- |\n")
                for cmd in small_result[key]:

                    cell_value = "NA"
                    if test_fail_message in small_result[key][cmd]:
                        failed_test_in_key = True
                        cell_value = (
                            f'<span style="color:red">***{test_fail_message}***</span>'
                        )

                    if test_pass_message in small_result[key][cmd]:
                        cell_value = f'<span style="color:green">***{test_pass_message}***</span>'

                    if cell_value != "NA":
                        sumtempfile.write(f"| {cmd} | {cell_value} |\n")

                    # open both files

            if failed_test_in_key == True:

                with open(sum_fail_file, "a+") as failfile, open(
                    sum_temp_file, "r"
                ) as sumtempfile:
                    failfile.seek(0)
                    logging.debug("write failfile")
                    # read content from first file
                    for line in sumtempfile:
                        logging.debug("fail templine")
                        logging.debug(line)
                        # write content to second file
                        failfile.write(line)
            else:
                with open(sum_pass_file, "a+") as passfile, open(
                    sum_temp_file, "r"
                ) as sumtempfile:
                    passfile.seek(0)
                    logging.debug("write passfile")
                    # read content from first file
                    for line in sumtempfile:
                        logging.debug("pass templine")
                        logging.debug(line)
                        # write content to second file
                        passfile.write(line)

        logging.info("read failfile")
        if os.path.exists(sum_fail_file):
            with open(sum_fail_file, "r") as failfile:
                failfile.seek(0)
                for line in failfile:
                    logging.debug("fail line")
                    logging.debug(line)
                    # write content to second file

                    sumfile.write(line)

        logging.info("read passfile")
        if os.path.exists(sum_pass_file):
            with open(sum_pass_file, "r") as passfile:
                passfile.seek(0)

                for line in passfile:
                    # write content to second file
                    logging.debug("pass line")
                    logging.debug(line)
                    sumfile.write(line)


################
################
def doTest(options, t):
    """Run test with options"""
    try:
        key = options["key"]

        # info
        logging.info("Connecting to %s...", key)
        t[key]["connection"] = test_fail_message

        # create connect object for current machine
        connect = Connection(
            host=options["host"],
            user=options["user"],
            connect_kwargs=options["connect_kwargs"],
        )

        t[key]["connection"] = test_pass_message
        logging.info("Connection Success %s", key)

        for cmd in options["commands"]:
            # default to fail so failed connections aren't ignored
            t[key][cmd] = test_fail_message



            # info
            logging.debug(
                f"""
                #######################################
                {key}

                host={options["host"]}
                user={options["user"]}
                connect_kwargs={mask_password(options["connect_kwargs"])}

                Running { options["commands"][cmd] }
                #######################################"""
            )

            # run command on remote machine
            hide_run_output = True
            if options["log_level"] == "DEBUG":
                hide_run_output = False

            result = connect.run(
                options["commands"][cmd], hide=hide_run_output, timeout=300
            )

            # format string for results
            msg = "Ran {0.command!r} on {0.connection.host}, got stdout:\n{0.stdout}"
            result_msg = "{0.stdout}"

            if "tofile" not in cmd:
                # if not writing to a file add command result dictionary
                t[key][cmd] = result_msg.format(result).strip()
            else:
                # else add file path
                file_name = f'file_outputs/{options["key"]}_{cmd}_results.txt'
                f = open(file_name, "w")
                f.write(msg.format(result))
                f.close()
                t[key][cmd] = file_name
    except Exception as e:
        traceback.print_exception(e)


# def tt():
#     test = {}
#     test["key"] = {}
#     test["key"]["cmdo"] = ""
#     test["key"]["cmdo0"] = ""
#     # test["key"].append({"cmd1": "FAIL"})
#     # test["key"].append({"cmd2": "FAIL"})

#     # ttt(test, "key")
#     print(test)
