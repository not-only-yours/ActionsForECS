#Create a new Hosted Zone 

resource "aws_route53_zone" "test" {
  name = var.DNS
}

#Standard route53 DNS record for "test" pointing to an front-end ALB

resource "aws_route53_record" "test" {
  zone_id = aws_route53_zone.test.zone_id
  name    = aws_route53_zone.test.name
  type    = "A"
  alias {
    name                   = "${module.frontend-alb.dns_name}"
    zone_id                = "${module.frontend-alb.zone_id}"
    evaluate_target_health = false
  }
}
