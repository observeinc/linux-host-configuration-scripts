#!/usr/bin/env python3


from multiprocessing.pool import ThreadPool as Pool
import json
import configparser
import pprint
import os
import glob
import time
from fabric import Connection
from fabric import task

# import logging
# logging.basicConfig(level=logging.DEBUG)


def getObserveConfig(config, environment):
    """Fetches config file"""
    # Set your Observe environment details in config\configfile.ini
    configuration = configparser.ConfigParser()
    configuration.read("config.ini")
    observe_configuration = configuration[environment]

    return observe_configuration[config]


def getCurlCommand(options):
    """Create command for running install script"""
    YOUR_CUSTOMERID = getObserveConfig("customer_id", options["ENVIRONMENT"])
    YOUR_DATA_STREAM_TOKEN = getObserveConfig(
        "datastream_token", options["ENVIRONMENT"]
    )
    DOMAIN = getObserveConfig("domain", options["ENVIRONMENT"])

    FLAGS = {
        "config_files_clean": "TRUE",
        "ec2metadata": "TRUE",
        "datacenter": "FAB_DATA_CENTER",
        "appgroup": "FAB_APP_GROUP",
    }

    if "FLAGS" in options:
        FLAGS.update(options["FLAGS"])

    return f'curl "https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/{options["BRANCH"]}/observe_configure_script.sh" | bash -s -- --customer_id {YOUR_CUSTOMERID} --ingest_token {YOUR_DATA_STREAM_TOKEN} --observe_host_name https://{YOUR_CUSTOMERID}.collect.{DOMAIN}.com/ --config_files_clean {FLAGS["config_files_clean"]} --ec2metadata {FLAGS["ec2metadata"]} --datacenter {FLAGS["datacenter"]} --appgroup {FLAGS["appgroup"]} '


# @task
# def hello(ctx, fileName="world"):
#     with open("hosts.json") as json_file:
#         hosts = json.load(json_file)

#         for key in hosts:
#             print(hosts[key]["connect_kwargs"]["key_filename"])

#         run("ls")
#         run("whoami")
#         print("Hello %s!" % fileName)

# your "parallelness"
pool_size = 20
pool = Pool(pool_size)

# folder to write files to
folder_name = "file_outputs"

# files
tf_apply_error_output = f"python_scripts/{folder_name}/tf_apply_error.txt"
tf_destroy_error_output = f"python_scripts/{folder_name}/tf_destroy_error.txt"
tf_apply_output = f"python_scripts/{folder_name}/tf_apply.txt"
tf_destroy_output = f"python_scripts/{folder_name}/tf_destroy.txt"
test_results_file_name = f"{folder_name}/test_results.json"

test_fail_message = "FAIL"
test_pass_message = "PASS"


def folderCleanup():
    """Clean out file ouputs on each run"""
    files = glob.glob(f"{folder_name}/*")
    for f in files:
        os.remove(f)


def terraformOutput(fileName="tf_hosts.json"):
    """Run terraform ouput command"""
    # run output to file that is read by test
    os.system(
        f"cd ../; terraform output -json | jq -r '.fab_host_all.value' > python_scripts/{fileName}"
    )


def ciSumFile(sumfile, agg_result):
    # Check if script executing in GitHub Actions
    am_i_in_ci = os.getenv("CI")

    # Set TEST_RESULT environment variable in GitHub Actions
    if am_i_in_ci == "true":
        env_file = os.getenv("GITHUB_ENV")
        gha_sum_file = os.getenv("GITHUB_STEP_SUMMARY")

        # open both files
        with open(sumfile, "r") as firstfile, open(gha_sum_file, "w") as secondfile:
            secondfile.seek(0)
            # read content from first file
            for line in firstfile:
                # write content to second file
                secondfile.write(line)

        with open(env_file, "a") as myfile:
            myfile.write(f"TEST_RESULT={agg_result}")


@task
def test(
    ctx,
    fileName="tf_hosts.json",
    branch="main",
    runTerraform="false",
    sleep=300,
    runTerraformDestroy="false",
    runTerraformOutput="true",
    failMe="false",
    outPutTitleAppend="1",
):
    """Run a test of install script"""
    if runTerraform == "true":
        try:
            # delete files from last run
            folderCleanup()
            # run terraform appy to create infrastructure
            print("#######################################")
            print("Running terraform apply ...")
            print()
            print(f"Error output written to {tf_apply_error_output}")
            print(f"Standard output written to {tf_apply_output}")
            print("#######################################")
            print()
            os.system(
                f'cd ../; export TF_LOG="ERROR"; terraform apply -auto-approve 2> {tf_apply_error_output} 1> {tf_apply_output}'
            )

            print("Terraform apply complete")
            print()
            # Give compute instances a minute (TODO - Move this into test runs as different os vary - can it be deterministic?)
            print(f"Wait {sleep} seconds for machines to instantiate ...")
            time.sleep(sleep)

        except Exception as e:
            print("Terraform Flamed")
            print(e.message)
            print(e.args)
            print(f"Error output written to {tf_apply_error_output}")
            exit()

    try:
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
                if runTerraform == "true":
                    sleep = hosts[key]["sleep"]

                ec2metadata = "FALSE"
                datacenter = "FAB_DC"
                appgroup = "FAB_APP_GROUP"
                config_files_clean = "TRUE"

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
                        "ENVIRONMENT": "arthur-stage-tenant",
                        "BRANCH": branch,
                        "FLAGS": {
                            "config_files_clean": config_files_clean,
                            "ec2metadata": ec2metadata,
                            "datacenter": datacenter,
                            "appgroup": appgroup,
                        },
                    }
                )

                # ls_cmd = "ls"

                # multitask pool - call doTest with parameters
                pool.apply_async(
                    doTest,
                    (
                        {
                            "host": hosts[key]["host"],
                            "user": hosts[key]["user"],
                            "connect_kwargs": hosts[key]["connect_kwargs"],
                            "commands": {
                                "tofile_curl": curl_cmd,
                                "tdagent": "if systemctl is-active --quiet td-agent-bit; then echo PASS; else echo FAIL; fi",
                                "osquery": "if systemctl is-active --quiet osqueryd; then echo PASS; else echo FAIL; fi",
                                "telegraf": "if systemctl is-active --quiet telegraf; then echo PASS; else echo FAIL; fi",
                                "tofile_telegraf_status": "sudo service telegraf status  | cat",
                                "tofile_osqueryd_status": "sudo service osqueryd status  | cat",
                                "tofile_td-agent-bit_status": "sudo service td-agent-bit status | cat",
                            },
                            "key": key,
                            "sleep": sleep,
                        },
                        test_results,
                    ),
                )

            # wait for jobs to complete
            pool.close()
            pool.join()

            # analyze results
            agg_result = test_pass_message

            if failMe == "true":
                agg_result = "FAIL"

            small_result = {}
            fail_result = {}

            # for key in test_results:
            #     print(key)
            #     for key2 in test_results[key]:
            #         print(key2)
            #         print(test_results[key][key2])

            for key in test_results:
                small_result[key] = {}
                fail_result[key] = {}

                for cmd in test_results[key]:
                    print(cmd)
                    if test_fail_message in test_results[key][cmd]:
                        print(test_fail_message)
                        agg_result = test_fail_message
                        small_result[key][cmd] = test_results[key][cmd]
                        fail_result[key][cmd] = test_results[key][cmd]
                    if test_pass_message in test_results[key][cmd]:
                        print(test_pass_message)
                        small_result[key][cmd] = test_results[key][cmd]

            sum_pass_file = f"{folder_name}/small_pass_result.md"
            sum_fail_file = f"{folder_name}/small_fail_result.md"
            sum_temp_file = f"{folder_name}/small_temp_result.md"

            with open(sum_file, "w+") as sumfile:
                sumfile.write(f"# TEST RUN {outPutTitleAppend}\n")

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
                                cell_value = f'<span style="color:red">***{test_fail_message}***</span>'

                            if test_pass_message in small_result[key][cmd]:
                                cell_value = f'<span style="color:green">***{test_pass_message}***</span>'

                            sumtempfile.write(f"| {cmd} | {cell_value} |\n")

                            # open both files

                        if failed_test_in_key == True:

                            with open(sum_fail_file, "a+") as failfile:
                                failfile.seek(0)
                                # read content from first file
                                for line in sumtempfile:
                                    # write content to second file
                                    failfile.write(line)
                        else:
                            with open(sum_pass_file, "a+") as passfile:
                                passfile.seek(0)
                                # read content from first file
                                for line in sumtempfile:
                                    # write content to second file
                                    passfile.write(line)

                with open(sum_fail_file, "r") as failfile:
                    failfile.seek(0)
                    for line in failfile:
                        # write content to second file
                        sumfile.write(line)

                with open(sum_pass_file, "r") as passfile:
                    passfile.seek(0)
                    for line in passfile:
                        # write content to second file
                        sumfile.write(line)

            ciSumFile(sum_file, agg_result)

            # print results
            pp = pprint.PrettyPrinter(indent=4)
            print()
            print("#######################################")
            print("########### TEST RESULTS ##############")
            print("#######################################")
            print("###########  AGGREGATE   ##############")
            print(agg_result)
            print()
            pp.pprint(small_result)
            print()
            print("###########  DETAIL   ##############")
            pp.pprint(test_results)
            print()
            print("#######################################")
            print("#######################################")
            print("#######################################")
            print()

            # write results to file
            with open(test_results_file_name, "w") as file:
                json_string = json.dumps(
                    test_results, default=lambda o: o.__dict__, sort_keys=True, indent=2
                )
                file.write(json_string)
                file.close()
    except Exception as e:
        print("Tests Flamed")
        print(e)
        sum_file = f"{folder_name}/no_result.md"

        with open(sum_file, "w+") as myfile:
            myfile.write(f"### Test Run Error\n")
            myfile.write(f"{e}")

        ciSumFile(sum_file, "FAIL")

    finally:
        if runTerraform == "true" and runTerraformDestroy == "true":
            print("Running terraform destroy ...")
            print()
            print(f"Error output written to {tf_destroy_error_output}")
            print(f"Standard output written to {tf_destroy_output}")
            os.system(
                f'cd ../; export TF_LOG="ERROR"; terraform destroy -auto-approve 2> {tf_destroy_error_output} 1> {tf_destroy_output}'
            )
        print()
        print("Done")


# def tt():
#     test = {}
#     test["key"] = {}
#     test["key"]["cmdo"] = ""
#     test["key"]["cmdo0"] = ""
#     # test["key"].append({"cmd1": "FAIL"})
#     # test["key"].append({"cmd2": "FAIL"})

#     # ttt(test, "key")
#     print(test)


# def ttt(t, key):
#     t[key].append({"test": "fred"})


def doTest(options, t):
    """Run test with options"""
    key = options["key"]

    # info
    print(
        f"""
        #######################################
        {key}
        Running commands ...
        #######################################"""
    )
    print()

    # create connect object for current machine
    connect = Connection(
        host=options["host"],
        user=options["user"],
        connect_kwargs=options["connect_kwargs"],
    )

    for cmd in options["commands"]:
        # default to fail so failed connections aren't ignored
        t[key][cmd] = test_fail_message

        # info
        print(
            f"""
            #######################################
            {key}

            host={options["host"]}
            user={options["user"]}
            connect_kwargs={options["connect_kwargs"]}

            Running { options["commands"][cmd] }
            #######################################"""
        )

        # run command on remote machine
        result = connect.run(options["commands"][cmd], hide=True, timeout=300)

        # format string for results
        msg = "Ran {0.command!r} on {0.connection.host}, got stdout:\n{0.stdout}"
        result_msg = "{0.stdout}"

        if "tofile" not in cmd:
            # if not writing to a file add command result dictionary
            t[key][cmd] = result_msg.format(result)
        else:
            # else add file path
            file_name = f'file_outputs/{options["key"]}_{cmd}_results.txt'
            f = open(file_name, "w")
            f.write(msg.format(result))
            f.close()
            t[key][cmd] = file_name
