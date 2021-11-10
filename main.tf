# Register providers
terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.4.2"
    }
  }
}
# use -var="do_token=$HOME/.tokens/vultr_api_token" with terraform command to set the token
variable "vultr_api_token" {}
# use -var="private_key=$HOME/.ssh/id_rsa" to pass down a private key for the ssh connection
variable "private_key" {}

# Configure the Vultr Provider
provider "vultr" {
  api_key = var.vultr_api_token

}
# Get ssh key
data "vultr_ssh_key" "jcedenoSSH" {
  filter {
    name = "name"
    # Name of your ssh key in Vultr
    values = ["m1-mini"]
  }
}
data "vultr_ssh_key" "aleSSH" {
  filter {
    name = "name"
    # Name of your ssh key in Vultr
    values = ["ale"]
  }
}
data "vultr_ssh_key" "jcedenoMac" {
  filter {
    name = "name"
    # Name of your ssh key in Vultr
    values = ["mac-jc"]
  }
}


# Deploy the droplet
resource "vultr_bare_metal_server" "dedsafio-droplet" { # To use baremetal, change vultr_instance to vultr_baremetal_instance
  plan        = "vbm-8c-132gb"                          # Dedicated 8vcpu 32gb ram, change to vbm-8c-132gb to use baremetal
  app_id      = "37"                                    # Docker on Ubuntu 20.04
  region      = "ewr"                                   # NYC/NJ region
  hostname    = "dedsafio"
  label       = "dedsafioBingo" # Label in Vultr
  ssh_key_ids = [data.vultr_ssh_key.jcedenoMac.id, data.vultr_ssh_key.jcedenoSSH.id, data.vultr_ssh_key.aleSSH.id]

  connection {
    host        = self.main_ip
    user        = "root"
    type        = "ssh"
    private_key = file(var.private_key)
    timeout     = "3m"
  }
  # Create the folders for the deployment 
  provisioner "remote-exec" {
    inline = [
      # Create the /home/minecraft directory
      "mkdir /home/minecraft",
      "cd /home/minecraft",
      # Create all the directories and make them accessible for any user.
      "mkdir -m 777 -p minecraft-data/proxy minecraft-data/lobby minecraft-data/sv1 minecraft-data/sv2 minecraft-data/sv3 minecraft-data/sv4 minecraft-data/sv5 minecraft-data/sv6",
      # Open ports
      "ufw allow 25558:25565/tcp"
    ]
  }
  # Copy the files to the proxy
  provisioner "file" {
    source      = "images"
    destination = "/home/minecraft/"
  }
  # Run the docker-compose command
  provisioner "remote-exec" {
    inline = [
      # Change directories to the /home/minecraft directory
      "cd /home/minecraft",
      # Copy the contents of the images folder to the respective server folder
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/sv1/",
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/sv2/",
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/sv3/",
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/sv4/",
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/sv5/",
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/sv6/",
      "cp -r images/dedsafio-lobby/* /home/minecraft/minecraft-data/lobby/",
      "cp -r images/dedsafio-proxy/* /home/minecraft/minecraft-data/proxy/",
      # Move the docker-compose file to the /home/minecraft directory
      "mv images/docker-compose.yml /home/minecraft/",
      # Move the replace world scriipto into the /home/minecraft dir
      "mv images/replace.sh /home/minecraft/minecraft-data/",
      #Change all permissions to 777 to ensure that the files are accessible for any user
      "chmod -R 777 *",
      # Start the docker-compose process
      "docker-compose up -d",
    ]
  }
}
