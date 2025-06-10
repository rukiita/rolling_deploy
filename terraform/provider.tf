# AWS プロバイダの設定
provider "aws" {
  region = "ap-northeast-1"
}

# 現在のAWSリージョンとアカウントIDを取得するデータソース
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}