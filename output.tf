output "cluster_id" {
  value = aws_eks_cluster.lancash.id
}

output "node_group_id" {
  value = aws_eks_node_group.lancash.id
}

output "vpc_id" {
  value = aws_vpc.DefaultVPC_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.lancash_subnet[*].id
}

