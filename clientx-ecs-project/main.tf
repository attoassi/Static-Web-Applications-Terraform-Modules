# configure aws provider
provider "aws" {
  region  = var.region
  profile = "Your-profile-Name"
}

# create vpc
module "vpc" {
  source                       = "../modules/A01_vpc"
  region                       = var.region
  project_name                 = var.project_name
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr
}

# create nat-gateway
module "nat-gateway" {
  source                     = "../modules/A02_nat-gateway"
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
}

# Create security groups
module "security-group" {
  source = "../modules/A03_security-groups"
  vpc_id = module.vpc.vpc_id
}

# Create the ecs tasks execution role
module "ecs-tasks-execution-role" {
  source       = "../modules/A04_ecs-tasks-execution-role"
  project_name = module.vpc.project_name
}

# Create ssl certificate
module "acm-sslcertificate" {
  source           = "../modules/A05_acm-sslcertificate"
  domain_name      = var.domain_name
  alternative_name = var.alternative_name
}

# Create application load balancer
module "Application_Load_Balancer" {
  source                = "../modules/A06_ALB"
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security-group.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  vpc_id                = module.vpc.vpc_id
  certificate_arn       = module.acm-sslcertificate.certificate_arn
}

# Create ecs cluster & service
module "ecs-service" {
  source                       = "../modules/A07_ecs-service"
  project_name                 = module.vpc.project_name
  ecs_tasks_execution_role_arn = module.ecs-tasks-execution-role.ecs_tasks_execution_role_arn
  container_image              = var.container_image
  region                       = module.vpc.region
  private_app_subnet_az1_id    = module.vpc.private_data_subnet_az1_id
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  ecs_security_group_id        = module.security-group.ecs_security_group_id
  alb_target_group_arn         = module.Application_Load_Balancer.alb_target_group_arn
}

# Create Auto scaling group
module "auto_scaling_group" {
  source           = "../modules/A08_Auto-Scaling-Group"
  ecs_cluster_name = module.ecs-service.ecs_cluster_name
  ecs_service_name = module.ecs-service.ecs_service_name
}

# Create record set in route 53
module "route_53" {
  source                             = "../modules/A09_Route-53"
  domain_name                        = module.acm-sslcertificate.domain_name
  record_name                        = var.record_name
  application_load_balancer_dns_name = module.Application_Load_Balancer.application_load_balancer_dns_name
  application_load_balancer_zone_id  = module.Application_Load_Balancer.application_load_balancer_zone_id
}

output "website_url" {
  value = join("", ["https://", var.record_name, ".", var.domain_name])
}
