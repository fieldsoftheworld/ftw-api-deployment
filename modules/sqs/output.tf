output "task_queue_url" {
  description = "SQS task queue URL for EC2 workers"
  value       = aws_sqs_queue.task_queue.url
}

output "task_queue_arn" {
  description = "SQS task queue ARN"
  value       = aws_sqs_queue.task_queue.arn
}

output "task_queue_name" {
  description = "SQS task queue name"
  value       = aws_sqs_queue.task_queue.name
}

output "dlq_url" {
  description = "Dead letter queue URL"
  value       = aws_sqs_queue.task_dlq.url
}

output "dlq_arn" {
  description = "Dead letter queue ARN"
  value       = aws_sqs_queue.task_dlq.arn
}