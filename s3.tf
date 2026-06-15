resource "aws_s3_bucket" "frontend" {
  # ATTENTION : Ce nom doit être globalement unique sur tout AWS. 
  # N'hésite pas à ajouter une suite de chiffres à la fin.
  bucket = "minecraft-leaderboard-frontend-kln" 
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html" # Indispensable pour que le routeur d'Angular fonctionne
  }
}

# Désactivation des blocages de sécurité par défaut pour rendre le site public
resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# La politique qui autorise n'importe qui à lire les fichiers du site
resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      },
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.frontend_public_access]
}