provider "aws" {
    region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "vladbrebu-devops-tf-state-54821"
    key = "terraform/state.tfstate"
    region = "us-east-1"
  }
}
