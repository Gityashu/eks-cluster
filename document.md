#           EKS-CLUSTER-SETUP 

**# Prerequisites**
<pre>
<li>AWS Account with appropriate permissions.</li>
<li>AWS CLI installed and configured (aws configure).</li>
<li>Terraform installed on your local machine.</li>
<li>Basic knowledge of command-line usage.</li></pre>  

**1. **Install Terraform****

Install Terraform on your system. For Ubuntu, you can use:
<pre>
  bash

sudo snap install terraform --classic
</pre>

Or, use the official HashiCorp instructions for your OS:
https://developer.hashicorp.com/terraform/install

**2. **Prepare Your Working Directory****

Create a directory for your project and navigate into it:
<pre>
bash
  
mkdir terraform-eks
cd terraform-eks
</pre>  
**3. Clone a Terraform EKS Module Repository (Recommended)**

You can use a ready-made module to simplify the setup. For example:
<pre>
bash

https://github.com/Innovlabsai/invlab-eks.git
cd invlab-eks</pre>

Or use any other module, such as:

https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/

**4. Review and Edit Configuration**

Edit main.tf (or variables.tf as needed) to set your cluster name, region, node group settings, etc.

A minimal example using the official EKS module:
<pre>'''
text
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.31"
  cluster_name    = "example"
  cluster_version = "1.31"
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    example = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      vpc_id         = aws_vpc.main.id
      subnet_ids     = aws_subnet.public_subnet.*.id
      tags = {
        Environment = "dev"
        Terraform   = "true"
      }
    }
  }
}
'''</pre>  
Adjust VPC, subnet, and other settings as required for your environment.

**5. Initialize Terraform**

Run the following command to initialize your Terraform workspace and download required providers/modules:
<pre>
bash
  
terraform init
</pre>

**6. Review the Execution Plan**
 Preview what Terraform will do:
<pre>
bash
  
terraform plan
</pre>

**7. Apply the Configuration**

Create the EKS cluster and all related resources:
<pre>
  
bash
  
terraform apply
</pre>
<ul>
<li>Review the plan output.</li>  
<li>Type yes when prompted to proceed.</li>
<li>Cluster creation may take 10–15 minutes.</li>
</ul>  

**8. Verify the Cluster**

<ul>
 <li>Log in to the AWS Console.</li>

<li>Navigate to EKS service and confirm your cluster is listed.</li>

<li>Check worker nodes under Cluster > Configuration > Compute.</li>

</ul>

**9. Connect with kubectl**

After creation, update your kubeconfig to connect to the cluster:
<pre>
bash

aws eks --region <region> update-kubeconfig --name <cluster_name>
kubectl get nodes
</pre>

<li>Now you can manage your cluster using kubectl.</li>  

**10. Clean Up Resources** 

To destroy all resources created by Terraform:
<pre>
bash

terraform destroy
</pre>
 # NOTE: place the environment variables in the repo secret's
<ul>
<li>Open the setting in the repository.</li>

<li>Under the secret and variables.</li>

<li>Click on actions and add new repository secret's.</li>  
</ul>
