$env:DB_HOST="tech-challenge-comments-db.c6ngymy00woo.us-east-1.rds.amazonaws.com"
$env:DB_PORT="5432"
$env:DB_NAME="commentsdb"
$env:DB_USER="comments_user"
$env:DB_PASSWORD="ChangeMeStrong123!"

python api/init_db.py