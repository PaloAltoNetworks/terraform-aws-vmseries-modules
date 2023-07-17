from json import loads
from logging import getLogger, basicConfig, INFO, DEBUG
from os import getenv
from xml.etree import ElementTree as et
from xml.etree.ElementTree import Element

from boto3 import client, resource
from botocore.exceptions import ClientError
from botocore.config import Config

from panos.panorama import Panorama


class ConfigureLogger:
    def __init__(self, *args, **kwargs):
        self.logger = getLogger(self.__class__.__name__)
        basicConfig(format='%(asctime)s %(message)s')
        self.logger.setLevel(INFO if getenv("logger_level") else DEBUG)


class VMSeriesInterfaceScaling(ConfigureLogger):
    def __init__(self, asg_event: dict):
        super().__init__()

        # Load lambda configuration from environment variable
        region = loads(getenv('lambda_config')).get('region')
        lambda_config = Config(
            region_name=region
        )

        # Prepare boto3 clients for required services
        self.ec2_client = client('ec2', config=lambda_config)
        self.ec2_resource = resource('ec2', config=lambda_config)
        self.asg_client = client('autoscaling', config=lambda_config)
        self.elbv2_client = client('elbv2', config=lambda_config)
        self.ssm_client = client('ssm', config=lambda_config)
        self.main(asg_event)

    def main(self, asg_event: dict):
        """
        Main function is used for handle correct lifecycle action (instance launch or instance terminate).

        :param asg_event: dict data from Lambda handler
        :return: none
        """
        # Acquire information about subnets, AZ, network interfaces, instance ID and target group ARN
        instance_id = asg_event["detail"]["EC2InstanceId"]
        instance_zone, subnet_id, network_interfaces = self.inspect_ec2_instance(instance_id)

        # Load ARNs of target group from environment variable
        ip_target_groups = loads(getenv('autoscaling_config')).get('ip_target_groups')

        # Depending on event type, take appropriate actions
        if (event := asg_event["detail-type"]) == "EC2 Instance-launch Lifecycle Action":
            self.logger.info("Run launch mode.")
            self.disable_source_dest_check(network_interfaces[0]['NetworkInterfaceId'])
            self.setup_network_interfaces(instance_zone, subnet_id, instance_id)
            self.register_untrust_ip_as_target(ip_target_groups, instance_id)
        elif event == "EC2 Instance-terminate Lifecycle Action":
            self.logger.info("Run cleanup mode.")
            self.delicense_fw(instance_id)
            self.clean_eip(network_interfaces, instance_id)
            self.deregister_untrust_ip_as_target(ip_target_groups, instance_id)
        else:
            raise Exception(f"Event type cannot be handle! {event}")

        # For each type of event (launch, terminate), lifecycle action needs to be completed
        self.complete_lifecycle(asg_event['detail'])

    def setup_network_interfaces(self, instance_zone: str, subnet_id: str, instance_id: str):
        """
        Main logic here is to set necessary parameters and call
        functions to create Elastic Network Interfaces (ENI) with correct config and attach it to the instance.

        :param instance_id: EC2 Instance id
        :param subnet_id: Subnet id
        :param instance_zone: Availability zone for current instance
        :return:
        """
        # Prepare interface in propriate structure
        self.logger.info(f"Instance ID: {instance_id}, Instance zone: {instance_zone}")
        self.logger.debug(f"Subnet ID of the first interface: {subnet_id}")
        interfaces = self.create_interface_settings(instance_zone)

        # For each interface in the list, create and configure ENI
        for interface in interfaces:
            self.logger.info(
                f"Found new interface to create: id={interface['index']}, subnet={interface['subnet']}, "
                f"security_group={interface['sg']}")
            self.logger.info(f"Interface structure: {interface}")
            self.create_and_configure_new_network_interface(instance_id, interface)

    def clean_eip(self, network_interfaces: list, instance_id: str):
        """
        Function used for release EIP from terminated EC2 Instanced.
        Main logic here is found which ENI has EIP, disassociate EIP from it and release that address.

        :param network_interfaces: Elastic Network Interface (ENI) list
        :param instance_id: EC2 Instance id
        :return: none
        """
        # Search for network interfaces with EIP
        self.logger.info(f"Search for interfaces with EIP on {instance_id}")
        interface_with_associated_ip = [interface for interface in network_interfaces if interface.get('Association')]

        # If EIP found for ENI, get EIP info and disassociate address
        # In other case do nothing
        if interface_with_associated_ip:
            for interface in interface_with_associated_ip:
                eip = interface.get('Association').get('PublicIp')
                self.logger.info(f"Found interfaces with EIP {eip}")
                eip_info = self.ec2_client.describe_addresses(PublicIps=[eip])
                association_id = eip_info.get('Addresses')[0].get('AssociationId')
                allocation_id = eip_info.get('Addresses')[0].get('AllocationId')
                try:
                    self.ec2_client.disassociate_address(AssociationId=association_id)
                except Exception as e:
                    raise Exception(f"There was a problem with disassociate EIP for {interface} with error msg: {e}")
                try:
                    self.ec2_client.release_address(AllocationId=allocation_id)
                except Exception as e:
                    raise Exception(f"There was problem with releasing EIP for {interface} with error msg: {e}")
                self.logger.info(f"Successfully release {eip}")
        else:
            self.logger.info("Not found any interfaces with EIP")

    @staticmethod
    def create_interface_settings(instance_zone: str) -> list:
        """
        This function normalize data with settings of each ENI.

        :param instance_zone: EC2 Instance availability zone
        :return: list of dict with interface settings
        """
        # Load network interfaces configuration from environment variable
        settings = loads(getenv('interfaces_config'))
        interface = {}

        # For each network interface, prepare settings in a propriate structure
        for eni, sett in settings.items():
            for k, v in sett.items():
                interface[eni] = {} if eni not in interface.keys() else interface[eni]
                interface[eni]["index"] = int(v) if 'device_index' in k else interface.get(eni).get('index')
                interface[eni]["sg"] = v[0] if 'security_group_ids' in k else interface.get(eni).get('sg')
                interface[eni]["c_pub_ip"] = v if 'create_public_ip' in k else interface.get(eni).get('c_pub_ip')
                interface[eni]["s_dest_ch"] = v if 'source_dest_check' in k else interface.get(eni).get('s_dest_ch')
                if 'subnet_id' in k:
                    for az, subnet in v.items():
                        if az == instance_zone:
                            interface[eni]["subnet"] = subnet
        interfaces = sorted((interface for interface in interface.values()), key=lambda x: x["index"])
        return interfaces

    def inspect_ec2_instance(self, instance_id: str) -> tuple:
        """
        Helper class used for return EC2 Instance data: AZ, subnets, network interfaces

        :param instance_id: EC2 Instance id.
        :return: availability zone and subnet id of EC2 instance
        """

        instance_info = self.ec2_client.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'][0]
        return instance_info['Placement']['AvailabilityZone'], instance_info['SubnetId'], \
               instance_info['NetworkInterfaces']

    def create_network_interface(self, instance_id: str, subnet_id: str, sg_id: int) -> str:
        """
        As function name, it creates new ENI, if something wrong it catch error.

        :param instance_id: EC2 Instance id
        :param subnet_id: Subnet id
        :param sg_id: Security group id
        :return: Network Interface id
        """

        self.logger.debug(f"DEBUG: create_interface: instance_id={instance_id}, subnet_id={subnet_id}, sg_id={sg_id}")
        try:
            network_interface = self.ec2_client.create_network_interface(SubnetId=subnet_id, Groups=[sg_id])
            network_interface_id = network_interface['NetworkInterface']['NetworkInterfaceId']
            self.logger.info(f"Created network interface: {network_interface_id}")
            return network_interface_id
        except ClientError as e:
            self.logger.error(f"Error creating network interface: {e.response['Error']['Code']}")

    def create_and_configure_new_network_interface(self, instance_id: str, interface: dict):
        """
        This function call create_network_interface for create new ENI and after that through att_network_interface
        attach ENI to proper EC2 and fix ENI configuration.

        :param instance_id: EC2 Instance id
        :param interface: Interface dict data
        :return: none
        """
        # Create ENI and get its ID
        interface_id = self.create_network_interface(instance_id, interface['subnet'], interface['sg'])

        # If ENI ID was returned, attach ENI to instance
        if interface_id:
            if interface['index'] != 0:
                attachment_id = self.attach_network_interface(instance_id, interface_id, interface['index'])
                self.modify_network_interface(interface_id, attachment_id, interface['s_dest_ch'])
            # If EIP is required for ENI, add public IP
            if interface['c_pub_ip']:
                self.add_public_ip_to_eni(interface_id)

    def add_public_ip_to_eni(self, interface_id: str):
        """
        This function is used to create public ip and associate it with provided ENI ID.

        :param interface_id: Network Interface id
        :return: none
        """
        # Get public IP
        public_ip_allocation = self.ec2_client.allocate_address(Domain='vpc')
        self.logger.info(f"Created public ip {public_ip_allocation['PublicIp']} for {interface_id}")

        # Associate public IP with ENI
        public_ip_association = self.ec2_client.associate_address(
            AllocationId=public_ip_allocation['AllocationId'],
            NetworkInterfaceId=interface_id
        )
        self.logger.debug(f"Successfully created association: {public_ip_association['AssociationId']}")

    def attach_network_interface(self, instance_id: str, interface_id: str, index) -> str:
        """
        This function attach ENI to EC2 Instance.

        :param instance_id: EC2 Instance id
        :param interface_id: Network Interface id
        :param index: ENI index number in EC2 instance
        :return: none
        """

        self.logger.debug(f"DEBUG: attach_interface: instance_id={instance_id}, interface_id={interface_id}, "
                          f"interface_index={index}")

        # Attach ENI to EC2 instnace only if instance ID and ENI ID are not empty
        if instance_id and interface_id:
            try:
                attach_interface_id = self.ec2_client.attach_network_interface(
                    NetworkInterfaceId=interface_id,
                    InstanceId=instance_id,
                    DeviceIndex=index
                )
                attachment_id = attach_interface_id['AttachmentId']
                self.logger.info(f"Created network attachment: {attachment_id}")
                return attachment_id
            except ClientError as e:
                self.delete_interface(interface_id)
                self.logger.error(f"Error attaching network interface {interface_id}: {e.response['Error']['Code']}"
                                  f"Deleting interface.")
        else:
            self.logger.error(f"Missing values for either instance_id or interface_id!")

    def disable_source_dest_check(self, interface_id: str):
        """
        Network interfaces created by resource "aws_launch_template" by default have option
        source/destination check enabled, but for dataplane interfaces it has to be disabled.

        :param interface_id: Network interface ID
        :return: none
        """
        self.logger.info(f"Disable source_dest_check for network interface {interface_id}")
        self.ec2_client.modify_network_interface_attribute(
                NetworkInterfaceId=interface_id,
                SourceDestCheck={
                    'Value': False,
                }
            )

    def modify_network_interface(self, interface_id: str, attachment_id: str, source_dest_check: bool = True):
        """
        This function modify ENI to be able to delete it on EC2 termination.

        :param source_dest_check: Enable or disable source destination check in ENI
        :param interface_id: Network Interface id
        :param attachment_id: ENI attachment id
        :return:
        """

        self.logger.debug(f"DEBUG: tune_interface: interface_id={interface_id}, attachment_id={attachment_id}, "
                          f"source_dest_check: {source_dest_check}")

        # Modify ENI attribute in order to be able to delete it on EC2 terminations
        self.ec2_client.modify_network_interface_attribute(
            Attachment={'AttachmentId': attachment_id, 'DeleteOnTermination': True},
            NetworkInterfaceId=interface_id,
        )

        # If source/destination check was defined, then change its value according to provided settings
        if not source_dest_check:
            self.ec2_client.modify_network_interface_attribute(
                NetworkInterfaceId=interface_id,
                SourceDestCheck={
                    'Value': source_dest_check,
                }
            )

    def delete_interface(self, interface_id: str):
        """
        This function is used when there was some problem with ENI attachment to EC2 Instance.
        Purpose of it is not creating unused resources.

        :param interface_id: Network Interface id
        :return: none
        """

        self.logger.info(f"Deleting interface with id={interface_id}")
        try:
            self.ec2_client.delete_network_interface(NetworkInterfaceId=interface_id)
        except ClientError as e:
            self.logger.error(f"Error deleting interface {interface_id}: {e.response['Error']['Code']}")

    def complete_lifecycle(self, asg_event: dict):
        """
        If everything was completed, calling this function continue ASG lifecycle.

        :param asg_event: ASG event, dict
        :return: none
        """

        self.logger.debug("DEBUG: complete")
        try:
            self.asg_client.complete_lifecycle_action(
                LifecycleHookName=asg_event['LifecycleHookName'],
                AutoScalingGroupName=asg_event['AutoScalingGroupName'],
                LifecycleActionToken=asg_event['LifecycleActionToken'],
                LifecycleActionResult='CONTINUE'
            )
        except ClientError as e:
            self.logger.error(f"Error completing life cycle hook for instance: {e.response['Error']['Code']}")

    def ip_network_interface(self, instance_id: str, device_index: str):
        """
        Function is getting IP address of untrust interface (with device index equal 2).
        Internally function is using:
        https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_network_interfaces.html

        :param instance_id: EC2 Instance id
        :return: none
        """
        description = self.ec2_client.describe_network_interfaces(
            Filters=[
                {
                    'Name': 'attachment.instance-id',
                    'Values': [instance_id]
                },
                {
                    'Name': 'attachment.device-index',
                    'Values': [device_index]
                }
            ]
        )
        return description['NetworkInterfaces'][0]['PrivateIpAddress']

    def register_untrust_ip_as_target(self, ip_target_groups: list, instance_id: str):
        """
        Function is registering IP of untrust interface in target groups for autoscaling.
        Internally function is using:
        https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/elbv2.html#ElasticLoadBalancingv2.Client.register_targets

        :param ip_target_groups: List target group to which IP of untrust interface needs to be added
        :param instance_id: EC2 Instance id
        :return: none
        """
        untrust_ip = self.ip_network_interface(instance_id, '2')

        for target_group in ip_target_groups:
            self.logger.info(f"Register target with IP {untrust_ip} in target group {target_group['arn']}")
            self.elbv2_client.register_targets(
                TargetGroupArn=target_group['arn'],
                Targets=[
                    {
                        'Id': untrust_ip,
                        'Port': int(target_group['port']),
                    },
                ]
            )

    def deregister_untrust_ip_as_target(self, ip_target_groups: list, instance_id: str):
        """
        Function is de-registering IP of untrust interface in target groups for autoscaling.
        Internally function is using:
        https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/elbv2.html#ElasticLoadBalancingv2.Client.deregister_targets

        :param ip_target_groups: List target group to which IP of untrust interface needs to be removed
        :param instance_id: EC2 Instance id
        :return: none
        """
        untrust_ip = self.ip_network_interface(instance_id, '2')
        
        for target_group in ip_target_groups:
            self.logger.info(f"Deregister target with IP {untrust_ip} in target group {target_group['arn']}")
            self.elbv2_client.deregister_targets(
                TargetGroupArn=target_group['arn'],
                Targets=[
                    {
                        'Id': untrust_ip,
                    },
                ]
            )

    def panorama_cmd(self, panorama, cmd: str, xml: bool = True, cmd_xml: bool = True) -> Element:
        """
        Helper function used for call command to Panorama.

        :param panorama: Panorama object
        :param cmd: command send further to Panorama
        :param xml: (bool) Return value should be a string
        :param cmd_xml: (bool) True: cmd is not XML, False: cmd is XML
        :return: Output of executed command
        """
        self.logger.info(f"Call Panorama with: '{cmd}' command.")
        request = panorama.op(cmd=cmd, xml=xml, cmd_xml=cmd_xml)
        return et.fromstring(request)

    def check_ssm_param(self, ssm_param_name: str) -> dict:
        """
        Helper function to check config parameter in SSM Parameter Store

        :ssm_param_name: Parameter name
        :return: dict
        """
        ssm_param_list = self.ssm_client.get_parameter(Name=ssm_param_name, WithDecryption=True).get("Parameter").get("Value"). \
            replace("\'", "\"")
        return loads(ssm_param_list)

    def delicense_fw(self, instance_id) -> bool:
        """
        Function used to de-license VM-Series using plugin sw_fw_license.
        In order to deactivate license used by VM-Series with specified IP address, below steps are done:
        - connect to Panorama using acquired secrets
        - list all devices in license manager
        - de-license only this serial number, which is matching specified IP address

        :param instance_id: EC2 Instance id
        :return: True if VM-Series was de-licensed correctly, False in other case
        """
        self.logger.info(f"Start delicense instance {instance_id}")

        # Find IP address of VM-Series instance managed by Panorama
        vmseries_ip_address = self.ip_network_interface(instance_id, '1')
        self.logger.debug(f"Found VM-Series ip: {vmseries_ip_address} ")

        # Check if delicense FW or not
        if loads(getenv('delicense_config')).get('enabled'):
            # Get setting required to connect to Panorama
            ssm_param_name = loads(getenv('delicense_config')).get('ssm_param')
            panorama_config = self.check_ssm_param(ssm_param_name)
            panorama_username = panorama_config.get("panuser")
            panorama_password = panorama_config.get("panpass")
            panorama_hostname = panorama_config.get("panhost")
            panorama_hostname2 = panorama_config.get("panhost2")
            panorama_lm_name = panorama_config.get("panlm")

            # Check if first Panorama is active - if not, the use second Panorama for de-licensing
            if self.check_is_active_in_ha(panorama_hostname, panorama_username, panorama_password):
                # De-license using active, first Panorama instance from Active-Passive HA cluster
                delicensed = self.request_panorama_delicense_fw(vmseries_ip_address, panorama_hostname, panorama_username, panorama_password, panorama_lm_name)
            else:
                # De-license using active, second Panorama instance from Active-Passive HA cluster
                delicensed = self.request_panorama_delicense_fw(vmseries_ip_address, panorama_hostname2, panorama_username, panorama_password, panorama_lm_name)

            return delicensed
        else:
            return False

    def check_is_active_in_ha(self, panorama_hostname, panorama_username, panorama_password) -> bool:
        """
        Function used to check if provided Panorama hostname is active

        :param panorama_hostname: Hostname of the Panorama server
        :param panorama_username: Account's name
        :param panorama_password: Account's password
        :return: True if Panorama is active in HA cluster
        """
        try:
            # Set status of active
            active = False

            # Connect to selected Panorama instance
            self.logger.info(f"Connecting to '{panorama_hostname}' using user '{panorama_username}''")
            panorama = Panorama(hostname=panorama_hostname,
                                api_username=panorama_username,
                                api_password=panorama_password)

            # Check high-availability state
            cmd = "show high-availability state"
            firewalls_parsed = self.panorama_cmd(panorama, cmd=cmd)

            # Check if in active state
            for info in firewalls_parsed[0]:
                if info.tag is not None and info.tag == "local-info":
                    for attr in info:
                        if attr.tag is not None and attr.tag == "state":
                            active = "active" in attr.text

            # Return high-availability state
            return active
        except:
            self.logger.info(f"Error while checking high-availability state for Panorama {panorama_hostname}")
            return False

    def request_panorama_delicense_fw(self, vmseries_ip_address, panorama_hostname, panorama_username, panorama_password, panorama_lm_name) -> bool:
        """
        Function used to de-license VM-Series using plugin sw_fw_license running on Panorama server

        :param vmseries_ip_address: IP address of the MGMT interface for VM-Series
        :param panorama_hostname: Hostname of the Panorama server
        :param panorama_username: Account's name
        :param panorama_password: Account's password
        :return: True if VM-Series was de-licensed correctly, False in other case
        """
        try:
            # Set status of delicensing
            delicensed = False

            # Connect to selected Panorama instance
            self.logger.info(f"Connecting to '{panorama_hostname}' using user '{panorama_username}' to license manager '{panorama_lm_name}'")
            panorama = Panorama(hostname=panorama_hostname,
                                api_username=panorama_username,
                                api_password=panorama_password)

            # List all devices under the configured license manager
            cmd = f"show plugins sw_fw_license devices license-manager \"{panorama_lm_name}\""
            firewalls_parsed = self.panorama_cmd(panorama, cmd=cmd)

            # If the command succeeded, start sweeping the list of FWs
            if firewalls_parsed.attrib["status"] == 'success':
                do_commit = False
                self.logger.info("Parsing firewall list")
                for fw in firewalls_parsed[0][0]:
                    ip_obj = fw.find("ip")
                    # For each firewall from the list, check if IP address is matching value of vmseries_ip_address
                    if ip_obj is not None:
                        ip = ip_obj.text
                        self.logger.info(f"Working on VM-Series with management IP: {ip}")
                        if ip is not None and ip == vmseries_ip_address:
                            serial_obj = fw.find("serial")
                            if serial_obj is not None:
                                serial = serial_obj.text
                                # If IP address is the same as destroyed VM and serial is not none, then delicense firewall
                                if serial_obj.text is not None:
                                    self.logger.info(f"De-licensing firewall: {serial} ...")
                                    cmd = f"request plugins sw_fw_license deactivate license-manager \"{panorama_lm_name}\" devices member \"{serial}\""
                                    resp_parsed = self.panorama_cmd(panorama, cmd)
                                    if resp_parsed.attrib["status"] == "success":
                                        self.logger.info(f"De-licensing firewall: {serial} succeeded")
                                        do_commit = True
                                        delicensed = True
                                    else:
                                        self.logger.info(f"De-licensing firewall: {serial} failed")
                # Commit changes in case we did de-license a FW
                if do_commit:
                    self.logger.info("Committing changes in Panorama")
                    panorama.commit(sync=False, admins="__sw_fw_license")

            # Return final result of de-licensing
            return delicensed
        except:
            self.logger.info(f"Error while de-licensing VM-Series using Panorama {panorama_hostname}")
            return False


def lambda_handler(asg_event: dict, context: dict):
    VMSeriesInterfaceScaling(asg_event)
