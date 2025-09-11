output "ecr_repo_url" {
  value = aws_ecr_repository.app.repository_url
}
output "alb_dns" {
  value = aws_lb.app.dns_name
}
output "ecs_cluster" {
  value = aws_ecs_cluster.cluster.name
}
output "ecs_service" {
  value = aws_ecs_service.service.name
}
output "exec_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}
