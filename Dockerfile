# Python 3.8 슬림 버전 사용
FROM python:3.8-slim

# 환경 변수 설정 (Python 버퍼링 비활성화 권장)
ENV PYTHONUNBUFFERED True

# 작업 디렉토리 설정
WORKDIR /app

# requirements.txt 파일을 먼저 복사하여 의존성 설치 레이어 캐싱 활용
COPY requirements.txt requirements.txt

# pip 업그레이드 및 의존성 설치
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 나머지 애플리케이션 코드를 작업 디렉토리로 복사
COPY . .

# Cloud Run이 기본적으로 사용하는 포트 8080 노출 (Gunicorn도 이 포트 사용)
EXPOSE 8080

# Gunicorn을 사용하여 앱 실행
# main:app 은 main.py 파일 안의 app 변수를 의미
# Cloud Run은 0.0.0.0 주소와 $PORT 환경 변수 사용을 권장 (기본값 8080)
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app 