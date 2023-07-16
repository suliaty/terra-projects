resource "aws_vpc" "main" {
  cidr_block       = var.vpc-cidr

  tags = {
    Name = "main"
  }
}
# Declare the data source
data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.pub-cidr
  availability_zone = data.aws_availability_zones.azs.names[0]
  tags={
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.priv-cidr
  availability_zone = data.aws_availability_zones.azs.names[1]
  tags={
    Name = "private"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "pub-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.pub_rt.id
}

