import configparser
import json
import re
import logging
import requests
import os, sys
import pprint


ENVIRONMENT = 'target-stage-tenant'

# Set up the logger instance
logger = logging.getLogger(__name__)


def getObserveConfig(config: str, environment: str) -> str:
    """Fetches config file
    @param config:
    @param environment:
    @return: config element
    """

    # Set your Observe environment details in config\configfile.ini
    configuration = configparser.ConfigParser()
    configuration.read("config.ini")
    observe_configuration = configuration[environment]

    return observe_configuration[config]


def get_bearer_token() -> str:
    """Logins into account and gets bearer token
    @return: bearer_token
    """

    customer_id = getObserveConfig("customer_id", ENVIRONMENT)
    domain = getObserveConfig("domain", ENVIRONMENT)
    user_email = getObserveConfig("user_email", ENVIRONMENT)
    user_password = getObserveConfig("user_password", ENVIRONMENT)

    url = f"https://{customer_id}.{domain}.com/v1/login"

    message = '{"user_email":"$user_email$","user_password":"$user_password$"}'
    tokens_to_replace = {
        "$user_email$": user_email,
        "$user_password$": user_password,
    }
    for key, value in tokens_to_replace.items():
        message = message.replace(key, value)

    header = {
        "Content-Type": "application/json",
    }

    response = json.loads(
        requests.post(url, data=message, headers=header, timeout=10).text
    )
    bearer_token = response['access_key']
    return bearer_token


def send_query(bearer_token: str, query: str, url_extension: str = '', type='gql') -> list or object:
    """

    @param bearer_token: generated from credentials
    @param query: graphQL query
    @return: response of graphQL query
    """
    customer_id = getObserveConfig("customer_id", ENVIRONMENT)
    domain = getObserveConfig("domain", ENVIRONMENT)

    # Set the GraphQL API endpoint URL
    url = f"https://{customer_id}.{domain}.com/v1/meta{url_extension}"

    # Set the headers (including authentication)
    headers = {
        "Authorization": f"""Bearer {customer_id} {bearer_token}""",
        'Content-Type': 'application/json',
        'Accept': 'application/x-ndjson'
    }

    # Create the request payload for GQL/OpenAPI
    if type == 'gql':
        data = {
            'query': query
        }
    elif type == 'openapi':
        data = json.loads(query)
    else:
        data = {None}
    # Send the POST request
    try:
        response = requests.post(url, json=data, headers=headers)
        response.raise_for_status()
        # result = response.json() #TODO json object is per line with new line delimiteres for openpi
        if type == 'gql':
            result = response.json()
            logger.debug("Request for query {} successful with status code {}:".format(query, response.status_code))
            logger.debug("Response:{}".format(result))
            return result
        else:
            result = response.text
            json_objects = result.strip().split('\n')
            json_list = []
            if json_objects:
                for obj in json_objects:
                    json_list.append(json.loads(obj))
            logger.debug("Request for query {} successful with status code {}:".format(query, response.status_code))
            logger.debug("Response:{}".format(json_list))
            return json_list
    except requests.exceptions.HTTPError as err:
        logging.debug(err.request.url)
        logging.debug(err)
        logging.debug(err.response.text)
        return None

def search_dataset_id(bearer_token: str, dataset_name: str) -> str:
    """Uses Bearer token and dataset_name to return dataset_id
    dataset_id is used to query a dataset
    @param bearer_token: token for querying
    @param dataset_name: dataset name for which to find its id eg: "Server/OSQuery Events"
    @return:
    """

    query = """    
    query {
        datasetSearch(labelMatches: "%s"){
            dataset{
                id
                name
            }
        }
    }
    """ % (dataset_name)

    response = send_query(bearer_token, query, type='gql')

    dataset_id = response["data"]["datasetSearch"][0]["dataset"]["id"]
    logging.debug("Dataset Name: {} <-->  Dataset ID: {}".format(dataset_name, dataset_id))

    return dataset_id


def query_dataset(bearer_token: str, dataset_id: str, pipeline: str = "", interval: str = "30m") -> list:
    """

    Queries the last 30 minutes (default) of a dataset returning result of query. Uses Observe OpenAPI

    @param bearer_token: bearer token for authorization
    @param dataset_id: dataset_id to query using openAPI query
    @param pipeline: OPAL Pipeline

    @return: dataset: queried dataset  in json separated by timestamps

    See  https://developer.observeinc.com/#/paths/~1v1~1meta~1export~1query/post
    """
    logger.info("Querying Dataset for Dataset ID: {}".format(dataset_id))
    query = """
     {
        "query": {
            "stages":[
              {
                 "input":[
                     {
                     "inputName": "default",
                     "datasetId": "%s"
                    }
                ],
                "stageID":"main",
                "pipeline": "%s"
            }
        ]
      },

      "interval" : "%s"
      
    }
    """ % (dataset_id, pipeline, interval)
    dataset = send_query(bearer_token, query, url_extension='/export/query', type='openapi')
    return dataset


def is_instance_present(instance_id: str, query: list) -> bool:
    """
    Check if an instance with the given instance ID (in gcp, aws, azure) is present in the query results.
    instance_id comes from tf_hosts.json which is the output of tf output fab_host_all command

    @param instance_id: string of type <i-0abc123>
    @param query: list containing output of OPAL query via open API
    @return: True if an EC2 instance with the specified instance ID is found, False otherwise.
    """
    instance_id_found = any(item.get('instance_id') == instance_id for item in query)
    name = next((item.get('name') for item in query if 'name' in item), None)

    if instance_id_found:
        logger.info(f"Instance ID {instance_id} is present in the {name} query.")
        return True
    else:
        logger.info(f"Instance ID {instance_id} is NOT present in the {name} query.")
        return False


def validate_in_observe(instance_id: str, type: str, cloud: str) -> bool:
    """
    Validate in Observe whether an Instance is present in Events of type <>

    @param instance_id: takes instance_id (gcp,aws,azure) and validate whether in Observe Host Monitoring <i-123abc..>
    @param type: can be fluentbit, telegraf, osquery events in Host Monitoring
    @param cloud: can be aws, azure, gcp, use for generating correct OPAL to query
    @return True if instance_id present in type event, False if not present in type event
    """
    logger.info("Starting Validation for instance_id {} of type {} in cloud {}".format(instance_id, type, cloud))
    logging.getLogger().setLevel(logging.INFO)

    if cloud =='aws':
        fluentbit_pipeline = "make_col instance_id:string(event.ec2_instance_id)|make_col " \
                             "name:'fluentbit_events'|timechart options(bins: 1), " \
                             "count: count_distinct_exact(1), group_by(instance_id,name)"

        telegraf_pipeline = "make_col instance_id:string(tags.instanceId)|make_col name:'telegraf_events'|timechart " \
                            "options(bins: 1), count: count_distinct_exact(1), group_by(instance_id, name)"

        osquery_pipeline = "make_col instance_id:string(tags.ec2_instance_id)|make_col " \
                           "name:'osquery_events'|timechart options(bins: 1), " \
                           "count: count_distinct_exact(1), group_by(instance_id,name)"


    if cloud =='gcp':
        fluentbit_pipeline = "make_col instance_id:string(tags.host)|make_col " \
                             "name:'fluentbit_events'|timechart options(bins: 1), " \
                             "count: count_distinct_exact(1), group_by(instance_id,name)"

        telegraf_pipeline = "make_col instance_id:string(tags.host)|make_col name:'telegraf_events'|timechart " \
                            "options(bins: 1), count: count_distinct_exact(1), group_by(instance_id, name)"

        osquery_pipeline = "make_col instance_id:string(tags.host)|make_col " \
                           "name:'osquery_events'|timechart options(bins: 1), " \
                           "count: count_distinct_exact(1), group_by(instance_id,name)"
    if cloud == 'azure':
        fluentbit_pipeline = "make_col instance_id:string(tags.host)|make_col " \
                             "name:'fluentbit_events'|make_col datacenter:string(tags.datacenter)|filter datacenter = " \
                             "'AZURE'|timechart options(bins: 1), " \
                             "count: count_distinct_exact(1), group_by(instance_id,name)"

        telegraf_pipeline = "make_col instance_id:string(tags.host)|make_col name:'telegraf_events'|make_col " \
                            "datacenter:string(tags.datacenter)|filter datacenter = 'AZURE'|timechart " \
                            "options(bins: 1), count: count_distinct_exact(1), group_by(instance_id, name)"

        osquery_pipeline = "make_col instance_id:string(tags.host)|make_col " \
                           "name:'osquery_events'|make_col datacenter:string(tags.datacenter)|filter datacenter = " \
                           "'AZURE'|timechart options(bins: " \
                           "1), " \
                           "count: count_distinct_exact(1), group_by(instance_id,name)"



    bearer_token = get_bearer_token()

    if type == 'fluentbit':
        dataset_id = search_dataset_id(bearer_token, "Server/Fluentbit Events")
        pipeline = fluentbit_pipeline
    elif type == 'osquery':
        dataset_id = search_dataset_id(bearer_token, "Server/OSQuery Events")
        pipeline = osquery_pipeline
    elif type == 'telegraf':
        dataset_id = search_dataset_id(bearer_token, "Server/Telegraf Events")
        pipeline = telegraf_pipeline
    else:
        raise ValueError

    query = query_dataset(bearer_token, dataset_id, pipeline)
    return is_instance_present(instance_id, query)



if __name__ == '__main__':
    validate_in_observe(instance_id="i-06b1cb51220183ce6", type='fluentbit')
    validate_in_observe(instance_id="i-06b1cb51220183ce6", type='osquery')
    validate_in_observe(instance_id="i-06b1cb51220183ce6", type='telegraf')
    pass
