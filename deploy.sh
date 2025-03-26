#!/bin/bash
set -e  # 에러 발생 시 스크립트 즉시 종료

# 설정
REGION="ap-northeast-2"
REPOSITORY="195275652706.dkr.ecr.${REGION}.amazonaws.com"
IMAGE_NAME="${REPOSITORY}/dev-backend:latest"
CONTAINER_NAME="spring-backend"
PORT=8080

echo "[INFO] 백엔드 배포 시작"

# 포트 점유 확인 및 컨테이너 제거
if lsof -i :$PORT &>/dev/null; then
  echo "[WARNING] Port $PORT is in use. Stopping existing container on that port..."
  CONTAINER_ID=$(docker ps --filter "publish=$PORT" --format "{{.ID}}")
  if [ -n "$CONTAINER_ID" ]; then
    docker stop "$CONTAINER_ID"
    docker rm "$CONTAINER_ID"
  fi
fi

# 이전 이름의 컨테이너 정리
echo "[INFO] Stopping previous container ($CONTAINER_NAME) if exists..."
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

# ECR 로그인
echo "[INFO] Logging into Amazon ECR..."
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin $REPOSITORY

# 이미지 pull
echo "[INFO] Pulling image: $IMAGE_NAME"
docker pull $IMAGE_NAME

# 새 컨테이너 실행
echo "[INFO] Running new container..."
docker run -d \
  --name $CONTAINER_NAME \
  -p $PORT:$PORT \
  $IMAGE_NAME

echo "[SUCCESS] Spring backend deployed on port $PORT"
