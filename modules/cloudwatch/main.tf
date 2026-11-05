resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "production-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"

  period    = 300
  statistic = "Average"

  threshold = 80

  alarm_description = "RDS CPU utilization is above 80 percent"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  alarm_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]
}