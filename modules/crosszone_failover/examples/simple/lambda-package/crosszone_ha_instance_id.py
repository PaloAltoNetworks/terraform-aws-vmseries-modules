import logging
import boto3
import urllib
import urllib3
import sys
import ssl
from botocore.exceptions import ClientError
urllib3.disable_warnings()

event = {}
context = {}


ec2 = boto3.resource('ec2')
ec2_client = boto3.client('ec2')
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    print(f'Received Event: {event}')

    try:
        good_enis = ec2_client.describe_network_interfaces(
                Filters=[
                {
                    'Name': 'attachment.instance-id',
                    'Values': [
                        event['good_instance']
                    ]          
                },
            ]
        )
    except ClientError as e:
        logger.error(f"Error Getting Interfaces for Instance: {str(e)}")

    try:
        failed_enis = ec2_client.describe_network_interfaces(
                Filters=[
                {
                    'Name': 'attachment.instance-id',
                    'Values': [
                        event['failed_instance']
                    ]          
                },
            ]
        )
    except ClientError as e:
        logger.error(f"Error Getting Interfaces for Instance: {str(e)}")      

    # Build new dict with just the required values
    eni_dict = {}
    eni_dict['good'] = {}
    eni_dict['failed'] = {}
    for eni in good_enis['NetworkInterfaces']:
        eni_dict['good'][eni['NetworkInterfaceId']] = {}
        eni_dict['good'][eni['NetworkInterfaceId']]['PrivateIpAddress'] = eni['PrivateIpAddress']
        eni_dict['good'][eni['NetworkInterfaceId']]['DeviceIndex'] = eni['Attachment']['DeviceIndex']
        for tag in eni['TagSet']: # Get Interfaces with tags set for health check
            if tag['Key'] == 'pan_health_check':
                eni_dict['good'][eni['NetworkInterfaceId']]['HealthCheckTag'] = tag['Value']
    for eni in failed_enis['NetworkInterfaces']:
        eni_dict['failed'][eni['NetworkInterfaceId']] = {}
        eni_dict['failed'][eni['NetworkInterfaceId']]['PrivateIpAddress'] = eni['PrivateIpAddress']
        eni_dict['failed'][eni['NetworkInterfaceId']]['DeviceIndex'] = eni['Attachment']['DeviceIndex']
        for tag in eni['TagSet']: # Get Interfaces with tags set for health check
            if tag['Key'] == 'pan_health_check':
                eni_dict['failed'][eni['NetworkInterfaceId']]['HealthCheckTag'] = tag['Value']


    logger.info(f'Retrieved Interface information for both instances: {eni_dict}')

    for eni, value in eni_dict['good'].items():
        if 'HealthCheckTag' in value and value['HealthCheckTag'] == 'public':
            path_check_public(value['PrivateIpAddress'])

    for eni, value in eni_dict['good'].items():
        if 'HealthCheckTag' in value and value['HealthCheckTag'] == 'private':
            path_check_private(value['PrivateIpAddress'])

    update_route_tables(event['vpc_id'], eni_dict)


def path_check_public(ip):  
    http = url
    logger.debug("http var {}".format(http)) 
    print(http)
    urlvar = 'http://' + ip
    try:
        logger.info(f'Sending public path check to {urlvar} with Host Header checkip.amazonaws.com')
        r = http.request('GET', urlvar, headers={'Host': 'checkip.amazonaws.com'}, timeout=2.0, retries=2)
    except Exception as e:
        logger.error(f"Path Check Failed, exiting without making route changes: {str(e)}")  
        raise
    logger.debug(r)
    logger.debug(r.status)
    logger.debug(r.headers)
    if (r.status == 200):
        logger.info("*****Path 200OK*****")
    elif (r.status == 302):
        logger.info("*****Site Redirected*****")
    else:
        logger.info("*****Site NOT 200OK*****")
        return

# def path_check_private(ip):  

#     # ctx = ssl.create_default_context()
#     # ctx.check_hostname = False
#     # ctx.verify_mode = ssl.CERT_NONE

#     ssl._create_default_https_context = ssl._create_unverified_context

#     urllib3.disable_warnings()
#     https = urllib3.PoolManager()
#     https.verify = False
#     logger.debug("https var {}".format(https)) 
#     urlvar = 'https://' + ip + '/php/login.php'
#     try:
#         logger.info(f'Sending private path check to {urlvar}')
#         r = https.request('GET', urlvar, timeout=2.0, retries=2, verify=False )
#     except Exception as e:
#         logger.error(f"Path Check Failed, exiting without making route changes: {str(e)}")  
#         raise
#     logger.debug(r)
#     logger.debug(r.status)
#     logger.debug(r.headers)
#     if (r.status == 200):
#         logger.info("*****Path 200OK*****")
#     elif (r.status == 302):
#         logger.info("*****Site Redirected*****")
#     else:
#         logger.info("*****Site NOT 200OK*****")
#         return

def path_check_private(ip):
    ctx = ssl.create_default_context
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    url = "https://" + ip + "/api"
    # logger.info('API call is {} {}'.format(url, data))
    # encoded_data = urllib.parse.urlencode(data).encode('utf-8')
    response = urllib.request.urlopen(url,  context=ctx)
    print(response)
    return response

    

def update_route_tables(vpc_id, eni_dict):

    route_table = ec2_client.describe_route_tables(
            Filters=[
            {
                'Name': 'vpc-id',
                'Values': [
                    vpc_id
                ]          
            },
        ]
    )
    if route_table.get('RouteTables'):
        for i in range(len(route_table['RouteTables'])):
            routes = route_table['RouteTables'][i]['Routes']
            for route in routes:
                    key = 'NetworkInterfaceId'
                    if key in route:
                        if route['NetworkInterfaceId'] in eni_dict['failed']:
                            eni_index = eni_dict['failed'][route['NetworkInterfaceId']]['DeviceIndex']
                            print(f"Found route for failed instance {route['NetworkInterfaceId']} in route table {route_table['RouteTables'][i]['RouteTableId']} with device index {eni_index}'" )
                            good_eni = next((str(k) for k, v in eni_dict['good'].items() if v['DeviceIndex'] == eni_index ))
                            response = ec2_client.replace_route(
                                RouteTableId=(route_table['RouteTables'][i]['RouteTableId']),
                                DryRun=False,
                                NetworkInterfaceId=good_eni,
                                DestinationCidrBlock=(route['DestinationCidrBlock'])
                            )
                            logger.info(f"Replace Route ec2 Response: {response}")
                            logger.info(f"Succesfully updated route for {route['DestinationCidrBlock']} from failed instance ENI {route['NetworkInterfaceId']} to good instance ENI {good_eni} in route table {route_table['RouteTables'][i]['RouteTableId']}")                   
    else:
        logger.info('No routes to process')


if __name__ == '__main__':
    event = {'vpc_id': 'vpc-0f4e5948fa1be9e0a', 
            'failed_instance': 'i-0c87777294d8c0cfb', 
            'good_instance': 'i-0111e99d48d3ec911', }
    context = {}
    lambda_handler(event, context)