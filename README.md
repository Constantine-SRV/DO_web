# Example Setup in DigitalOcean

This Terraform code performs the following steps to set up the infrastructure in DigitalOcean:

1. Create a PostgreSQL database.
2. Restore a database dump downloaded from Azure Blob Storage.
3. Create two Virtual Machines (Droplets).
4. Install and run the application from the repository: [BlazorAut](https://github.com/Constantine-SRV/BlazorAut).
5. Configure an Application Load Balancer (ALB).  

I did not configure firewalls for the VMs or install a certificate in the ALB.  
