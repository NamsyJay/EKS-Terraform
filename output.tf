output "eks_cluster_name" {
  value = aws_eks_cluster.lancash.name
}

output "node_group_id" {
  value = aws_eks_node_group.lancash.id
}

output "vpc_id" {
  value = aws_vpc.lancash_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.lancash_subnet[*].id
}

