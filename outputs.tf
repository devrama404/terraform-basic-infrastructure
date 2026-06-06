output "ec2_public_ip" {
 description = "Public IP EC2"
 value       = aws_eip.web_eip.public_ip
}

output "s3_bucket_arn" {
 description = "ARN S3 Bucket"
 value       = aws_s3_bucket.storage.arn
}
