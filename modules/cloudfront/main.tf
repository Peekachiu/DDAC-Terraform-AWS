###########################################################
# CloudFront Distribution
###########################################################
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  web_acl_id          = var.waf_web_acl_arn
  price_class         = "PriceClass_100" # Use PriceClass_All for global

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-${var.alb_dns_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # Talking to ALB over HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${var.alb_dns_name}"

    forwarded_values {
      query_string = true
      headers      = ["*"] # Forward all headers (needed for API/Dynamic content)

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Force HTTPS on the front end
    min_ttl                = 0
    default_ttl            = 0 # Disable caching for dynamic app content
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-cdn"
  }
}