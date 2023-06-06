import os
import boto3
import datetime
from kubernetes import client
from kubernetes.client.rest import ApiException
from eks_token import get_token

# Configure your cluster name and region here
cluster_name = os.environ["CLUSTER_NAME"]
region = os.environ["REGION"]
namespace = os.environ["NAMESPACE"]
deployments_to_rotate = os.environ["DEPLOYMENTS_TO_ROTATE"]


def restart_deployment(v1, deployment, namespace):
    now = datetime.datetime.utcnow()
    now = str(now.isoformat("T") + "Z")
    body = {
        'spec': {
            'template': {
                'metadata': {
                    'annotations': {
                        'kubectl.kubernetes.io/restartedAt': now
                    }
                }
            }
        }
    }
    try:
        v1.patch_namespaced_deployment(
            deployment, namespace, body, pretty='true')
    except ApiException as e:
        print(
            "Exception when calling AppsV1Api->read_namespaced_deployment_status: %s\n" % e)


def lambda_handler(event, context):
    deployments_list = list(deployments_to_rotate.split(" "))

    eks_api = boto3.client('eks', region_name=region)
    cluster_info = eks_api.describe_cluster(name=cluster_name)
    endpoint = cluster_info['cluster']['endpoint']
    token = get_token(cluster_name=cluster_name)['status']['token']

    configuration = client.Configuration()
    configuration.host = endpoint
    configuration.api_key = {"authorization": "Bearer " + token}
    configuration.verify_ssl = False
    configuration.debug = True

    api = client.ApiClient(configuration)
    v1 = client.AppsV1Api(api)
    for deployment in deployments_list:
        restart_deployment(v1, deployment, namespace)
