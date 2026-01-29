resource "aws_sns_topic" "terraform_failures" {
  name = "terraform-failures-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  count     = var.admin_email ? 1 : 0
  topic_arn = aws_sns_topic.terraform_failures.arn
  protocol  = "email"
  endpoint  = var.admin_email
}
