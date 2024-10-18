#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Nukes AWS resources
# ! CAUTION only use in dev, poc, sdbx, etc.

echo "mini_nuke.sh started."

# TODO: accept arguments

export AWS_PAGER=""

# KMS
if [[ "${DELETE_KMS:-"false"}" == "true" ]]; then
  REGIONS=("us-east-1" "ap-northeast-1")
  for REGION in "${REGIONS[@]}"; do
    # KMS aliases
    ALIAS_NAMES=$(aws kms list-aliases --region "${REGION}" --query "Aliases[?TargetKeyId!=null && starts_with(AliasName, 'alias/aws') == \`false\`].AliasName" --output text)
    if [[ -z "${ALIAS_NAMES}" ]]; then
      echo "no KMS aliases found in region: ${REGION}"
    else
      for ALIAS_NAME in ${ALIAS_NAMES}; do
        echo "deleting KMS alias: ${ALIAS_NAME}"
        aws kms delete-alias --alias-name "${ALIAS_NAME}" --region "${REGION}"
      done
    fi

    KEY_IDS="$(aws kms list-keys --region "${REGION}" --query "Keys[*].KeyId" --output text)"
    if [[ -z "${KEY_IDS}" ]]; then
      echo "no KMS keys found in region: ${REGION}"
    else
      for KEY_ID in ${KEY_IDS}; do
        KEY_MANAGER="$(aws kms describe-key --key-id "${KEY_ID}" --region "${REGION}" --query "KeyMetadata.KeyManager" --output text)"
        KEY_STATE="$(aws kms describe-key --key-id "${KEY_ID}" --region "${REGION}" --query "KeyMetadata.KeyState" --output text)"
        if [[ "${KEY_MANAGER}" == "CUSTOMER" ]] && [[ "${KEY_STATE}" != "PendingDeletion" ]] && [[ "${KEY_STATE}" != "PendingReplicaDeletion" ]]; then
          echo "scheduling deletion for KMS key: ${KEY_ID}"
          aws kms schedule-key-deletion --key-id "${KEY_ID}" --pending-window-in-days 7 --region "${REGION}"
        fi
      done
    fi
  done
fi

# Elastic Load Balancers
ELB_ARNS="$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerArn" --output text)"
if [[ -z "${ELB_ARNS}" ]]; then
  echo "no ELBs found."
else
  set +e
  while true; do
    ERROR_OCCURRED=false
    # Listeners
    for ELB_ARN in ${ELB_ARNS}; do
      LISTENERS="$(aws elbv2 describe-listeners --load-balancer-arn "${ELB_ARN}" --query "Listeners[*].ListenerArn" --output text)"
      if [[ -z "${LISTENERS}" ]]; then
        echo "no listeners found for ELB: ${ELB_ARN}"
      else
        for LISTENER_ARN in ${LISTENERS}; do
          echo "deleting listener: ${LISTENER_ARN}"
          aws elbv2 delete-listener --listener-arn "${LISTENER_ARN}" || ERROR_OCCURRED=true
        done
      fi
    done

    # Target Groups
    TARGET_GROUPS=$(aws elbv2 describe-target-groups --query "TargetGroups[*].TargetGroupArn" --output text)
    if [[ -z "${TARGET_GROUPS}" ]]; then
      echo "no target groups found."
    fi

    for TG_ARN in ${TARGET_GROUPS}; do
      echo "checking tags for target group: ${TG_ARN}"
      TAGS=$(aws elbv2 describe-tags --resource-arns "${TG_ARN}" --query "TagDescriptions[0].Tags[?Key=='managed_by' && Value=='terraform']" --output text)
      if [[ -z "${TAGS}" ]]; then
        echo "skipping target group: ${TG_ARN} (not managed by Terraform)"
      else
        TARGETS=$(aws elbv2 describe-target-health --target-group-arn "${TG_ARN}" --query "TargetHealthDescriptions[*].Target.Id" --output text)
        if [[ -z "${TARGETS}" ]]; then
          echo "no targets registered in target group: ${TG_ARN}"
        else
          echo "deregistering targets from target group: ${TG_ARN}"
          for TARGET in ${TARGETS}; do
            aws elbv2 deregister-targets --target-group-arn "${TG_ARN}" --targets Id="${TARGET}" || ERROR_OCCURRED=true
          done
          sleep 5
        fi
        echo "deleting target group managed by Terraform: ${TG_ARN}"
        aws elbv2 delete-target-group --target-group-arn "${TG_ARN}" || ERROR_OCCURRED=true
      fi
    done

    for ELB_ARN in ${ELB_ARNS}; do
      echo "deleting ELB: ${ELB_ARN}..."
      aws elbv2 delete-load-balancer --load-balancer-arn "${ELB_ARN}"
      echo "confirmed deletion of ELB: ${ELB_ARN}"
    done

    if [[ "${ERROR_OCCURRED}" == false ]]; then
      break
    fi
  done
  set -e
fi

# VPC Endpoint Services
VPC_ENDPOINT_SERVICES="$(aws ec2 describe-vpc-endpoint-service-configurations --query "ServiceConfigurations[*].ServiceId" --output text)"
if [[ -z "${VPC_ENDPOINT_SERVICES}" ]]; then
  echo "no VPC Endpoint Services found."
else
  for SERVICE_ID in ${VPC_ENDPOINT_SERVICES}; do
    echo "deleting VPC Endpoint Service: ${SERVICE_ID}"
    aws ec2 delete-vpc-endpoint-service-configurations --service-ids "${SERVICE_ID}"
  done
fi

[[ "${DELETE_ELB_ONLY:-"false"}" == "true" ]] && exit 0

# EventBridge Schedules
EVENT_BRIDGE_SCHEDULES=$(aws scheduler list-schedules --query "Schedules[*].Arn" --output text)
if [[ -z "${EVENT_BRIDGE_SCHEDULES}" ]]; then
  echo "no EventBridge schedules found."
else
  for SCHEDULE_ARN in ${EVENT_BRIDGE_SCHEDULES}; do
    echo "deleting EventBridge schedule: ${SCHEDULE_ARN}"
    aws scheduler delete-schedule --name "${SCHEDULE_ARN##*/}" || echo "Schedule ${SCHEDULE_ARN} could not be deleted or does not exist."
  done
fi

# EventBridge Schedule Groups
EVENT_BRIDGE_SCHEDULE_GROUPS=$(aws scheduler list-schedule-groups --query "ScheduleGroups[*].Arn" --output text)
if [[ -z "${EVENT_BRIDGE_SCHEDULE_GROUPS}" ]]; then
  echo "no EventBridge schedule groups found."
else
  for SCHEDULE_GROUP_ARN in ${EVENT_BRIDGE_SCHEDULE_GROUPS}; do
    SCHEDULE_GROUP_NAME="${SCHEDULE_GROUP_ARN##*/}"
    if [[ "${SCHEDULE_GROUP_NAME}" == "default" ]]; then
      continue
    fi
    echo "deleting EventBridge schedule group: ${SCHEDULE_GROUP_ARN}"
    aws scheduler delete-schedule-group --name "${SCHEDULE_GROUP_NAME}" || echo "Schedule group ${SCHEDULE_GROUP_ARN} could not be deleted or does not exist."
  done
fi

# ECS
ECS_CLUSTERS="$(aws ecs list-clusters --query "clusterArns" --output text)"
if [[ -z "${ECS_CLUSTERS}" ]]; then
  echo "no ECS clusters found."
else
  for CLUSTER_ARN in ${ECS_CLUSTERS}; do
    # ECS Tasks
    ECS_TASKS="$(aws ecs list-tasks --cluster "${CLUSTER_ARN}" --query "taskArns" --output text)"
    if [[ -z "${ECS_TASKS}" ]]; then
      echo "no ECS tasks found in cluster: ${CLUSTER_ARN}"
    else
      for TASK_ARN in ${ECS_TASKS}; do
        echo "stopping ECS task: ${TASK_ARN} in cluster: ${CLUSTER_ARN}"
        aws ecs stop-task --cluster "${CLUSTER_ARN}" --task "${TASK_ARN}"
      done
    fi

    # ECS Services
    ECS_SERVICES="$(aws ecs list-services --cluster "${CLUSTER_ARN}" --query "serviceArns" --output text)"
    if [[ -z "${ECS_SERVICES}" ]]; then
      echo "no ECS services found in cluster: ${CLUSTER_ARN}"
    else
      for SERVICE_ARN in ${ECS_SERVICES}; do
        echo "deleting ECS service: ${SERVICE_ARN} in cluster: ${CLUSTER_ARN}"
        aws ecs update-service --cluster "${CLUSTER_ARN}" --service "${SERVICE_ARN}" --desired-count 0
        aws ecs delete-service --cluster "${CLUSTER_ARN}" --service "${SERVICE_ARN}" --force
      done
    fi

    echo "deleting ECS cluster: ${CLUSTER_ARN}"
    aws ecs delete-cluster --cluster "${CLUSTER_ARN}"
  done
fi

# S3 buckets
S3_BUCKETS="$(aws s3api list-buckets --query "Buckets[*].Name" --output text)"
if [[ -z "${S3_BUCKETS}" ]]; then
  echo "no S3 buckets found."
else
  for BUCKET in ${S3_BUCKETS}; do
    echo "deleting S3 bucket: ${BUCKET}"

    # S3 objects
    OBJECT_VERSIONS="$(aws s3api list-object-versions --bucket "${BUCKET}" --query "Versions[*].[Key,VersionId]" --output text)"
    if [[ -z "${OBJECT_VERSIONS}" ]]; then
      echo "no S3 objects found in bucket: ${BUCKET}"
    else
      while read -r KEY VERSION_ID; do
        if [[ -n "${VERSION_ID}" && "${VERSION_ID}" != "null" ]]; then
          echo "deleting S3 object: ${KEY}, version: ${VERSION_ID}"
          aws s3api delete-object --bucket "${BUCKET}" --key "${KEY}" --version-id "${VERSION_ID}"
        fi
      done <<< "${OBJECT_VERSIONS}"
    fi

    # S3 delete markers
    DELETE_MARKERS="$(aws s3api list-object-versions --bucket "${BUCKET}" --query "DeleteMarkers[*].[Key,VersionId]" --output text)"
    if [[ -z "${DELETE_MARKERS}" ]]; then
      echo "no S3 delete markers found in bucket: ${BUCKET}"
    else
      while read -r KEY VERSION_ID; do
        if [[ -n "${VERSION_ID}" && "${VERSION_ID}" != "null" ]]; then
          echo "deleting S3 delete marker: ${KEY}, version: ${VERSION_ID}"
          aws s3api delete-object --bucket "${BUCKET}" --key "${KEY}" --version-id "${VERSION_ID}"
        fi
      done <<< "${DELETE_MARKERS}"
    fi

    # S3 bucket
    aws s3 rb "s3://${BUCKET}" --force
  done
fi

# DynamoDB
DYNAMODB_TABLES="$(aws dynamodb list-tables --query "TableNames" --output text)"
if [[ -z "${DYNAMODB_TABLES}" ]]; then
  echo "no DynamoDB tables found."
else
  for TABLE in ${DYNAMODB_TABLES}; do
    echo "deleting DynamoDB table: ${TABLE}"
    aws dynamodb delete-table --table-name "${TABLE}"
  done
fi

# VPC Endpoints
while true; do
  VPC_ENDPOINTS="$(aws ec2 describe-vpc-endpoints --query "VpcEndpoints[*].VpcEndpointId" --output text)"

  if [[ -z "${VPC_ENDPOINTS}" ]]; then
    echo "no VPC Endpoints found."
    break
  else
    for VPCE_ID in ${VPC_ENDPOINTS}; do
      echo "deleting VPC Endpoint: ${VPCE_ID}"
      for i in {1..10}; do
        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "${VPCE_ID}" && break || echo "Failed to delete VPC Endpoint: ${VPCE_ID} (Attempt $i)"
        sleep 5
      done
    done
  fi
  sleep 10
done

# IAM Identity Providers
IDENTITY_PROVIDERS="$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[*].Arn" --output text)"
if [[ -z "${IDENTITY_PROVIDERS}" ]]; then
  echo "no Identity Providers found."
else
  for PROVIDER_ARN in ${IDENTITY_PROVIDERS}; do
    echo "deleting Identity Provider: ${PROVIDER_ARN}"
    aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "${PROVIDER_ARN}"
  done
fi

# IAM Policies
CUSTOMER_MANAGED_POLICIES="$(aws iam list-policies --scope Local --query 'Policies[*].Arn' --output text)"
if [[ -z "${CUSTOMER_MANAGED_POLICIES}" ]]; then
  echo "no IAM Policies found."
else
  for POLICY_ARN in ${CUSTOMER_MANAGED_POLICIES}; do
    ATTACHMENTS="$(aws iam list-entities-for-policy --policy-arn "${POLICY_ARN}" --query "PolicyRoles[*].RoleName" --output text)"
    if [[ -z "${ATTACHMENTS}" ]]; then
      echo "no attachments found for policy: ${POLICY_ARN}"
    else
      for ROLE_NAME in $(aws iam list-entities-for-policy --policy-arn "${POLICY_ARN}" --query "PolicyRoles[*].RoleName" --output text); do
        echo "detaching policy ${POLICY_ARN} from role ${ROLE_NAME}"
        aws iam detach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${POLICY_ARN}"
      done

      for USER_NAME in $(aws iam list-entities-for-policy --policy-arn "${POLICY_ARN}" --query "PolicyUsers[*].UserName" --output text); do
        echo "detaching policy ${POLICY_ARN} from user ${USER_NAME}"
        aws iam detach-user-policy --user-name "${USER_NAME}" --policy-arn "${POLICY_ARN}"
      done

      for GROUP_NAME in $(aws iam list-entities-for-policy --policy-arn "${POLICY_ARN}" --query "PolicyGroups[*].GroupName" --output text); do
        echo "detaching policy ${POLICY_ARN} from group ${GROUP_NAME}"
        aws iam detach-group-policy --group-name "${GROUP_NAME}" --policy-arn "${POLICY_ARN}"
      done
    fi

    POLICY_VERSIONS=$(aws iam list-policy-versions --policy-arn "${POLICY_ARN}" --query "Versions[?IsDefaultVersion==\`false\`].VersionId" --output text)
    for VERSION_ID in ${POLICY_VERSIONS}; do
      echo "deleting non-default version ${VERSION_ID} for policy ${POLICY_ARN}"
      aws iam delete-policy-version --policy-arn "${POLICY_ARN}" --version-id "${VERSION_ID}"
    done

    echo "deleting policy ${POLICY_ARN}"
    aws iam delete-policy --policy-arn "${POLICY_ARN}"
  done
fi

# IAM Roles
IAM_ROLES="$(aws iam list-roles --query "Roles[?starts_with(RoleName, 'AWS') == \`false\` && starts_with(RoleName, 'aws') == \`false\`].RoleName" --output text)"
if [[ -z "${IAM_ROLES}" ]]; then
  echo "no IAM Roles found."
else
  for ROLE_NAME in ${IAM_ROLES}; do
    # IAM Role Attached Policies
    ATTACHED_POLICIES="$(aws iam list-attached-role-policies --role-name "${ROLE_NAME}" --query "AttachedPolicies[*].PolicyArn" --output text)"
    if [[ -z "${ATTACHED_POLICIES}" ]]; then
      echo "no attached policies found for role: ${ROLE_NAME}"
    else
      for POLICY_ARN in ${ATTACHED_POLICIES}; do
        echo "detaching policy ${POLICY_ARN} from role ${ROLE_NAME}"
        aws iam detach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${POLICY_ARN}"
      done
    fi

    # IAM Role Inline Policies
    INLINE_POLICIES="$(aws iam list-role-policies --role-name "${ROLE_NAME}" --query "PolicyNames" --output text)"
    if [[ -z "${INLINE_POLICIES}" ]]; then
      echo "no inline policies found for role: ${ROLE_NAME}"
    else
      for POLICY_NAME in ${INLINE_POLICIES}; do
        echo "deleting inline policy ${POLICY_NAME} from role ${ROLE_NAME}"
        aws iam delete-role-policy --role-name "${ROLE_NAME}" --policy-name "${POLICY_NAME}"
      done
    fi

    echo "deleting IAM Role: ${ROLE_NAME}"
    aws iam delete-role --role-name "${ROLE_NAME}"
  done
fi

# CloudWatch Logs
LOG_GROUPS="$(aws logs describe-log-groups --query "logGroups[*].logGroupName" --output text)"
if [[ -z "${LOG_GROUPS}" ]]; then
  echo "no CloudWatch log groups found."
else
  for LOG_GROUP in ${LOG_GROUPS}; do
    echo "deleting CloudWatch log group: ${LOG_GROUP}"
    aws logs delete-log-group --log-group-name "${LOG_GROUP}"
  done
fi

# ECR
ECR_REPOSITORIES="$(aws ecr describe-repositories --query "repositories[*].repositoryName" --output text)"
if [[ -z "${ECR_REPOSITORIES}" ]]; then
  echo "no ECR repositories found."
else
  for REPO in ${ECR_REPOSITORIES}; do
    # ECR Images
    IMAGES="$(aws ecr list-images --repository-name "${REPO}" --query "imageIds[*]" --output json)"
    if [[ "${IMAGES}" == "[]" ]]; then
      echo "no images found in repository: ${REPO}"
    else
      echo "deleting images in repository: ${REPO}"
      aws ecr batch-delete-image --repository-name "${REPO}" --image-ids "${IMAGES}"
    fi

    echo "deleting ECR repository: ${REPO}"
    aws ecr delete-repository --repository-name "${REPO}" --force
  done
fi

# Cloud Map Services
CLOUD_MAP_SERVICES="$(aws servicediscovery list-services --query "Services[*].Id" --output text)"
if [[ -z "${CLOUD_MAP_SERVICES}" ]]; then
  echo "no Cloud Map services found."
else
  for SERVICE_ID in ${CLOUD_MAP_SERVICES}; do
    echo "deleting Cloud Map service: ${SERVICE_ID}"
    aws servicediscovery delete-service --id "${SERVICE_ID}"
  done
fi

# Cloud Map Namespaces
CLOUD_MAP_NAMESPACES="$(aws servicediscovery list-namespaces --query "Namespaces[*].Id" --output text)"
if [[ -z "${CLOUD_MAP_NAMESPACES}" ]]; then
  echo "no Cloud Map namespaces found."
else
  for NAMESPACE_ID in ${CLOUD_MAP_NAMESPACES}; do
    STATUS="$(aws servicediscovery get-namespace --id "${NAMESPACE_ID}" --query "Namespace.Properties.HttpProperties.HttpNameStatus" --output text)"
    if [[ "${STATUS}" == "PENDING_DELETION" ]]; then
      echo "Namespace ${NAMESPACE_ID} is already in the process of deletion."
    else
      echo "deleting Cloud Map namespace: ${NAMESPACE_ID}"
      aws servicediscovery delete-namespace --id "${NAMESPACE_ID}"
    fi
  done
fi

# ACM Certificates
ACM_CERTIFICATES="$(aws acm list-certificates --query "CertificateSummaryList[*].CertificateArn" --output text)"
if [[ -z "${ACM_CERTIFICATES}" ]]; then
  echo "no ACM certificates found."
else
  for CERT_ARN in ${ACM_CERTIFICATES}; do
    echo "deleting ACM certificate: ${CERT_ARN}"
    aws acm delete-certificate --certificate-arn "${CERT_ARN}"
  done
fi

# Security Groups
SECURITY_GROUPS="$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)"
for SG_ID in ${SECURITY_GROUPS}; do
  # Network Interfaces
  ENI_IDS="$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=${SG_ID}" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text)"
  if [[ -z "${ENI_IDS}" ]]; then
    echo "No ENIs found for Security Group: ${SG_ID}"
  else
    for ENI_ID in ${ENI_IDS}; do
      ENI_DESCRIPTION="$(aws ec2 describe-network-interfaces --network-interface-ids "${ENI_ID}" --query "NetworkInterfaces[0].Description" --output text)"
      if [[ "${ENI_DESCRIPTION}" != *"ELB"* && "${ENI_DESCRIPTION}" != *"NAT"* && "${ENI_DESCRIPTION}" != *"managed"* ]]; then
        ATTACHMENT_ID="$(aws ec2 describe-network-interfaces --network-interface-ids "${ENI_ID}" --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text)"
        if [[ "${ATTACHMENT_ID}" == "None" ]]; then
          echo "ENI: ${ENI_ID} is not attached to any resource."
        else
          echo "detaching ENI: ${ENI_ID}, AttachmentId: ${ATTACHMENT_ID}"
          aws ec2 detach-network-interface --attachment-id "${ATTACHMENT_ID}" --force || echo "Failed to detach ENI: ${ENI_ID}"
          sleep 5
        fi

        echo "attempting to delete ENI: ${ENI_ID}"
        for i in {1..5}; do
          aws ec2 delete-network-interface --network-interface-id "${ENI_ID}" && break || echo "Failed to delete ENI: ${ENI_ID} (Attempt $i)"
          sleep 5
        done
      else
        echo "skipping system-managed ENI: ${ENI_ID} (Description: ${ENI_DESCRIPTION})"
      fi
    done
  fi
done
for SG_ID in ${SECURITY_GROUPS}; do
  # Security Group Ingress Rules
  INGRESS_RULES="$(aws ec2 describe-security-groups --group-ids "${SG_ID}" --query "SecurityGroups[0].IpPermissions" --output json)"
  if [[ "${INGRESS_RULES}" == "[]" ]]; then
    echo "no ingress rules to delete for Security Group: ${SG_ID}"
  else
    echo "revoking ingress rules for Security Group: ${SG_ID}"
    echo "${INGRESS_RULES}" | jq -c '.[]' | while read -r rule; do
      aws ec2 revoke-security-group-ingress --group-id "${SG_ID}" --ip-permissions "${rule}"
    done
  fi
  # Security Group Egres Rules
  EGRESS_RULES="$(aws ec2 describe-security-groups --group-ids "${SG_ID}" --query "SecurityGroups[0].IpPermissionsEgress" --output json)"
  if [[ "${EGRESS_RULES}" == "[]" ]]; then
    echo "no egress rules to delete for Security Group: ${SG_ID}"
  else
    echo "revoking egress rules for Security Group: ${SG_ID}"
    echo "${EGRESS_RULES}" | jq -c '.[]' | while read -r rule; do
      aws ec2 revoke-security-group-egress --group-id "${SG_ID}" --ip-permissions "${rule}"
    done
  fi
done
for SG_ID in ${SECURITY_GROUPS}; do
  echo "deleting Security Group: ${SG_ID}"
  for i in {1..5}; do
    aws ec2 delete-security-group --group-id "${SG_ID}" && break || echo "Failed to delete Security Group: ${SG_ID} (Attempt $i)"
    sleep 5
  done
done

# VPCs
VPC_IDS="$(aws ec2 describe-vpcs --query "Vpcs[*].VpcId" --output text)"
if [[ -z "${VPC_IDS}" ]]; then
  echo "no VPCs found."
else
  for VPC_ID in ${VPC_IDS}; do
    # Internet Gateways
    IGW_IDS="$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --query "InternetGateways[*].InternetGatewayId" --output text)"
    if [[ -z "${IGW_IDS}" ]]; then
      echo "no Internet Gateways found for VPC: ${VPC_ID}"
    else
      for IGW_ID in ${IGW_IDS}; do
        echo "detaching and deleting Internet Gateway: ${IGW_ID}"
        aws ec2 detach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}"
        aws ec2 delete-internet-gateway --internet-gateway-id "${IGW_ID}"
      done
    fi

    # Subnets
    SUBNET_IDS="$(aws ec2 describe-subnets --filters Name=vpc-id,Values="${VPC_ID}" --query "Subnets[*].SubnetId" --output text)"
    if [[ -z "${SUBNET_IDS}" ]]; then
      echo "no Subnets found for VPC: ${VPC_ID}"
    else
      for SUBNET_ID in ${SUBNET_IDS}; do
        echo "deleting Subnet: ${SUBNET_ID}"
        aws ec2 delete-subnet --subnet-id "${SUBNET_ID}"
      done
    fi

    # Route Tables
    RT_IDS="$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" --query "RouteTables[*].RouteTableId" --output text)"
    for RT_ID in ${RT_IDS}; do
      if ! aws ec2 describe-route-tables --route-table-ids "${RT_ID}" --query "RouteTables[*].Associations[*].Main" --output text | grep -q "True"; then
        echo "deleting Route Table: ${RT_ID}"
        aws ec2 delete-route-table --route-table-id "${RT_ID}"
      fi
    done

    echo "deleting VPC: ${VPC_ID}"
    aws ec2 delete-vpc --vpc-id "${VPC_ID}"
  done
fi

# Route53
if [[ "${DELETE_ROUTE53:-"true"}" == "true" ]]; then
  HOSTED_ZONES="$(aws route53 list-hosted-zones --query "HostedZones[*].Id" --output text)"
  if [[ -z "${HOSTED_ZONES}" ]]; then
    echo "no Route 53 hosted zones found."
  else
    for ZONE_ID in ${HOSTED_ZONES}; do
      ZONE_ID_SHORT="${ZONE_ID#/hostedzone/}"

      HOSTED_ZONE_NAME=$(aws route53 get-hosted-zone --id "${ZONE_ID_SHORT}" --query "HostedZone.Name" --output text)

      # Record Sets
      RECORD_SETS="$(aws route53 list-resource-record-sets --hosted-zone-id "${ZONE_ID_SHORT}" --query "ResourceRecordSets[]" --output json)"

      if [[ "${RECORD_SETS}" == "[]" ]]; then
        echo "no custom records found in hosted zone: ${ZONE_ID_SHORT}"
      else
        echo "deleting custom records in hosted zone: ${ZONE_ID_SHORT}"
        echo "${RECORD_SETS}" | jq -c '.[]' | while read -r RECORD; do
          RECORD_TYPE=$(echo "${RECORD}" | jq -r '.Type')
          RECORD_NAME=$(echo "${RECORD}" | jq -r '.Name')

          if [[ "${RECORD_TYPE}" == "NS" && "${RECORD_NAME}" != "${HOSTED_ZONE_NAME}" ]]; then
            echo "deleting NS record: ${RECORD_NAME} in hosted zone: ${ZONE_ID_SHORT}"
          elif [[ "${RECORD_TYPE}" == "NS" || "${RECORD_TYPE}" == "SOA" ]]; then
            echo "skipping ${RECORD_TYPE} record in hosted zone: ${ZONE_ID_SHORT}"
            continue
          fi

          CHANGE_BATCH=$(jq -n --argjson record "${RECORD}" '{
            "Changes": [
              {
                "Action": "DELETE",
                "ResourceRecordSet": $record
              }
            ]
          }')

          aws route53 change-resource-record-sets --hosted-zone-id "${ZONE_ID_SHORT}" --change-batch "${CHANGE_BATCH}"
        done
      fi

      echo "deleting Route 53 hosted zone: ${ZONE_ID_SHORT}"
      aws route53 delete-hosted-zone --id "${ZONE_ID_SHORT}"
    done
  fi
fi

echo "mini_nuke.sh completed."
