resource "aws_sns_topic" "terraform_failures" {
  name = "terraform-failures-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  for_each = toset(var.tf_failure_emails)
  topic_arn = aws_sns_topic.terraform_failures.arn
  protocol  = "email"
  endpoint  = each.value
}

# Define the policy as a data source
data "aws_iam_policy_document" "sns_publish_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.terraform_lambda_role.arn]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.terraform_failures.arn]
  }
}

# Attach the policy to the SNS topic
resource "aws_sns_topic_policy" "allow_publish" {
  arn    = aws_sns_topic.terraform_failures.arn
  policy = data.aws_iam_policy_document.sns_publish_policy.json
}