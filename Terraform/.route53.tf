#resource "aws_route53_zone" "main" {
#  name = "test-ops.pp.ua"
#}
#
#
#resource "aws_route53_record" "dev" {
#  zone_id = "${aws_route53_zone.main.zone_id}"
#  name = "ops.pp.ua"
#  type = "NS"
#  ttl = "30"
#  records = ["${aws_route53_zone.main.name_servers.0}"]
#}

##resource "dns_cname_record" "dev" {
##  zone  = "example.com."
##  name  = "dev"
##  cname = "test-ops.pp.ua"
##  ttl   = 300
#}

## Standard route53 DNS record for "app" pointing to an ALB
#resource "aws_route53_record" "app" {
#  zone_id = data.aws_route53_zone.public.zone_id
#  name    = "${var.test_dns_name}.${data.aws_route53_zone.public.name}"
#  type    = "A"
#  alias {
#    name                   = "aws_alb.backend.dns_name"
#    zone_id                = "aws_alb.backend.zone_id"
#    evaluate_target_health = false
#  }
#  #provider = aws.account_route53
#}

 
resource "aws_route53_zone" "public" {
  name = "monitoring-ops.pp.ua"
}

#Standard route53 DNS record for "app" pointing to an ALB

 resource "aws_route53_record" "public" {
   zone_id = aws_route53_zone.public.zone_id
   name    = aws_route53_zone.public.name
   type    = "A"
   alias {
     name                   = "${module.frontend-alb.dns_name}"
     zone_id                = "${module.frontend-alb.zone_id}"
     evaluate_target_health = false
   }
 }