output "dashboard_link" {
  value = "https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}