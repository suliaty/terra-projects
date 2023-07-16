variable "vpc-cidr" {
 type =string
 default ="10.0.0.0/16" 
}

variable "pub-cidr" {
    type = string
    default = "10.0.5.0/16"
}

variable "priv-cidr" {
  type =string
  default = "10.0.7.0/16"
}